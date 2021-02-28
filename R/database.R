
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