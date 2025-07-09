-- query 1: finding stocks with heavy insider buying
SELECT *
FROM Insider_Trades
JOIN(
    SELECT stock_id
    FROM Insider_Trades
    WHERE trade_type = 'Buy'
    GROUP BY stock_id
    ORDER BY COUNT(*) DESC
    LIMIT 3
) AS top_stocks ON Insider_Trades.stock_id = top_stocks.stock_id
WHERE Insider_Trades.trade_type = 'Buy';

--query 2: identifying companies where insiders are selling before major price drops
SELECT
    insider_trades.stock_id AS trader_sid,
    stocks.symbol,
    stocks.company_name,
    insider_trades.insider_name,
    insider_trades.trade_date,
    insider_trades.trade_type,
    insider_trades.shares_traded,
    insider_trades.trade_price,
    sp_prev.close_price AS prev_close_price,
    sp_curr.close_price AS curr_close_price,
    CONCAT(ROUND((sp_curr.close_price / sp_prev.close_price) * 100, 2), '%') AS pct_of_prev_price
FROM insider_trades
JOIN stocks
    ON stocks.stock_id = insider_trades.stock_id
JOIN stock_prices sp_curr
    ON sp_curr.stock_id = insider_trades.stock_id
    AND insider_trades.trade_date = sp_curr.date
JOIN stock_prices sp_prev
    ON sp_prev.stock_id = insider_trades.stock_id
    AND DATE_SUB(insider_trades.trade_date, INTERVAL 7 DAY) = sp_prev.date
WHERE insider_trades.trade_type = 'Sale'
    AND insider_trades.trade_date >= '2024-09-25'
    AND (sp_curr.close_price / sp_prev.close_price) < 0.90
ORDER BY pct_of_prev_price ASC;

--query 3: identifying companies where insiders are buying before major price gains.
SELECT
    s.company_name,
    it.insider_name,
    it.trade_date,
    it.trade_type,
    it.trade_price,
    sp.close_price AS price_after_7_days,
    CONCAT(ROUND(((sp.close_price - it.trade_price) / it.trade_price) * 100, 2), '%') AS percent_gain
FROM
    Insider_Trades it
JOIN
    Stocks s ON it.stock_id = s.stock_id
JOIN
    Stock_Prices sp
    ON sp.stock_id = it.stock_id
    AND sp.date = DATE_ADD(it.trade_date, INTERVAL 7 DAY)
WHERE
    it.trade_type = 'Buy'
    AND it.trade_date >= '2024-10-18'
    AND ((sp.close_price - it.trade_price) / it.trade_price) >= 0.01
ORDER BY
    ((sp.close_price - it.trade_price) / it.trade_price) DESC;

-- query 4: dompare trading volume before and after insider trades
WITH volume_stats AS (
    SELECT
        s.company_name,
        it.insider_name,
        it.trade_date,
        it.trade_type,
        it.shares_traded,
        it.trade_price,
        -- Average volume before the trade
        ROUND(AVG(CASE
            WHEN sp.date BETWEEN DATE_SUB(it.trade_date, INTERVAL 7 DAY)
            AND DATE_SUB(it.trade_date, INTERVAL 1 DAY)
            THEN sp.volume
        END), 2) AS volume_before,
        -- Average volume after the trade
        ROUND(AVG(CASE
            WHEN sp.date BETWEEN DATE_ADD(it.trade_date, INTERVAL 1 DAY)
            AND DATE_ADD(it.trade_date, INTERVAL 7 DAY)
            THEN sp.volume
        END), 2) AS volume_after
    FROM
        Insider_Trades it
    JOIN
        Stocks s ON it.stock_id = s.stock_id
    JOIN
        Stock_Prices sp ON sp.stock_id = it.stock_id
        AND sp.date BETWEEN DATE_SUB(it.trade_date, INTERVAL 7 DAY)
        AND DATE_ADD(it.trade_date, INTERVAL 7 DAY)
    WHERE
        it.trade_type = 'Buy'
        AND it.trade_price > 0
        AND it.trade_date BETWEEN '2024-10-20' AND '2025-04-08'
    GROUP BY
        s.symbol, s.company_name, it.insider_name, it.trade_date,
        it.trade_type, it.shares_traded, it.trade_price
)
SELECT *,
    CONCAT(ROUND(((volume_after - volume_before) / volume_before) * 100, 2), '%') AS percent_volume_change
FROM volume_stats
ORDER BY percent_volume_change DESC;

