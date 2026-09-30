<#
.SYNOPSIS
  Liga o repositório materia-medica (GitHub) à pasta 09-materia-medica do vault do Obsidian.

.DESCRIPTION
  - Pasta não existe             -> git clone
  - Pasta já é um clone          -> git pull
  - Pasta existe sem git (zip)   -> backup fora do vault + converte a pasta num clone
                                    (arquivos seus que não estão no repositório são mantidos)

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\instalar-no-vault.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\instalar-no-vault.ps1 -VaultPath "D:\Obsidian\MeuVault"
#>
param(
    [string]$VaultPath,
    [string]$RepoUrl = 'https://github.com/jeanavila997-ux/materia-medica.git',
    [string]$Pasta = '09-materia-medica',
    [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'

function Git-Run {
    param([Parameter(ValueFromRemainingArguments)] [string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') falhou (código $LASTEXITCODE)" }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git não encontrado. Instale com:  winget install --id Git.Git -e   e abra um novo PowerShell."
}

# ---------- Localizar o vault ----------
if (-not $VaultPath) {
    $cfg = if ($env:APPDATA) { Join-Path $env:APPDATA 'obsidian\obsidian.json' } else { '' }
    if ($cfg -and (Test-Path $cfg)) {
        $json = Get-Content $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
        $vaults = @($json.vaults.PSObject.Properties | ForEach-Object { $_.Value })
        $aberto = $vaults | Where-Object { $_.open } | Select-Object -First 1
        if ($aberto) { $VaultPath = $aberto.path }
        elseif ($vaults.Count -eq 1) { $VaultPath = $vaults[0].path }
        elseif ($vaults.Count -gt 1) {
            for ($i = 0; $i -lt $vaults.Count; $i++) { Write-Host "  [$i] $($vaults[$i].path)" }
            $VaultPath = $vaults[[int](Read-Host 'Número do vault')].path
        }
    }
}
if (-not $VaultPath -or -not (Test-Path $VaultPath)) { $VaultPath = Read-Host 'Caminho completo do vault do Obsidian' }
if (-not (Test-Path (Join-Path $VaultPath '.obsidian'))) {
    throw "'$VaultPath' não parece um vault do Obsidian (falta a pasta .obsidian)."
}
$Destino = Join-Path $VaultPath $Pasta
Write-Host "Vault:   $VaultPath"
Write-Host "Destino: $Destino"

# ---------- Caso 1: não existe -> clone ----------
if (-not (Test-Path $Destino)) {
    Git-Run clone --branch $Branch $RepoUrl $Destino
}
# ---------- Caso 2: já é clone -> pull ----------
elseif (Test-Path (Join-Path $Destino '.git')) {
    Push-Location $Destino
    try { Git-Run pull --ff-only } finally { Pop-Location }
}
# ---------- Caso 3: pasta sem git (veio do zip) -> converter ----------
else {
    $Docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $Docs) { $Docs = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME } }
    $BackupDir = Join-Path $Docs 'materia-medica-backups'
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    $BackupZip = Join-Path $BackupDir "$Pasta-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').zip"
    Compress-Archive -Path $Destino -DestinationPath $BackupZip -Force
    Write-Host "Backup da pasta atual: $BackupZip"

    Push-Location $Destino
    try {
        Git-Run init --quiet
        Git-Run remote add origin $RepoUrl
        Git-Run fetch origin $Branch
        Git-Run checkout -f -B $Branch "origin/$Branch"
        Git-Run branch --set-upstream-to "origin/$Branch" $Branch
        $extras = @(git status --porcelain --untracked-files=all)
        if ($extras.Count -gt 0) {
            Write-Host "Arquivos seus que não estão no GitHub (mantidos; o sincronizar.ps1 envia):"
            $extras | ForEach-Object { Write-Host "  $_" }
        }
    } finally { Pop-Location }
}

Push-Location $Destino
try {
    $ultimo = git log -1 --format='%h %s (%cr)'
    $n = @(Get-ChildItem -Recurse -Filter *.md | Where-Object { $_.FullName -notmatch '\\\.git\\|/\.git/' }).Count
} finally { Pop-Location }
Write-Host "OK: $n notas em $Destino" -ForegroundColor Green
Write-Host "Último commit: $ultimo"
Write-Host "Para atualizar depois: powershell -ExecutionPolicy Bypass -File `"$Destino\_scripts\sincronizar.ps1`""
