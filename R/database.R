
#' @import DBI
#' @import RPostgres

#' @export
get_connection <- function() {
    DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = "aoe",
        host = "db",
        port = 5432,
        user = "gowerc",
        password = "mypassword"
    )
}