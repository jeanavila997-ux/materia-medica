# Matéria Médica

Base de conhecimento pessoal e veterinária sobre plantas medicinais, medicamentos, compostos químicos e homeopatia. Mantida em Markdown para funcionar ao mesmo tempo **no GitHub** e **dentro do Obsidian** — como vault próprio em `D:\materia-medica` (padrão) ou como subpasta de outro vault.

> Conteúdo informativo e educacional. Não substitui prescrição de médico ou médico-veterinário.

## Roteiro de cada ficha
Identificação → características da planta → princípios ativos e compostos → ação fisiológica → **absorção e percurso no organismo (ADME)** → dose de ação → **DL50 e meia-vida** → benefícios → atenção (contraindicações, interações, carência) → homeopatia → estudos com link → status regulatório → pendências.

## Estrutura
```
materia-medica/                     # = D:\materia-medica (vault próprio)
├── 00-materia-medica-home.md       # página inicial com painéis Dataview
├── _guia/mm-como-preencher.md      # regras, escalas de evidência/risco, glossário
├── _templates/                     # modelos: planta, fármaco, composto, homeopático
├── plantas/                        # uma ficha por planta
├── farmacos/                       # medicamentos humanos e veterinários
├── compostos/                      # moléculas compartilhadas entre plantas e fármacos
├── homeopatia/                     # remédios homeopáticos
├── _anexos/                        # PDFs e imagens
├── _scripts/                       # instalação e sincronização com o vault (Windows)
└── .github/                        # validação automática das fichas
```

## Fichas
| Tipo | Ficha | Status |
|---|---|---|
| Planta | [Ipê-roxo (pau d'arco)](plantas/ipe-roxo.md) | revisado |
| Composto | [Lapachol](compostos/lapachol.md) | revisado |
| Composto | [β-lapachona](compostos/beta-lapachona.md) | revisado |
| Fármaco (vet.) | [Buparvaquona](farmacos/buparvaquona.md) | rascunho |

## Instalação no PC (Windows)
**Padrão — vault próprio em `D:\materia-medica`.** No PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\configurar-pasta.ps1
```
Funciona com a pasta em qualquer estado: inexistente (clona), extraída de zip (faz backup em `Documentos\materia-medica-backups` e converte num clone; corrige a pasta aninhada `home\claude\materia-medica` de zips antigos) ou já clonada (atualiza). Depois: Obsidian → *Abrir pasta como cofre* → `D:\materia-medica`, ative o plugin principal **Templates** e instale o plugin da comunidade **Dataview**.

Outro local: `-Destino "E:\caminho\materia-medica"`. Dentro de um vault existente: use `_scripts\instalar-no-vault.ps1` (cria `<vault>\09-materia-medica`).

## Sincronizar
Clique duas vezes em `_scripts\sincronizar.cmd` — registra o que você editou no Obsidian, traz fichas novas do GitHub e envia as suas. No primeiro envio o Windows abre o login do GitHub no navegador. Em conflito, nada é perdido: o script para e avisa.

## Como adicionar uma ficha
- **Pelo Claude:** "cria a ficha de [nome] na matéria médica". A ficha é enviada a este repositório e chega ao vault no próximo `sincronizar`.
- **À mão, no Obsidian:** Ctrl+P → *Templates: Inserir template* → escolha `tpl-planta`, `tpl-farmaco`, `tpl-composto` ou `tpl-homeopatico`.

Regras em [`_guia/mm-como-preencher.md`](_guia/mm-como-preencher.md): todo número com espécie, via e fonte; dado ausente vira pendência; dedução é marcada como *(inferência)*.

## Validação automática
A cada push, a Action `validar-fichas` confere o frontmatter YAML, os campos obrigatórios por tipo e se todo `[[link]]` aponta para uma nota existente.
