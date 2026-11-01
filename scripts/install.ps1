<#
.SYNOPSIS
Install this skill into one or more coding-agent skill directories.

.DESCRIPTION
Links a harness skill root to this repository (a junction on Windows, a symlink
elsewhere), or copies the skill files there with -Copy. Supported harnesses:
dsh (DeepSeek Harness), codex (OpenAI Codex CLI), claude (Claude Code).

The destination is <root>/scala-react-functional-course, where <root> is
  dsh:    $env:DSH_HOME/skills    or ~/.dsh/skills    (project: <project>/.dsh/skills)
  codex:  $env:CODEX_HOME/skills  or ~/.codex/skills  (project: <project>/.codex/skills)
  claude: ~/.claude/skills                            (project: <project>/.claude/skills)

.EXAMPLE
./scripts/install.ps1 -Harness dsh -Scope user

.EXAMPLE
./scripts/install.ps1 -Harness all -Scope project -Project C:\code\course

.EXAMPLE
./scripts/install.ps1 -Harness dsh -Copy -DryRun
#>
[CmdletBinding()]
param(
  [ValidateSet('dsh', 'codex', 'claude', 'all')]
  [string]$Harness = 'dsh',

  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',

  [string]$Project = (Get-Location).Path,

  [switch]$Copy,

  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$skillName = 'scala-react-functional-course'
$markerName = '.skill-install.json'
$repoRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$onWindows = $env:OS -eq 'Windows_NT'

if (-not (Test-Path (Join-Path $repoRoot 'SKILL.md'))) {
  throw "SKILL.md not found in $repoRoot; run this script from a clone of the skill repository."
}

function Get-SkillRoot([string]$name, [string]$scope, [string]$project) {
  $homeDir = $HOME
  $suffix = 'skills'
  switch ($name) {
    'dsh' {
      $base = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $homeDir '.dsh' }
      if ($scope -eq 'project') { return Join-Path $project '.dsh' $suffix }
      return Join-Path $base $suffix
    }
    'codex' {
      $base = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeDir '.codex' }
      if ($scope -eq 'project') { return Join-Path $project '.codex' $suffix }
      return Join-Path $base $suffix
    }
    default {
      if ($scope -eq 'project') { return Join-Path $project '.claude' $suffix }
      return Join-Path (Join-Path $homeDir '.claude') $suffix
    }
  }
}

function Get-LinkTarget([string]$path) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($null -eq $item) { return $null }
  if ($item.LinkType) { return ($item.Target | Select-Object -First 1) }
  return $null
}

function Test-SamePath([string]$left, [string]$right) {
  if (-not $left -or -not $right) { return $false }
  $a = [System.IO.Path]::GetFullPath($left).TrimEnd('\', '/')
  $b = [System.IO.Path]::GetFullPath($right).TrimEnd('\', '/')
  return [string]::Equals($a, $b, [System.StringComparison]::OrdinalIgnoreCase)
}

function Copy-Skill([string]$target) {
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  foreach ($entry in @('SKILL.md', 'references', 'agents', 'LICENSE', 'README.md')) {
    $source = Join-Path $repoRoot $entry
    if (Test-Path -LiteralPath $source) {
      Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
    }
  }
  [ordered]@{
    repo        = $repoRoot
    harness     = $Harness
    scope       = $Scope
    installedAt = (Get-Date).ToString('o')
  } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $target $markerName)
}

$harnesses = if ($Harness -eq 'all') { @('dsh', 'codex', 'claude') } else { @($Harness) }
$projectPath = if ($Scope -eq 'project') {
  if (Test-Path -LiteralPath $Project) { (Resolve-Path -LiteralPath $Project).Path } else { [System.IO.Path]::GetFullPath($Project) }
} else { $Project }

foreach ($name in $harnesses) {
  $root = Get-SkillRoot $name $Scope $projectPath
  $target = Join-Path $root $skillName

  if (Test-Path -LiteralPath $target) {
    $link = Get-LinkTarget $target
    if ($link -and (Test-SamePath $link $repoRoot)) { Write-Host "Already installed: $target"; continue }
    if ($link) { Write-Warning "Skipping ${target}: it links to $link, not to this repository."; continue }
    Write-Warning "Skipping ${target}: a real directory already exists there; remove it first if it is stale."
    continue
  }

  if ($DryRun) { Write-Host "Would link $target -> $repoRoot"; continue }

  New-Item -ItemType Directory -Path $root -Force | Out-Null
  if ($Copy) {
    Copy-Skill $target
    Write-Host "Copied skill files into $target"
    continue
  }
  try {
    if ($onWindows) {
      New-Item -ItemType Junction -Path $target -Target $repoRoot | Out-Null
    } else {
      New-Item -ItemType SymbolicLink -Path $target -Target $repoRoot | Out-Null
    }
    Write-Host "Linked $target -> $repoRoot"
  } catch {
    Write-Warning "Link creation failed ($($_.Exception.Message)); copying the skill files instead."
    Copy-Skill $target
    Write-Host "Copied skill files into $target"
  }
}

Write-Host 'Restart the harness or wait for its skill catalog to refresh.'
