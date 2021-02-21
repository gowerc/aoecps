
### API from : https://aoe2.net/#api

#' @import httr
#' @import lubridate

#' @export 
api_meta <- function(
    game = "aoe2de", 
    language = "en", 
    type = NULL
){
    resp <- httr::GET(
        url = "https://aoe2.net/api/strings",
        query = list(
            game = game,
            language = language
        )
    )
    httr::stop_for_status(resp)
    return(httr::content(resp, type = type))
}


#' @export 
api_matches <- function(
    count = 1000,
    since = round(as.numeric(lubridate::now() - lubridate::minutes(15))),
    game = "aoe2de", 
    language = "en", 
    type = NULL
){
    resp <- httr::GET(
        url = "https://aoe2.net/api/matches",
        query = list(
            language = language,
            game = game,
            count = count,
            since = since
        )
    )
    httr::stop_for_status(resp)
    return(httr::content(resp, type = type))
}

