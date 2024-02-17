# pgvector-r

[pgvector](https://github.com/pgvector/pgvector) examples for R

Supports [DBI](https://github.com/r-dbi/DBI) and [dbx](https://github.com/ankane/dbx)

[![Build Status](https://github.com/pgvector/pgvector-r/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-r/actions)

## Getting Started

Follow the instructions for your database library:

- [DBI](#dbi)
- [dbx](#dbx)

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
pgvector.serialize <- function(v) {
  stopifnot(is.numeric(v))
  paste0("[", paste(v, collapse=","), "]")
}

embeddings <- matrix(c(
  1, 1, 1,
  2, 2, 2,
  1, 1, 2
), nrow=3, byrow=TRUE)

items <- data.frame(embedding=apply(embeddings, 1, pgvector.serialize))
dbAppendTable(db, "items", items)
```

Get the nearest neighbors

```r
params <- pgvector.serialize(c(1, 2, 3))
dbGetQuery(db, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", params=params)
```

Add an approximate index

```r
dbExecute(db, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
# or
dbExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
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
pgvector.serialize <- function(v) {
  stopifnot(is.numeric(v))
  paste0("[", paste(v, collapse=","), "]")
}

embeddings <- matrix(c(
  1, 1, 1,
  2, 2, 2,
  1, 1, 2
), nrow=3, byrow=TRUE)

items <- data.frame(embedding=apply(embeddings, 1, pgvector.serialize))
dbxInsert(db, "items", items)
```

Get the nearest neighbors

```r
params <- pgvector.serialize(c(1, 2, 3))
dbxSelect(db, "SELECT * FROM items ORDER BY embedding <-> ? LIMIT 5", params=params)
```

Add an approximate index

```r
dbxExecute(db, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
# or
dbxExecute(db, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
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
```

In R, do:

```r
install.packages("remotes")
remotes::install_deps(dependencies=TRUE)
```

And run:

```sh
Rscript DBI/example.R
Rscript dbx/example.R
```
