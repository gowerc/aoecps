# Analysis Dataset Team Arabia ELO > 1200  (Ia)
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
    select(mversion = version, civ = id, civ_name = string)


meta_map <- meta %>% 
    filter(type == "map_type") %>% 
    select(mversion = version, map_type = id, map_name = string)


map_numbers <- meta_map %>%
    filter(map_name == "Arabia") %>%
    pull(map_type)


keep_matches <- tbl(con, "match_meta") %>%
    filter(leaderboard_id == 4, ranked) %>%
    filter(map_type %in% map_numbers) %>% 
    select(match_id, map_type, version)


dat <- tbl(con, "match_players") %>%
    select(match_id, rating, civ, won, slot, team) %>%
    inner_join(keep_matches, by = "match_id") %>% 
    collect()


dat2 <- dat %>%
    mutate(mversion = get_meta_version(started)) %>%
    left_join(meta_civ, by = c("civ", "mversion")) %>%
    left_join(meta_map, by = c("map_type", "mversion")) %>%
    filter(map_name == "Arabia") %>%
    select(-civ, -map_type, -mversion)


no_rating <- dat2 %>%
    filter(is.na(rating)) %>%
    pull(match_id) %>%
    unique()

elo_allow <- dat2 %>%
    group_by(match_id) %>%
    summarise(m = min(rating)) %>%
    filter(!is.na(m) & m >= 1400)


dat3 <- dat2 %>%
    filter(!match_id %in% no_rating) %>% 
    mutate(ANLFL = match_id %in% elo_allow$match_id)


saveRDS(
    object = dat3,
    file = "./data/ta.Rds"
)


team_meta <- list(
    n_db = as.numeric(tbl(con, "match_meta") %>% tally() %>% pull(n)),
    n_team = as.numeric(tbl(con, "match_meta") %>% filter(leaderboard_id == 4, ranked) %>% tally() %>% pull(n)),
    n_valid_team = dat3 %>% filter(ANLFL) %>% distinct(match_id) %>% nrow()
)

saveRDS(
    object = team_meta, 
    file = "./data/ta_meta.Rds"
)





