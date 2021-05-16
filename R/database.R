
#' @import DBI
#' @import RPostgres
#' @export
get_connection <- function() {
    DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = Sys.getenv("APP_DB"),
        host = Sys.getenv("APP_HOST"),
        port = 5432,
        user = Sys.getenv("APP_USER"),
        password = Sys.getenv("APP_PASSWORD")
    )
}


#' @importFrom jsonlite read_json
#' @import tibble
#' @importFrom purrr map_df
#' @export
get_game_meta <- function(){
    x <- read_json("./data-raw/db_meta.json")
    map_df(names(x), function(i){
        tibble(
            version = i,
            string = unlist(x[[i]]$string),
            id = unlist(x[[i]]$id),
            type = unlist(x[[i]]$type)
        )
    })
}



