pkgload::load_all()
library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)
library(ggrepel)

solo <- readRDS(file = "data/iae12_bt_civ.Rds") %>%
    select(name, solo = est)

team <- readRDS(file = "data/tae12_bt_civ.Rds") %>%
    select(name, team = est)


dat <- solo %>%
    left_join(team, by = "name") %>%
    mutate(name = as.character(name)) %>%
    mutate(solo = as.numeric(solo)) %>%
    mutate(team = as.numeric(team)) 


ref <- dat %>%
    filter(name != "ELO Delta (25)") %>%
    gather(KEY, VAL, -name) %>%
    group_by(KEY) %>%
    summarise(m = median(VAL))

solo_ref <- ref %>%
    filter(KEY == "solo") %>%
    pull(m)

team_ref <- ref %>%
    filter(KEY == "team") %>%
    pull(m)


footnotes <- c(
    "Performance scores represent the relative difference from the reference civilisation (Vikings).<br/>",
    "The red line represents the median performance score across all civilisations."
) %>%
    as_footnote()

p <- ggplot(data = dat, aes(x = solo, y = team, label = name)) +
    geom_point() +
    theme_bw() +
    geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
    scale_x_continuous(breaks = pretty_breaks(10)) +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    geom_hline(yintercept = team_ref, col = "red", alpha = 0.6) +
    geom_vline(xintercept = solo_ref, col = "red", alpha = 0.6) +
    xlab("Solo Games") +
    ylab("Team Games") +
    theme(plot.caption = element_text(hjust = 0)) +
    labs( caption = footnotes)


save_plot(
    plot = p,
    filename = "./outputs/g_ae12_bt_civ.png"
)



