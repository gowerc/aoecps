suppressPackageStartupMessages({
    pkgload::load_all()
    library(dplyr)
    library(jsonlite)
    library(lubridate)
    library(DBI)
    library(tidyr)
})

con <- get_connection()

started_df <- dbGetQuery(
    conn = con,
    "select max(started) as started from matches"
)

timestamp <- started_df$started[[1]]

if(is.na(timestamp)){
    timestamp <- as_datetime("2021-02-10:00:00:01") %>% 
        as.numeric() %>% 
        round()
}

CUTOFF <- (Sys.time() - hours(20)) %>% 
    as.numeric() %>% 
    round()

while(timestamp < CUTOFF){

    message("Getting :", as_datetime(timestamp))

    data_parsed <- api_matches(count = 1000, since = timestamp) %>%
        jsonlite::fromJSON() %>%
        tibble() 

    players <- data_parsed %>%
        select(match_id, players) %>%
        unnest(players)

    matches <- data_parsed %>%
        select(-players)

    ### Remove duplicate entries
    dbExecute(
        conn = con,
        sprintf(
            "DELETE FROM matches where match_id in ('%s');",
            paste0(matches$match_id, collapse = "','")
        )
    )

    dbExecute(
        conn = con,
        sprintf(
            "DELETE FROM players where match_id in ('%s');",
            paste0(matches$match_id, collapse = "','")
        )
    )

    dbWriteTable(
        conn = con, 
        name = "matches", 
        value = matches, 
        append = TRUE
    )

    dbWriteTable(
        conn = con, 
        name = "players", 
        value = players, 
        append = TRUE
    )
    
    timestamp <-  max(matches$started)
}



