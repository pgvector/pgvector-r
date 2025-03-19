library(DBI)
library(httr2)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_example")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS documents"))
invisible(dbExecute(db, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))"))

embed <- function(input) {
  url <- "https://api.openai.com/v1/embeddings"
  token <- Sys.getenv("OPENAI_API_KEY")
  data <- list(
    input=input,
    model="text-embedding-3-small"
  )

  resp <- request(url) |> req_auth_bearer_token(token) |> req_body_json(data) |> req_perform()
  lapply((resp |> resp_body_json())$data, function(x) { unlist(x$embedding) })
}

encodeVector <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

input <- c(
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
)
embeddings <- embed(input)
items <- data.frame(content=input, embedding=sapply(embeddings, encodeVector))
invisible(dbAppendTable(db, "documents", items))

query <- "forest"
queryEmbedding <- embed(c(query))[[1]]
params <- list(encodeVector(queryEmbedding))
result <- dbGetQuery(db, "SELECT content FROM documents ORDER BY embedding <=> $1 LIMIT 5", params=params)
print(result$content)
