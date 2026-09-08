[CmdletBinding()]
param(
  [string]$OutputDirectory,
  [string]$RequiredAncestor = '5f1bc43506d0e8f72af2c1d684ae7a819d4d72cc',
  [string]$RequiredBranch = 'codex-ieos-stage1-task-tracker',
  [switch]$InteractiveUat,
  [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedCliVersion = '2.116.0'
$Repository = [IO.Path]::GetFullPath($PSScriptRoot)
$RunId = [guid]::NewGuid().ToString('N')
$ProjectId = "ieos-stage1-$($RunId.Substring(0,12))"
$Lab = Join-Path ([IO.Path]::GetTempPath()) $ProjectId

if (-not $OutputDirectory) {
  $OutputDirectory = Join-Path ([IO.Path]::GetTempPath()) "$ProjectId-results"
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$ReportPath = Join-Path $OutputDirectory 'ieos-disposable-test-report.md'

$Results = [ordered]@{
  'Environment setup' = 'NOT RUN'
  'Public migration replay' = 'NOT RUN'
  'Stage 1 behavioural matrix' = 'NOT RUN'
  'Staging replay 001-008' = 'NOT RUN'
  'Database lint' = 'NOT RUN'
  'Approval/edit regression' = 'NOT RUN'
  'Desktop/mobile UAT' = $(if ($InteractiveUat) { 'NOT RUN' } else { 'NOT REQUESTED' })
  'Cleanup' = 'NOT RUN'
}

$AcceptancePassed = $false
$CleanupPassed = $false
$FailureMessage = ''
$CurrentPhase = $null
$StackAttempted = $false
$DbContainer = $null
$SupabaseExe = $null
$SupabasePrefix = @()
$TestedHead = 'NOT VERIFIED'
$NextProcess = $null

$StagingScripts = @(
  '001_mirror_schema.sql',
  '002_auth_access_rls.sql',
  '003_seed_test_users.sql',
  '004_content_core.sql',
  '005_migrate_legacy_content.sql',
  '006_approval_workflow.sql',
  '007_edit_support.sql',
  '008_approval_security_hardening.sql'
)

$PublicScripts = @(
  '0001_init.sql',
  '0002_org_business_unit_team.sql',
  '0003_auth_access_rls.sql',
  '0004_content_core.sql',
  '20260908113917_work_management_foundation.sql'
)

function Write-Utf8([string]$Path, [string]$Text) {
  [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

function Get-HarnessExitCode([bool]$TestsPassed, [bool]$DidCleanupPass) {
  if ($TestsPassed -and $DidCleanupPass) { return 0 }
  if ($TestsPassed -and -not $DidCleanupPass) { return 2 }
  if (-not $TestsPassed -and $DidCleanupPass) { return 1 }
  return 3
}

function Format-NativeCommand([string]$Executable, [string[]]$ArgumentList) {
  (@($Executable) + @($ArgumentList) | ForEach-Object {
    if ($_ -notmatch '^[A-Za-z0-9_./:\\=-]+$') { '"' + ($_ -replace '"', '""') + '"' } else { $_ }
  }) -join ' '
}

function Run-Native(
  [string]$Executable,
  [string[]]$ArgumentList,
  [string]$LogName,
  [switch]$AllowFailure
) {
  $logPath = Join-Path $OutputDirectory $LogName
  Write-Host "RUN: $(Format-NativeCommand $Executable $ArgumentList)"
  $savedPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $raw = @(& $Executable @ArgumentList 2>&1)
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $savedPreference
  }
  $lines = @($raw | ForEach-Object { "$_" })
  Write-Utf8 $logPath (($lines -join "`r`n") + "`r`n")
  $lines | ForEach-Object { Write-Host $_ }
  if ($code -ne 0 -and -not $AllowFailure) {
    throw "Command failed with exit code $code; see $logPath"
  }
  [pscustomobject]@{ Code = $code; Lines = $lines; Log = $logPath }
}

function Resolve-SupabaseCli {
  $pinned = 'C:\Users\USER\Documents\Codex\2026-08-27\project-inter-excel-operations-hub-model\work\stage1b-0020-local-lab\.lab-tools\node_modules\.bin\supabase.cmd'
  if ($env:SUPABASE_CLI -and (Test-Path -LiteralPath $env:SUPABASE_CLI)) {
    $script:SupabaseExe = $env:SUPABASE_CLI
    $script:SupabasePrefix = @()
  } elseif (Test-Path -LiteralPath $pinned) {
    $script:SupabaseExe = $pinned
    $script:SupabasePrefix = @()
  } else {
    $npx = (Get-Command npx.cmd -ErrorAction Stop).Source
    $script:SupabaseExe = $npx
    $script:SupabasePrefix = @('--yes', "supabase@$ExpectedCliVersion")
  }
  $versionResult = Run-Native $SupabaseExe (@($SupabasePrefix) + @('--version')) 'supabase-cli-version.log'
  $version = @($versionResult.Lines | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Select-Object -First 1)
  if ($version.Count -ne 1 -or $version[0].Trim() -ne $ExpectedCliVersion) {
    throw "Expected Supabase CLI $ExpectedCliVersion."
  }
}

function Run-Supabase([string[]]$ArgumentList, [string]$LogName, [switch]$AllowFailure) {
  $joined = (' ' + ($ArgumentList -join ' ') + ' ').ToLowerInvariant()
  foreach ($forbidden in @(
    ' --linked ', ' link ', ' db push ', ' db pull ', ' migration repair ',
    ' --db-url ', ' functions deploy ', ' projects ', ' secrets '
  )) {
    if ($joined.Contains($forbidden)) {
      throw "Safety guard rejected forbidden Supabase argument: $forbidden"
    }
  }
  Run-Native $SupabaseExe (@($SupabasePrefix) + @($ArgumentList)) $LogName -AllowFailure:$AllowFailure
}

function Run-Docker([string[]]$ArgumentList, [string]$LogName, [switch]$AllowFailure) {
  Run-Native 'docker.exe' $ArgumentList $LogName -AllowFailure:$AllowFailure
}

function Run-Sql([string]$SqlPath, [string]$LogName) {
  if (-not $DbContainer -or $DbContainer -notlike 'supabase_db_ieos-stage1-*') {
    throw 'Disposable local database container was not safely resolved.'
  }
  $remotePath = '/tmp/' + (([IO.Path]::GetFileName($SqlPath)) -replace '[^A-Za-z0-9_.-]', '_')
  Run-Docker @('cp', $SqlPath, "${DbContainer}:$remotePath") "copy-$LogName" | Out-Null
  Run-Docker @(
    'exec', $DbContainer, 'psql', '-X', '-q', '-A', '-t',
    '-v', 'ON_ERROR_STOP=1', '-U', 'postgres', '-d', 'postgres', '-f', $remotePath
  ) $LogName
}

function Read-Tap([string]$Path) {
  $passed = 0
  $failed = 0
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^ok\s+\d+\s*-') { $passed++ }
    elseif ($line -match '^not ok\s+\d+\s*-') { $failed++ }
  }
  [pscustomobject]@{ Pass = $passed; Fail = $failed; Total = $passed + $failed }
}

function Assert-DisposablePath([string]$Path) {
  $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
  $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
  if (-not $fullPath.StartsWith($tempRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing cleanup outside the Windows temporary directory: $fullPath"
  }
  if ((Split-Path -Leaf $fullPath) -notlike 'ieos-stage1-*') {
    throw "Refusing cleanup of unexpected directory: $fullPath"
  }
}

function Write-Report([int]$ExitCode) {
  $lines = @(
    '# IEOS Stage 1 task-management disposable test report',
    '',
    "- Repository: ``$Repository``",
    "- Required preserved ancestor: ``$RequiredAncestor``",
    "- Tested HEAD: ``$TestedHead``",
    "- Required branch: ``$RequiredBranch``",
    "- Disposable project: ``$ProjectId``",
    '- Hosted/production connectivity: prohibited by command guards, cleared environment variables, no link markers, and local/container-only database commands',
    "- Process exit code: **$ExitCode**",
    '',
    '## Phase results',
    '',
    '| Phase | Result |',
    '|---|---|'
  )
  foreach ($entry in $Results.GetEnumerator()) {
    $lines += "| $($entry.Key) | $($entry.Value -replace '\|', '\|') |"
  }
  if ($FailureMessage) {
    $lines += @('', '## Failure', '', $FailureMessage)
  }
  $lines += @(
    '',
    '## Exit-code contract',
    '',
    '- `0`: acceptance suites passed and cleanup passed',
    '- `1`: acceptance suite failed; cleanup passed',
    '- `2`: acceptance suites passed; cleanup failed',
    '- `3`: acceptance suite and cleanup both failed'
  )
  Write-Utf8 $ReportPath (($lines -join "`r`n") + "`r`n")
}

function Invoke-HarnessSelfTest {
  $cases = @(
    @{ Tests = $true; Cleanup = $true; Expected = 0 },
    @{ Tests = $false; Cleanup = $true; Expected = 1 },
    @{ Tests = $true; Cleanup = $false; Expected = 2 },
    @{ Tests = $false; Cleanup = $false; Expected = 3 }
  )
  foreach ($case in $cases) {
    $actual = Get-HarnessExitCode $case.Tests $case.Cleanup
    if ($actual -ne $case.Expected) {
      throw "Harness self-test failed: expected $($case.Expected), got $actual."
    }
  }
  Write-Host 'RESULT: PASS - harness exit-code self-test passed.'
}

if ($SelfTest) {
  Invoke-HarnessSelfTest
  exit 0
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

try {
  $CurrentPhase = 'Environment setup'
  $gitHead = (& git -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to determine repository HEAD.'
  }
  $TestedHead = $gitHead

  $gitBranch = (& git -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0 -or $gitBranch -ne $RequiredBranch) {
    throw "Repository branch must be $RequiredBranch. Actual: $gitBranch"
  }

  & git -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository merge-base --is-ancestor $RequiredAncestor $gitHead
  if ($LASTEXITCODE -ne 0) {
    throw "Repository HEAD is not descended from preserved baseline $RequiredAncestor. Actual: $gitHead"
  }

  $workingTree = @(& git -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository status --porcelain --untracked-files=all)
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to verify repository working tree.'
  }
  if ($workingTree.Count -gt 0) {
    throw 'Repository working tree must be clean before disposable acceptance.'
  }
  foreach ($scriptName in $PublicScripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $Repository "supabase\migrations\$scriptName"))) {
      throw "Missing public migration $scriptName"
    }
  }
  foreach ($scriptName in $StagingScripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $Repository "supabase\staging\$scriptName"))) {
      throw "Missing staging script $scriptName"
    }
  }
  foreach ($name in @(
    'SUPABASE_ACCESS_TOKEN', 'SUPABASE_DB_PASSWORD', 'SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY', 'DATABASE_URL', 'POSTGRES_URL', 'VERCEL_URL'
  )) {
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
  }
  $env:SUPABASE_TELEMETRY_DISABLED = '1'
  $env:DO_NOT_TRACK = '1'

  New-Item -ItemType Directory -Force -Path $Lab | Out-Null
  Push-Location $Lab
  try {
    Resolve-SupabaseCli
    Run-Supabase @('init', '--force') 'supabase-init.log' | Out-Null
    $configPath = Join-Path $Lab 'supabase\config.toml'
    $config = Get-Content -LiteralPath $configPath -Raw
    $config = [regex]::Replace($config, '(?m)^project_id\s*=\s*"[^"]+"', "project_id = `"$ProjectId`"")
    Write-Utf8 $configPath $config

    $dockerInfo = Run-Docker @('info', '--format', '{{.ServerVersion}}|{{.OSType}}') 'docker-info.log'
    if (($dockerInfo.Lines -join ' ') -notmatch '\|linux') {
      throw 'Docker must be available in Linux-container mode.'
    }

    $StackAttempted = $true
    Run-Supabase @('start') 'environment-start.log' | Out-Null
    $containers = Run-Docker @(
      'ps', '--filter', "name=^/supabase_db_$ProjectId$", '--format', '{{.Names}}'
    ) 'database-container.log'
    $containerNames = @($containers.Lines | Where-Object { $_.Trim() })
    if ($containerNames.Count -ne 1) { throw 'Disposable database container was not uniquely resolved.' }
    $DbContainer = $containerNames[0].Trim()
    $Results['Environment setup'] = "PASS - local Docker/Supabase project $ProjectId; no hosted link"

    $CurrentPhase = 'Public migration replay'
    foreach ($scriptName in $PublicScripts) {
      Run-Sql (Join-Path $Repository "supabase\migrations\$scriptName") "public-$scriptName.log" | Out-Null
    }
    $Results['Public migration replay'] = 'PASS - 0001-0004 plus additive Stage 1 migration'

    $CurrentPhase = 'Stage 1 behavioural matrix'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage1_work_management_fixtures.sql') 'stage1-fixtures.log' | Out-Null
    $stage1Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage1_work_management_behavioural.sql') 'stage1-behavioural-matrix-60.log'
    $stage1Tap = Read-Tap $stage1Matrix.Log
    if ($stage1Tap.Total -ne 60 -or $stage1Tap.Fail -ne 0) {
      throw "Stage 1 behavioural matrix failed: $($stage1Tap.Pass) passed, $($stage1Tap.Fail) failed, expected 60 tests."
    }
    $Results['Stage 1 behavioural matrix'] = 'PASS - 60/60 identity, scope, evidence, completion, attention and audit tests'

    $CurrentPhase = 'Staging replay 001-008'
    foreach ($scriptName in $StagingScripts) {
      Run-Sql (Join-Path $Repository "supabase\staging\$scriptName") "replay-$scriptName.log" | Out-Null
    }
    $Results['Staging replay 001-008'] = 'PASS - clean local replay in exact order'

    $CurrentPhase = 'Database lint'
    Run-Supabase @('db', 'lint', '--local', '--fail-on', 'error') 'database-lint.log' | Out-Null
    $Results['Database lint'] = 'PASS - Supabase database lint (error threshold)'

    $CurrentPhase = 'Approval/edit regression'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\008_ieos_staging_fixtures.sql') 'behavioural-fixtures.log' | Out-Null
    $matrix = Run-Sql (Join-Path $Repository 'supabase\tests\008_ieos_approval_edit_behavioural.sql') 'behavioural-matrix-35.log'
    $tap = Read-Tap $matrix.Log
    if ($tap.Total -ne 35 -or $tap.Fail -ne 0) {
      throw "Behavioural matrix failed: $($tap.Pass) passed, $($tap.Fail) failed, expected 35 tests."
    }
    $Results['Approval/edit regression'] = 'PASS - 35/35'

    if ($InteractiveUat) {
      $CurrentPhase = 'Desktop/mobile UAT'
      $savedPreference = $ErrorActionPreference
      try {
        $ErrorActionPreference = 'Continue'
        $statusLines = @(& $SupabaseExe @SupabasePrefix status --output env 2>$null)
        $statusCode = $LASTEXITCODE
      } finally {
        $ErrorActionPreference = $savedPreference
      }
      if ($statusCode -ne 0) { throw 'Could not read disposable local Supabase status for UAT.' }
      $localApi = (($statusLines | Where-Object { $_ -match '^API_URL=' } | Select-Object -First 1) -replace '^API_URL="?([^"\r\n]+)"?$', '$1')
      $localAnonKey = (($statusLines | Where-Object { $_ -match '^ANON_KEY=' } | Select-Object -First 1) -replace '^ANON_KEY="?([^"\r\n]+)"?$', '$1')
      if (-not $localApi.StartsWith('http://127.0.0.1:') -or -not $localAnonKey) {
        throw 'Disposable UAT credentials were not resolved as loopback-only.'
      }
      $env:NEXT_PUBLIC_SUPABASE_URL = $localApi
      $env:NEXT_PUBLIC_SUPABASE_ANON_KEY = $localAnonKey
      $env:NEXT_PUBLIC_SUPABASE_SCHEMA = 'public'
      $nextStdout = Join-Path $OutputDirectory 'uat-next.log'
      $nextStderr = Join-Path $OutputDirectory 'uat-next-error.log'
      $nextExe = Join-Path $Repository 'node_modules\.bin\next.cmd'
      if (-not (Test-Path -LiteralPath $nextExe)) { throw 'Local Next.js executable is unavailable.' }
      # Webpack supports the safe local node_modules junction used by this
      # preserved worktree; Turbopack intentionally rejects links outside its root.
      $NextProcess = Start-Process -FilePath $nextExe -ArgumentList @('dev','--webpack','--hostname','127.0.0.1','--port','3201') -WorkingDirectory $Repository -WindowStyle Hidden -PassThru -RedirectStandardOutput $nextStdout -RedirectStandardError $nextStderr
      $ready = $false
      for ($attempt = 0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Seconds 1
        try {
          $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:3201/login' -TimeoutSec 2
          if ($response.StatusCode -eq 200) { $ready = $true; break }
        } catch { }
      }
      if (-not $ready) { throw "Local UAT app did not start; see $nextStderr" }
      Write-Host 'LOCAL UAT READY: http://127.0.0.1:3201/login'
      Write-Host 'Synthetic accounts: director@stage1.ieos.test, manager@stage1.ieos.test, intern@stage1.ieos.test'
      Write-Host 'Synthetic password: IEOS-Stage1-UAT-Only!'
      $uatConfirmation = Read-Host 'After desktop/mobile UAT, type PASS to finish and clean up'
      if ($uatConfirmation -ne 'PASS') { throw 'Interactive UAT was not confirmed as PASS.' }
      $Results['Desktop/mobile UAT'] = 'PASS - operator confirmed desktop and mobile-width checks against synthetic local data'
    }
    $AcceptancePassed = $true
  } finally {
    Pop-Location
  }
} catch {
  $FailureMessage = $_.Exception.Message
  if ($CurrentPhase -and $Results.Contains($CurrentPhase) -and $Results[$CurrentPhase] -notlike 'PASS*') {
    $Results[$CurrentPhase] = "FAIL - $FailureMessage"
  }
  Write-Host "ACCEPTANCE FAILURE: $FailureMessage"
} finally {
  try {
    if ($NextProcess -and -not $NextProcess.HasExited) {
      Stop-Process -Id $NextProcess.Id -Force -ErrorAction Stop
      $NextProcess.WaitForExit(5000)
    }
    if ($StackAttempted -and $SupabaseExe) {
      Push-Location $Lab
      try {
        $stop = Run-Supabase @('stop', '--project-id', $ProjectId, '--no-backup') 'cleanup-stop.log' -AllowFailure
      } finally {
        Pop-Location
      }
      if ($stop.Code -ne 0) { throw "Supabase stop returned exit code $($stop.Code)." }
    }
    Assert-DisposablePath $Lab
    if (Test-Path -LiteralPath $Lab) { Remove-Item -LiteralPath $Lab -Recurse -Force }
    if (Test-Path -LiteralPath $Lab) { throw 'Disposable lab directory still exists.' }
    $CleanupPassed = $true
    $Results['Cleanup'] = 'PASS - local stack stopped without backup; temporary lab removed'
  } catch {
    $Results['Cleanup'] = "FAIL - $($_.Exception.Message)"
    if (-not $FailureMessage) { $FailureMessage = 'Cleanup failure: ' + $_.Exception.Message }
    Write-Host "CLEANUP FAILURE: $($_.Exception.Message)"
  }

  $exitCode = Get-HarnessExitCode $AcceptancePassed $CleanupPassed
  Write-Report $exitCode
  Write-Host "Report: $ReportPath"
  if ($exitCode -eq 0) {
    Write-Host 'RESULT: PASS - Stage 1 replay, security, regression, lint, and cleanup completed.'
  } elseif ($exitCode -eq 2) {
    Write-Host 'RESULT: TESTS PASSED; CLEANUP FAILED - see report.'
  } else {
    Write-Host 'RESULT: FAIL - see phase results and report.'
  }
}

exit $exitCode
