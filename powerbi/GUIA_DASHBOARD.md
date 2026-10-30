# Guia do Dashboard (Power BI)

## 1. Conexão
`Obter dados > Banco de dados MySQL` (instale antes o **MySQL Connector/NET**).
Servidor `localhost`, banco `olist`. Importe: `vw_pedidos`, `vw_vendas`, `vw_clientes`.

## 2. Tabela calendário (Modelagem > Nova tabela)
```DAX
dCalendario =
ADDCOLUMNS(
    CALENDAR(DATE(2017,1,1), DATE(2018,8,31)),
    "Ano", YEAR([Date]),
    "MesNum", MONTH([Date]),
    "Mes", FORMAT([Date], "mmm/yy"),
    "AnoMes", YEAR([Date]) * 100 + MONTH([Date])
)
```
Marque como tabela de datas. Em `Mes`, **Classificar por coluna** = `AnoMes`.

## 3. Relacionamentos
| De | Para | Cardinalidade |
|---|---|---|
| dCalendario[Date] | vw_pedidos[data_compra] | 1 : N |
| vw_pedidos[order_id] | vw_vendas[order_id] | 1 : N (filtro de pedidos → vendas) |
| vw_clientes[customer_unique_id] | vw_pedidos[customer_unique_id] | 1 : N |

## 4. Medidas DAX
```DAX
Faturamento = SUM(vw_vendas[price])

Pedidos = DISTINCTCOUNT(vw_vendas[order_id])

Ticket Médio = DIVIDE([Faturamento], [Pedidos])

Itens Vendidos = COUNTROWS(vw_vendas)

Frete Total = SUM(vw_vendas[freight_value])

Frete % = DIVIDE([Frete Total], [Faturamento])

Nota Média = AVERAGE(vw_pedidos[nota_avaliacao])

Prazo Médio (dias) = AVERAGE(vw_pedidos[dias_entrega])

% Atraso =
DIVIDE(
    CALCULATE(COUNTROWS(vw_pedidos), vw_pedidos[flag_atraso] = 1),
    COUNTROWS(vw_pedidos)
)

Faturamento Mês Anterior =
CALCULATE([Faturamento], DATEADD(dCalendario[Date], -1, MONTH))

Crescimento MoM =
DIVIDE([Faturamento] - [Faturamento Mês Anterior], [Faturamento Mês Anterior])

Faturamento Ano Anterior =
CALCULATE([Faturamento], SAMEPERIODLASTYEAR(dCalendario[Date]))

Crescimento YoY =
DIVIDE([Faturamento] - [Faturamento Ano Anterior], [Faturamento Ano Anterior])

% Clientes Recorrentes =
DIVIDE(
    CALCULATE(COUNTROWS(vw_clientes), vw_clientes[perfil] = "Recorrente"),
    COUNTROWS(vw_clientes)
)
```

## 5. Layout sugerido (3 páginas)

**Página 1 – Visão Geral**
- Cartões: Faturamento, Pedidos, Ticket Médio, Nota Média, Crescimento YoY
- Linha: Faturamento por `dCalendario[Mes]` (+ linha de Ticket Médio no eixo secundário)
- Colunas: Pedidos por mês
- Segmentações: Ano e Estado

**Página 2 – Produtos e Vendedores**
- Barras horizontais: Top 10 categorias por Faturamento
- Treemap: participação das categorias
- Tabela: Top 10 produtos (unidades e faturamento)
- Segmentação: Categoria

**Página 3 – Clientes e Logística**
- Mapa (ou barras): Faturamento por Estado
- Colunas: Nota Média por `faixa_atraso` (o gráfico mais impactante do projeto)
- Cartões: % Atraso, Prazo Médio, Frete %
- Rosca: Recorrente x Compra única
- Barras: Forma de pagamento

## 6. Boas práticas visuais
- 1 cor principal + 1 de destaque (ex.: azul-escuro e laranja); fundo claro.
- Título em cada gráfico dizendo a conclusão ("Atraso derruba a nota de 4,3 para 2,5"), não só o nome do gráfico.
- Formatar valores em R$ e %, sem casas decimais desnecessárias.
- Alinhar objetos pela grade; mesmo tamanho para cartões.
- Exporte prints para `/images` e grave um GIF curto navegando pelos filtros.
