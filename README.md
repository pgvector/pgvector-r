# pgvector-r

[pgvector](https://github.com/pgvector/pgvector) examples for R

Supports [DBI](https://github.com/r-dbi/DBI) and [dbx](https://github.com/ankane/dbx)

[![Build Status](https://github.com/pgvector/pgvector-r/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-r/actions)

## Getting Started

Follow the instructions for your database library:

- [DBI](#dbi)
- [dbx](#dbx)

Or check out an example:

- [Embeddings](examples/openai/example.R) with OpenAI
- [Binary embeddings](examples/cohere/example.R) with Cohere
- [Sparse search](examples/sparse/example.R) with Text Embeddings Inference

## DBI

Enable the extension

```r
dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector")
```

Create a table

```r
dbExecute(db, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert vectors

```r
encodeVector <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

embeddings <- list(
  c(1, 1, 1),
  c(2, 2, 2),
  c(1, 1, 2)
)

items <- data.frame(embedding=sapply(embeddings, encodeVector))
dbAppendTable(db, "items", items)
```

Get the nearest neighbors

```r
params <- list(encodeVector(c(1, 2, 3)))
dbGetQuery(db, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", params=params)
```

Add an approximate index

```r
dbExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
# or
dbExecute(db, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](DBI/example.R)

## dbx

Enable the extension

```r
dbxExecute(db, "CREATE EXTENSION IF NOT EXISTS vector")
```

Create a table

```r
dbxExecute(db, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert vectors

```r
encodeVector <- function(vec) {
  stopifnot(is.numeric(vec))
  paste0("[", paste(vec, collapse=","), "]")
}

embeddings <- list(
  c(1, 1, 1),
  c(2, 2, 2),
  c(1, 1, 2)
)

items <- data.frame(embedding=sapply(embeddings, encodeVector))
dbxInsert(db, "items", items)
```

Get the nearest neighbors

```r
params <- list(encodeVector(c(1, 2, 3)))
dbxSelect(db, "SELECT * FROM items ORDER BY embedding <-> ? LIMIT 5", params=params)
```

Add an approximate index

```r
dbxExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
# or
dbxExecute(db, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](dbx/example.R)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-r/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-r/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-r.git
cd pgvector-r
createdb pgvector_r_test
Rscript -e "install.packages('remotes', repos='https://cloud.r-project.org')"
Rscript -e "remotes::install_deps(dependencies=TRUE)"
Rscript DBI/example.R
Rscript dbx/example.R
```

To run an example:

```sh
cd examples/openai
createdb pgvector_example
Rscript -e "remotes::install_deps(dependencies=TRUE)"
Rscript example.R
```
