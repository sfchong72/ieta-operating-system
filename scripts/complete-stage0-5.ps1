[CmdletBinding()]
param(
    [string] $OutputDirectory = 'C:\Users\USER\Documents\Codex\2026-09-07\why-x20\outputs\ieos-stage0-5-acceptance'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$expectedBranch = 'codex-ieos-stage0-5-governance'
$preservedHead = 'a353df594e740cf423fda2ee1031b8ae0754e9ab'
$safeDirectory = 'safe.directory=C:/Users/USER/Dev/ieta-operating-system'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Arguments)
    & git -c $safeDirectory -C $repositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

function Assert-NoSensitiveStaging {
    $staged = @(& git -c $safeDirectory -C $repositoryRoot diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect staged paths.'
    }

    $unsafe = @($staged | Where-Object {
        $_ -match '(^|/|\\)\.env($|\.)' -or
        $_ -match '(^|/|\\)\.vercel($|/|\\)' -or
        $_ -match 'private.*key|service.*role|telegram.*token'
    })

    if ($unsafe.Count -gt 0) {
        throw 'Safety stop: a sensitive configuration path is staged.'
    }
}

function Commit-Slice {
    param(
        [string] $Message,
        [string[]] $Paths
    )

    & git -c $safeDirectory -C $repositoryRoot add -- @Paths
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to stage commit slice: $Message"
    }

    Assert-NoSensitiveStaging

    & git -c $safeDirectory -C $repositoryRoot diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SKIP (no changes): $Message"
        return
    }
    if ($LASTEXITCODE -ne 1) {
        throw "Unable to inspect staged changes for: $Message"
    }

    Invoke-Git commit -m $Message
}

$branch = (& git -c $safeDirectory -C $repositoryRoot branch --show-current)
if ($LASTEXITCODE -ne 0 -or $branch -ne $expectedBranch) {
    throw "Safety stop: current branch must be $expectedBranch."
}

$mergeBase = (& git -c $safeDirectory -C $repositoryRoot merge-base HEAD $preservedHead)
if ($LASTEXITCODE -ne 0 -or $mergeBase -ne $preservedHead) {
    throw 'Safety stop: the controlled branch does not descend from the preserved HEAD.'
}

# Repository-local, reversible outbound protections. Fetch remains unchanged.
Invoke-Git config remote.origin.pushurl disabled://ieos-stage0-5
Invoke-Git config core.hooksPath .githooks

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'assert-local-only.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Local-only safety assertion failed.'
}

$preservationZip = 'C:\Users\USER\Documents\Codex\2026-09-07\why-x20\outputs\ieos-post-stabilisation-preservation-2026-09-08\working-tree-files.zip'
$expectedZipHash = '3916B4C60F0A729BDB2A59A95738C7235679CB683D57BBE72876A42BD903F031'
if (-not (Test-Path -LiteralPath $preservationZip)) {
    throw 'Preservation ZIP is missing.'
}
$actualZipHash = (Get-FileHash -LiteralPath $preservationZip -Algorithm SHA256).Hash
if ($actualZipHash -ne $expectedZipHash) {
    throw 'Preservation ZIP verification failed.'
}
Write-Host 'Preservation ZIP: VERIFIED'

Commit-Slice -Message 'chore: stabilise IEOS runtime and tooling' -Paths @(
    'app/auth/callback/route.ts',
    'eslint.config.mjs',
    'lib/data/access.ts',
    'lib/data/content-ideas.ts',
    'lib/data/content-items.ts',
    'lib/data/content-tasks.ts',
    'lib/data/sops.ts',
    'lib/data/work-files.ts',
    'lib/supabase/admin.ts',
    'lib/supabase/client.ts',
    'lib/supabase/middleware.ts',
    'lib/supabase/retry.ts',
    'lib/supabase/server.ts',
    'next.config.ts',
    'package-lock.json',
    'package.json'
)

Commit-Slice -Message 'test: recover approval schema and security acceptance' -Paths @(
    'run-ieos-disposable-test.ps1',
    'supabase/staging/006_approval_workflow.sql',
    'supabase/staging/007_edit_support.sql',
    'supabase/staging/008_approval_security_hardening.sql',
    'supabase/tests/008_ieos_approval_edit_behavioural.sql',
    'supabase/tests/support/008_ieos_staging_fixtures.sql'
)

Commit-Slice -Message 'feat: recover approval data and actions' -Paths @(
    'lib/actions/approvals.ts',
    'lib/actions/content-items.ts',
    'lib/data/approval-actions.ts',
    'lib/data/approval-categories.ts',
    'lib/data/campaigns.ts',
    'lib/data/record-edit-log.ts',
    'lib/data/types.ts'
)

Commit-Slice -Message 'feat: recover approval and planner interface' -Paths @(
    'app/(app)/approvals/page.tsx',
    'app/(app)/planner/[id]/edit/page.tsx',
    'app/(app)/planner/[id]/page.tsx',
    'app/(app)/planner/new/page.tsx',
    'app/(app)/planner/page.tsx',
    'components/approvals/approval-forms.tsx',
    'components/content-item-form.tsx',
    'components/nav-shell.tsx',
    'components/planner/approval-history.tsx',
    'components/planner/submit-review-form.tsx'
)

Commit-Slice -Message 'feat: recover controlled edit support' -Paths @(
    'app/(app)/ideas/[id]/page.tsx',
    'app/(app)/knowledge/[id]/page.tsx',
    'app/(app)/sops/[id]/page.tsx',
    'app/(app)/tasks/[id]/edit/page.tsx',
    'app/(app)/tasks/[id]/page.tsx',
    'components/task-actions/edit-work-file-form.tsx',
    'components/task-form.tsx',
    'lib/actions/ideas.ts',
    'lib/actions/knowledge.ts',
    'lib/actions/sops.ts',
    'lib/actions/tasks.ts'
)

Commit-Slice -Message 'docs: establish IEOS Stage 0.5 governance' -Paths @(
    '.githooks/pre-push',
    'AGENTS.md',
    'README.md',
    'docs/AGENTIC_LAYER.md',
    'docs/ARCHITECTURE.md',
    'docs/DATA_MODEL.md',
    'docs/EXECUTION_GUARDRAILS.md',
    'docs/IEOS_MASTER_PLAN.md',
    'docs/IEOS_Phase1_Specification.md',
    'docs/IEOS_Technical_Inspection.md',
    'docs/INTELLIGENCE_LAYER.md',
    'docs/PRD.md',
    'docs/SECURITY.md',
    'docs/STAGE0_5_COMMIT_SLICES.md',
    'docs/TASKS.md',
    'docs/TEST_PLAN.md',
    'scripts/assert-local-only.ps1',
    'scripts/complete-stage0-5.ps1'
)

$remaining = @(& git -c $safeDirectory -C $repositoryRoot status --short --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to verify the final working tree.'
}
if ($remaining.Count -gt 0) {
    Write-Host 'Uncommitted paths remain:'
    $remaining | ForEach-Object { Write-Host $_ }
    throw 'Safety stop: not every recovered/governance path was assigned to a commit slice.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Push-Location $repositoryRoot
try {
    & npm.cmd run typecheck
    if ($LASTEXITCODE -ne 0) { throw 'Typecheck failed.' }

    & npm.cmd run lint
    if ($LASTEXITCODE -ne 0) { throw 'Lint failed.' }

    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\run-ieos-disposable-test.ps1' -OutputDirectory $OutputDirectory
    if ($LASTEXITCODE -ne 0) { throw 'Disposable IEOS acceptance failed.' }
} finally {
    Pop-Location
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'assert-local-only.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Final local-only safety assertion failed.'
}

Write-Host 'STAGE 0.5 AUTOMATED GATES: PASS'
Write-Host "Acceptance output: $OutputDirectory"
Write-Host 'No push, deployment, or hosted database command was executed.'
exit 0

