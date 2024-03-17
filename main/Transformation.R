library(RSQLite)
library(readr)
library(lubridate)


# Incremental Load
print("Loading CSV file")

# File format for automation: <table name>_YYYY-MM-DDTHHMMSS.csv
current_date <- Sys.Date()
print(paste("current date:", current_date))
# Get only Incremental file
all_files <- list.files("./data_upload", full.names = FALSE, pattern = "_")
for (variable in all_files) {
  file_name <- unlist(strsplit(gsub(".csv","",variable), "_")) # split file name using _ separator
  table_name <- file_name[1]
  date_time_parts <- unlist(strsplit(file_name[2], "T"))  # Splitting file name using 'T' separator
  date_str <- date_time_parts[1]  # Date string
  time_str <- date_time_parts[2]  # Time string
  date_value <- lubridate::ymd(date_str) # Parsing date strings into datetime objects using lubridate
  
  # Get only NEW file that has been loaded into the folder (and run historical back 2 days)
  if (date_value>= current_date-1 && date_value<= current_date ) {
    print(paste("Reading file:",variable))
    this_filepath <- paste0("./data_upload/",variable)
    this_file_contents <- readr::read_csv(this_filepath)
    
    print(paste("Writing table to database:", table_name))
    my_db <- RSQLite::dbConnect(RSQLite::SQLite(),"./database/ecommerse.db")
    
    # Get the primary key column names from the database
    query <- paste("SELECT name FROM pragma_table_info('",table_name,"') WHERE pk = 1;",sep="")
    primary_key_columns <- dbGetQuery(my_db, query)
    
    # Get Foreign Key
    query <- paste("PRAGMA foreign_key_list('",table_name,"');",sep="")
    foreign_key_columns <- dbGetQuery(my_db, query)
    
    # Perform Validation
    source("./main/Validation.R")
    
    # Validation and Writing on each row to DB
    if (nrow(this_file_contents)>0 ){
      for (i in 1:nrow(this_file_contents)) {
        
        row <- this_file_contents[i, ]
        
        # Extract primary key values from the row
        primary_key_values <- paste(names(row)[names(row) %in% primary_key_columns], row[names(row) %in% primary_key_columns], sep = "=", collapse = " AND ")
        
        # Find if the primary key exists
        query <- paste("SELECT * FROM", table_name, paste("WHERE", primary_key_values))
        existing_row <- dbGetQuery(my_db, query)
        
        if (nrow(existing_row) == 0) {
          # Row is unique, append to the table
          print(paste("Append:",primary_key_values))
          dbWriteTable(my_db, table_name, row, append = TRUE)
        } else {
          # Row already exists, update the existing row
          print(paste("Update:",primary_key_values))
          update_query <- paste("UPDATE", table_name, paste("SET", paste(names(row), "=", paste0("'", row, "'"), collapse = ", "), "WHERE", primary_key_values))
          dbExecute(my_db, update_query)
        }
      }
    }
    else {
      print("Nothing to update in database since all rows are not pass the validations")
    }
  }
}
print("Done!")

# Check if the connection object exists and is valid
if (exists("my_db") && RSQLite::dbIsValid(my_db)) {
  # Disconnect from the database
  RSQLite::dbDisconnect(my_db)
} else {
  # Print a message or handle the case where the connection object is not found or invalid
  print("Connection object not found or is invalid.")
}
