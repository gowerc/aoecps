#' @import dplyr

#' @export
get_meta_version <- function(start_dt){
    case_when(
        start_dt <= ymd_hms("2021-8-09T00-00-00") ~ "A",
        start_dt >= ymd_hms("2021-8-11T00-00-00") ~ "B",
        TRUE ~ "ZZZ"
    )
}


#' @export 
logit <- function(x){
    log(x / (1 - x))
}


#' @export 
invlogit <- function(x){
    exp(x)/(1+exp(x))
}


#' @export 
as_footnote <- function(x, width = 140){
    x %>%
        paste(collapse = " ") %>%
        stringr::str_split("<br/>") %>%
        purrr::flatten_chr() %>%
        stringr::str_trim() %>% 
        stringr::str_wrap(width = width) %>%
        paste(collapse = "\n")
}


#' @export 
save_plot <- function(plot, filename, height = 5.5 , width = 8, ...){
    ggsave(    
        plot = plot,
        filename = filename,
        height = height,
        width = width,
        ...
    )
}

#' @export
get_map_class <- function(){
    x <- yaml::read_yaml("./data-raw/map_class.yml")
    tibble(
        map_name = names(unlist(x)),
        map_class = unlist(x)
    )
}
