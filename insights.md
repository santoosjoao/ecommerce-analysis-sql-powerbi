# Insights e Recomendações

> **Escopo:** KPIs, evolução mensal, comparativo anual e categorias usam pedidos entregues de **jan/2017 a ago/2018**.
> Produtos, estados, pagamentos, recorrência, vendedores e entrega x avaliação foram calculados na primeira execução sobre **todo o
> histórico** de pedidos entregues. O script `03` agora usa o mesmo recorte (jan/2017–ago/2018) em todas as consultas, então os
> números dessas análises podem variar levemente ao reexecutar.
> Faturamento = soma do preço dos produtos (sem frete).

## Resumo executivo
Entre jan/2017 e ago/2018, a empresa faturou **R$ 13,18 milhões** em **96.211 pedidos** entregues, para
**93.104 clientes únicos**, com ticket médio de **R$ 137,00**. O crescimento é expressivo (**+141%** no comparativo
jan–ago de 2018 vs 2017) e vem de **volume**, não de ticket, concentrando-se em 2017: em 2018 o faturamento mensal estagnou. Os pontos de atenção são: **estagnação em 2018**, **logística**
(atraso derruba a nota de 4,29 para 1,70), **baixa recorrência** (97% compram uma única vez) e
**concentração geográfica** (63% do faturamento em SP, RJ e MG).

---

## 1. Forte crescimento em 2017 e estagnação em 2018
- **Achado:** a empresa mais que dobrou de tamanho, mas o crescimento veio de volume (o ticket não mudou) e o
  faturamento mensal parou de subir em 2018.
- **Evidência:** jan–ago/2018 faturou R$ 7,22 mi contra R$ 2,99 mi em jan–ago/2017 (**+141%**), com pedidos
  subindo de 21.998 para 52.783 (**+140%**) e ticket de R$ 136,08 para R$ 136,75 (**+0,5%**). Em 8 meses de 2018, o
  faturamento já superou em **21%** o de todo o ano de 2017 (R$ 5,96 mi). Porém, pelo gráfico mensal, o maior mês foi
  **nov/2017 (R$ 987,6 mil)** e nenhum mês de 2018 o superou: a média mensal de 2018 foi de ~R$ 902 mil, e ago/2018
  fechou em R$ 838,6 mil (valor que pode estar subestimado, pois só pedidos entregues entram na conta).
- **Sazonalidade:** nov/2017 teve 7.544 pedidos (todos os status) contra 4.631 em out/2017 (**+63%**),
  pico provavelmente ligado à Black Friday.
- **Recomendação:** investigar por que o ritmo parou em 2018 (aquisição de clientes, mix, capacidade logística),
  testar alavancas de ticket (kits, compre junto, frete grátis acima de um valor mínimo) e planejar estoque,
  frete e atendimento para datas sazonais.

## 2. Receita concentrada em poucas categorias
- **Achado:** cinco categorias respondem por cerca de 40% do faturamento.
- **Evidência:** health_beauty (9,3%, R$ 1,23 mi), watches_gifts (8,8%), bed_bath_table (7,8%),
  sports_leisure (7,2%) e computers_accessories (6,7%) somam ~39,9%.
  watches_gifts tem o maior ticket do grupo (R$ 198,71 por item) com apenas 5.855 itens, enquanto
  bed_bath_table vende 10.945 itens a R$ 93,46.
- **Recomendação:** proteger a disponibilidade e o preço das categorias líderes; ampliar o mix de
  categorias de ticket alto (como watches_gifts) e usar as de alto volume (bed_bath_table) como porta de
  entrada para cross-sell.

## 3. Catálogo pulverizado, sem dependência de produtos específicos
- **Achado:** nenhum produto individual é relevante para o faturamento total.
- **Evidência:** o produto mais vendido teve 520 unidades e R$ 37 mil, cerca de **0,3%** do faturamento.
  O top 5 de produtos é dominado por itens de baixo valor (garden_tools, furniture_decor, bed_bath_table).
- **Recomendação:** gerir o negócio por categoria, e não por produto. Usar o ranking de produtos para
  decisões de estoque, não para estratégia de receita.

## 4. Sudeste concentra a receita; frete e prazo pesam nas demais regiões
- **Achado:** SP, RJ e MG somam quase dois terços do faturamento, e fora de SP o frete é mais caro e a entrega mais lenta.
- **Evidência:** SP 38,3%, RJ 13,3% e MG 11,7% (**63,3%**; no dashboard, R$ 5,1 mi, R$ 1,8 mi e R$ 1,5 mi). O frete equivale a 13,9% do valor dos produtos em SP, contra
  16,8% a 18,2% em RJ, MG, RS e PR. Prazo médio de entrega: **8,7 dias em SP** contra 15,1 em RJ e RS e 11,9 em MG e PR.
  No total, o frete representa **16,6%** do faturamento (R$ 2,19 mi).
- **Recomendação:** negociar transportadoras regionais, avaliar um centro de distribuição fora de SP e testar
  frete grátis condicionado a valor mínimo nas regiões com menor participação.

## 5. Pedidos atrasados recebem avaliações muito piores
- **Achado:** quanto maior o atraso, pior a avaliação, e mesmo atrasos curtos já aparecem com notas menores. É uma
  **associação**: a base não permite afirmar que o atraso, sozinho, causa a nota baixa.
- **Evidência:** 91,9% dos pedidos chegam no prazo, com nota **4,29**. Atraso de 1–3 dias: 3,60; de 4–7 dias: 2,11;
  acima de 7 dias: **1,70** (queda de 2,59 pontos, ou **-60%**). São 7.826 pedidos atrasados (**8,1%**) e o prazo médio de entrega é de **12,5 dias**.
- **Recomendação:** revisar a promessa de prazo (estimar o que dá para cumprir), monitorar SLA por
  transportadora e região, e avisar proativamente o cliente em caso de atraso. Como o problema atinge
  só ~8% dos pedidos, o ganho em satisfação por real investido tende a ser alto.

## 6. Baixíssima recorrência de clientes
- **Achado:** quase todos os clientes compram uma única vez.
- **Evidência:** **97,0%** (90.557) compraram uma vez; apenas **3,0%** (2.801) voltaram.
- **Recomendação:** programa de pós-venda (e-mail em 30 e 60 dias), cupom de segunda compra e recomendação
  baseada na categoria da primeira compra. Estimativa simples: se 1% dos clientes (≈ 931) fizesse uma compra
  adicional pelo ticket médio, seriam **≈ R$ 128 mil** a mais, cerca de 1% do faturamento do período.

## 7. Cartão de crédito domina os pagamentos
- **Achado:** o cartão é o principal meio de pagamento e o boleto ainda tem peso relevante.
- **Evidência:** cartão de crédito = **78,3%** do valor (ticket R$ 163,32); boleto = 17,9% (R$ 145,03);
  voucher = 2,4%; débito = 1,4%.
- **Recomendação:** manter e comunicar o parcelamento, que sustenta o ticket do cartão; manter o boleto para
  não perder o público sem cartão; explorar o voucher como ferramenta de fidelização.

## 8. Receita concentrada em uma minoria de vendedores
- **Achado:** poucos vendedores sustentam a maior parte da receita.
- **Evidência:** **532 de 2.970 vendedores (17,9%)** geram 80% da receita, seguindo a regra 80/20.
- **Recomendação:** programa de retenção e de SLA para os top vendedores e onboarding para desenvolver
  os de médio porte.

---

## Conclusão final

**Diagnóstico geral.** Entre jan/2017 e ago/2018, a empresa construiu uma operação de **R$ 13,18 milhões** e cresceu
**141%** no comparativo anual. Esse crescimento, porém, tem três fragilidades: foi obtido por **volume** (o ticket ficou
em ~R$ 137), **parou em 2018** (faturamento mensal estável, em torno de R$ 0,9 mi) e se apoia quase só em **clientes
novos** (97% compram uma única vez). Além disso, há um problema operacional claro e mensurável: a **logística**.

**Problemas identificados, em ordem de prioridade**

| # | Problema | Evidência | Por que importa | Ação sugerida |
|---|---|---|---|---|
| 1 | Atraso na entrega | 8,1% dos pedidos atrasam; a nota é de 1,7 nos atrasos acima de 7 dias contra 4,3 no prazo; prazo médio de 12,5 dias, sendo 8,7 em SP e 15,1 em RJ e RS | Experiência ruim afeta reputação e, provavelmente, a recompra | Rever o prazo prometido, criar SLA por transportadora e região e avisar o cliente sobre atrasos |
| 2 | Baixa retenção | 97% compraram uma vez; só 2.801 clientes recorrentes | A receita depende de adquirir clientes novos o tempo todo | Pós-venda em 30 e 60 dias, cupom de segunda compra e recomendação por categoria |
| 3 | Estagnação em 2018 | Média mensal de ~R$ 902 mil em 2018; maior mês foi nov/2017 (R$ 987,6 mil); ticket +0,5% | Sem novas alavancas, a receita não cresce | Investigar as causas, testar kits e frete grátis acima de um valor mínimo e planejar a sazonalidade |
| 4 | Concentração | SP, RJ e MG = 63,3% do faturamento; 5 categorias = ~40%; 17,9% dos vendedores geram 80% | Risco de dependência de poucas regiões, categorias e vendedores | Expandir com logística local, ampliar o mix e criar programa de retenção dos top vendedores |
| 5 | Frete alto fora de SP | Frete = 16,6% do faturamento; 16,8% a 18,2% em RJ, MG, RS e PR contra 13,9% em SP | Pode reduzir a conversão nas regiões mais distantes | Negociar transportadoras regionais e testar frete grátis condicionado |

**Leitura do analista.** Os problemas 1 e 2 provavelmente estão ligados: uma experiência de entrega ruim tende a reduzir a
chance de recompra. Essa é uma **hipótese**, e a base não permite provar o vínculo, porque a recompra é de apenas 3%.
O problema 3 é, em parte, consequência dos demais: sem retenção e sem aumento de ticket, o crescimento depende só de
aquisição. Os problemas 4 e 5 são riscos estruturais que ficam mais relevantes se a empresa quiser crescer fora do Sudeste.

**Prioridade recomendada**
1. **Logística:** é a ação mais controlável, atinge só ~8% dos pedidos (bom retorno para o esforço) e pode ser medida
   por % de atraso e nota média.
2. **Retenção:** estimativa simples, com o ticket médio de R$ 137: cada 1 ponto percentual de clientes que recomprarem
   vale cerca de **R$ 128 mil**; 5 pontos percentuais, cerca de **R$ 640 mil**.
3. **Ticket, mix e regiões:** retomar o crescimento sem depender apenas de volume.

**Metas sugeridas** (a validar com o negócio): reduzir o % de atraso de 8,1% para menos de 5%; elevar a recorrência de
3% para 5%; e voltar a superar o pico mensal de nov/2017 (R$ 987,6 mil).

---

## Limitações
- Não há dados de custo ou margem: a análise usa receita, não lucro.
- Base anonimizada, de 2016 a 2018. Os meses de 2016 e o fim da base (set/out 2018) ficam fora dos KPIs.
- Valores de pagamento incluem frete e juros de parcelamento, por isso diferem do faturamento (que usa o preço dos produtos).
- Pedidos de nov/2017 no item 1 incluem todos os status.

## Próximos passos
- Rodar `sql/05_analise_hipotese_recompra.sql` e registrar aqui se a recompra é menor após entrega atrasada ou nota baixa.
- Segmentação RFM de clientes.
- Previsão de demanda mensal.
- Análise de texto dos comentários de avaliação.
