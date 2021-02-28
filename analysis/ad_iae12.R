## Analysis Dataset Individual Arabia ELO > 1200  (IAE12)

pkgload::load_all()
library(dplyr)
library(dbplyr)
library(DBI)
library(tidyr)
library(stringr)
library(assertthat)
library(forcats)

con <- get_connection()

meta <- tbl(con, "game_meta") %>% collect()

meta_civ <- meta %>% 
    filter(type == "civ") %>% 
    select(version, civ = id, civ_name = string)


meta_map <- meta %>% 
    filter(type == "map_type") %>% 
    select(version, map_type = id, map_name = string)


keep_matches <- tbl(con, "match_meta") %>%
    filter(leaderboard_id == 3, ranked) %>%
    select(match_id, map_type, version)


dat <- tbl(con, "match_players") %>%
    select(match_id, rating, civ, won, slot) %>%
    inner_join(keep_matches, by = "match_id") %>%
    collect()


dat2 <- dat %>%
    mutate(oversion = version) %>% 
    mutate(version = version_map(version)) %>%
    left_join(meta_civ, by = c("civ", "version")) %>%
    left_join(meta_map, by = c("map_type", "version")) %>%
    filter(map_name == "Arabia")


slot_meta <- dat2 %>%
    filter(slot == 1) %>% 
    select(match_id, map_name, version, oversion)


slot1 <- dat2 %>%
    filter(slot == 1) %>%
    select(
        s1_rating = rating,
        s1_civ = civ_name,
        s1_won = won,
        match_id
    )


slot2 <- dat2 %>%
    filter(slot == 2) %>%
    select(
        s2_rating = rating,
        s2_civ = civ_name,
        s2_won = won,
        match_id
    )


adat <- slot1 %>%
    inner_join(slot2, by = "match_id") %>%
    left_join(slot_meta, by = "match_id") %>%
    mutate(
        p1_civ = civmap(s1_civ),
        p2_civ = civmap(s2_civ),
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
    file = "./data/iae12.Rds"
)
