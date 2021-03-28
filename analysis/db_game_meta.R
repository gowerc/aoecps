suppressPackageStartupMessages({
    pkgload::load_all()
    library(DBI)
    library(tibble)
    library(dplyr)
    library(purrr)
}) 

VERSION <- "A"

con <- get_connection()

meta <- api_meta() %>%
    jsonlite::fromJSON()


types <- names(meta)[! names(meta) %in% "language"]

dat <- map(
    types,
    function(x, y) as_tibble(y[[x]]) %>% mutate(type = x),
    y = meta
) %>% 
    bind_rows() %>%
    mutate(version = VERSION)

dbInsert(
    con = con,
    name = "game_meta", 
    value = dat,
    key = c("version", "type", "id")
)



