print("Performing Validation")

# ------ 1. Check duplicate primary key within CSV file ------
print(paste0("Checking duplicate primary for: ",variable))

number_of_rows <- nrow(this_file_contents)

for (i in primary_key_columns) {
  if (nrow(unique(this_file_contents[,i]))==number_of_rows) {
    print(paste("Primary key =",i,": Passed"))
  }
  else {
    stop(paste("Found duplcate record in ", variable,": STOP process!"))
  }
}


# ------ 2. Check data quality and integrity ------
print(paste0("Checking integrity for: ",variable))

# Function to validate email addresses
validate_emails <- function(emails) {
  pattern <- "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  grepl(pattern, emails)
}

# Function to validate phone numbers
validate_phones <- function(phones) {
  # This is a simple example and might not cover all international formats
  pattern <- "^\\+?[1-9][0-9]{7,14}$"
  grepl(pattern, phones)
}

# Function to validate dates
validate_dates <- function(dates) {
  date_format <- "%Y-%m-%d"
  dates_parsed <- parse_date_time(dates, orders = date_format)
  !is.na(dates_parsed)
}

# Function to validate prices
validate_prices <- function(prices) {
  prices >= 0
}

# Function to validate currency codes
validate_currencies <- function(currencies) {
  pattern <- "^[A-Z]{3}$"
  grepl(pattern, currencies)
}

# Function error handling
validation <- function(this_file_contents,type,column) {
  tmp_table <- this_file_contents
  if (type == 'Email') {
    tmp_table$valid_format <- validate_emails(column)
  } else if (type == 'Phone_numbers') {
    tmp_table$valid_format <- validate_phones(column)
  } else if (type == 'Dates') {
    tmp_table$valid_format <- validate_dates(column)
  } else if (type == 'Prices' || type == 'Budget') {
    tmp_table$valid_format <- validate_prices(column)
  } else if (type == 'Currencies') {
    tmp_table$valid_format <- validate_currencies(column)
  }
  print(tmp_table)
  for (i in 1:nrow(tmp_table)){
    tmp_row <- tmp_table[i,]
    if (!tmp_row$valid_format) {
      warning(type," Format of ID: ",tmp_row$id, " in ", variable," is incorrect. Please check." )
    }
  }
  if (all(tmp_table$valid_format) == TRUE){
    print(paste(type," Format: Passed!"))
  }
  tmp_table <- tmp_table[tmp_table$valid_format,] # remove row
  tmp_table <- tmp_table[, !names(tmp_table) %in% "valid_format"] # remove check column
  return(tmp_table)
}


# Perform integrity check
if (table_name == 'customers' && nrow(this_file_contents) >0) {
  this_file_contents <- validation(this_file_contents,'Email',this_file_contents$email)
  #this_file_contents <- validation(this_file_contents,'Phone_numbers',this_file_contents$phone_number)
  
} else if (table_name == 'orders' && nrow(this_file_contents) >0) {
  #this_file_contents <- validation(this_file_contents,'Dates',this_file_contents$order_date)
} else if (table_name == 'products' && nrow(this_file_contents) >0) {
  this_file_contents <- validation(this_file_contents,'Prices',this_file_contents$price)
  this_file_contents <- validation(this_file_contents,'Currencies',this_file_contents$currency)
  
} else if (table_name == 'categories' && nrow(this_file_contents) >0) {
  
} else if (table_name == 'sellers' && nrow(this_file_contents) >0) {
  this_file_contents <- validation(this_file_contents,'Email',this_file_contents$email)
  
} else if (table_name == 'shippers' && nrow(this_file_contents) >0) {
  #this_file_contents <- validation(this_file_contents,'Phone_numbers',this_file_contents$phone_number)
} else if (table_name == 'advertisements' && nrow(this_file_contents) >0) {
  this_file_contents <- validation(this_file_contents,'Currencies',this_file_contents$currency)
  this_file_contents <- validation(this_file_contents,'Budget',this_file_contents$budget)
}


# ------ 3. Check Foreign key ------
if(nrow(this_file_contents) >0) {
  foreign_table <- foreign_key_columns[,'table']
  tmp_table <- this_file_contents
  for (i in foreign_table) {
    foreign_key_ori_column <- foreign_key_columns[foreign_key_columns[,'table'] == i,'from']
    foreign_key_dest_column <- foreign_key_columns[foreign_key_columns[,'table'] == i,'to']
    print(paste("Checking Foreign key in table",i, "column:",foreign_key_ori_column))
    for (j in 1:nrow(this_file_contents)) {
      foreign_key_value <- this_file_contents[j,foreign_key_ori_column]
      query <- paste("SELECT", foreign_key_dest_column," FROM",i," WHERE", foreign_key_dest_column,"=", foreign_key_value, ";")
      result <- dbGetQuery(my_db, query)
      col <- paste("check_",i,sep="")
      if (nrow(result) == 0) {
        warning("Foreign key is missing in row ID =  ", this_file_contents[j,primary_key_columns[1,]], " Please check.")
        tmp_table[[col]] <- FALSE
      } else {
        tmp_table[[col]] <- TRUE
      }
    }
  }
  rows_to_remove <- apply(tmp_table[, grepl("^check", names(tmp_table))], 1, function(row) any(!row))
  tmp_table <- tmp_table[, !grepl("^check", names(tmp_table))] # remove column
  tmp_table <- tmp_table[!rows_to_remove, ] # remove failed row
  this_file_contents <- tmp_table
} else{
  print("No validation check in this table since there's no foreign key")
}

print("Validation Completed")



