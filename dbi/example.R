library(DBI)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_r_test")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS items"))
invisible(dbExecute(db, "CREATE TABLE items (embedding vector(3))"))

vecToDb <- function(v) {
  stopifnot(is.numeric(v))
  paste0("[", paste(v, collapse=","), "]")
}

vecFromDb <- function(v) {
  lapply(strsplit(substring(v, 2, nchar(v) - 1), ","), as.numeric)
}

embeddings <- matrix(c(
  1, 1, 1,
  2, 2, 2,
  1, 1, 2
), nrow=3, byrow=TRUE)

items <- data.frame(embedding=apply(embeddings, 1, vecToDb))
invisible(dbAppendTable(db, "items", items))

params <- vecToDb(c(1, 1, 1))
result <- dbGetQuery(db, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", params=params)
print(vecFromDb(result$embedding))

invisible(dbExecute(db, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)"))
