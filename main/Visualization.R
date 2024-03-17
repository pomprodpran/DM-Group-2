# Define SQL queries for each table
sql_queries <- list(
  orders = "SELECT * FROM orders",
  customers = "SELECT * FROM customers",
  categories = "SELECT * FROM categories",
  advertisements = "SELECT * FROM advertisements",
  shippers = "SELECT * FROM shippers",
  products = "SELECT * FROM products",
  sellers = "SELECT * FROM sellers"
)


# Read data from each table using SQL queries

orders <- dbGetQuery(my_db, 
                     sql_queries$orders)
customers <- dbGetQuery(my_db, 
                        sql_queries$customers)
categories <- dbGetQuery(my_db, 
                         sql_queries$categories)
advertisements <- dbGetQuery(my_db, 
                             sql_queries$advertisements)
shippers <- dbGetQuery(my_db, 
                       sql_queries$shippers)
products <- dbGetQuery(my_db, 
                       sql_queries$products)
sellers <- dbGetQuery(my_db, 
                      sql_queries$sellers)

