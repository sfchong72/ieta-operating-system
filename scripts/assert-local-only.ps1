[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string] $message) {
    $failures.Add($message)
}

$branch = (& git -c safe.directory=C:/Users/USER/Dev/ieta-operating-system -C $repositoryRoot branch --show-current 2>$null)
if ($LASTEXITCODE -ne 0) {
    Add-Failure 'Unable to verify the current Git branch.'
} elseif ($branch -ne 'codex-ieos-stage0-5-governance') {
    Add-Failure "Unexpected branch '$branch'. Stage 0.5 requires codex-ieos-stage0-5-governance."
}

$pushUrl = (& git -c safe.directory=C:/Users/USER/Dev/ieta-operating-system -C $repositoryRoot config --get-all remote.origin.pushurl 2>$null)
if ($LASTEXITCODE -ne 0 -or -not ($pushUrl -contains 'disabled://ieos-stage0-5')) {
    Add-Failure 'Repository push URL is not disabled.'
}

$hooksPath = (& git -c safe.directory=C:/Users/USER/Dev/ieta-operating-system -C $repositoryRoot config --get core.hooksPath 2>$null)
if ($LASTEXITCODE -ne 0 -or $hooksPath -ne '.githooks') {
    Add-Failure 'Repository-local pre-push hook is not enabled.'
}

$projectRef = Join-Path $repositoryRoot 'supabase\.temp\project-ref'
if (Test-Path -LiteralPath $projectRef) {
    Add-Failure 'A hosted Supabase project link marker exists.'
}

$connectionVariableNames = @(
    'DATABASE_URL',
    'DIRECT_URL',
    'POSTGRES_URL',
    'POSTGRES_PRISMA_URL',
    'SUPABASE_DB_URL'
)

foreach ($name in $connectionVariableNames) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        continue
    }

    try {
        $uri = [Uri] $value
        if ($uri.Host -notin @('localhost', '127.0.0.1', '::1')) {
            Add-Failure "Environment variable $name points to a non-loopback host."
        }
    } catch {
        Add-Failure "Environment variable $name is set but cannot be verified as a local connection."
    }
}

foreach ($relativePath in @('.env.local', '.env.staging.local', '.vercel\project.json')) {
    if (Test-Path -LiteralPath (Join-Path $repositoryRoot $relativePath)) {
        $warnings.Add("Ignored local linkage/configuration file present: $relativePath (contents not read).")
    }
}

if ($warnings.Count -gt 0) {
    foreach ($warning in $warnings) {
        Write-Warning $warning
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure
    }
    exit 1
}

Write-Host 'LOCAL-ONLY GUARD: PASS'
Write-Host 'Branch, push protection, hook, and hosted-link checks passed.'
exit 0

