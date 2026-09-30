# Matéria Médica

Base de conhecimento pessoal e veterinária sobre plantas medicinais, medicamentos, compostos químicos e homeopatia. Mantida em Markdown para funcionar ao mesmo tempo **no GitHub** e **dentro do Obsidian**, na pasta `09-materia-medica/` do vault.

> Conteúdo informativo e educacional. Não substitui prescrição de médico ou médico-veterinário.

## Roteiro de cada ficha
Identificação → características da planta → princípios ativos e compostos → ação fisiológica → **absorção e percurso no organismo (ADME)** → dose de ação → **DL50 e meia-vida** → benefícios → atenção (contraindicações, interações, carência) → homeopatia → estudos com link → status regulatório → pendências.

## Estrutura
```
materia-medica/                     # = pasta 09-materia-medica/ no vault
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

## Ligação com o Obsidian
Primeira vez, no PowerShell do Windows:
```powershell
powershell -ExecutionPolicy Bypass -File .\instalar-no-vault.ps1
```
O script clona este repositório para `<vault>\09-materia-medica`. Se a pasta já existir (extraída de zip), ele a converte num clone e faz backup antes.

Depois, para trazer fichas novas e enviar o que você editou no Obsidian:
```powershell
powershell -ExecutionPolicy Bypass -File "<vault>\09-materia-medica\_scripts\sincronizar.ps1"
```

## Como adicionar uma ficha
- **Pelo Claude:** "cria a ficha de [nome] na matéria médica". A ficha é enviada a este repositório e chega ao vault no próximo `sincronizar`.
- **À mão, no Obsidian:** Configurações → Templates → pasta `09-materia-medica/_templates` → *Inserir template*.

Regras em [`_guia/mm-como-preencher.md`](_guia/mm-como-preencher.md): todo número com espécie, via e fonte; dado ausente vira pendência; dedução é marcada como *(inferência)*.

## Validação automática
A cada push, a Action `validar-fichas` confere o frontmatter YAML, os campos obrigatórios por tipo e se todo `[[link]]` aponta para uma nota existente.
