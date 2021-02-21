library(dplyr)
library(httr)
library(tidyr)
library(purrr)
library(jsonlite)
library(glue)
library(DBI)
library(dbplyr)
pkgload::load_all()


con <- get_connection()

keepme <- tbl(con, "matches") %>%
    filter(ranked, leaderboard_id == 3) %>%
    select(match_id)


tbl(con, "players") %>%
    semi_join(keepme, by = "match_id") %>%
    collect() %>%
    as_tibble()
