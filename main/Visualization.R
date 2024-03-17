
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


# Data Analysis 

# Query 1:  Number of Products in Each Category


category_products <- dbGetQuery(my_db, "SELECT c.name AS category_name, COUNT(p.id) AS num_products
                              FROM products AS p
                              INNER JOIN categories AS c ON p.category_id = c.id
                              GROUP BY p.category_id, c.name
                              ORDER BY num_products DESC
                              LIMIT 10")

category_products %>%
  ggplot(aes(x = reorder(category_name, -num_products), y = num_products)) +
  geom_bar(stat = "identity", fill = "maroon", color = "black") +
  labs(title = "Number of Products in Each Category",
       x = "Category Name",
       y = "Number of Products") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        axis.title.y = element_text(size = 12),
        axis.title.x = element_text(size = 12),
        plot.title = element_text(size = 14, hjust = 0.5),
        panel.border = element_rect(color = "black", fill = NA, size = 1),
        plot.margin = margin(t = 0.5, r = 0.5, b = 1, l = 1, unit = "cm")) +  # Specify margins
  geom_text(aes(label = num_products), vjust = -0.3, size = 3, color = "black")  # Add labels for each bar


# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/number_of_products_in_each_category",
              this_filename_date,"_",
              this_filename_time,".png"))


# Query 2: Monthly Sales Analysis

daily_sales <- dbGetQuery(my_db, "
  SELECT order_date,
  price * quantity * (1 - (discount / 100)) AS revenue
  FROM orders
  JOIN products ON orders.product_id = products.id
")

# Convert order_date to date format
daily_sales$order_date <- as.Date(daily_sales$order_date, format = "%Y-%m-%d")

# Aggregate by month
monthly_sales <- daily_sales %>%
  mutate(year_month = floor_date(order_date, "month")) %>%
  group_by(year_month) %>%
  summarise(revenue = sum(revenue))

# Plot monthly sales trend with advanced visualization
ggplot(monthly_sales, aes(x = year_month, y = revenue)) +
  geom_line(color = "blue", size = 1.5) +
  geom_point(color = "red", size = 3) +
  geom_smooth(method = "lm", se = FALSE, color = "darkgreen", linetype = "dashed") +
  labs(title = "Monthly Sales Trend", x = "Date", y = "Revenue") +
  theme_bw() + 
  theme(plot.title = element_text(size = 20, face = "bold"),
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) + # Rotate x-axis labels vertically
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
  scale_y_continuous(labels = scales::dollar_format(prefix = "$"))

# Saving the image file for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/monthly_sales_analysis",
              this_filename_date,"_",
              this_filename_time,".png"))


# Query 3: Top 10 Selling Products by Quantity Sold

top_products <- dbGetQuery(my_db,
                           "SELECT p.name AS product_name, SUM(o.quantity) AS total_sold
  FROM products AS p
  INNER JOIN orders AS o ON p.id = o.product_id
  GROUP BY p.name
  ORDER BY total_sold DESC
  LIMIT 10")


top_products %>%
  ggplot(aes(x = reorder(product_name, total_sold), y = total_sold, fill = product_name)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_brewer(palette = "Paired") +  # Using a built-in palette
  labs(title = "Top 10 Selling Products",
       x = "Product",
       y = "Total Quantity Sold") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
        axis.text.y = element_text(size = 12, color = "black"),
        axis.title = element_text(size = 16, color = "black", face = "bold"),
        plot.title = element_text(size = 20, color = "black", face = "bold"),
        legend.position = "none") +
  scale_y_continuous(labels = scales::comma_format()) +
  coord_flip() +  # Flip the coordinates to make horizontal bars
  geom_text(aes(label = total_sold), vjust = -0.3, size = 4, color = "black", fontface = "bold")

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Top 10 Selling Products by Quantity Sold",
              this_filename_date,"_",
              this_filename_time,".png"))



# Query 4: Top 10 Sellers by the Total Revenue

top_sellers <- dbGetQuery(my_db,
                          "SELECT s.name AS seller_name, ROUND(SUM(p.price * o.quantity * (1 - (o.discount / 100)))) AS total_revenue
                FROM sellers AS s
                INNER JOIN products AS p ON s.id = p.seller_id
                INNER JOIN orders AS o ON p.id = o.product_id
                GROUP BY s.name
                ORDER BY total_revenue DESC
                LIMIT 10")

top_sellers %>%
  ggplot(aes(x = total_revenue, y = reorder(seller_name, total_revenue), fill = seller_name)) +
  geom_bar(stat = "identity") +
  labs(title = "Top 10 Sellers by Total Revenue",
       subtitle = "Total Revenue for the Top 10 Sellers",
       x = "Total Revenue (in USD)",
       y = "Sellers", 
       fill = "Seller Name") +  
  scale_fill_brewer(palette = "Paired") +
  theme_bw() +
  theme(plot.title = element_text(size = 20, face = "bold"),
        plot.subtitle = element_text(size = 14),
        axis.title = element_text(size = 14),
        axis.text.y = element_text(size = 12),
        axis.text.x = element_text(size = 10, angle = 45, hjust = 1, vjust = 1),  
        panel.grid = element_blank()) +
  geom_text(aes(label = total_revenue), # Remove scales::dollar()
            position = position_stack(vjust = 1.1), 
            hjust = 0.6, color = "black", size = 3) +  
  coord_flip()

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Top_10_Sellers_by_total_revenue",
              this_filename_date,"_",
              this_filename_time,".png"))


# Query 5: Top 10 Customers by the Amount Spent

top_customers <- dbGetQuery(my_db,
                            "SELECT c.id AS customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       ROUND(SUM(p.price * o.quantity * (1 - (o.discount / 100)))) AS total_spent
        FROM customers AS c
        INNER JOIN orders AS o ON c.id = o.customer_id
        INNER JOIN products AS p ON o.product_id = p.id
        GROUP BY c.id, customer_name
        ORDER BY total_spent DESC
        LIMIT 10"
)

# Prepare data for stacked bar chart

top_customers %>%
  arrange(desc(total_spent)) %>%
  ggplot(aes(x = reorder(customer_name, total_spent), y = total_spent, fill = customer_name)) +
  geom_bar(stat = "identity") +
  labs(title = "Top Customers' Share of Total Spent",
       x = "Customer",
       y = "Total Spent") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none") +
  scale_fill_brewer(palette = "Set3") +
  geom_text(aes(label = total_spent), size = 4, color = "black") +
  coord_flip()

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Top_10_customers_by_amount_spent",
              this_filename_date,"_",
              this_filename_time,".png"))


# Query 6: Top Rating Products (Need to re-check)

top_rating_products <- dbGetQuery(my_db, "
SELECT categories.name AS category, AVG(orders.rating_review) AS avg_rating, SUM(orders.quantity) AS total_sales
FROM products
INNER JOIN orders ON products.id = orders.product_id
INNER JOIN categories ON products.category_id = categories.id
WHERE orders.rating_review IS NOT NULL
GROUP BY categories.name"
)

# Create the visualization
ggplot(top_rating_products, aes(x = total_sales, y = avg_rating, size = total_sales, fill = category)) +
  geom_point(shape = 21, color = "black", alpha = 0.6) + # Adding transparency for better visibility
  scale_size_continuous(range = c(5, 20)) + # Adjusting size range for better differentiation
  labs(title = "Product Ratings vs Total Sales by Category",
       x = "Total Sales",
       y = "Average Rating",
       size = "Total Sales",
       fill = "Category") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5), # Adjusting title size and alignment
    axis.title = element_text(size = 12), # Adjusting axis label size
    axis.text = element_text(size = 10), # Adjusting axis text size
    legend.title = element_text(size = 12), # Adjusting legend title size
    legend.text = element_text(size = 10), # Adjusting legend text size
    legend.position = "bottom", # Positioning the legend at the bottom
    legend.box = "horizontal" # Setting legend layout to horizontal
  ) +
  geom_text(aes(label = category), vjust = -1, hjust = 0, size = 3) + # Adding category labels
  annotate("text", x = 500, y = 4.5, label = "Bubble size represents total sales", 
           size = 3, color = "black", fontface = "italic", hjust = 0) # Adding annotation for bubble size explanation

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Product_ratings_vs_total_sales_by_category",
              this_filename_date,"_",
              this_filename_time,".png"))


## Query 7: Sales by Categories

sales_by_category <- dbGetQuery(my_db, "
  SELECT c.name AS category_name, SUM(p.price * o.quantity * (1 - (o.discount / 100))) AS total_sales
  FROM categories AS c
  LEFT JOIN products AS p ON c.id = p.category_id
  LEFT JOIN orders AS o ON p.id = o.product_id
  GROUP BY c.name
")

sales_by_category %>%
  ggplot(aes(area = total_sales, fill = category_name, label = paste0(category_name, "\n", scales::dollar(total_sales)))) +
  geom_treemap() +
  geom_treemap_text(fontface = "bold", place = "centre", grow = TRUE, reflow = TRUE, color = "lightgrey") + # Change text color to light grey
  scale_fill_viridis_d() +  # You can use any other color palette as per your preference
  labs(title = "Sales by Categories (Tree Map)",
       fill = "Category",
       caption = "Sales values are in USD") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(size = 14, face = "bold"),
        plot.caption = element_text(size = 10, color = "gray"))

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Treemap_for_sales_by_categories",
              this_filename_date,"_",
              this_filename_time,".png"))

# Query 8: Sales vs Ad Clicks Analysis

sales_ad_clicks_data <- dbGetQuery(my_db, "
  SELECT order_date,
  IFNULL(SUM(p.price * o.quantity * (1 - (o.discount / 100))), 0) AS total_sales,
  IFNULL(SUM(a.ad_clicks), 0) AS total_ad_clicks
  FROM orders AS o
  LEFT JOIN advertisements AS a ON o.product_id = a.product_id
  LEFT JOIN products AS p ON o.product_id = p.id
  GROUP BY order_date
")

# Convert order_date to Date format
sales_ad_clicks_data$order_date <- as.Date(sales_ad_clicks_data$order_date)

# Aggregate data by month
sales_ad_clicks_monthly <- sales_ad_clicks_data %>%
  mutate(order_month = floor_date(order_date, "month")) %>%
  group_by(order_month) %>%
  summarise(total_sales = sum(total_sales),
            total_ad_clicks = sum(total_ad_clicks))

# Apply log transformation to sales and ad clicks
sales_ad_clicks_monthly <- sales_ad_clicks_monthly %>%
  mutate(log_total_sales = log(total_sales + 1),  # Add 1 to avoid log(0)
         log_total_ad_clicks = log(total_ad_clicks + 1))  # Add 1 to avoid log(0)

sales_ad_clicks_monthly %>%
  ggplot( aes(x = order_month)) +
  geom_line(aes(y = log_total_sales, color = "Total Sales"), size = 1.5) +
  geom_line(aes(y = log_total_ad_clicks, color = "Total Ad Clicks"), linetype = "dashed", size = 1.5) +
  scale_color_manual(values = c("Total Sales" = "#E41A1C", "Total Ad Clicks" = "#377EB8")) +  # Unique colors
  labs(title = "Trend of Sales and Ad Clicks Over Time",
       x = "Month",
       y = "Log Count") +
  theme_bw() +
  theme(legend.position = "top") +
  scale_x_date(date_labels = "%b %Y", date_breaks = "1 month") +
  ylim(0, max(c(max(sales_ad_clicks_monthly$log_total_sales), max(sales_ad_clicks_monthly$log_total_ad_clicks))))


# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/sales_vs_ad_clicks_analysis",
              this_filename_date,"_",
              this_filename_time,".png"))


# Query 9: Top 5 Sellers Time Series Analysis

xyz <- dbGetQuery(my_db, "SELECT order_date, seller_id,
  price * quantity * (1 - (discount / 100)) AS revenue
  FROM orders
  JOIN products ON orders.product_id = products.id"
)

top_5_sellers <- dbGetQuery(my_db,
                            "SELECT s.id AS seller_id,
                              s.name AS seller_name,
                              SUM(o.quantity) AS total_quantity_sold
                              FROM sellers AS s
                              INNER JOIN products AS p ON s.id = p.seller_id
                              INNER JOIN orders AS o ON p.id = o.product_id
                              GROUP BY s.id, s.name
                              ORDER BY total_quantity_sold DESC
                              LIMIT 5"
)


# Convert order_date to Date format
xyz$order_date <- as.Date(xyz$order_date, format = "%Y-%m-%d" )


# Aggregate by month
xyz <- xyz %>%
  mutate(year_month = floor_date(order_date, "month")) %>%
  group_by(seller_id, year_month) %>%
  filter(seller_id %in% top_5_sellers$seller_id)

ggplot(xyz, aes(x = factor(format(year_month, "%b %Y"), 
                           levels = unique(format(year_month, "%b %Y"))), 
                y = revenue, 
                size = revenue)) +  # Set constant size for bubbles
  geom_point(aes(fill = seller_id), shape = 21, color = "black", alpha = 0.7) +  # Use fill aesthetic for seller names
  scale_size_continuous(range = c(5, 20)) +
  labs(title = "Top 5 Sellers Sales Over Time",
       x = "Order Month",
       y = "Total Sales",
       size = NULL,  # Remove legend for size aesthetic
       fill = "Seller Name") +  # Set legend title
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, margin = margin(t = 5, r = 5, b = 5, l = 5)),
        axis.title.x = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),  # Center and style title
        axis.text = element_text(size = 10),  # Adjust text size
        axis.title = element_text(size = 12, face = "bold"))  # Adjust title size and style

# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/Top_5_sellers_time_series",
              this_filename_date,"_",
              this_filename_time,".png"))



# Query 10: Average Ratings of Products in each Category 


rating_category <- dbGetQuery(my_db,
                              "SELECT categories.name AS category, AVG(orders.rating_review) AS avg_rating
                              FROM products
                              INNER JOIN orders ON products.id = orders.product_id
                              INNER JOIN categories ON products.category_id = categories.id
                              WHERE orders.rating_review IS NOT NULL
                              GROUP BY categories.name"
)

# Create a bar chart for analyzing average ratings by category
ggplot(rating_category, aes(x = category, y = avg_rating, fill = category)) +
  geom_bar(stat = "identity") +
  labs(title = "Average Ratings of Products by Category",
       x = "Category",
       y = "Average Rating") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10, color = "#333333"), # Adjust text size and color
    axis.text.y = element_text(size = 10, color = "#333333"), # Adjust text size and color
    axis.title = element_text(size = 12, color = "#333333"), # Adjust axis title size and color
    plot.title = element_text(hjust = 0.5, size = 16, color = "#333333", face = "bold"), # Adjust title size and color, make it bold
    panel.background = element_rect(fill = "#f2f2f2"), # Change background color
    panel.grid.major = element_blank(), # Remove major gridlines
    panel.grid.minor = element_blank(), # Remove minor gridlines
    legend.position = "none" # Remove legend
  ) +
  geom_text(aes(label = round(avg_rating, 2)), vjust = -0.5, size = 3, fontface = "bold", color = "black") + # Add data labels with bold font and black color
  scale_fill_brewer(palette = "Set3") + # Apply a qualitative color palette
  coord_flip() # Flip the coordinates for better readability


# Saving the image for the plot
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

ggsave(paste0("Visualisations/average_ratings_of_products_in_each_category",
              this_filename_date,"_",
              this_filename_time,".png"))

