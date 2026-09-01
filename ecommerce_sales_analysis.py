# E-Commerce Sales & Profitability Analysis
# Tools: Python, Pandas, Matplotlib

import pandas as pd
import matplotlib.pyplot as plt

# 1. Load the six datasets
customers = pd.read_csv("data/customers.csv")
products = pd.read_csv("data/products.csv")
orders = pd.read_csv("data/orders.csv")
order_items = pd.read_csv("data/order_items.csv")
returns = pd.read_csv("data/returns.csv")
payments = pd.read_csv("data/payments.csv")

print("All 6 datasets loaded successfully.")

# 2. Basic checks
datasets = {
    "Customers": customers,
    "Products": products,
    "Orders": orders,
    "Order Items": order_items,
    "Returns": returns,
    "Payments": payments
}

for name, df in datasets.items():
    print(f"\n{name} shape:", df.shape)
    print("Missing values:", df.isnull().sum().sum())
    print("Duplicate rows:", df.duplicated().sum())

# 3. Data quality
print("\nOrder status:")
print(orders["order_status"].value_counts())

print("\nQuantity values:")
print(order_items["quantity"].value_counts().sort_index())

zero_qty = order_items[order_items["quantity"] == 0]
print("\nRows with zero quantity:", len(zero_qty))

# 4. Prepare completed-order sales data
data = orders.merge(order_items, on="order_id")
data = data.merge(products, on="product_id")

data = data[
    (data["order_status"] == "Completed") &
    (data["quantity"] > 0)
].copy()

# 5. Revenue and profit
# Revenue is calculated after discount.
data["revenue"] = (
    data["quantity"] *
    data["unit_price"] *
    (1 - data["discount"])
)

data["profit"] = (
    data["quantity"] *
    (
        data["unit_price"] * (1 - data["discount"])
        - data["unit_cost"]
    )
)

total_orders = data["order_id"].nunique()
total_units = data["quantity"].sum()
total_revenue = data["revenue"].sum()
total_profit = data["profit"].sum()
profit_margin = total_profit / total_revenue
aov = total_revenue / total_orders

print("\n--- Overall KPIs ---")
print("Completed Orders:", total_orders)
print("Units Sold:", total_units)
print("Revenue:", round(total_revenue, 2))
print("Profit:", round(total_profit, 2))
print("Profit Margin:", round(profit_margin * 100, 2), "%")
print("Average Order Value:", round(aov, 2))

# 6. Monthly revenue
data["month"] = pd.to_datetime(data["order_date"]).dt.to_period("M")
monthly_revenue = data.groupby("month")["revenue"].sum().sort_index()

print("\nMonthly Revenue:")
print(monthly_revenue)

# 7. Category analysis
category_analysis = (
    data.groupby("category")
    .agg(
        revenue=("revenue", "sum"),
        profit=("profit", "sum"),
        units_sold=("quantity", "sum")
    )
    .sort_values("revenue", ascending=False)
)

print("\nRevenue and Profit by Category:")
print(category_analysis)

# 8. Top 10 products
product_revenue = (
    data.groupby("product_id")["revenue"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

print("\nTop 10 Products by Revenue:")
print(product_revenue)

# 9. Top 10 customers
customer_revenue = (
    data.groupby("customer_id")["revenue"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

print("\nTop 10 Customers by Revenue:")
print(customer_revenue)

# 10. Payment method analysis
payment_data = payments.merge(
    orders[["order_id", "order_status"]],
    on="order_id",
    how="inner"
)

payment_data = payment_data[
    payment_data["order_status"] == "Completed"
]

payment_analysis = (
    payment_data.groupby("payment_method")["payment_amount"]
    .sum()
    .sort_values(ascending=False)
)

print("\nPayment Amount by Method:")
print(payment_analysis)

# 11. Return analysis
returned_orders = returns["order_id"].nunique()
return_rate = returned_orders / orders["order_id"].nunique()

print("\nReturned Orders:", returned_orders)
print("Return Rate:", round(return_rate * 100, 2), "%")

print("\nReturn Reasons:")
print(returns["return_reason"].value_counts())

# 12. Cancellation analysis
total_all_orders = orders["order_id"].nunique()
cancelled_orders = orders.loc[
    orders["order_status"] == "Cancelled", "order_id"
].nunique()

cancellation_rate = cancelled_orders / total_all_orders

print("\nCancelled Orders:", cancelled_orders)
print("Cancellation Rate:", round(cancellation_rate * 100, 2), "%")

# 13. Repeat customers
customer_orders = data.groupby("customer_id")["order_id"].nunique()
repeat_customers = (customer_orders > 1).sum()

print("\nRepeat Customers:", repeat_customers)

# 14. Charts
monthly_revenue.plot(kind="line")
plt.title("Monthly Revenue")
plt.xlabel("Month")
plt.ylabel("Revenue")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

category_analysis["revenue"].sort_values().plot(kind="barh")
plt.title("Revenue by Category")
plt.xlabel("Revenue")
plt.ylabel("Category")
plt.tight_layout()
plt.show()

customer_revenue.sort_values().plot(kind="barh")
plt.title("Top 10 Customers by Revenue")
plt.xlabel("Revenue")
plt.ylabel("Customer ID")
plt.tight_layout()
plt.show()

product_revenue.sort_values().plot(kind="barh")
plt.title("Top 10 Products by Revenue")
plt.xlabel("Revenue")
plt.ylabel("Product ID")
plt.tight_layout()
plt.show()

category_analysis["profit"].sort_values().plot(kind="barh")
plt.title("Profit by Category")
plt.xlabel("Profit")
plt.ylabel("Category")
plt.tight_layout()
plt.show()
