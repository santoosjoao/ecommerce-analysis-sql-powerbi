-- =====================================================================
-- 02_limpeza_validacao.sql  |  Qualidade dos dados
-- Entenda os problemas da base ANTES de analisar e documente as
-- decisões (copie os resultados para o README).
-- =====================================================================
USE olist;

-- 1) Distribuição de status dos pedidos
SELECT order_status, COUNT(*) AS pedidos,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders GROUP BY order_status ORDER BY pedidos DESC;
-- Decisão: faturamento considera apenas 'delivered'.

-- 2) Período coberto e meses incompletos
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes, COUNT(*) AS pedidos
FROM orders GROUP BY 1 ORDER BY 1;
-- Decisão: 2016 e set/out 2018 têm volume muito baixo -> análise de
-- jan/2017 a ago/2018 para não distorcer tendências.

-- 3) Nulos nas colunas de data
SELECT
  SUM(order_approved_at IS NULL)             AS sem_aprovacao,
  SUM(order_delivered_carrier_date IS NULL)  AS sem_despacho,
  SUM(order_delivered_customer_date IS NULL) AS sem_entrega
FROM orders;

-- 4) Pedidos 'delivered' sem data de entrega (inconsistência)
SELECT COUNT(*) AS delivered_sem_data
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- 5) Datas ilógicas (entrega antes da compra)
SELECT COUNT(*) AS entrega_antes_da_compra
FROM orders WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 6) Pedidos sem itens
SELECT COUNT(*) AS pedidos_sem_itens
FROM orders o LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE oi.order_id IS NULL;

-- 7) Itens sem categoria
SELECT COUNT(*) AS itens_sem_categoria
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL;

-- 8) Categorias sem tradução
SELECT DISTINCT p.product_category_name
FROM products p LEFT JOIN category_translation t
  ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL;

-- 9) Pedidos com mais de uma avaliação (duplicidade)
SELECT COUNT(*) AS pedidos_com_varias_avaliacoes FROM (
  SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1
) x;
-- Decisão: usar a média da nota por pedido.

-- 10) Preço zerado ou negativo
SELECT COUNT(*) AS preco_invalido FROM order_items WHERE price <= 0;

-- 11) Valor pago diferente de itens + frete (> R$ 1)
SELECT COUNT(*) AS pedidos_divergentes FROM (
  SELECT o.order_id
  FROM orders o
  JOIN (SELECT order_id, SUM(price + freight_value) total
        FROM order_items GROUP BY order_id) i ON i.order_id = o.order_id
  JOIN (SELECT order_id, SUM(payment_value) pago
        FROM order_payments GROUP BY order_id) p ON p.order_id = o.order_id
  WHERE ABS(i.total - p.pago) > 1
) d;
-- Diferenças vêm, em geral, de juros de parcelamento e vouchers.
