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


# 2. Check 
