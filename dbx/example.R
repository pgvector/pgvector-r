library(dbx)

db <- dbxConnect(adapter="postgres", dbname="pgvector_r_test")

invisible(dbxExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbxExecute(db, "DROP TABLE IF EXISTS items"))
invisible(dbxExecute(db, "CREATE TABLE items (embedding vector(3))"))

pgvector.serialize <- function(v) {
  stopifnot(is.numeric(v))
  paste0("[", paste(v, collapse=","), "]")
}

pgvector.unserialize <- function(v) {
  lapply(strsplit(substring(v, 2, nchar(v) - 1), ","), as.numeric)
}

embeddings <- matrix(c(
  1, 1, 1,
  2, 2, 2,
  1, 1, 2
), nrow=3, byrow=TRUE)

items <- data.frame(embedding=apply(embeddings, 1, pgvector.serialize))
invisible(dbxInsert(db, "items", items))

params <- pgvector.serialize(c(1, 1, 1))
result <- dbxSelect(db, "SELECT * FROM items ORDER BY embedding <-> ? LIMIT 5", params=params)
print(pgvector.unserialize(result$embedding))

invisible(dbxExecute(db, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)"))
