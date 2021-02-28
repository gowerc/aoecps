suppressPackageStartupMessages({
    pkgload::load_all()
    library(DBI)
    library(tibble)
    library(dplyr)
    library(purrr)
}) 

con <- get_connection()

meta <- api_meta() %>%
    jsonlite::fromJSON()

aoever <- api_matches(count = 1) %>%
    jsonlite::fromJSON() %>%
    `[[`("version")

stopifnot(
    !is.na(aoever),
    is.character(aoever)
)

types <- names(meta)[! names(meta) %in% "language"]

dat <- map(
    types,
    function(x, y) as_tibble(y[[x]]) %>% mutate(type = x),
    y = meta
) %>% 
    bind_rows() %>%
    mutate(version = aoever)

dbInsert(
    con = con,
    name = "game_meta", 
    value = dat,
    key = c("version", "type", "id")
)



