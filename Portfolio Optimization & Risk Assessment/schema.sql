CREATE TABLE Stocks (
    stock_id INT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL
);

CREATE TABLE Historical_Returns (
    return_id INT PRIMARY KEY,
    stock_id INT REFERENCES Stocks(stock_id),
    date DATE NOT NULL,
    daily_return DECIMAL(10, 4),
    cumulative_return DECIMAL(10, 4)
);

CREATE TABLE Portfolio (
    portfolio_id INT,
    stock_id INT NOT NULL,
    allocation_percentage DECIMAL(5, 2),
    CONSTRAINT fk_portfolio_stock FOREIGN KEY (stock_id)
    REFERENCES Stocks(stock_id)
);