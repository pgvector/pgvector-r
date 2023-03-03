# pgvector-r

[pgvector](https://github.com/pgvector/pgvector) examples for R

Supports [DBI](https://github.com/r-dbi/DBI)

[![Build Status](https://github.com/pgvector/pgvector-r/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-r/actions)

## Getting Started

Follow the instructions for your database library:

- [DBI](#dbi)

## DBI

Create a table

```r
dbExecute(db, "CREATE TABLE items (embedding vector(3))")
```

Insert vectors

```r
vecToDb <- function(v) {
  paste0("[", paste(v, collapse=","), "]")
}

embeddings <- matrix(c(
  1, 1, 1,
  2, 2, 2,
  1, 1, 2
), nrow=3, byrow=TRUE)

items <- data.frame(embedding=apply(embeddings, 1, vecToDb))
dbAppendTable(db, "items", items)
```

Get the nearest neighbors

```r
params <- vecToDb(c(1, 2, 3))
dbGetQuery(db, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", params=params)
```

Add an approximate index

```r
dbExecute(db, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](dbi/example.R)

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
Rscript dbi/example.R
```
