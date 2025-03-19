library(dbx)

db <- dbxConnect(adapter="postgres", dbname="pgvector_r_test")

invisible(dbxExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbxExecute(db, "DROP TABLE IF EXISTS items"))
invisible(dbxExecute(db, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))"))

encodeVector <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

decodeVector <- function(str) {
  as.numeric(strsplit(substring(str, 2, nchar(str) - 1), ",")[[1]])
}

embeddings <- list(
  c(1, 1, 1),
  c(2, 2, 2),
  c(1, 1, 2)
)

items <- data.frame(embedding=sapply(embeddings, encodeVector))
invisible(dbxInsert(db, "items", items))

params <- list(encodeVector(c(1, 1, 1)))
result <- dbxSelect(db, "SELECT * FROM items ORDER BY embedding <-> ? LIMIT 5", params=params)
print(lapply(result$embedding, decodeVector))

invisible(dbxExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)"))
