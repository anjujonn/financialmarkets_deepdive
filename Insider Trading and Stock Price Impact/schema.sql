CREATE TABLE Stocks (
    stock_id INT PRIMARY KEY AUTO_INCREMENT,
    symbol VARCHAR(10) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL
);

CREATE TABLE Stock_Prices (
    price_id INT PRIMARY KEY AUTO_INCREMENT,
    stock_id INT,
    date DATE NOT NULL,
    open_price DECIMAL(10, 2) NOT NULL,
    close_price DECIMAL(10, 2) NOT NULL,
    high DECIMAL(10, 2) NOT NULL,
    low DECIMAL(10, 2) NOT NULL,
    volume BIGINT NOT NULL,
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id)
);

CREATE TABLE Insider_Trades (
    trade_id INT PRIMARY KEY AUTO_INCREMENT,
    stock_id INT,
    insider_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    trade_date DATE NOT NULL,
    trade_type ENUM('Buy', 'Sale', 'Option Exercise') NOT NULL,
    shares_traded BIGINT NOT NULL,
    shares_total BIGINT NOT NULL,
    trade_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id)
);

CREATE INDEX idx_stock_prices_stock_date
ON Stock_Prices(stock_id, date);
CREATE INDEX idx_insider_trades_type_date_stock
ON Insider_Trades(trade_type, trade_date, stock_id);