---
type: moc
tags: [materia-medica, moc]
revisado: 2026-09-30
aliases: ["matéria médica", "farmacologia de plantas"]
---
# Matéria Médica — plantas, fármacos e homeopatia

Base pessoal e veterinária de plantas medicinais e medicamentos. Cada item é uma ficha com o mesmo roteiro:

**identificação → planta → princípios ativos → ação → absorção e percurso (ADME) → dose → DL50 e meia-vida → benefícios → atenção → homeopatia → estudos com link.**

- Como preencher, escalas e glossário: [[mm-como-preencher]]
- Pedir ao Claude: **"cria a ficha de [nome] na matéria médica"**

## Estrutura
| Pasta | Conteúdo | Template |
|---|---|---|
| `plantas/` | Uma ficha por planta | `tpl-planta` |
| `farmacos/` | Medicamentos humanos e veterinários | `tpl-farmaco` |
| `compostos/` | Moléculas compartilhadas entre plantas/fármacos | `tpl-composto` |
| `homeopatia/` | Remédios homeopáticos | `tpl-homeopatico` |
| `_anexos/` | PDFs e imagens | — |

## Plantas
```dataview
TABLE WITHOUT ID file.link AS "Planta", nome_cientifico AS "Nome científico", principios_ativos AS "Princípios ativos", evidencia AS "Evidência", risco AS "Risco", status AS "Status"
FROM "09-materia-medica/plantas"
SORT file.name ASC
```

## Fármacos
```dataview
TABLE WITHOUT ID file.link AS "Fármaco", classe AS "Classe", especies AS "Espécies", carencia AS "Carência", risco AS "Risco", status AS "Status"
FROM "09-materia-medica/farmacos"
SORT file.name ASC
```

## Compostos
```dataview
TABLE WITHOUT ID file.link AS "Composto", classe_quimica AS "Classe", encontrado_em AS "Encontrado em", dl50 AS "DL50", meia_vida AS "Meia-vida"
FROM "09-materia-medica/compostos"
SORT file.name ASC
```

## Homeopatia
```dataview
TABLE WITHOUT ID file.link AS "Remédio", origem AS "Origem", dinamizacoes AS "Dinamizações", evidencia_clinica AS "Evidência clínica"
FROM "09-materia-medica/homeopatia"
SORT file.name ASC
```

## Consultas úteis
**Uso veterinário por espécie** (troque `"bovino"` por cao, gato, equino…):
```dataview
TABLE WITHOUT ID file.link AS "Item", type AS "Tipo", vias AS "Vias", carencia AS "Carência", risco AS "Risco"
FROM "09-materia-medica/plantas" OR "09-materia-medica/farmacos"
WHERE contains(especies, "bovino")
```

**Risco alto ou moderado:**
```dataview
TABLE WITHOUT ID file.link AS "Item", risco AS "Risco", dl50 AS "DL50"
FROM "09-materia-medica/plantas" OR "09-materia-medica/farmacos"
WHERE risco = "alto" OR risco = "moderado"
```

**Fichas em rascunho e pendências abertas:**
```dataview
TASK
FROM "09-materia-medica/plantas" OR "09-materia-medica/farmacos" OR "09-materia-medica/compostos" OR "09-materia-medica/homeopatia"
WHERE !completed
GROUP BY file.link
```

## Fichas atuais
- Plantas: [[ipe-roxo]]
- Fármacos: [[buparvaquona]] *(rascunho)*
- Compostos: [[lapachol]] · [[beta-lapachona]]

---
*Conteúdo informativo e educacional. Não substitui prescrição de médico ou médico-veterinário.*
