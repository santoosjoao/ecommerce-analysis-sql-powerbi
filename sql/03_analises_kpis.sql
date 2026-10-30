-- =====================================================================
-- 03_analises_kpis.sql  |  Análises de negócio (MySQL 8.0+)
-- Escopo PADRONIZADO em todas as consultas: pedidos 'delivered' de
-- jan/2017 a ago/2018 (mesmo recorte das views do Power BI).
-- Faturamento = SUM(price) (produtos, sem frete).
-- Exceção: a consulta 12 (cancelamentos) usa todos os status.
-- =====================================================================
USE olist;

-- ---------------------------------------------------------------------
-- 1) KPIs gerais
-- ---------------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id)                              AS pedidos,
    COUNT(DISTINCT c.customer_unique_id)                    AS clientes_unicos,
    ROUND(SUM(oi.price), 2)                                 AS faturamento,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)    AS ticket_medio,
    ROUND(SUM(oi.freight_value), 2)                         AS frete_total,
    ROUND(100 * SUM(oi.freight_value) / SUM(oi.price), 1)   AS frete_pct_do_faturamento
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN customers c    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- ---------------------------------------------------------------------
-- 2) Desempenho mensal + crescimento MoM (window function LAG)
-- ---------------------------------------------------------------------
WITH mensal AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS mes,
           COUNT(DISTINCT o.order_id)                          AS pedidos,
           SUM(oi.price)                                       AS faturamento
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT mes, pedidos,
       ROUND(faturamento, 2)                         AS faturamento,
       ROUND(faturamento / pedidos, 2)               AS ticket_medio,
       ROUND(100 * (faturamento - LAG(faturamento) OVER (ORDER BY mes))
             / LAG(faturamento) OVER (ORDER BY mes), 1) AS crescimento_mom_pct
FROM mensal
ORDER BY mes;

-- ---------------------------------------------------------------------
-- 3) Comparativo ano contra ano (jan-ago de 2017 vs 2018)
-- ---------------------------------------------------------------------
SELECT YEAR(o.order_purchase_timestamp)        AS ano,
       COUNT(DISTINCT o.order_id)              AS pedidos,
       ROUND(SUM(oi.price), 2)                 AS faturamento,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND MONTH(o.order_purchase_timestamp) BETWEEN 1 AND 8
  AND YEAR(o.order_purchase_timestamp) IN (2017, 2018)
GROUP BY 1;

-- ---------------------------------------------------------------------
-- 4) Top 10 categorias: faturamento e participação (%)
-- ---------------------------------------------------------------------
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'sem_categoria') AS categoria,
       COUNT(*)                                                  AS itens_vendidos,
       ROUND(SUM(oi.price), 2)                                   AS faturamento,
       ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 1) AS participacao_pct,
       ROUND(AVG(oi.price), 2)                                   AS preco_medio
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY 1
ORDER BY faturamento DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 5) Top 10 produtos mais vendidos (em unidades)
-- ---------------------------------------------------------------------
SELECT oi.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name) AS categoria,
       COUNT(*)                AS unidades,
       ROUND(SUM(oi.price), 2) AS faturamento
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY oi.product_id, categoria
ORDER BY unidades DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 6) Desempenho por estado do cliente
-- ---------------------------------------------------------------------
SELECT c.customer_state                                         AS estado,
       COUNT(DISTINCT o.order_id)                               AS pedidos,
       ROUND(SUM(oi.price), 2)                                  AS faturamento,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)     AS ticket_medio,
       ROUND(100 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 1) AS participacao_pct,
       ROUND(100 * SUM(oi.freight_value) / SUM(oi.price), 1)    AS frete_pct,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS prazo_medio_dias
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN customers c    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_state
ORDER BY faturamento DESC;

-- ---------------------------------------------------------------------
-- 7) Atraso na entrega x nota de avaliação
--    (associação, não causalidade: ver 05_analise_hipotese_recompra.sql)
-- ---------------------------------------------------------------------
WITH pedidos AS (
    SELECT o.order_id,
           CASE
             WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN '1. No prazo'
             WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 3 THEN '2. Atraso 1-3 dias'
             WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 7 THEN '3. Atraso 4-7 dias'
             ELSE '4. Atraso > 7 dias'
           END AS situacao_entrega,
           (SELECT AVG(r.review_score) FROM order_reviews r WHERE r.order_id = o.order_id) AS nota
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
)
SELECT situacao_entrega,
       COUNT(*)                                          AS pedidos,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_pedidos,
       ROUND(AVG(nota), 2)                               AS nota_media
FROM pedidos
GROUP BY situacao_entrega
ORDER BY situacao_entrega;

-- ---------------------------------------------------------------------
-- 8) Formas de pagamento e parcelamento (pedidos do escopo)
-- ---------------------------------------------------------------------
SELECT p.payment_type                                       AS forma_pagamento,
       COUNT(DISTINCT p.order_id)                           AS pedidos,
       ROUND(SUM(p.payment_value), 2)                       AS valor,
       ROUND(100 * SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER (), 1) AS participacao_pct,
       ROUND(AVG(p.payment_value), 2)                       AS ticket_medio
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY p.payment_type
ORDER BY valor DESC;

SELECT CASE WHEN p.payment_installments = 1 THEN '1x (à vista)'
            WHEN p.payment_installments BETWEEN 2 AND 5 THEN '2-5x'
            WHEN p.payment_installments BETWEEN 6 AND 10 THEN '6-10x'
            ELSE '11x+' END AS faixa_parcelas,
       COUNT(*)                     AS pagamentos,
       ROUND(AVG(p.payment_value), 2) AS valor_medio
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
WHERE p.payment_type = 'credit_card'
  AND o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY faixa_parcelas
ORDER BY MIN(p.payment_installments);

-- ---------------------------------------------------------------------
-- 9) Clientes recorrentes x únicos (customer_unique_id!)
-- ---------------------------------------------------------------------
WITH compras AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS qtd_pedidos
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT CASE WHEN qtd_pedidos = 1 THEN 'Compra única' ELSE 'Recorrente (2+)' END AS perfil,
       COUNT(*)                                          AS clientes,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct
FROM compras
GROUP BY perfil;

-- ---------------------------------------------------------------------
-- 10) Concentração de vendedores (Pareto): quantos geram 80% da receita?
-- ---------------------------------------------------------------------
WITH vend AS (
    SELECT oi.seller_id, SUM(oi.price) AS faturamento
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY oi.seller_id
),
acum AS (
    SELECT seller_id, faturamento,
           SUM(faturamento) OVER (ORDER BY faturamento DESC) / SUM(faturamento) OVER () AS pct_acumulado,
           ROW_NUMBER() OVER (ORDER BY faturamento DESC) AS ranking
    FROM vend
)
SELECT COUNT(*)                                        AS vendedores_para_80pct,
       (SELECT COUNT(*) FROM vend)                     AS total_vendedores,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM vend), 1) AS pct_dos_vendedores
FROM acum
WHERE pct_acumulado <= 0.80;

-- ---------------------------------------------------------------------
-- 11) Sazonalidade: dia da semana
-- ---------------------------------------------------------------------
SELECT DAYNAME(o.order_purchase_timestamp)   AS dia_semana,
       COUNT(DISTINCT o.order_id)            AS pedidos,
       ROUND(SUM(oi.price), 2)               AS faturamento
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY DAYOFWEEK(o.order_purchase_timestamp), dia_semana
ORDER BY DAYOFWEEK(o.order_purchase_timestamp);

-- ---------------------------------------------------------------------
-- 12) Taxa de cancelamento por mês (todos os status)
-- ---------------------------------------------------------------------
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes,
       COUNT(*)                                       AS pedidos,
       SUM(order_status = 'canceled')                 AS cancelados,
       ROUND(100 * SUM(order_status = 'canceled') / COUNT(*), 2) AS taxa_cancelamento_pct
FROM orders
WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY 1
ORDER BY 1;
