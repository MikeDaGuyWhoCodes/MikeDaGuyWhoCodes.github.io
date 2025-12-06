class Portfolio:
    def __init__(self, initial_cash):
        self.cash = initial_cash
        self.stock_Cheese = 0
        self.stock_boring = 0
        self.price_Cheese = 100.00
        self.price_boring = 50.00

    def buy_stock(self, ticker, quantity):
        if ticker == "CHE":
            price = self.price_Cheese
            cost = price * quantity
            if self.cash >= cost:
                self.cash -= cost
                self.stock_Cheese += quantity
                print(f"SUCCESS: Bought {quantity} shares of CHEESE @ ${price:.2f}.")
            else:
                print(f"ERROR: Not enough cash to buy {quantity} CHEESE shares.")
        elif ticker == "BOR":
            price = self.price_boring
            cost = price * quantity
            if self.cash >= cost:
                self.cash -= cost
                self.stock_boring += quantity
                print(f"SUCCESS: Bought {quantity} shares of BORING @ ${price:.2f}.")
            else:
                print(f"ERROR: Not enough cash to buy {quantity} BORING shares.")
        else:
            print("ERROR: Invalid stock ticker provided.")
        self.cash = round(self.cash, 2)

    def print_status(self):
        value_tek = self.stock_Cheese * self.price_Cheese
        value_bio = self.stock_boring * self.price_boring
        
        total_portfolio_value = value_Cheese + value_bio
        total_assets = self.cash + total_portfolio_value
        print("CASH BALANCE:")
        print(f"  Available Cash: ${self.cash:.2f}")
        print("\nPORTFOLIO HOLDINGS:")
        print(f"  Cheese Shares: {self.stock_Cheese} (Value: ${value_tek:.2f})")
        print(f"  BIO Shares: {self.stock_boring} (Value: ${value_bio:.2f})")
        
        print("\nTOTAL ASSETS:")
        print(f"  Total Portfolio Value: ${total_portfolio_value:.2f}")
        print(f"  Grand Total (Cash + Holdings): ${total_assets:.2f}")
if __name__ == "__main__":
    
    print("Starting Simple Stock Portfolio Simulation:")
    my_portfolio = Portfolio(5000.00)
    my_portfolio.print_status()
    print("\nTrading Round 1: ")
    my_portfolio.buy_stock("CHE", 10)
    print("\nTrading Round 2: ")
    my_portfolio.buy_stock("BIO", 25)
    print("\nTrading Round 3 (Error Check): ")
    my_portfolio.buy_stock("CHE", 100)

    my_portfolio.print_status()
