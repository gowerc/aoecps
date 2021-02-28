#' @import dplyr

#' @export 
dbInsert <- function(con, name, value, keys){
    
    if (nrow(value) == 0) {
        stop("No rows to insert")
    }

    ## Get a temporary file name (remove risk of droping real table)
    tmptbl <- tempfile(tmpdir = "") %>%
        stringr::str_remove("^/")
    
    ## Get proper column order
    columnnames <- DBI::dbGetQuery(
        conn = con,
        glue::glue(
            "SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = '{name}'
            ORDER BY ordinal_position;",
            name = name
        )
    )$column_name
    
    ## Ensure columns exist and are in right order
    cnames <- colnames(value)
    stopifnot(
        length(cnames) == length(columnnames),
        all(columnnames %in% cnames),
        all(cnames %in% columnnames),
        all(keys %in% columnnames)
    )
    
    columnnames_string <- paste(
        columnnames, 
        collapse = ", "
    )
    
    keys_string <- paste0(
        columnnames[columnnames %in% keys],
        collapse = ", "
    )
    
    value2 <- value[, columnnames]
    
    ## Upload data to temporary table
    DBI::dbWriteTable(
        conn = con,
        name = tmptbl,
        value = value2,
        append = TRUE,
        temporary = TRUE
    )
    
    DBI::dbExecute(
        conn = con,
        glue::glue(
            "INSERT INTO {name}
            SELECT {colnam} FROM {tmptbl}
            ON CONFLICT ({keys}) DO NOTHING;",
            keys = keys_string,
            name = name,
            tmptbl = tmptbl,
            colnam = columnnames_string
        )
    )
    
    DBI::dbExecute(
        conn = con,
        glue::glue(
            "DROP TABLE {tmptbl};",
            tmptbl = tmptbl
        )
    )
}