library(treemapify)
library(maps)
library(mapproj)
library(gridExtra)
library(grid)
library(lubridate)


# Data Analysis 
## Create views for analysis

### View linked product, categories, sellers and advertisements
dbExecute(my_db, "DROP VIEW IF EXISTS df_products;")


view_product_query <-paste("CREATE VIEW IF NOT EXISTS df_products AS
SELECT p.id, p.seller_id, p.category_id, p.price, p.inventory,
s.name AS seller_name,
CONCAT(p.name, ' ID ', p.id) AS product_name,
SUM(a.ad_clicks) AS total_ad_clicks,
SUM(a.budget) AS total_budget,
cat.name AS category_name
FROM products as p
LEFT JOIN sellers s ON p.seller_id = s.id
LEFT JOIN categories cat On p.category_id = cat.id
LEFT JOIN advertisements a on p.id= a.product_id
GROUP BY p.id;")
dbExecute(my_db, view_product_query)


#df_products <- dbGetQuery(my_db, "SELECT *
#                              FROM df_products")


### View linked orders, customers and products (including ads and sellers details)
dbExecute(my_db, "DROP VIEW IF EXISTS df_sales;")

view_sales_query <-paste("CREATE VIEW IF NOT EXISTS df_sales AS
SELECT o.id, o.customer_id, o.product_id, o.quantity, o.discount, o.order_date, o.rating_review, dfp.price,
round(o.quantity*(1-o.discount/100.00)*dfp.price,2) AS sales,
round(o.quantity*(o.discount/100.00)*dfp.price,2) AS discount_value,
round(o.quantity*1000000/dfp.total_ad_clicks,2) AS conversion_rate,
dfp.seller_id, dfp.seller_name, dfp.total_budget, dfp.product_name,dfp.category_name, 
CONCAT(first_name, ' ', last_name) AS customer_name
FROM orders AS o
LEFT JOIN df_products dfp ON o.product_id = dfp.id
LEFT JOIN customers c ON o.customer_id = c.id;")
dbExecute(my_db,view_sales_query)



df_sales <- dbGetQuery(my_db, "SELECT *
                              FROM df_sales")


df_sales <- dbGetQuery(my_db, "SELECT o.id, o.customer_id, o.product_id, o.quantity, o.discount, o.order_date, o.rating_review, dfp.price,
round(o.quantity*(1-o.discount/100)*dfp.price,2) AS sales,
round(o.quantity*(o.discount/100)*dfp.price,2) AS discount_value,
round(o.quantity*1000000/dfp.total_ad_clicks,2) AS conversion_rate,
dfp.seller_id, dfp.seller_name, dfp.total_budget, dfp.product_name,dfp.category_name, 
CONCAT(first_name, ' ', last_name) AS customer_name
FROM orders AS o
LEFT JOIN df_products dfp ON o.product_id = dfp.id
LEFT JOIN customers c ON o.customer_id = c.id")





## Figure 1:  Number of Products by Categories


## Categories with number of products in each category

category_products <- dbGetQuery(my_db, "SELECT c.name AS category_name, COUNT(p.id) AS num_products
                              FROM products AS p
                              INNER JOIN categories AS c ON p.category_id = c.id
                              GROUP BY p.category_id, c.name
                              ORDER BY num_products DESC
                              LIMIT 10")

  figure.1 <- category_products %>%
    ggplot(aes(x = reorder(category_name, -num_products), y = num_products)) +
    geom_bar(stat = "identity", fill = "#4393C3", color = "black") +
    labs(title = "Number of Products by Categories",
         x = "Category Name",
         y = "Number of Products") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
          axis.title.y = element_text(size = 12),
          axis.title.x = element_text(size = 12),
          plot.title = element_text(size = 14, hjust = 0.5),
          panel.border = element_rect(color = "black", fill = NA, size = 1),
          plot.margin = margin(t = 0.5, r = 0.5, b = 1, l = 1, unit = "cm")) +  
    geom_text(aes(label = num_products), vjust = -0.3, size = 3, color = "black") 


## Figure 2: Number of Ad clicks by Categories


## Categories with number of ad clicks in each category

category_adclicks <- dbGetQuery(my_db, "
  SELECT p.id, p.category_id, c.name AS category_name,
  SUM(a.ad_clicks) AS total_ad_clicks
  FROM products AS p
  INNER JOIN advertisements a ON p.id = a.product_id
  INNER JOIN categories c ON p.category_id = c.id 
  GROUP BY p.category_id, c.name
  ORDER BY total_ad_clicks DESC
")

  figure.2 <- category_adclicks %>%
    ggplot(aes(x = reorder(category_name, -total_ad_clicks), y = total_ad_clicks/1000000)) +
    geom_bar(stat = "identity", fill = "#4393C3", color = "black") +
    labs(title = "Total Ad clicks (millions) by Categories",
         x = "Category Name",
         y = "Total Ad clicks") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
          axis.title.y = element_text(size = 12),
          axis.title.x = element_text(size = 12),
          plot.title = element_text(size = 14, hjust = 0.5),
          panel.border = element_rect(color = "black", fill = NA, size = 1),
          plot.margin = margin(t = 0.5, r = 0.5, b = 1, l = 1, unit = "cm")) +  # Specify margins
    geom_text(aes(label = round(total_ad_clicks/1000000,2)), vjust = -0.3, size = 3, color = "black")   # Add labels for each bar


## Figure 3: Number of Customers by States


# read customers table from sql
customers <- dbGetQuery(my_db, "
  SELECT *
  FROM customers
")

cust_geo <- customers %>% group_by(billing_address_state) %>% summarise(n = n())

if (require("maps")) {
  states <- map_data("state")
  cust_geo$region <- tolower(cust_geo$billing_address_state)
  choro <- merge(states, cust_geo, sort = FALSE, by = "region")
  choro <- choro[order(choro$order), ]
   figure.3 <- ggplot(choro, aes(long, lat)) +
      geom_polygon(aes(group = group, fill = n)) +
      coord_map("albers",  lat0 = 45.5, lat1 = 29.5) +
      scale_fill_continuous(trans = "reverse") +
      labs(title = "Number of Customers by States") +
      theme_minimal() +
      theme(legend.position = "left",
            axis.title = element_blank(),
            axis.ticks = element_blank(),
            axis.text = element_blank(),
            plot.title = element_text(size = 14, hjust = 0.5),
            panel.border = element_rect(color = "black", fill = NA, size = 1),
            plot.margin = margin(t = 0.5, r = 0.5, b = 1, l = 1, unit = "cm"))
  
}

## Figure 4: Number of Sellers by States

# read sellers table from sql
sellers <- dbGetQuery(my_db, "
  SELECT *
  FROM sellers
")

seller_geo <- sellers %>% group_by(address_state) %>% summarise(n = n())

if (require("maps")) {
  states <- map_data("state")
  seller_geo$region <- tolower(seller_geo$address_state)
  choro <- merge(states, seller_geo, sort = FALSE, by = "region")
  choro <- choro[order(choro$order), ]
    figure.4 <- ggplot(choro, aes(long, lat)) +
      geom_polygon(aes(group = group, fill = n)) +
      coord_map("albers",  lat0 = 45.5, lat1 = 29.5) +
      scale_fill_continuous(trans = "reverse") +
      labs(title = "Number of Sellers by States") +
      theme_minimal() +
      theme(legend.position = "left",
            axis.title = element_blank(),
            axis.ticks = element_blank(),
            axis.text = element_blank(),
            plot.title = element_text(size = 14, hjust = 0.5),
            panel.border = element_rect(color = "black", fill = NA, size = 1),
            plot.margin = margin(t = 0.5, r = 0.5, b = 1, l = 1, unit = "cm"))
  
}


## Dashboard 1: Platform Overview

# Extract the date and time
this_filename_date <- as.character(Sys.Date())
this_filename_time <- as.character(format(Sys.time(), format = "%H_%M"))

# Combine charts and save as image
g <- grid.arrange(figure.1, figure.2, figure.3, figure.4, nrow = 2,
             top = textGrob("Platform Overview",gp=gpar(fontsize=24,font=2)))
ggsave(file=paste0("Visualisations/platform_overview",
              this_filename_date,"_",
              this_filename_time,".png"), g)

## Figure 5: Monthly Sales Analysis

daily_sales <- dbGetQuery(my_db, "
  SELECT order_date, sales
  FROM df_sales
")

# Convert order_date to date format
daily_sales$order_date <- as.Date(as.character(daily_sales$order_date), format = "%Y-%m-%d")
# Aggregate by month
monthly_sales <- daily_sales %>%
  mutate(year_month = gsub('-','',as.character(format(as.Date(order_date), "%Y-%m")))) %>%
  group_by(year_month) %>%
  summarise(sales = sum(sales)) %>%
  arrange(desc(year_month))

# Take last 12 months
monthly_sales <- head(monthly_sales, 12)

# Plot monthly sales trend with advanced visualization
 figure.5 <- ggplot(monthly_sales, aes(x = as.factor(year_month), y = sales)) +
    geom_line(color = "blue", size = 1.5) +
    geom_point(color = "red", size = 3) +
    geom_smooth(method = "lm", se = FALSE, color = "darkgreen", linetype = "dashed") +
    labs(title = "Monthly Sales Trend (last 12 months)", x = "Month", y = "Sales") +
    theme_bw() + 
    theme(axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none",
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 10)) + # Rotate x-axis labels vertically
    #scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
    scale_y_continuous(labels = scales::dollar_format(prefix = "$")) 

## Figure 6: Sales by Categories


sales_by_category <- dbGetQuery(my_db, "
  SELECT category_name, SUM(sales) AS total_sales
  FROM df_sales
  GROUP BY category_name
")

  figure.6 <- sales_by_category %>%
    ggplot(aes(area = total_sales, fill = category_name, label = paste0(category_name, "\n", scales::dollar(total_sales)))) +
    geom_treemap() +
    geom_treemap_text(fontface = "bold", place = "centre", grow = TRUE, reflow = TRUE, color = "lightgrey") + 
    scale_fill_viridis_d() +  
    labs(title = "Sales by Categories",
         fill = "Category",
         caption = "Sales values are in USD") +
    theme_minimal() +
    theme(legend.position = "none",
          plot.caption = element_text(size = 10, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold")) 


## Figure 7: Top 10 Customers by Amount Spent

top_customers <- dbGetQuery(my_db,
                            "SELECT CONCAT(customer_name, ' ID ', customer_id) AS customer_name, sales 
  FROM df_sales
  GROUP BY customer_name
  ORDER BY sales DESC
  LIMIT 10"
)

  figure.7 <- top_customers %>%
    arrange(desc(sales)) %>%
    ggplot(aes(x = reorder(customer_name, sales), y = sales, fill = customer_name)) +
    geom_bar(stat = "identity") +
    labs(title = "Top 10 Customers by Total Sales",
         x = "Customer",
         y = "Total Sales") +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    geom_text(aes(label = sales), size = 4, color = "black") +
    coord_flip() 


## Figure 8. Top 10 Sellers by Total Sales


top_sellers <- dbGetQuery(my_db,
                          "SELECT CONCAT(seller_name, ' ID ', seller_id) AS seller_name, sales 
  FROM df_sales
  GROUP BY seller_name
  ORDER BY sales DESC
  LIMIT 10")

  figure.8 <- top_sellers %>%
    arrange(desc(sales)) %>%
    ggplot(aes(x = reorder(seller_name, sales), y = sales, fill = seller_name)) +
    geom_bar(stat = "identity") +
    labs(title = "Top 10 Sellers by Total Sales",
         x = "Seller",
         y = "Total Sales") +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    geom_text(aes(label = sales), size = 4, color = "black") +
    coord_flip() 


## Dashboard 2: Sales Performance

# Combine charts and save as image
g2 <- grid.arrange(figure.5, figure.6, figure.7, figure.8, nrow = 2,
             top = textGrob("Sales Performance",gp=gpar(fontsize=24,font=2)))
ggsave(file=paste0("Visualisations/sales_performance",
                   this_filename_date,"_",
                   this_filename_time,".png"), g2)


## Figure 9: Top 10 Selling Products by Value


top_products <- dbGetQuery(my_db,
                           "SELECT product_name, SUM(sales) AS total_sales
  FROM df_sales
  GROUP BY product_name
  ORDER BY total_sales DESC
  LIMIT 10")


  figure.9 <- top_products %>%
    ggplot(aes(x = reorder(product_name, total_sales), y = total_sales, fill = product_name)) +
    geom_bar(stat = "identity", color = "black") +
    labs(title = "Top 10 Selling Products by Value",
         x = "Product",
         y = "Total Sales") +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    coord_flip() +  # Flip the coordinates to make horizontal bars
    geom_text(aes(label = total_sales), vjust = -0.3, size = 4, color = "black", fontface = "bold") 


## Figure 10: Top 10 Selling Products by Quantity

top_products_q <- dbGetQuery(my_db,
                             "SELECT product_name, SUM(quantity) AS total_sold
  FROM df_sales
  GROUP BY product_name
  ORDER BY total_sold DESC
  LIMIT 10")

  figure.10 <- top_products_q %>%
    ggplot(aes(x = reorder(product_name, total_sold), y = total_sold, fill = product_name)) +
    geom_bar(stat = "identity", color = "black") +
    scale_fill_brewer(palette = "Paired") +  # Using a built-in palette
    labs(title = "Top 10 Selling Products by Quantity",
         x = "Product",
         y = "Total Quantity Sold") +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    coord_flip() +  # Flip the coordinates to make horizontal bars
    geom_text(aes(label = total_sold), vjust = -0.3, size = 4, color = "black", fontface = "bold") 


## Figure 11: Top & Bottom 5 Rating Products


top_products_r <- dbGetQuery(my_db,
                             "SELECT product_name, rating_review
  FROM df_sales
  WHERE rating_review BETWEEN 1 AND 5")

top_products_r <- top_products_r %>% group_by(product_name) %>% summarise (average_rating = round(sum(rating_review)/n(),2)) %>% arrange(desc(average_rating))  
top_5_rating <- head(top_products_r,5)
bottom_5_rating <- tail(top_products_r,5)
top_bottom_5_rating <-rbind(top_5_rating,bottom_5_rating)

  figure.11 <- top_bottom_5_rating %>%
    ggplot(aes(x = reorder(product_name, average_rating), y = average_rating, fill = product_name)) +
    geom_bar(stat = "identity", color = "black") +
    labs(title = "Top & Bottom 5 Rating Products",
         x = "Product",
         y = "Average Rating") +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    coord_flip() +  # Flip the coordinates to make horizontal bars
    geom_text(aes(label = average_rating), vjust = -0.3, size = 4, color = "black", fontface = "bold") 


## Figure 12: Top 10 Products by Ad clicks to Sales Conversion

top_products_c <- dbGetQuery(my_db,
                             "SELECT product_name, SUM(conversion_rate) as total_conversion_rate
  FROM df_sales
  WHERE conversion_rate IS NOT NULL
  GROUP BY product_name
  ORDER BY total_conversion_rate DESC
  LIMIT 10")


  figure.12 <- top_products_c %>%
    ggplot(aes(x = reorder(product_name, total_conversion_rate), y = total_conversion_rate, fill = product_name)) +
    geom_bar(stat = "identity", color = "black") +
    labs(title = "Total Conversion Rate",
         x = "Product",
         y = "Conversion Rate (sales quality/million ad clicks)") +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none") +
    scale_fill_brewer(palette = "Set3") +
    coord_flip() +  # Flip the coordinates to make horizontal bars
    geom_text(aes(label = total_conversion_rate), vjust = -0.3, size = 4, color = "black", fontface = "bold") 


## Dashboard 3: Top Products

# Combine charts and save as image
g3 <- grid.arrange(figure.9, figure.10, figure.11, figure.12, nrow = 2,
             top = textGrob("Top Products",gp=gpar(fontsize=24,font=2)))
ggsave(file=paste0("Visualisations/top_products",
                   this_filename_date,"_",
                   this_filename_time,".png"), g3)


## Figure 13: Average Rating by Months

rating_y <- dbGetQuery(my_db,
                       "SELECT id, product_name, order_date, rating_review, sales
  FROM df_sales
  WHERE rating_review BETWEEN 1 AND 5")

# Convert order_date to date format
rating_y$order_date <- as.Date(as.character(rating_y$order_date), format = "%Y-%m-%d")
rating_y <- rating_y %>% mutate(year_month = gsub('-','',as.character(format(as.Date(order_date), "%Y-%m"))))


# Calculate the average   
rating_y_sum <- rating_y %>% group_by(year_month) %>% summarise (n_y = n(), average_rating = round(sum(rating_review)/n(),2)) %>% arrange(desc(year_month)) 

test <- rating_y %>% group_by(rating_review) %>% summarise(sales = sum(sales))
# Take last 12 months
rating_y_sum <- head(rating_y_sum,12)


# Plot monthly sales trend with advanced visualization
figure.13 <- ggplot(rating_y_sum, aes(x = year_month, y = average_rating)) +
    geom_line(color = "blue", size = 1.5) +
    geom_point(color = "red", size = 3) +
    geom_smooth(method = "lm", se = FALSE, color = "darkgreen", linetype = "dashed") +
    labs(title = "Monthly Average Rating (last 12 months)", x = "Month", y = "Average Rating") +
    theme_bw() + 
    theme(axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none",
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 10))  # Rotate x-axis labels vertically
  #scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") 


## Figure 14: Percentage of Nil Rating

rating_all <- dbGetQuery(my_db,
                         "SELECT id, product_name, order_date, rating_review, sales
  FROM df_sales")

# Convert order_date to date format
rating_all$order_date <- as.Date(as.character(rating_all$order_date), format = "%Y-%m-%d")
rating_all <- rating_all %>% mutate(year_month = gsub('-','',as.character(format(as.Date(order_date), "%Y-%m"))))

# Calculate total number of orders per months
rating_all_summary <- rating_all %>% group_by(year_month) %>% summarise (n_all = n())

# Filter no rating and convert date format
rating_n <- rating_all %>% filter(rating_review == 0) 

# Calculate number of orders with no review 
rating_n_summary <- rating_n %>% group_by(year_month) %>% summarise (n_n = n()) 

# Combine data
rating_n_summary <- merge(rating_all_summary, rating_n_summary)

# Calculate nil review rate
rating_n_summary <- rating_n_summary %>% mutate(nil_review_rate = n_n *100/n_all) %>% arrange(desc(year_month))

# Take last 12 months
rating_n_summary <- head(rating_n_summary,12)

# Plot monthly sales trend with advanced visualization
figure.14 <- ggplot(rating_n_summary, aes(x = year_month, y = nil_review_rate)) +
    geom_line(color = "blue", size = 1.5) +
    geom_point(color = "red", size = 3) +
    geom_smooth(method = "lm", se = FALSE, color = "darkgreen", linetype = "dashed") +
    labs(title = "Percentage of Nil Review (last 12 months)", x = "Month", y = "% of Nil Review") +
    theme_bw() + 
    theme(axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold"),
          legend.position = "none",
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 10)) # Rotate x-axis labels vertically
  #scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") 

## Figure 15: Revenues by Rating Review

revenue_by_rating_y <- rating_y %>% group_by(rating_review) %>% summarise(sales = sum(sales))
revenue_by_rating_n <- rating_n %>% group_by(rating_review) %>% summarise(sales = sum(sales))
revenue_by_rating <- rbind(revenue_by_rating_y, revenue_by_rating_n)

  figure.15 <- revenue_by_rating %>% 
    ggplot(aes(area = sales, fill = rating_review, label = paste0("Rating ", rating_review, "\n", scales::dollar(sales)))) +
    geom_treemap() +
    geom_treemap_text(fontface = "bold", place = "centre", grow = TRUE, reflow = TRUE, color = "lightgrey") + 
    labs(title = "Sales by Rating",
         fill = "Rating Review",
         caption = "Sales values are in USD") +
    theme_minimal() +
    theme(legend.position = "none",
          plot.caption = element_text(size = 10, color = "black"),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_text(size = 12, color = "black", face = "bold"),
          plot.title = element_text(size = 16, color = "black", face = "bold")) 


## Figure 16: Average Discount by Month

  discount <- dbGetQuery(my_db, "
  SELECT order_date, discount_value, sales
  FROM df_sales
")
  
  # Convert order_date to date format
  discount$order_date <- as.Date(as.character(discount$order_date), format = "%Y-%m-%d")
  
  # Aggregate by month
  discount <- discount %>%
    mutate(year_month = gsub('-','',as.character(format(as.Date(order_date), "%Y-%m")))) %>%
    group_by(year_month) %>%
    summarise(sales = sum(sales), discount_value = sum(discount_value), average_discount = discount_value/sales) %>%
    arrange(desc(year_month))
  
  # Take last 12 months
  discount <- head(discount, 12)
  
  # Plot monthly sales trend with advanced visualization
  ( figure.16 <- ggplot(discount, aes(x = year_month, y = average_discount)) +
      geom_bar(stat = "identity", color = "black") + 
      labs(title = "Monthly Average Discount (last 12 months)", x = "Month", y = "Average Rating") +
      theme_bw() + 
      theme(axis.text.y = element_text(size = 10, color = "black"),
            axis.title = element_text(size = 12, color = "black", face = "bold"),
            plot.title = element_text(size = 16, color = "black", face = "bold"),
            legend.position = "none",
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 10)) 
    #scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") 
  )

## Dashboard 4: Customer Satisfaction

# Combine charts and save as image
g4 <- grid.arrange(figure.13, figure.14, figure.15, figure.16, ncol = 2,
             top = textGrob("Customer Statisfaction",gp=gpar(fontsize=24,font=2)))
ggsave(file=paste0("Visualisations/customer_satisfaction",
                   this_filename_date,"_",
                   this_filename_time,".png"), g4)


