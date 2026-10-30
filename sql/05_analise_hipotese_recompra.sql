-- =====================================================================
-- 05_analise_hipotese_recompra.sql  |  Testando a hipótese principal
--
-- Hipótese: uma experiência ruim (entrega atrasada / nota baixa) no
-- PRIMEIRO pedido reduz a chance de o cliente voltar a comprar.
--
-- Cuidados metodológicos:
--  * Escopo: pedidos 'delivered', jan/2017 a ago/2018.
--  * Só entram clientes cujo 1º pedido foi até fev/2018, para que todos
--    tenham pelo menos 6 meses para voltar a comprar dentro da base.
--  * Isto mostra ASSOCIAÇÃO, não causa: outros fatores (categoria,
--    estado, preço) podem influenciar. Interprete com cautela.
-- =====================================================================
USE olist;

-- ---------------------------------------------------------------------
-- A) Taxa de recompra conforme a entrega do 1º pedido
-- ---------------------------------------------------------------------
WITH pedidos AS (
    SELECT c.customer_unique_id,
           o.order_id,
           o.order_purchase_timestamp       AS data_compra,
           o.order_delivered_customer_date  AS entrega,
           o.order_estimated_delivery_date  AS prevista,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp, o.order_id) AS ordem,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id)                  AS total_pedidos
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
),
primeiro AS (
    SELECT customer_unique_id, total_pedidos,
           CASE WHEN entrega <= prevista THEN 'No prazo' ELSE 'Atrasado' END AS situacao
    FROM pedidos
    WHERE ordem = 1
      AND data_compra < '2018-03-01'
)
SELECT situacao,
       COUNT(*)                                              AS clientes,
       SUM(total_pedidos > 1)                                AS recompraram,
       ROUND(100 * SUM(total_pedidos > 1) / COUNT(*), 2)     AS taxa_recompra_pct
FROM primeiro
GROUP BY situacao;

-- ---------------------------------------------------------------------
-- B) Taxa de recompra conforme a nota do 1º pedido
-- ---------------------------------------------------------------------
WITH pedidos AS (
    SELECT c.customer_unique_id,
           o.order_id,
           o.order_purchase_timestamp AS data_compra,
           (SELECT AVG(r.review_score) FROM order_reviews r WHERE r.order_id = o.order_id) AS nota,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                              ORDER BY o.order_purchase_timestamp, o.order_id) AS ordem,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id)                  AS total_pedidos
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
),
primeiro AS (
    SELECT customer_unique_id, total_pedidos,
           CASE WHEN nota IS NULL THEN '0. Sem avaliação'
                WHEN nota < 3     THEN '1. Nota 1-2 (ruim)'
                WHEN nota < 4     THEN '2. Nota 3 (regular)'
                ELSE                   '3. Nota 4-5 (boa)' END AS faixa_nota
    FROM pedidos
    WHERE ordem = 1
      AND data_compra < '2018-03-01'
)
SELECT faixa_nota,
       COUNT(*)                                              AS clientes,
       SUM(total_pedidos > 1)                                AS recompraram,
       ROUND(100 * SUM(total_pedidos > 1) / COUNT(*), 2)     AS taxa_recompra_pct
FROM primeiro
GROUP BY faixa_nota
ORDER BY faixa_nota;

-- ---------------------------------------------------------------------
-- C) Onde os atrasos se concentram? (% de atraso e prazo por estado)
-- ---------------------------------------------------------------------
SELECT c.customer_state                                                    AS estado,
       COUNT(*)                                                            AS pedidos,
       ROUND(100 * SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date)
             / COUNT(*), 1)                                                AS pct_atraso,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS prazo_medio_dias
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_state
HAVING COUNT(*) >= 300
ORDER BY pct_atraso DESC;
