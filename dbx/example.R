library(dbx)

db <- dbxConnect(adapter="postgres", dbname="pgvector_r_test")

invisible(dbxExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbxExecute(db, "DROP TABLE IF EXISTS items"))
invisible(dbxExecute(db, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))"))

pgvector.serialize <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

pgvector.unserialize <- function(v) {
  as.numeric(strsplit(substring(v, 2, nchar(v) - 1), ",")[[1]])
}

embeddings <- list(
  c(1, 1, 1),
  c(2, 2, 2),
  c(1, 1, 2)
)

items <- data.frame(embedding=sapply(embeddings, pgvector.serialize))
invisible(dbxInsert(db, "items", items))

params <- list(pgvector.serialize(c(1, 1, 1)))
result <- dbxSelect(db, "SELECT * FROM items ORDER BY embedding <-> ? LIMIT 5", params=params)
print(lapply(result$embedding, pgvector.unserialize))

invisible(dbxExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)"))
