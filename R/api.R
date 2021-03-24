
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

#' @export 
parse_matches <- function(matches_raw){
    matches_raw %>%
        jsonlite::fromJSON() %>%
        tibble() %>%
        mutate(
            match_id = as.character(match_id),
            lobby_id = as.character(lobby_id),
            match_uuid = as.character(match_uuid),
            version = as.character(version),
            name = as.character(name),
            num_players = as.integer(num_players),
            num_slots = as.integer(num_slots),
            average_rating = as.integer(average_rating),
            cheats = as.logical(cheats),
            full_tech_tree = as.logical(full_tech_tree),
            ending_age = as.integer(ending_age),
            expansion = as.logical(expansion),
            game_type = as.integer(game_type),
            has_custom_content = as.logical(has_custom_content),
            has_password = as.logical(has_password),
            lock_speed = as.logical(lock_speed),
            lock_teams = as.logical(lock_teams),
            map_size = as.integer(map_size),
            map_type = as.integer(map_type),
            pop = as.integer(pop),
            ranked = as.logical(ranked),
            leaderboard_id = as.integer(leaderboard_id),
            rating_type = as.integer(rating_type),
            resources = as.integer(resources),
            rms = as.character(rms),
            scenario = as.character(scenario),
            server = as.character(server),
            shared_exploration = as.logical(shared_exploration),
            speed = as.integer(speed),
            starting_age = as.integer(starting_age),
            team_together = as.logical(team_together),
            team_positions = as.logical(team_positions),
            treaty_length = as.integer(treaty_length),
            turbo = as.logical(turbo),
            victory = as.integer(victory),
            victory_time = as.integer(victory_time),
            visibility = as.integer(visibility),
            opened = as.integer(opened),
            started = as.integer(started),
            finished = as.integer(finished),
            players = as.list(players)
        )
}
