<#
.SYNOPSIS
  Sincroniza a pasta 09-materia-medica do vault com o GitHub nos dois sentidos.

.DESCRIPTION
  1. Se você editou ou criou notas no Obsidian, faz commit delas.
  2. Traz as fichas novas do GitHub (git pull --rebase).
  3. Envia as suas edições (git push).
  Em caso de conflito, desfaz a tentativa e avisa. Nada é perdido.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "D:\Vault\09-materia-medica\_scripts\sincronizar.ps1"
#>
param([string]$Mensagem = "Notas editadas no Obsidian ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))")
$ErrorActionPreference = 'Stop'

$Repo = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $Repo '.git'))) {
    throw "'$Repo' não é um clone git. Rode antes o instalar-no-vault.ps1."
}
Set-Location $Repo
$antes = git rev-parse HEAD

# 1. Commit das edições locais
if (@(git status --porcelain).Count -gt 0) {
    git add -A
    git commit -m $Mensagem | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Falha no commit das edições locais.' }
    Write-Host 'Edições locais registradas.'
}

# 2. Trazer do GitHub
git pull --rebase --quiet
if ($LASTEXITCODE -ne 0) {
    git rebase --abort 2>$null
    throw 'Conflito: a mesma nota foi alterada aqui e no GitHub. Nada foi perdido; resolva a nota em conflito (ou peça ajuda ao Claude) e rode de novo.'
}

# 3. Enviar
$pendentes = git rev-list --count '@{u}..HEAD'
if ([int]$pendentes -gt 0) {
    git push --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Falha no push. Verifique login/permissão no GitHub.' }
    Write-Host "Enviados $pendentes commit(s) para o GitHub."
}

$depois = git rev-parse HEAD
if ($antes -ne $depois) {
    Write-Host 'Arquivos alterados:' -ForegroundColor Cyan
    git diff --stat $antes $depois
} else {
    Write-Host 'Já estava tudo sincronizado.'
}
Write-Host 'OK' -ForegroundColor Green
