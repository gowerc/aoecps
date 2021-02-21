suppressPackageStartupMessages({
    pkgload::load_all()
    library(DBI)
    library(tibble)
    library(dplyr)
}) 

con <- get_connection()

meta <- api_meta()

aoever <- api_matches(count = 1) %>%
    jsonlite::fromJSON() %>%
    `[[`("version")

stopifnot(
    !is.na(aoever),
    is.character(aoever)
)

dat <- tibble(
    version = aoever,
    meta = meta
)

existing_vers <- dbGetQuery(
    conn = con,
    "select version from meta;"
)

if( aoever %in% existing_vers[["version"]]){
    dbExecute(
        conn = con,
        sprintf("DELETE FROM meta where version = '%s';", aoever)
    )
}

dbWriteTable(
    conn = con,
    name = "meta",
    append = TRUE,
    value = dat
)

