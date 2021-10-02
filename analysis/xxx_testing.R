
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(lubridate)
library(stringr)
library(forcats)

devtools::load_all()


players <- readRDS("./data/ad_players.Rds")
pre_matchmeta <- readRDS("./data/ad_matchmeta.Rds")

# "Team Random Map" 
# "1v1 Random Map"  
# "1v1 Empire Wars"
# "Team Empire Wars"



matchmeta <- pre_matchmeta %>%
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 1200,
        map_class == "Open",
        leaderboard_name == "1v1 Random Map"
    )

wr_naive <- data_wr_naive(matchmeta, players)
wr_avg <- data_wr_avg(matchmeta, players)
pr <- data_pr(matchmeta, players)

plot_wr_naive(wr_naive)
plot_wr_avg(wr_avg)
plot_pr(pr)



matchmeta <- pre_matchmeta %>% 
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 1200,
        map_class == "Closed",
        leaderboard_name == "1v1 Random Map"
    )
players <- pre_players %>% semi_join(matchmeta, by= "match_id")
x <- get_wr_naive_data(matchmeta, players)
get_wr_naive_plot(x)


matchmeta <- pre_matchmeta %>% 
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 2000,
        map_class == "Open",
        leaderboard_name == "Team Random Map"
    )
players <- pre_players %>% semi_join(matchmeta, by= "match_id")
x <- get_wr_naive_data(matchmeta, players)
get_wr_naive_plot(x)


matchmeta <- pre_matchmeta %>% 
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 2000,
        map_class == "Closed",
        leaderboard_name == "Team Random Map"
    )
players <- pre_players %>% semi_join(matchmeta, by= "match_id")
x <- get_wr_naive_data(matchmeta, players)
get_wr_naive_plot(x)



matchmeta <- pre_matchmeta %>% 
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 1200,
        leaderboard_name == "1v1 Empire Wars"
    )
players <- pre_players %>% semi_join(matchmeta, by= "match_id")
x <- get_wr_naive_data(matchmeta, players)
get_wr_naive_plot(x)



matchmeta <- pre_matchmeta %>% 
    filter(
        start_dt >= ymd_hms("2021-08-20 01:00:00"),
        rating_min >= 1200,
        leaderboard_name == "Team Empire Wars"
    )
players <- pre_players %>% semi_join(matchmeta, by= "match_id")
x <- get_wr_naive_data(matchmeta, players)
get_wr_naive_plot(x)



