pkgload::load_all()
library(dplyr)
library(tidyr)

meta <- readRDS("./data/meta.Rds")


civs <- meta$civ %>%
    as_tibble() %>%
    mutate(string = str_trim(string))


dat <- list.files("./data", full.names = TRUE, pattern= "^results_") %>%
    map(readRDS) %>%
    bind_rows() %>%
    distinct()


dat2 <- dat %>%
    filter(ranked, leaderboard_id == 3) %>%
    select(match_id , players) %>%
    unnest(players) %>%
    select(match_id, slot, civ, won, rating) %>%
    mutate(slot = paste0("p", slot)) %>%
    filter(!is.na(civ))



p1 <- dat2 %>%
    filter(slot == "p1") %>%
    left_join(civs, by = c("civ" = "id")) %>%
    select(
        match_id,
        p1_civ = string,
        p1_won = won,
        p1_rating = rating
    )

p2 <- dat2 %>%
    filter(slot == "p2") %>%
    left_join(civs, by = c("civ" = "id")) %>%
    select(
        match_id,
        p2_civ = string,
        p2_won = won,
        p2_rating = rating
    )


dat3 <- left_join(p1, p2, by = "match_id") %>%
    filter( !is.na(p1_won), !is.na(p2_won))



# dat2 %>%
#     group_by(civ) %>%
#     tally() %>%
#     ungroup() %>%
#     mutate(p = n / sum(n) * 100) %>%
#     left_join(civs, by = c("civ" = "id")) %>%
#     arrange(p) %>%
#     select(civ = string, n , p) %>%
#     mutate( p = round(p,2)) %>%
#     knitr::kable()


# dat3 %>%
#     get_wr() %>%
#     select(civ, n, p) %>%
#     mutate(p = round(p,2)) %>%
#     knitr::kable()


saveRDS(
    object = dat3,
    file = "./data/ad_results.Rds"
)
