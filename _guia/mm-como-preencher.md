---
type: guia
tags: [materia-medica, guia]
revisado: 2026-09-30
---
# Como preencher as fichas

## Como adicionar um item novo
1. **Planta** → crie a nota em `plantas/` usando o template `tpl-planta`.
2. **Medicamento/fármaco** (humano ou veterinário) → `farmacos/` com `tpl-farmaco`.
3. **Composto químico** que aparece em várias plantas (ex.: lapachol) → `compostos/` com `tpl-composto`. Assim a ficha da planta só linka o composto, sem repetir os dados.
4. **Remédio homeopático** → `homeopatia/` com `tpl-homeopatico`, linkando a planta de origem.

Configure uma vez: **Configurações → Plugins principais → Templates → Pasta de templates** = `_templates` (vault próprio em `D:\materia-medica` — o `configurar-pasta.ps1` já deixa isso pronto) ou `09-materia-medica/_templates` (se a pasta estiver dentro de outro vault). Depois é só usar *Inserir template* numa nota nova.

Ou peça ao Claude: **"cria a ficha de [planta/medicamento] na matéria médica"**. Ele pesquisa, preenche o template e entrega o `.md` pronto.

## Regras de qualidade
- **Todo número tem fonte e espécie.** DL50, dose e meia-vida sem espécie, via e referência não entram.
- **Separe dado de interpretação.** Quando algo for dedução (ex.: "provável sítio de absorção"), escreva *(inferência)*.
- **Humano ≠ animal ≠ in vitro.** Diga sempre de onde veio o dado.
- Dado que não foi encontrado fica como **"sem dados"** e vai para *Pendências*. Nunca se inventa.
- Links diretos para PubMed/PMC, DOI ou documento oficial.

## Escalas usadas nas Properties

**`evidencia`** (a melhor evidência disponível para o uso principal):
| Valor | Significado |
|---|---|
| `tradicional` | Só uso popular/etnobotânico |
| `pre-clinica` | Células (in vitro) e/ou animais de laboratório |
| `clinica-preliminar` | Estudos pequenos, abertos ou sem controle na espécie-alvo |
| `clinica-moderada` | Ensaios controlados, mas poucos ou com limitações |
| `clinica-forte` | Ensaios randomizados consistentes e/ou meta-análise |

**`risco`**: `baixo` · `moderado` (interações ou toxicidade em dose alta) · `alto` (janela terapêutica estreita, toxicidade grave documentada).

## Glossário
| Termo | O que significa |
|---|---|
| **ADME** | Absorção, Distribuição, Metabolismo e Excreção: o percurso do composto no organismo |
| **Biodisponibilidade (F)** | % da dose que chega inalterada à circulação sistêmica. IV = 100% por definição |
| **Efeito de primeira passagem** | Parte da dose oral destruída no intestino e no fígado antes de chegar ao sangue |
| **Tmax / Cmax** | Tempo até o pico plasmático / concentração máxima atingida |
| **Meia-vida (t½)** | Tempo para a concentração plasmática cair pela metade. Cerca de 5 meias-vidas ≈ eliminação quase completa |
| **Cinética "flip-flop"** | Quando a t½ oral é bem maior que a IV: a absorção lenta passa a controlar a queda da concentração |
| **DL50** | Dose que matou 50% dos animais de teste, numa espécie e via específicas. **Não é dose segura** e não se converte direto entre espécies |
| **Janela terapêutica** | Distância entre a dose eficaz e a dose tóxica |
| **Período de carência** | Tempo entre a última dose e o abate (carne) ou o aproveitamento de leite/ovos, para não deixar resíduo no alimento |
| **NQO1** | Enzima (NAD(P)H quinona oxidorredutase 1) que ativa ou desativa quinonas; é o alvo da β-lapachona |

## Particularidades veterinárias
- **Ruminantes, via oral:** o rúmen fermenta e pode alterar o composto antes do intestino. Dado de rato ou humano por via oral **não se transfere** direto para bovinos.
- **Gatos:** metabolizam mal vários compostos (glicuronidação deficiente) e são sensíveis a agentes oxidantes que causam hemólise.
- **Animais de produção:** sem período de carência estabelecido, o uso gera risco de resíduo no alimento. Registre sempre o status no MAPA.

## Homeopatia
A seção de homeopatia registra **o que a homeopatia afirma** (matéria médica, dinamizações), separado da evidência científica.
- A homeopatia é reconhecida como especialidade médica e veterinária no Brasil, e há medicamentos homeopáticos regulados pela Anvisa.
- Contexto de evidência: a revisão do NHMRC (Austrália, 2015) concluiu que não há condição de saúde com evidência confiável de efeito da homeopatia além do placebo. Por isso o campo `evidencia_clinica` é preenchido separadamente, estudo por estudo.
- **Tintura-mãe (TM) não é diluída.** Tem o risco tóxico do extrato da planta e segue as mesmas precauções.
- Quando não existir preparação homeopática da planta, registre `homeopatia: nao-encontrada` com as fontes consultadas.

Fontes:
- [NHMRC — Evidence on the effectiveness of homeopathy (information paper, 2015)](https://core.ac.uk/outputs/30672543/)
- [The Conversation — No evidence homeopathy is effective: NHMRC review](https://theconversation.com/no-evidence-homeopathy-is-effective-nhmrc-review-25368)
- [CRMV-SP — Homeopatia: uma das primeiras especialidades reconhecidas na Medicina Veterinária](https://crmvsp.gov.br/homeopatia-uma-das-primeiras-especialidades-reconhecidas-na-medicina-veterinaria-segue-em-expansao/)
- [Homeopathy Research Institute — contraponto dos defensores ao relatório australiano](https://www.hri-research.org/resources/homeopathy-the-debate/the-australian-report-on-homeopathy/)

---
Voltar: [[00-materia-medica-home|Matéria Médica]]
