<#
.SYNOPSIS
Remove this skill from one or more coding-agent skill directories.

.DESCRIPTION
Removes only what this repository installed: a directory link that points at the
repository, or a copied directory carrying this repository's install marker
(.skill-install.json). Real directories and links owned by anything else are left
alone and reported.

.EXAMPLE
./scripts/uninstall.ps1 -Harness dsh -Scope user

.EXAMPLE
./scripts/uninstall.ps1 -Harness all -Scope project -Project C:\code\course -DryRun
#>
[CmdletBinding()]
param(
  [ValidateSet('dsh', 'codex', 'claude', 'all')]
  [string]$Harness = 'dsh',

  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',

  [string]$Project = (Get-Location).Path,

  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$skillName = 'scala-react-functional-course'
$markerName = '.skill-install.json'
$repoRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path

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

$harnesses = if ($Harness -eq 'all') { @('dsh', 'codex', 'claude') } else { @($Harness) }
$projectPath = if ($Scope -eq 'project') {
  if (Test-Path -LiteralPath $Project) { (Resolve-Path -LiteralPath $Project).Path } else { [System.IO.Path]::GetFullPath($Project) }
} else { $Project }

foreach ($name in $harnesses) {
  $root = Get-SkillRoot $name $Scope $projectPath
  $target = Join-Path $root $skillName

  if (-not (Test-Path -LiteralPath $target)) { Write-Host "Not installed: $target"; continue }

  $link = Get-LinkTarget $target
  if ($link) {
    if (-not (Test-SamePath $link $repoRoot)) {
      Write-Warning "Skipping ${target}: it links to $link, not to this repository."
      continue
    }
    if ($DryRun) { Write-Host "Would remove link $target"; continue }
    (Get-Item -LiteralPath $target -Force).Delete()
    Write-Host "Removed link $target"
    continue
  }

  $markerPath = Join-Path $target $markerName
  if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Warning "Skipping ${target}: no install marker, so this script did not create it."
    continue
  }
  $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
  if (-not (Test-SamePath $marker.repo $repoRoot)) {
    Write-Warning "Skipping ${target}: it was installed from $($marker.repo)."
    continue
  }
  if ($DryRun) { Write-Host "Would remove copied directory $target"; continue }
  Remove-Item -LiteralPath $target -Recurse -Force
  Write-Host "Removed copied directory $target"
}

Write-Host 'Restart the harness or wait for its skill catalog to refresh.'
