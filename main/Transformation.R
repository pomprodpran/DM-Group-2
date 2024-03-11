library(RSQLITE)

# Rscript R/transformation.R
# load the data
# print("loading")
# data_files <- list.files("data_uploads", pattern = "MOCK_DATA_PRODUCTS", file.names = TRUE)
# data_to_write <- data.frame()
# 
# # for each csv
# for(file in data_files) {
#   print(paste("Reading file:",file))
#   this_file_rows <- read.csv(file, stingsAsFactors = FALSE)
#   data_to_write <- rbind(data_to_write, this_file_rows)
# }
# print("writing them to database")
# 
# connection <- RSQLITE::dbConnect(RSQLite::SQLite(), "database/product.db")
# RSQLITE::dbWriteTable(connection,"products", data_to_write,overwrite = TRUE)
# RSQLITE::dbDisconnect(connection)
# print("Done!")

print("Transformation file")

