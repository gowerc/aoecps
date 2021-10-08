get_meta_version <- function(start_dt) {
    case_when(
        start_dt <= ymd_hms("2021-8-09T00-00-00") ~ "A",
        start_dt >= ymd_hms("2021-8-11T00-00-00") ~ "B",
        TRUE ~ "ZZZ"
    )
}


logit <- function(x) {
    log(x / (1 - x))
}


invlogit <- function(x) {
    exp(x) / (1 + exp(x))
}


as_footnote <- function(x, width = 140) {
    x %>%
        paste(collapse = " ") %>%
        stringr::str_split("<br/>") %>%
        purrr::flatten_chr() %>%
        stringr::str_trim() %>%
        stringr::str_wrap(width = width) %>%
        paste(collapse = "\n")
}


get_map_class <- function() {
    x <- yaml::read_yaml("./data-raw/map_class.yml")
    tibble(
        map_name = names(unlist(x)),
        map_class = unlist(x)
    )
}


get_opts <- function(key = NULL) {
    x <- yaml::read_yaml("./data-raw/report_meta.yml")
    if(is.null(key)) return(x)
    assertthat::assert_that(key %in% names(x))
    x2 <- x[[key]]
    x2$lower_dt <- lubridate::ymd_hms(x2$lower_dt)
    x2
}
