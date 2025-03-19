# good resources
# https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
# https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1
#
# run with
# text-embeddings-router --model-id opensearch-project/opensearch-neural-sparse-encoding-v1 --pooling splade

library(DBI)
library(httr2)
library(Matrix)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_example")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS documents"))
invisible(dbExecute(db, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))"))

embed <- function(inputs) {
  url <- "http://localhost:3000/embed_sparse"
  data <- list(
    inputs=inputs
  )

  resp <- request(url) |> req_body_json(data) |> req_perform()
  sapply((resp |> resp_body_json()), function(v) {
    indices <- sapply(v, function(e) { e$index })
    values <- sapply(v, function(e) { e$value })
    sparseVector(i=indices, x=values, length=30522)
  })
}

encodeSparseVector <- function(vec) {
  stopifnot(inherits(vec, "sparseVector"))
  elements <- mapply(function(i, v) { paste0(i, ":", v) }, vec@i, vec@x)
  paste0("{", paste0(elements, collapse=","), "}/", length(vec))
}

input <- c(
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
)
embeddings <- embed(input)
items <- data.frame(content=input, embedding=sapply(embeddings, encodeSparseVector))
invisible(dbAppendTable(db, "documents", items))

query <- "forest"
queryEmbedding <- embed(c(query))[[1]]
params <- list(encodeSparseVector(queryEmbedding))
result <- dbGetQuery(db, "SELECT content FROM documents ORDER BY embedding <#> $1 LIMIT 5", params=params)
print(result$content)
