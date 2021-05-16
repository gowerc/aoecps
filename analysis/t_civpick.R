pkgload::load_all()
library(dplyr)
library(purrr)
library(ggplot2)
library(scales)
library(tidyr)


dat <- readRDS("./data/ia.Rds") %>%
    filter(ANLFL) 


dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, id = s1_id),
    dat %>% select(civ = s2_civ, id = s2_id)
)

games <- dat2 %>% 
    group_by(id) %>% 
    tally()

ggplot(data = games, aes(x = n)) + 
    geom_histogram() + 
    scale_x_continuous(breaks = pretty_breaks(10), trans = "log")

