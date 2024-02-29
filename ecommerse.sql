-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

DROP TABLE IF EXISTS `customers` ;
DROP TABLE IF EXISTS `orders` ;

-- Customer Schema
CREATE TABLE IF NOT EXISTS `customers` (
  customer_id INT PRIMARY KEY,
  customer_firstmane VARCHAR(250) NOT NULL,
  customer_lastname VARCHAR(250) NOT NULL,
  customer_email TEXT,
  phone_number VARCHAR(20),
  date_of_birth DATE,
  billing_address_state TEXT,
  billing_address_city TEXT,
  billing_address_country TEXT,
  billing_address_postcode TEXT
);

-- Order Schema
CREATE TABLE IF NOT EXISTS `orders` (
  order_id INT PRIMARY KEY,
  quantity INT NOT NULL,
  shipping_address_state TEXT,
  shipping_address_city TEXT,
  shipping_address_country TEXT,
  shipping_address_postcode TEXT,
  FOREIGN KEY ('customer_id')
    REFERENCES customers ('customer_id')
  FOREIGN KEY ('product_id')
    REFERENCES products ('product_id') 
  FOREIGN KEY ('shipper_id')
    REFERENCES shippers ('shipper_id')  
);


INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (3, 'Bertram', 'Linares', 'waneta5991@adjust.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (46, 'Sana', 'Denham', 'dalene.beane1@swing.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (88, 'Laree', 'Keaton', 'yangbeers068@yahoo.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (24, 'Blanch', 'Woodard', 'georgene.manuel51@porter.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (59, 'Michiko', 'Spangler', 'charis.usher76427@yahoo.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (36, 'Nanci', 'Timmerman', 'wendie_rutherford@hotmail.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (98, 'Meridith', 'Pellegrino', 'twana_cavanaugh@focusing.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (49, 'Romeo', 'Roberts', 'dorsey_goodrich@gmail.com');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (45, 'Tracy', 'Chinn', 'chery.ison18564@welsh.misato.wakayama.jp');
INSERT INTO customers (customer_id, customer_firstname, customer_lastname, customer_email) VALUES (50, 'Rupert', 'Cox', 'lavada858@gmail.com');




