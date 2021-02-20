#' @import dplyr

#' @export
get_wr <- function(dat){
    bind_rows(
        dat %>% select(civ = p1_civ, result = p1_won),
        dat %>% select(civ = p2_civ, result = p2_won)
    )  %>%
        group_by(civ) %>%
        summarise(
            n = n(),
            won = sum(result),
            p = mean(result)
        )
}

#' @export
get_bs_wr <- function(dat, index = NA){
    dat %>%
        sample_frac(size = 1, replace = TRUE) %>%
        get_wr() %>%
        mutate(index = index)
}
