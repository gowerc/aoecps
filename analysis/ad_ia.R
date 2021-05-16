pkgload::load_all()
library(dplyr)
library(dbplyr)
library(DBI)
library(tidyr)
library(stringr)
library(assertthat)
library(lubridate)
library(forcats)


con <- get_connection()


meta <- get_game_meta()


meta_civ <- meta %>% 
    filter(type == "civ") %>% 
    select(mversion = version, civ = id, civ_name = string)


meta_map <- meta %>% 
    filter(type == "map_type") %>% 
    select(mversion = version, map_type = id, map_name = string)


keep_matches <- tbl(con, "match_meta") %>%
    filter(leaderboard_id == 3, ranked) %>%
    select(match_id, map_type, version)


dat <- tbl(con, "match_players") %>%
    select(match_id, rating, civ, won, slot, profile_id) %>%
    inner_join(keep_matches, by = "match_id") %>%
    collect()


sum_not_na <- function(x) sum(!is.na(x))


valid_players <- dat %>%
    group_by(match_id) %>%
    tally() %>%
    filter(n == 2)


valid_rating <- dat %>%
    group_by(match_id) %>%
    summarise(n_na = sum_not_na(rating)) %>% 
    filter(n_na == 2)


dat2 <- dat %>%
    semi_join(valid_players, by = "match_id") %>% 
    semi_join(valid_rating, by = "match_id") %>% 
    mutate(mversion = get_meta_version(started)) %>%
    left_join(meta_civ, by = c("civ", "mversion")) %>%
    left_join(meta_map, by = c("map_type", "mversion")) %>%
    mutate(version = if_else(is.na(version), "Unknown", version)) %>%
    filter(map_name == "Arabia")


slot_meta <- dat2 %>%
    filter(slot == 1) %>%
    select(match_id, map_name, version)


slot1 <- dat2 %>%
    filter(slot == 1) %>%
    select(
        s1_rating = rating,
        s1_civ = civ_name,
        s1_won = won,
        s1_id = profile_id,
        match_id
    )


slot2 <- dat2 %>%
    filter(slot == 2) %>%
    select(
        s2_rating = rating,
        s2_civ = civ_name,
        s2_won = won,
        s2_id = profile_id,
        match_id
    )


adat <- slot1 %>%
    inner_join(slot2, by = "match_id") %>%
    left_join(slot_meta, by = "match_id") %>%
    mutate(
        delo = (s1_rating - s2_rating) / 25,
        p1_result = as.numeric(s1_won)
    )


assert_that(
    nrow(adat) == nrow(slot1),
    nrow(adat) == nrow(slot2)
)


adat2 <- adat %>% 
    filter(s1_civ != s2_civ)  %>%
    filter(!is.na(s1_rating) & !is.na(s2_rating)) %>% 
    mutate(ANLFL = s1_rating >= 1200 & s2_rating >= 1200)


saveRDS(
    object = adat2,
    file = "./data/ia.Rds"
)


max_date <- tbl(con, "match_meta") %>% 
    summarise(m = max(started, na.rm = TRUE)) %>% 
    pull(m) %>% 
    as_datetime()


min_date <- tbl(con, "match_meta") %>% 
    summarise(m = min(started, na.rm = TRUE)) %>% 
    pull(m) %>% 
    as_datetime()
    
solo_meta <- list(
    db_min = min_date,
    db_max = max_date,
    n_db = as.numeric(tbl(con, "match_meta") %>% tally() %>% pull(n)),
    n_solo = as.numeric(tbl(con, "match_meta") %>% filter(leaderboard_id == 3, ranked) %>% tally() %>% pull(n)),
    n_valid_solo = adat2 %>% filter(ANLFL) %>% distinct(match_id) %>% nrow()
)

saveRDS(
    object = solo_meta, 
    file = "./data/ia_meta.Rds"
)
