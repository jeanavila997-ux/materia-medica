<#
.SYNOPSIS
  Deixa D:\materia-medica pronta: clone do GitHub + vault do Obsidian.

.DESCRIPTION
  Funciona em qualquer estado da pasta:
  - Não existe                         -> git clone
  - Já é um clone                      -> git pull
  - Veio de um zip (sem .git)          -> backup em Documentos\materia-medica-backups
                                          e converte a pasta num clone
  - Zip extraído com pasta aninhada    -> traz os arquivos de home\claude\materia-medica
    (home\claude\materia-medica)          para a raiz e apaga a pasta aninhada
  Arquivos seus que não estão no GitHub são mantidos (o sincronizar envia).
  Se a pasta não estiver dentro de outro vault, prepara ela como vault próprio
  (pasta de templates = _templates).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\configurar-pasta.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\configurar-pasta.ps1 -Destino "E:\estudos\materia-medica"
#>
param(
    [string]$Destino = 'D:\materia-medica',
    [string]$RepoUrl = 'https://github.com/jeanavila997-ux/materia-medica.git',
    [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'

function Git-Run {
    param([Parameter(ValueFromRemainingArguments)] [string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') falhou (código $LASTEXITCODE)" }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git não encontrado. Instale com:  winget install --id Git.Git -e   e abra um novo PowerShell.'
}
$Destino = [IO.Path]::GetFullPath($Destino)
Write-Host "Destino: $Destino"

# ---------- 1. Não existe -> clone ----------
if (-not (Test-Path $Destino)) {
    Git-Run clone --branch $Branch $RepoUrl $Destino
}
# ---------- 2. Já é clone -> pull ----------
elseif (Test-Path (Join-Path $Destino '.git')) {
    Push-Location $Destino
    try {
        $origem = git remote get-url origin
        if ($origem -ne $RepoUrl) { Write-Host "Aviso: origin aponta para $origem" -ForegroundColor Yellow }
        if (@(git status --porcelain).Count -gt 0) {
            Write-Host 'Há edições locais; pulei o pull. Rode o sincronizar para enviar e receber.' -ForegroundColor Yellow
        } else {
            Git-Run pull --ff-only
        }
    } finally { Pop-Location }
}
# ---------- 3. Pasta sem git (zip) -> backup + converter ----------
else {
    $Docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $Docs) { $Docs = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME } }
    $BackupDir = Join-Path $Docs 'materia-medica-backups'
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    $nome = Split-Path $Destino -Leaf
    $BackupZip = Join-Path $BackupDir "$nome-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').zip"
    Compress-Archive -Path (Join-Path $Destino '*') -DestinationPath $BackupZip -Force
    Write-Host "Backup da pasta atual: $BackupZip"

    Push-Location $Destino
    try {
        Git-Run init --quiet
        Git-Run remote add origin $RepoUrl
        Git-Run fetch origin $Branch

        # Zip antigo extraído com caminho aninhado: home\claude\materia-medica\...
        $topo = Join-Path $Destino 'home'
        $aninhada = Join-Path (Join-Path $topo 'claude') 'materia-medica'
        $soAninhada = (Test-Path $aninhada) -and
            (@(Get-ChildItem $topo -Force).Name -join '|') -eq 'claude' -and
            (@(Get-ChildItem (Join-Path $topo 'claude') -Force).Name -join '|') -eq 'materia-medica'
        $origemArq = if ($soAninhada) { $aninhada } else { $Destino }

        # Edição sua = conteúdo que nunca existiu no histórico do repositório.
        # Versões antigas vindas de zip são descartadas (o GitHub tem a atual).
        git show "origin/${Branch}:.gitattributes" | Set-Content -Encoding ascii (Join-Path $Destino '.git\info\attributes')
        $conhecidos = @{}
        git rev-list --objects --all | ForEach-Object { $conhecidos[$_.Split(' ')[0]] = $true }
        $guarda = Join-Path ([IO.Path]::GetTempPath()) "materia-medica-edicoes-$(Get-Date -Format 'yyyyMMddHHmmss')"
        $suas = @()
        Get-ChildItem $origemArq -Recurse -File -Force |
            Where-Object { $_.FullName.Substring($origemArq.Length) -notmatch '^[\\/]?\.(git|obsidian|trash)([\\/]|$)' } |
            ForEach-Object {
                $rel = $_.FullName.Substring($origemArq.Length).TrimStart('\', '/') -replace '\\', '/'
                $hash = git hash-object --path=$rel -- $_.FullName
                if (-not $conhecidos.ContainsKey($hash)) {
                    $copia = Join-Path $guarda $rel
                    New-Item -ItemType Directory -Force -Path (Split-Path $copia -Parent) | Out-Null
                    Copy-Item -LiteralPath $_.FullName -Destination $copia -Force
                    $suas += $rel
                }
            }

        Git-Run checkout -f -B $Branch "origin/$Branch"
        Git-Run branch --set-upstream-to "origin/$Branch" $Branch
        if ($soAninhada) {
            Remove-Item $topo -Recurse -Force
            Write-Host 'Pasta aninhada home\claude\materia-medica removida.'
        }
        foreach ($rel in $suas) {
            $alvo = Join-Path $Destino $rel
            New-Item -ItemType Directory -Force -Path (Split-Path $alvo -Parent) | Out-Null
            Copy-Item -LiteralPath (Join-Path $guarda $rel) -Destination $alvo -Force
        }
        if (Test-Path $guarda) { Remove-Item $guarda -Recurse -Force }

        $extras = @(git status --porcelain --untracked-files=all)
        if ($extras.Count -gt 0) {
            Write-Host 'Edições e notas suas, mantidas (o sincronizar envia ao GitHub):'
            $extras | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host 'Nenhuma edição sua encontrada; a pasta está igual ao GitHub.'
        }
    } finally { Pop-Location }
}

# ---------- Identidade do git (necessária para registrar edições) ----------
Push-Location $Destino
try {
    if (-not (git config user.name)) {
        $n = Read-Host 'Seu nome para os registros do git (ex.: Jean Avila)'
        if ($n) { Git-Run config user.name $n }
    }
    if (-not (git config user.email)) {
        $e = Read-Host 'Seu e-mail do GitHub'
        if ($e) { Git-Run config user.email $e }
    }
} finally { Pop-Location }

# ---------- Obsidian: vault próprio, se não estiver dentro de outro ----------
$dentroDeVault = $false
$p = Split-Path $Destino -Parent
while ($p) {
    if (Test-Path (Join-Path $p '.obsidian')) { $dentroDeVault = $true; break }
    $pai = Split-Path $p -Parent
    if ($pai -eq $p) { break }
    $p = $pai
}
if (-not $dentroDeVault) {
    $obs = Join-Path $Destino '.obsidian'
    New-Item -ItemType Directory -Force -Path $obs | Out-Null
    $tpl = Join-Path $obs 'templates.json'
    if (-not (Test-Path $tpl)) {
        [IO.File]::WriteAllText($tpl, '{"folder": "_templates"}')
        Write-Host 'Obsidian: pasta de templates definida como _templates.'
    }
} else {
    Write-Host "Obsidian: a pasta está dentro do vault $p (use o vault que já existe)."
}

# ---------- Resumo ----------
Push-Location $Destino
try {
    $ultimo = git log -1 --format='%h %s (%cr)'
    $n = @(Get-ChildItem -Recurse -Filter *.md -File |
        Where-Object { $_.FullName -notmatch '[\\/]\.(git|obsidian|trash)[\\/]' }).Count
} finally { Pop-Location }
Write-Host ''
Write-Host "OK: $n notas em $Destino" -ForegroundColor Green
Write-Host "Último commit: $ultimo"
Write-Host ''
Write-Host 'Próximos passos:'
if (-not $dentroDeVault) {
    Write-Host "  1. Obsidian -> 'Abrir pasta como cofre' -> $Destino"
    Write-Host "  2. Configurações -> Plugins principais -> ative 'Templates'"
    Write-Host "  3. Plugins da comunidade -> instale 'Dataview' (painéis da página inicial)"
}
Write-Host "  Sincronizar: clique duas vezes em $Destino\_scripts\sincronizar.cmd"
