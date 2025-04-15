library(DBI)
library(httr2)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_example")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS documents"))
invisible(dbExecute(db, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1536))"))

toBits <- function(ubinary) {
  paste0(sapply(ubinary, function(v) { rev(as.integer(intToBits(v)[1:8])) }), collapse="")
}

embed <- function(texts, inputType) {
  url <- "https://api.cohere.com/v2/embed"
  token <- Sys.getenv("CO_API_KEY")
  data <- list(
    texts=texts,
    model="embed-v4.0",
    input_type=inputType,
    embedding_types=list("ubinary")
  )

  resp <- request(url) |> req_auth_bearer_token(token) |> req_body_json(data) |> req_perform()
  sapply((resp |> resp_body_json())$embeddings$ubinary, function(v) { toBits(v) })
}

input <- c(
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
)
embeddings <- embed(input, "search_document")
items <- data.frame(content=input, embedding=embeddings)
invisible(dbAppendTable(db, "documents", items))

query <- "forest"
queryEmbedding <- embed(list(query), "search_query")[[1]]
params <- list(queryEmbedding)
result <- dbGetQuery(db, "SELECT content FROM documents ORDER BY embedding <~> $1 LIMIT 5", params=params)
print(result$content)
