[CmdletBinding()]
param(
  [string]$OutputDirectory,
  [string]$RequiredAncestor = '9cdd4ab0fb7e5db9f504dae29d35cc1fc7a9d01c',
  [string]$RequiredBranch = 'codex-ieos-stage5-marketing-leads',
  [switch]$InteractiveUat,
  [switch]$AllowUncommittedCandidate,
  [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedCliVersion = '2.116.0'
$Repository = [IO.Path]::GetFullPath($PSScriptRoot)
$RunId = [guid]::NewGuid().ToString('N')
$ProjectId = "ieos-stage5-$($RunId.Substring(0,12))"
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
  'Stage 2 behavioural matrix' = 'NOT RUN'
  'Stage 3 dashboard matrix' = 'NOT RUN'
  'Stage 4 master-file matrix' = 'NOT RUN'
  'Stage 5 marketing-lead matrix' = 'NOT RUN'
  'Staging replay 001-010' = 'NOT RUN'
  'Migration transaction rollback' = 'NOT RUN'
  'Recovery restore drill' = 'NOT RUN'
  'Public approval/edit regression' = 'NOT RUN'
  'P0 legacy security matrix' = 'NOT RUN'
  'Final privilege security matrix' = 'NOT RUN'
  'Incremental hosted-shape adoption drill' = 'NOT RUN'
  'Historical staging quarantine drill' = 'NOT RUN'
  'Database lint' = 'NOT RUN'
  'Local security advisors' = 'NOT RUN'
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
  '008_approval_security_hardening.sql',
  '009_p0_legacy_security.sql',
  '010_p0_final_privilege_lockdown.sql'
)

$PublicScripts = @(
  '0001_init.sql',
  '0002_org_business_unit_team.sql',
  '0003_auth_access_rls.sql',
  '0004_content_core.sql',
  '20260908113917_work_management_foundation.sql'
  '20260910101811_stage2_daily_output_log.sql'
  '20260910142301_stage3_manager_dashboard.sql'
  '20260913053937_stage4_master_file_register.sql'
  '20260913073400_stage5_restricted_marketing_leads.sql'
  '20260913142730_stage5_lead_form_configuration.sql'
  '20261011182326_p0_public_workflow_compatibility.sql'
  '20261011182327_p0_legacy_security.sql'
  '20261012015213_p0_final_legacy_privilege_lockdown.sql'
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
  $lines = @($raw | ForEach-Object { $line = "$_"; if ($line -match '"ANON_KEY"|"SERVICE_ROLE_KEY"') { '{"local_stack_status":"returned","credentials":"[redacted]"}' } else { $line } })
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
    throw 'Pinned local Supabase CLI is unavailable; package installation is not part of this test run.'
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

function Run-Sql([string]$SqlPath, [string]$LogName, [string]$Database = 'postgres') {
  if ($Database -notin @('postgres','p0_recovery','p0_hosted_adoption')) { throw 'Unknown disposable database.' }
  if (-not $DbContainer -or $DbContainer -notlike 'supabase_db_ieos-stage5-*') {
    throw 'Disposable local database container was not safely resolved.'
  }
  $remotePath = '/tmp/' + (([IO.Path]::GetFileName($SqlPath)) -replace '[^A-Za-z0-9_.-]', '_')
  Run-Docker @('cp', $SqlPath, "${DbContainer}:$remotePath") "copy-$LogName" | Out-Null
  Run-Docker @(
    'exec', $DbContainer, 'psql', '-X', '-q', '-A', '-t',
    '-v', 'ON_ERROR_STOP=1', '-U', 'postgres', '-d', $Database, '-f', $remotePath
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
  if ((Split-Path -Leaf $fullPath) -notlike 'ieos-stage5-*') {
    throw "Refusing cleanup of unexpected directory: $fullPath"
  }
}

function Write-Report([int]$ExitCode) {
  $lines = @(
    '# IEOS P0 sealed local candidate disposable test report',
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
  $gitHead = (& git --no-optional-locks -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to determine repository HEAD.'
  }
  $TestedHead = $gitHead

  $gitBranch = (& git --no-optional-locks -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository branch --show-current).Trim()
  if ($LASTEXITCODE -ne 0 -or $gitBranch -ne $RequiredBranch) {
    throw "Repository branch must be $RequiredBranch. Actual: $gitBranch"
  }

  & git --no-optional-locks -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository merge-base --is-ancestor $RequiredAncestor $gitHead
  if ($LASTEXITCODE -ne 0) {
    throw "Repository HEAD is not descended from preserved baseline $RequiredAncestor. Actual: $gitHead"
  }

  $workingTree = @(& git --no-optional-locks -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository status --porcelain --untracked-files=all)
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to verify repository working tree.'
  }
  if ($workingTree.Count -gt 0) {
    if (-not $AllowUncommittedCandidate) { throw 'Working tree is uncommitted; use the explicit sealed-candidate test mode.' }
  }
  $candidateFiles = @(& git --no-optional-locks -c "safe.directory=$($Repository -replace '\\','/')" -C $Repository ls-files --cached --others --exclude-standard)
  $candidateManifest = @($candidateFiles | Sort-Object -Unique | ForEach-Object {
    $filePath = Join-Path $Repository $_
    if (Test-Path -LiteralPath $filePath -PathType Leaf) {
      [pscustomobject]@{ Path = $_; SHA256 = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash }
    }
  })
  Write-Utf8 (Join-Path $OutputDirectory 'candidate-manifest.json') ($candidateManifest | ConvertTo-Json -Depth 3)
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
    'SUPABASE_SERVICE_ROLE_KEY', 'DATABASE_URL', 'POSTGRES_URL', 'VERCEL_URL',
    'NEXT_PUBLIC_SUPABASE_URL','NEXT_PUBLIC_SUPABASE_ANON_KEY','NEXT_PUBLIC_APP_URL',
    'STRIPE_SECRET_KEY','STRIPE_WEBHOOK_SECRET','OPENAI_API_KEY','GOOGLE_APPLICATION_CREDENTIALS'
  )) {
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
  }
  $envFiles = @(Get-ChildItem -LiteralPath $Repository -Force -File | Where-Object { $_.Name -like '.env*' -and $_.Name -ne '.env.example' })
  if ($envFiles.Count -gt 0) { throw 'Local .env files exist: isolate the candidate before starting a disposable server.' }
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
    if ($InteractiveUat) {
      $config = [regex]::Replace($config, '(?m)^site_url\s*=\s*"[^"]+"', 'site_url = "http://127.0.0.1:3201"')
      $config = [regex]::Replace($config, '(?m)^additional_redirect_urls\s*=\s*\[[^\r\n]*\]', 'additional_redirect_urls = ["http://127.0.0.1:3201/auth/callback"]')
      if ($config -notmatch '(?m)^site_url\s*=\s*"http://127\.0\.0\.1:3201"$' -or
          $config -notmatch '(?m)^additional_redirect_urls\s*=\s*\["http://127\.0\.0\.1:3201/auth/callback"\]$') {
        throw 'Disposable Supabase UAT redirect configuration could not be constrained to port 3201.'
      }
    }
    # Isolated ports: never stop or reuse another local Supabase project.
    $config = [regex]::Replace($config, '\b5432[0-9]\b', { param($match) ([int]$match.Value + 1110).ToString() })
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
      if ($scriptName -eq '20261011182326_p0_public_workflow_compatibility.sql') {
        $CurrentPhase = 'Migration transaction rollback'
        $trial = "begin;
" + ((@('20261011182326_p0_public_workflow_compatibility.sql','20261011182327_p0_legacy_security.sql','20261012015213_p0_final_legacy_privilege_lockdown.sql') | ForEach-Object {
          (Get-Content -LiteralPath (Join-Path $Repository "supabase\migrations\$_") -Raw) -replace '(?m)^begin;\s*$','' -replace '(?m)^commit;\s*$',''
        }) -join "
") + "
rollback;
"
        $trialPath = Join-Path $Lab 'p0-transaction-rollback.sql'
        Write-Utf8 $trialPath $trial
        Run-Docker @('exec',$DbContainer,'sh','-c','pg_dump -U postgres -d postgres --schema-only --schema=public --schema=staging --restrict-key=IEOSP0Rollback2026 | sed "/^\\restrict /d;/^\\unrestrict /d" > /tmp/p0-before.sql') 'rollback-before.log' | Out-Null

        $defaultsQuery = "select md5(coalesce(string_agg(row(d.defaclrole::regrole::text,coalesce(n.nspname,''),d.defaclobjtype,d.defaclacl::text)::text,chr(10) order by d.defaclrole,d.defaclnamespace,d.defaclobjtype),'')) from pg_default_acl d left join pg_namespace n on n.oid=d.defaclnamespace"
        $defaultsBefore = Run-Docker @('exec',$DbContainer,'psql','-X','-q','-A','-t','-v','ON_ERROR_STOP=1','-U','postgres','-d','postgres','-c',$defaultsQuery) 'rollback-defaults-before.log'
        Run-Sql $trialPath 'p0-transaction-rollback.log' | Out-Null

        $defaultsAfter = Run-Docker @('exec',$DbContainer,'psql','-X','-q','-A','-t','-v','ON_ERROR_STOP=1','-U','postgres','-d','postgres','-c',$defaultsQuery) 'rollback-defaults-after.log'
        if (($defaultsBefore.Lines -join '') -ne ($defaultsAfter.Lines -join '')) { throw 'Rollback did not preserve global/schema default privileges.' }

        Run-Docker @('exec',$DbContainer,'sh','-c','pg_dump -U postgres -d postgres --schema-only --schema=public --schema=staging --restrict-key=IEOSP0Rollback2026 | sed "/^\\restrict /d;/^\\unrestrict /d" > /tmp/p0-after.sql; cmp /tmp/p0-before.sql /tmp/p0-after.sql') 'rollback-schema-compare.log' | Out-Null
        $Results['Migration transaction rollback']='PASS - candidate migrations rolled back atomically; public/staging schema, owners, ACLs and global/schema defaults unchanged'
        $CurrentPhase = 'Public migration replay'
      }
      Run-Sql (Join-Path $Repository "supabase\migrations\$scriptName") "public-$scriptName.log" | Out-Null
    }
    $Results['Public migration replay'] = 'PASS - explicit legacy baseline, Stages 1–5, pending configuration and P0 migrations'

    $CurrentPhase = 'Stage 1 behavioural matrix'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage1_work_management_fixtures.sql') 'stage1-fixtures.log' | Out-Null
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage2_daily_output_fixtures.sql') 'stage2-fixtures.log' | Out-Null
    $stage1Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage1_work_management_behavioural.sql') 'stage1-behavioural-matrix-60.log'
    $stage1Tap = Read-Tap $stage1Matrix.Log
    if ($stage1Tap.Total -ne 60 -or $stage1Tap.Fail -ne 0) {
      throw "Stage 1 behavioural matrix failed: $($stage1Tap.Pass) passed, $($stage1Tap.Fail) failed, expected 60 tests."
    }
    $Results['Stage 1 behavioural matrix'] = 'PASS - 60/60 identity, scope, evidence, completion, attention and audit tests'

    $CurrentPhase = 'Stage 2 behavioural matrix'
    $stage2Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage2_daily_output_behavioural.sql') 'stage2-behavioural-matrix-35.log'
    $stage2Tap = Read-Tap $stage2Matrix.Log
    if ($stage2Tap.Total -ne 35 -or $stage2Tap.Fail -ne 0) {
      throw "Stage 2 behavioural matrix failed: $($stage2Tap.Pass) passed, $($stage2Tap.Fail) failed, expected 35 tests."
    }
    $Results['Stage 2 behavioural matrix'] = 'PASS - 35/35 daily-output identity, scope, evidence, immutability, review and activity tests'

    $CurrentPhase = 'Stage 3 dashboard matrix'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage3_manager_dashboard_fixtures.sql') 'stage3-fixtures.log' | Out-Null
    $stage3Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage3_manager_dashboard_behavioural.sql') 'stage3-dashboard-matrix-60.log'
    $stage3Tap = Read-Tap $stage3Matrix.Log
    if ($stage3Tap.Total -ne 60 -or $stage3Tap.Fail -ne 0) {
      throw "Stage 3 dashboard matrix failed: $($stage3Tap.Pass) passed, $($stage3Tap.Fail) failed, expected 60 tests."
    }
    $Results['Stage 3 dashboard matrix'] = 'PASS - 60/60 dashboard access, canonical flags, working-day, workload, review and aggregate-leakage tests'

    $CurrentPhase = 'Stage 4 master-file matrix'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage4_master_file_fixtures.sql') 'stage4-fixtures.log' | Out-Null
    $stage4Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage4_master_file_behavioural.sql') 'stage4-master-file-matrix-92.log'
    $stage4Tap = Read-Tap $stage4Matrix.Log
    if ($stage4Tap.Total -ne 92 -or $stage4Tap.Fail -ne 0) {
      throw "Stage 4 master-file matrix failed: $($stage4Tap.Pass) passed, $($stage4Tap.Fail) failed, expected 92 tests."
    }
    $Results['Stage 4 master-file matrix'] = 'PASS - 92/92 RLS, scoped search, P&C leakage, lifecycle, relationships and audit tests'

    $CurrentPhase = 'Stage 5 marketing-lead matrix'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\stage5_marketing_lead_fixtures.sql') 'stage5-fixtures.log' | Out-Null
    $stage5Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\stage5_marketing_lead_behavioural.sql') 'stage5-marketing-lead-matrix-66.log'
    $stage5Tap = Read-Tap $stage5Matrix.Log
    if ($stage5Tap.Total -ne 66 -or $stage5Tap.Fail -ne 0) {
      throw "Stage 5 marketing-lead matrix failed: $($stage5Tap.Pass) passed, $($stage5Tap.Fail) failed, expected 60 tests."
    }
    $Results['Stage 5 marketing-lead matrix'] = 'PASS - 66/66 PII, scope, appointment, follow-up, duplicate, history, task-privacy and audit tests'

    $CurrentPhase = 'Staging replay 001-010'
    foreach ($scriptName in $StagingScripts) {
      Run-Sql (Join-Path $Repository "supabase\staging\$scriptName") "replay-$scriptName.log" | Out-Null
    }
    $Results['Staging replay 001-010'] = 'PASS - clean local replay in exact order'

    $CurrentPhase = 'Database lint'
    Run-Supabase @('db', 'lint', '--local', '--fail-on', 'error') 'database-lint.log' | Out-Null
    $Results['Database lint'] = 'PASS - Supabase database lint (error threshold)'
    $CurrentPhase = 'Local security advisors'
    Run-Supabase @('db','advisors','--local','--type','security','--fail-on','error') 'local-security-advisors.log' | Out-Null
    $Results['Local security advisors']='PASS - local security advisor error gate; see log for warnings'


    $CurrentPhase = 'Approval/edit regression'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\008_ieos_staging_fixtures.sql') 'behavioural-fixtures.log' | Out-Null
    $matrix = Run-Sql (Join-Path $Repository 'supabase\tests\008_ieos_approval_edit_behavioural.sql') 'behavioural-matrix-35.log'
    $tap = Read-Tap $matrix.Log
    if ($tap.Total -ne 35 -or $tap.Fail -ne 0) {
      throw "Behavioural matrix failed: $($tap.Pass) passed, $($tap.Fail) failed, expected 35 tests."
    }
    $Results['Approval/edit regression'] = 'PASS - 35/35'

    $CurrentPhase = 'Public approval/edit regression'
    Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_public_approval_fixtures.sql') 'public-approval-fixtures.log' | Out-Null
    $publicMatrix = Run-Sql (Join-Path $Repository 'supabase\tests\p0_public_approval_behavioural.sql') 'public-approval-matrix-35.log'
    $publicTap = Read-Tap $publicMatrix.Log
    if ($publicTap.Total -ne 35 -or $publicTap.Fail -ne 0) { throw 'Public approval regression failed.' }
    $Results['Public approval/edit regression']='PASS - 35/35 against public schema'
    $CurrentPhase = 'P0 legacy security matrix'
    $p0Matrix = Run-Sql (Join-Path $Repository 'supabase\tests\p0_legacy_security_behavioural.sql') 'p0-legacy-security.log'
    $p0Tap = Read-Tap $p0Matrix.Log
    if ($p0Tap.Total -ne 66 -or $p0Tap.Fail -ne 0) { throw "P0 security matrix failed: $($p0Tap.Pass) passed; $($p0Tap.Fail) failed." }
    $Results['P0 legacy security matrix']='PASS - 66/66 legacy negative-access, activity, roles, workflow and readiness checks'

    $CurrentPhase = 'Final privilege security matrix'
    $finalMatrix = Run-Sql (Join-Path $Repository 'supabase\tests\p0_final_privilege_behavioural.sql') 'p0-final-privilege-security.log'
    $finalTap = Read-Tap $finalMatrix.Log
    if ($finalTap.Total -ne 270 -or $finalTap.Fail -ne 0) { throw 'Final privilege matrix failed.' }
    $Results['Final privilege security matrix']='PASS - 270/270 effective grants, callable functions, defaults and actual negative SQL operations'
    $CurrentPhase = 'Recovery restore drill'
    Run-Docker @('exec',$DbContainer,'pg_dump','-U','postgres','-d','postgres','-Fc','--schema=public','--schema=staging','--schema=auth','--schema=extensions','--schema=ieos_stage1_test','-f','/tmp/p0-recovery.dump') 'recovery-backup.log' | Out-Null

    # Schema-filtered pg_dump excludes global defaults. Back up their exact SQL separately.
    Run-Docker @('exec',$DbContainer,'sh','-c',"pg_dump -U postgres -d postgres --schema-only --section=post-data --restrict-key=IEOSP0DefaultACL2026 -f /tmp/p0-default-metadata.sql && sed -n '/^ALTER DEFAULT PRIVILEGES FOR ROLE postgres /{/ IN SCHEMA /!p;}' /tmp/p0-default-metadata.sql > /tmp/p0-global-default-acls.sql && test -s /tmp/p0-global-default-acls.sql") 'recovery-global-defaults-backup.log' | Out-Null
    $defaultOriginal = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_default_acl_fingerprint.sql') 'recovery-defaults-original.log'
    Run-Docker @('exec',$DbContainer,'createdb','-U','postgres','p0_recovery') 'recovery-createdb.log' | Out-Null
    Run-Docker @('exec',$DbContainer,'pg_restore','-U','supabase_admin','-d','p0_recovery','--clean','--if-exists','--exit-on-error','/tmp/p0-recovery.dump') 'recovery-restore.log' | Out-Null

    Run-Docker @('exec',$DbContainer,'psql','-X','-q','-v','ON_ERROR_STOP=1','-U','supabase_admin','-d','p0_recovery','-f','/tmp/p0-global-default-acls.sql') 'recovery-global-defaults-restore.log' | Out-Null
    $defaultRestored = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_default_acl_fingerprint.sql') 'recovery-defaults-restored.log' 'p0_recovery'
    if (($defaultOriginal.Lines -join '') -ne ($defaultRestored.Lines -join '')) { throw 'Recovery changed affected global/public/staging default ACLs.' }
    $original = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_database_fingerprint.sql') 'recovery-original-checksum.log'
    $restored = Run-Docker @('exec',$DbContainer,'psql','-X','-q','-A','-t','-v','ON_ERROR_STOP=1','-U','postgres','-d','p0_recovery','-f','/tmp/p0_database_fingerprint.sql') 'recovery-restored-checksum.log'
    $originalHash = @($original.Lines | Where-Object { $_ -match '^[a-f0-9]{32}$' })
    $restoredHash = @($restored.Lines | Where-Object { $_ -match '^[a-f0-9]{32}$' })
    if ($originalHash.Count -ne 1 -or $restoredHash.Count -ne 1 -or $originalHash[0] -ne $restoredHash[0]) { throw 'Restored application/auth records do not match the original checksum.' }
    $restoredSecurity = Run-Docker @('exec',$DbContainer,'psql','-X','-q','-A','-t','-v','ON_ERROR_STOP=1','-U','postgres','-d','p0_recovery','-f','/tmp/p0_legacy_security_behavioural.sql') 'recovery-restored-security.log'
    $restoredTap = Read-Tap $restoredSecurity.Log
    if ($restoredTap.Total -ne 66 -or $restoredTap.Fail -ne 0) { throw 'Restored database security regression failed.' }

    $restoredFinal = Run-Sql (Join-Path $Repository 'supabase\tests\p0_final_privilege_behavioural.sql') 'recovery-restored-final-security.log' 'p0_recovery'
    $restoredFinalTap = Read-Tap $restoredFinal.Log
    if ($restoredFinalTap.Total -ne 270 -or $restoredFinalTap.Fail -ne 0) { throw 'Restored final privilege regression failed.' }
    $Results['Recovery restore drill']='PASS - logical restore preserves all application/Auth records, ownership/default ACLs and 336/336 legacy/final security assertions'
    $CurrentPhase = 'Incremental hosted-shape adoption drill'
    Run-Docker @('exec',$DbContainer,'createdb','-U','postgres','p0_hosted_adoption') 'adoption-createdb.log' | Out-Null
    Run-Docker @('exec',$DbContainer,'pg_dump','-U','postgres','-d','postgres','-Fc','--schema=auth','--schema=extensions','--schema=ieos_stage1_test','-f','/tmp/p0-model-support.dump') 'adoption-support-backup.log' | Out-Null
    Run-Docker @('exec',$DbContainer,'pg_restore','-U','supabase_admin','-d','p0_hosted_adoption','--clean','--if-exists','--exit-on-error','/tmp/p0-model-support.dump') 'adoption-support-restore.log' | Out-Null
    # Historical baseline below constructs the SYNTHETIC model only, never the adoption list.
    foreach ($base in @('0001_init.sql','0002_org_business_unit_team.sql','0003_auth_access_rls.sql','0004_content_core.sql')) {
      Run-Sql (Join-Path $Repository "supabase\migrations\$base") "adoption-model-$base.log" 'p0_hosted_adoption' | Out-Null
    }
    foreach ($base in @('001_mirror_schema.sql','002_auth_access_rls.sql','004_content_core.sql','005_migrate_legacy_content.sql','006_approval_workflow.sql','007_edit_support.sql')) {
      Run-Sql (Join-Path $Repository "supabase\staging\$base") "adoption-model-$base.log" 'p0_hosted_adoption' | Out-Null
    }
    $model = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_hosted_model_prepare.sql') 'adoption-model-preflight.log' 'p0_hosted_adoption'
    $modelTap = Read-Tap $model.Log
    if ($modelTap.Total -ne 7 -or $modelTap.Fail -ne 0) { throw 'Hosted-shape model failed recorded metadata checks.' }
    foreach ($incremental in @($PublicScripts | Select-Object -Skip 4)) {
      $version = $incremental.Split('_')[0]
      $name = [IO.Path]::GetFileNameWithoutExtension($incremental).Substring($version.Length+1)
      $body = (Get-Content -LiteralPath (Join-Path $Repository "supabase\migrations\$incremental") -Raw) -replace '(?m)^begin;\s*$','' -replace '(?m)^commit;\s*$',''
      $atomicPath = Join-Path $Lab "adoption-atomic-$incremental"
      Write-Utf8 $atomicPath ("begin;"+[Environment]::NewLine+$body+[Environment]::NewLine+"insert into supabase_migrations.schema_migrations(version,name) values('$version','$name');"+[Environment]::NewLine+"commit;"+[Environment]::NewLine)
      Run-Sql $atomicPath "adoption-incremental-$incremental.log" 'p0_hosted_adoption' | Out-Null
    }
    $adoption = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_hosted_model_verify.sql') 'adoption-preservation-results.log' 'p0_hosted_adoption'
    $adoptionTap = Read-Tap $adoption.Log
    if ($adoptionTap.Total -ne 9 -or $adoptionTap.Fail -ne 0) { throw 'Incremental adoption/preservation failed.' }
    $Results['Incremental hosted-shape adoption drill']='PASS - 7 baseline/9 adoption assertions; nine forward migrations only; historical records and ledger preserved'
    $CurrentPhase = 'Historical staging quarantine drill'
    $quarantine = Run-Sql (Join-Path $Repository 'supabase\tests\support\p0_staging_quarantine_drill.sql') 'adoption-staging-quarantine.log' 'p0_hosted_adoption'
    $quarantineTap = Read-Tap $quarantine.Log
    if ($quarantineTap.Total -ne 4 -or $quarantineTap.Fail -ne 0) { throw 'Staging quarantine preservation failed.' }
    $Results['Historical staging quarantine drill']='PASS - 4/4 API-role denial/record preservation assertions; no hosted configuration change'
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
      $env:NEXT_PUBLIC_APP_URL = 'http://127.0.0.1:3201'
      $env:IEOS_LOCAL_UAT = '1'
      $env:TZ = 'UTC'
      $nextStdout = Join-Path $OutputDirectory 'uat-next.log'
      $nextStderr = Join-Path $OutputDirectory 'uat-next-error.log'
      $nextCli = Join-Path $Repository 'node_modules\next\dist\bin\next'
      $nodeExe = (Get-Command node.exe -ErrorAction Stop).Source
      if (-not (Test-Path -LiteralPath $nextCli)) { throw 'Local Next.js executable is unavailable.' }
      $portProbe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 3201)
      try {
        $portProbe.Start()
      } catch {
        throw 'Local UAT port 3201 is already in use; refusing to reuse an unrelated or stale server.'
      } finally {
        $portProbe.Stop()
      }
      # This Next.js version uses Webpack by default when --turbopack is absent.
      # Webpack supports the safe node_modules junction used by this worktree.
      # Launch Node directly so cleanup owns the actual development-server process,
      # rather than only the transient next.cmd wrapper.
      $NextProcess = Start-Process -FilePath $nodeExe -ArgumentList @($nextCli,'dev','--hostname','127.0.0.1','--port','3201') -WorkingDirectory $Repository -WindowStyle Hidden -PassThru -RedirectStandardOutput $nextStdout -RedirectStandardError $nextStderr
      $ready = $false
      # A cold Windows/Webpack start can spend more than 30 seconds compiling
      # middleware and the login route even after Next reports itself ready.
      for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 1
        if ($NextProcess.HasExited) { break }
        try {
          $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:3201/login' -TimeoutSec 2
          if ($response.StatusCode -eq 200) { $ready = $true; break }
        } catch { }
      }
      if (-not $ready) { throw "Local UAT app did not start; see $nextStdout and $nextStderr" }
      Write-Host 'LOCAL UAT READY: http://127.0.0.1:3201/login'
      Write-Host 'Synthetic accounts: director@stage1.ieos.test, manager@stage1.ieos.test, intern@stage1.ieos.test'
      Write-Host 'Synthetic UAT credentials are confined to the local fixture.'
      $uatSignal = Join-Path $OutputDirectory 'uat-pass.signal'
      if (Test-Path -LiteralPath $uatSignal) { Remove-Item -LiteralPath $uatSignal -Force }
      Write-Host "Waiting for Codex UAT completion signal: $uatSignal"
      $uatConfirmed = $false
      for ($attempt = 0; $attempt -lt 720; $attempt++) {
        Start-Sleep -Seconds 5
        if (Test-Path -LiteralPath $uatSignal) {
          $uatConfirmed = (Get-Content -LiteralPath $uatSignal -Raw).Trim() -eq 'PASS'
          break
        }
      }
      if (-not $uatConfirmed) { throw 'Interactive UAT was not confirmed as PASS before timeout.' }
      Remove-Item -LiteralPath $uatSignal -Force
      $Results['Desktop/mobile UAT'] = 'PASS - Codex completed desktop and mobile-width checks against synthetic local data'
    }
    foreach ($candidateFile in $candidateManifest) {
      if ((Get-FileHash -LiteralPath (Join-Path $Repository $candidateFile.Path) -Algorithm SHA256).Hash -ne $candidateFile.SHA256) {
        throw "Candidate changed during testing: $($candidateFile.Path)"
      }
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
    Write-Host 'RESULT: PASS - Stage 5 replay, security, regression, lint, and cleanup completed.'
  } elseif ($exitCode -eq 2) {
    Write-Host 'RESULT: TESTS PASSED; CLEANUP FAILED - see report.'
  } else {
    Write-Host 'RESULT: FAIL - see phase results and report.'
  }
}

exit $exitCode
