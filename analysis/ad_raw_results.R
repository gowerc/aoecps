suppressPackageStartupMessages({
    library(httr)
    library(dplyr)
    library(jsonlite)
    library(lubridate)
    library(glue)
    library(stringr)
    library(tidyr)
    library(mongolite)
})

# renv::snapshot()

# since (Optional) Only show matches starting after timestamp (epoch)

URL <- "https://aoe2.net/api/matches"

files <- list.files("./data", pattern = "^results_")


if( length(files) >= 1){
    timestamp <- files %>% 
        str_remove("^results_") %>% 
        str_remove("\\.Rds$") %>% 
        as.numeric() %>% 
        max() 
} else {
    ### day after Lords of the west release date
    timestamp <- as_datetime("2021-02-10:00:00:01") %>% 
        as.numeric() %>% 
        round()
}

CUTOFF <- (Sys.time() - hours(12)) %>% 
    as.numeric() %>% 
    round()


while(timestamp < CUTOFF){
    params <- list(
        language = "en",
        game = "aoe2de",
        count = 1000,
        since = timestamp
    )
    
    message("Getting: ", lubridate::as_datetime(timestamp))
    
    resp <- GET(url = URL, query = params)
    
    stop_for_status(resp)
    
    df <- content(resp) %>%  
        jsonlite::fromJSON() %>% 
        as_tibble()
    
    saveRDS(
        df,
        file = glue("./data/results_{ts}.Rds", ts = timestamp)
    )
    
    timestamp <-  max(df$started)
}



