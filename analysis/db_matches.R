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
    "select max(started) as started from match_meta"
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
    
    message("Getting: ", as_datetime(timestamp))
    
    data_raw <- api_matches(count = 1000, since = timestamp)
    
    data_parsed <- parse_matches(data_raw)

    match_players <- data_parsed %>%
        select(match_id, players) %>%
        unnest(players) %>%
        filter(!is.na(won))
    
    match_meta <- data_parsed %>%
        select(-players)
    
    dbInsert(
        con = con,
        name = "match_meta", 
        value = match_meta,
        key = "match_id"
    )
    
    dbInsert(
        con = con,
        name = "match_players", 
        value = match_players,
        key = c("match_id", "profile_id")
    )
    
    timestamp <-  max(match_meta$started)
}
