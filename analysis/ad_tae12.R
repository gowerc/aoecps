# Analysis Dataset Team Arabia ELO > 1200  (IAE12)

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
    mutate(oversion = version) %>% 
    mutate(version = version_map(version)) %>%
    left_join(meta_civ, by = c("civ", "version")) %>%
    left_join(meta_map, by = c("map_type", "version")) %>%
    filter(map_name == "Arabia")

elo_allow <- dat2 %>%
    group_by(match_id) %>%
    summarise(m = mean(rating)) %>%
    filter(!is.na(m) & m >= 1500)

dat3 <- dat2 %>%
    mutate(ANLFL = match_id %in% elo_allow$match_id)

saveRDS(
    object = dat3,
    file = "./data/tae12.Rds"
)


team_meta <- list(
    n_db = as.numeric(tbl(con, "match_meta") %>% tally() %>% pull(n)),
    n_team = as.numeric(tbl(con, "match_meta") %>% filter(leaderboard_id == 4, ranked) %>% tally() %>% pull(n)),
    n_valid_team = dat3 %>% filter(ANLFL) %>% distinct(match_id) %>% nrow()
)

saveRDS(
    object = team_meta, 
    file = "./data/tae12_meta.Rds"
)





