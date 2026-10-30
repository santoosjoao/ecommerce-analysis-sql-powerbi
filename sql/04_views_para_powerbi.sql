-- =====================================================================
-- 04_views_para_powerbi.sql
-- Camada pronta para consumo no Power BI (já filtrada e padronizada).
-- Escopo: 'delivered', jan/2017 a ago/2018.
-- Modelo: vw_pedidos (1) ----> (N) vw_vendas   por order_id
-- =====================================================================
USE olist;

-- Uma linha por PEDIDO (entrega, avaliação, pagamento)
CREATE OR REPLACE VIEW vw_pedidos AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state                                    AS estado,
    c.customer_city                                     AS cidade,
    DATE(o.order_purchase_timestamp)                    AS data_compra,
    i.qtd_itens,
    i.valor_produtos,
    i.valor_frete,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)       AS dias_entrega,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)  AS dias_atraso,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 1 ELSE 0 END                              AS flag_atraso,
    CASE
      WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'No prazo'
      WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 3 THEN 'Atraso 1-3 dias'
      WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 7 THEN 'Atraso 4-7 dias'
      ELSE 'Atraso > 7 dias'
    END                                                 AS faixa_atraso,
    r.nota_avaliacao,
    pg.payment_type                                     AS forma_pagamento,
    pg.payment_installments                             AS parcelas
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN (SELECT order_id, COUNT(*) AS qtd_itens,
             SUM(price) AS valor_produtos, SUM(freight_value) AS valor_frete
      FROM order_items GROUP BY order_id) i ON i.order_id = o.order_id
LEFT JOIN (SELECT order_id, AVG(review_score) AS nota_avaliacao
           FROM order_reviews GROUP BY order_id) r ON r.order_id = o.order_id
LEFT JOIN order_payments pg
       ON pg.order_id = o.order_id AND pg.payment_sequential = 1
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- Uma linha por ITEM vendido (produto, categoria, vendedor)
CREATE OR REPLACE VIEW vw_vendas AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'sem_categoria') AS categoria,
    oi.seller_id,
    s.seller_state                                      AS estado_vendedor,
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN vw_pedidos vp ON vp.order_id = oi.order_id
JOIN products p    ON p.product_id = oi.product_id
JOIN sellers s     ON s.seller_id = oi.seller_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;

-- Uma linha por CLIENTE (para análise de recorrência)
CREATE OR REPLACE VIEW vw_clientes AS
SELECT
    customer_unique_id,
    MIN(estado)                 AS estado,
    COUNT(*)                    AS qtd_pedidos,
    ROUND(SUM(valor_produtos),2) AS valor_total,
    MIN(data_compra)            AS primeira_compra,
    MAX(data_compra)            AS ultima_compra,
    CASE WHEN COUNT(*) > 1 THEN 'Recorrente' ELSE 'Compra única' END AS perfil
FROM vw_pedidos
GROUP BY customer_unique_id;

-- Teste
SELECT COUNT(*) AS linhas_pedidos FROM vw_pedidos;
SELECT COUNT(*) AS linhas_vendas  FROM vw_vendas;
SELECT perfil, COUNT(*) FROM vw_clientes GROUP BY perfil;
