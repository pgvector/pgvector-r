# good resource
# https://www.bioconductor.org/packages/release/bioc/vignettes/ChemmineR/inst/doc/ChemmineR.html

library(ChemmineR)
library(DBI)

db <- dbConnect(RPostgres::Postgres(), dbname="pgvector_example")

invisible(dbExecute(db, "CREATE EXTENSION IF NOT EXISTS vector"))
invisible(dbExecute(db, "DROP TABLE IF EXISTS molecules"))
invisible(dbExecute(db, "CREATE TABLE molecules (id text PRIMARY KEY, fingerprint bit(1024))"))

data(sdfsample)
fpset <- desc2fp(sdf2ap(sdfsample))
molecules <- data.frame(id=sdfid(sdfsample), fingerprint=as.character(fpset))
invisible(dbAppendTable(db, "molecules", molecules))

params <- list(molecules$fingerprint[[1]])
result <- dbGetQuery(db, "SELECT id FROM molecules ORDER BY fingerprint <%> $1 LIMIT 5", params=params)
print(result$id)
