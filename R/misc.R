#' @import dplyr

#' @export 
get_meta_version <- function(started){
    case_when(
        TRUE ~ "A"
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

