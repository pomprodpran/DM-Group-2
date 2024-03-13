-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

DROP TABLE IF EXISTS `customers` ;
DROP TABLE IF EXISTS `products` ;
DROP TABLE IF EXISTS `shippers` ;
DROP TABLE IF EXISTS `orders` ;
DROP TABLE IF EXISTS `advertisements` ;
DROP TABLE IF EXISTS `sellers` ;
DROP TABLE IF EXISTS `categories` ;


------------- CREATE TABLE -------------

-- Customer Schema
CREATE TABLE IF NOT EXISTS `customers` (
  'id' INT PRIMARY KEY,
  'first_name' VARCHAR(250) NOT NULL,
  'last_name' VARCHAR(250) NOT NULL,
  'email' TEXT NOT NULL,
  'phone_number' VARCHAR(20),
  'date_of_birth' DATE,
  'billing_address_street_number' TEXT,
  'billing_address_street_name' TEXT,
  'billing_address_street_suffix' TEXT,
  'billing_address_city' TEXT,
  'billing_address_state' TEXT,
  'billing_address_country' TEXT,
  'billing_address_postcode' TEXT,
  'current_shipping_address_street_number' TEXT,
  'current_shipping_address_street_name' TEXT,
  'current_shipping_address_street_suffix' TEXT,
  'current_shipping_address_city' TEXT,
  'current_shipping_address_state' TEXT,
  'current_shipping_address_country' TEXT,
  'current_shipping_address_postcode' TEXT,
  'current_payment_method' VARCHAR(250)
);

-- Sellers Schema
CREATE TABLE IF NOT EXISTS `sellers` (
  'id' INT PRIMARY KEY,
  'name' VARCHAR(250) NOT NULL,
  'email' TEXT,
  'address_street_number' TEXT,
  'address_street_name' TEXT,
  'address_street_suffix' TEXT,
  'address_city' TEXT,
  'address_state' TEXT,
  'address_country' TEXT,
  'address_postcode' TEXT
);

-- Categories Schema
CREATE TABLE IF NOT EXISTS `categories` (
  'id' INT PRIMARY KEY,
  'name' VARCHAR(250) NOT NULL,
  'description' TEXT
);

-- Products Schema
CREATE TABLE IF NOT EXISTS `products` (
  'id' INT PRIMARY KEY,
  'seller_id' INT NOT NULL,
  'category_id' INT NOT NULL,
  'name' VARCHAR(60) NOT NULL,
  'color' VARCHAR(60) NOT NULL,
  'size' VARCHAR(5),
  'brand' VARCHAR(250),
  'price' NUMERIC NOT NULL,
  'currency' CHAR(3) NOT NULL, 
  'inventory' INT,
  FOREIGN KEY ('seller_id') 
    REFERENCES sellers ('id'),
  FOREIGN KEY ('category_id') 
    REFERENCES category ('id')
);

-- Shipper Schema
CREATE TABLE IF NOT EXISTS `shippers` (
  'id' INT PRIMARY KEY,
  'name' CHAR(25) NOT NULL,
  'phone_number' VARCHAR(25) NOT NULL
);

-- Order Schema : create after 3 main tables
CREATE TABLE IF NOT EXISTS `orders` (
  'id' INT PRIMARY KEY,
  'customer_id' INT NOT NULL,
  'product_id' INT NOT NULL,
  'shipper_id' INT NOT NULL,
  'order_date' DATE NOT NULL,
  'order_time' TIMESTAMP NOT NULL,
  'quantity' INT NOT NULL,
  'discount' DECIMAL(3,2) NOT NULL,
  'rating_review' INT,
  FOREIGN KEY ('customer_id')
    REFERENCES customers ('id'),
  FOREIGN KEY ('product_id')
    REFERENCES products ('id'),
  FOREIGN KEY ('shipper_id')
    REFERENCES shippers ('id')
);

-- Ads Schema
CREATE TABLE IF NOT EXISTS `advertisements` (
  'id' INT PRIMARY KEY,
  'product_id' INT NOT NULL,
  'content' TEXT,
  'ad_clicks' INT,
  'budget' DECIMAL(10,2),
  'currency' CHAR(3),
  FOREIGN KEY ('product_id')
	REFERENCES products ('id')
);

