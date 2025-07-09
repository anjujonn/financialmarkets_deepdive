CREATE TABLE Stocks (
    stock_id INT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL,
    industry VARCHAR(225) NOT NULL
);

CREATE TABLE Stock_Prices (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    stock_id INT NOT NULL,
    date DATE NOT NULL,
    open_price DECIMAL(10,2) NOT NULL,
    close_price DECIMAL(10,2) NOT NULL,
    high DECIMAL(10,2) NOT NULL,
    low DECIMAL(10,2) NOT NULL,
    volume BIGINT NOT NULL,
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id) ON DELETE CASCADE
);

CREATE TABLE Moving_Average (
    stock_id INT NOT NULL,
    date DATE NOT NULL,
    five_day_avg DECIMAL(10,2) NOT NULL,
    twenty_day_avg DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (stock_id, date),
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id) ON DELETE CASCADE
);

CREATE TABLE MACD_Data (
    stock_id INT NOT NULL,
    date DATE NOT NULL,
    MACD DECIMAL(10,2) NOT NULL,
    Signal_Line DECIMAL(10,2) NOT NULL,
    Trading_Signal VARCHAR(10) NOT NULL,
    PRIMARY KEY (stock_id, date),
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id) ON DELETE CASCADE
);