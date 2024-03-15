print("Performing Validation")

# 1. Check duplicate primary key within CSV file
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


# 2. Check data quality and integrity
print(paste0("Checking integrity for: ",variable))

# Function to validate email addresses
# check email format
email_format <- function(emails) {
  pattern <- "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  grepl(pattern, emails)
}
# error handling
validate_emails <- function(this_file_contents) {
  tmp_table <- this_file_contents
  tmp_table$valid_email <- email_format(this_file_contents$email)
  for (i in 1:nrow(tmp_table)){
    tmp_row <- tmp_table[i,]
    if (!tmp_row$valid_email) {
      warning("Email Format of ID: ",tmp_row$id," is incorrect. Please check." )
    }
  }
  if (all(tmp_table$valid_email) == TRUE){
    print("Email Format: Passed!")
  }
  tmp_table <- tmp_table[tmp_table$valid_email,] # remove row
  tmp_table <- tmp_table[, !names(tmp_table) %in% "valid_email"] # remove check column
  return(tmp_table)
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


# Perform integrity check
if (table_name == 'customers' && nrow(this_file_contents) >0) {
  this_file_contents <- validate_emails(this_file_contents)
  
} else if (table_name == 'orders' && nrow(this_file_contents) >0) {
  
} else if (table_name == 'products' && nrow(this_file_contents) >0) {
  
} else if (table_name == 'categories' && nrow(this_file_contents) >0) {
  
} else if (table_name == 'sellers' && nrow(this_file_contents) >0) {
  this_file_contents <- validate_emails(this_file_contents)
  
} else if (table_name == 'shippers' && nrow(this_file_contents) >0) {
  
} else if (table_name == 'advertisements' && nrow(this_file_contents) >0) {
  
}
