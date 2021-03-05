#' @import dplyr

#' @export 
version_map <- function(x){
    case_when(
        x == "45185" ~ "45340",
        x == "44834" ~ "45340",
        x == "45340" ~ "45340",
        TRUE ~ x
    )
}


#' @export 
civmap <- function(x) {
    con <- get_connection()
    
    metaciv <- tbl(con, "game_meta") %>%
        filter(type == "civ") %>%
        select(version, civ = id, civ_name = string) %>%
        collect()
    
    DBI::dbDisconnect(con)
        
    d <- metaciv %>%
        filter(version == max(version)) %>%
        arrange(civ) %>%
        mutate(civ = civ + 1)
    
    if( is.character(x)){
        y <- d$civ
        names(y) <- d$civ_name
        return(unname(y[x]))
    } 
    if( is.numeric(x)){
        y <- d$civ_name
        names(y) <- d$civ
        return(unname(y[x]))
    } 
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
#' @import readr
get_civclass <- function() {
    civclass <- read_csv(
        file = "./data/raw/civclass.csv",
        col_types = readr::cols(
            civ = readr::col_character(),
            infantry = readr::col_character(),
            monk = readr::col_character(),
            cavalry = readr::col_character(),
            naval = readr::col_character(),
            archer = readr::col_character(),
            elephant = readr::col_character(),
            defensive = readr::col_character(),
            siege = readr::col_character(),
            camel = readr::col_character(),
            gunpowder = readr::col_character(),
            `cavalry archer` = readr::col_character()
        )
    ) %>%
        mutate(across(-matches("civ"), function(x) !is.na(x)))
    return(civclass)
}


#' @export
#' @import readr
get_civunit <- function() {
    civunit <- read_csv(
        file = "./data/raw/civunit.csv",
        col_types = cols(
            civ = col_character(),
            Arbalester = col_character(),
            `Hand Cannoneer` = col_character(),
            `Heavy Cavalry Archer` = col_character(),
            Champion = col_character(),
            Halberdier = col_character(),
            `Elite Eagle Warrior` = col_character(),
            Hussar = col_character(),
            Paladin = col_character(),
            `Heavy Camel` = col_character(),
            `Battle Elephant` = col_character(),
            `Steppe Lancer` = col_character(),
            `Siege Ram` = col_character(),
            `Siege Onager` = col_character(),
            `Heavy Scorpion` = col_character(),
            `Bombard Cannon` = col_character()
        )
    ) %>%
        mutate(across(-matches("civ"), function(x) !is.na(x)))
    return(civunit)
}   



#' @export 
as_footnote <- function(x, width = 130){
    x %>%
        paste(collapse = " ") %>%
        stringr::str_split("<br/>") %>%
        purrr::flatten_chr() %>%
        stringr::str_trim() %>% 
        stringr::str_wrap(width = width) %>%
        paste(collapse = "\n")
}

