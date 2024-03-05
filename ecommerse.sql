-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

DROP TABLE IF EXISTS `customers` ;
DROP TABLE IF EXISTS `products` ;
DROP TABLE IF EXISTS `shippers` ;
DROP TABLE IF EXISTS `orders` ;
DROP TABLE IF EXISTS `ads` ;
DROP TABLE IF EXISTS `sellers` ;
DROP TABLE IF EXISTS `category` ;


------------- CREATE TABLE -------------

-- TEST schema ***
CREATE TABLE IF NOT EXISTS `test_customers` (
  'customer_id' INT PRIMARY KEY,
  'customer_firstname' VARCHAR(250) NOT NULL,
  'customer_lastname' VARCHAR(250) NOT NULL,
  'customer_email' TEXT
  --phone_number VARCHAR(20),
  --date_of_birth DATE,
  --billing_address_state TEXT,
  --billing_address_city TEXT,
  --billing_address_country TEXT,
  --billing_address_postcode TEXT
);

-- Customer Schema
CREATE TABLE IF NOT EXISTS `customers` (
  'customer_id' INT PRIMARY KEY,
  'customer_firstname' VARCHAR(250) NOT NULL,
  'customer_lastname' VARCHAR(250) NOT NULL,
  'customer_email' TEXT,
  'phone_number' VARCHAR(20),
  'date_of_birth' DATE,
  'billing_address_state' TEXT,
  'billing_address_city' TEXT,
  'billing_address_country' TEXT,
  'billing_address_postcode' TEXT,
  'shipping_address_state' TEXT,
  'shipping_address_city' TEXT,
  'shipping_address_country' TEXT,
  'shipping_address_postcode' TEXT,
  'payment_method' TEXT
);

-- Seller Schema
CREATE TABLE IF NOT EXISTS `sellers` (
  'seller_id' INT PRIMARY KEY,
  'seller_name' VARCHAR(250) NOT NULL,
  'seller_email' TEXT,
  'seller_address_state' TEXT,
  'seller_address_city' TEXT,
  'seller_address_country' TEXT,
  'seller_address_postcode' TEXT
);

-- Category Schema
CREATE TABLE IF NOT EXISTS `category` (
  'category_id' INT PRIMARY KEY,
  'category_name' VARCHAR(250) NOT NULL,
  'category_description' TEXT
);

-- Product Schema
CREATE TABLE IF NOT EXISTS `products` (
  'product_id' INT PRIMARY KEY,
  'seller_id' INT NOT NULL,
  'category_id' INT NOT NULL,
  'product_name' VARCHAR(60) NOT NULL,
  'color' VARCHAR(60) NOT NULL,
  'size' VARCHAR(5) NOT NULL,
  'brand' VARCHAR(250),
  'price' NUMERIC NOT NULL,
  'currency' CHAR(3) NOT NULL, 
  FOREIGN KEY ('seller_id') 
    REFERENCES sellers ('seller_id'),
  FOREIGN KEY ('category_id') 
    REFERENCES category ('category_id')
);

-- Shipper Schema
CREATE TABLE IF NOT EXISTS `shippers` (
  shipper_id INT PRIMARY KEY,
  shipper_name CHAR(25) NOT NULL,
  shipper_phone VARCHAR(25) NOT NULL
);

-- Order Schema : create after 3 main tables
CREATE TABLE IF NOT EXISTS `orders` (
  order_id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  product_id INT NOT NULL,
  shipper_id INT NOT NULL,
  order_date DATE NOT NULL,
  quantity INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  rating_review INT,
  FOREIGN KEY ('customer_id')
    REFERENCES customers ('customer_id'),
  FOREIGN KEY ('product_id')
    REFERENCES products ('product_id'),
  FOREIGN KEY ('shipper_id')
    REFERENCES shippers ('shipper_id')
);

-- Ads Schema
CREATE TABLE IF NOT EXISTS `ads` (
  ads_id INT PRIMARY KEY,
  product_id INT NOT NULL,
  content TEXT,
  ads_clicks INT NOT NULL,
  budget DECIMAL(10,2),
  FOREIGN KEY ('product_id')
	REFERENCES products ('product_id')
);

