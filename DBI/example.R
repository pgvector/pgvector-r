library(DBI)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_r_test")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS items"))
invisible(dbExecute(db, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))"))

pgvector.serialize <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

pgvector.unserialize <- function(v) {
  lapply(strsplit(substring(v, 2, nchar(v) - 1), ","), as.numeric)
}

embeddings <- list(
  c(1, 1, 1),
  c(2, 2, 2),
  c(1, 1, 2)
)

items <- data.frame(embedding=sapply(embeddings, pgvector.serialize))
invisible(dbAppendTable(db, "items", items))

params <- list(pgvector.serialize(c(1, 1, 1)))
result <- dbGetQuery(db, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", params=params)
print(pgvector.unserialize(result$embedding))

invisible(dbExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)"))
