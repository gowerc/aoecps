pkgload::load_all()
library(ggplot2)
library(scales)
library(dplyr)
library(tidyr)
library(ggrepel)

idat <- readRDS("./data/ia_pr.Rds") %>%
    select(civ, ipr = pr)


tdat <- readRDS("./data/ta_pr.Rds") %>%
    select(civ, tpr = pr)


dat <- idat %>%
    left_join(tdat, by = "civ")


p <- ggplot(dat, aes(x = ipr, y = tpr, label = civ)) +
    geom_point() +
    theme_bw() +
    scale_x_continuous(breaks = pretty_breaks(10), trans = "log") +
    scale_y_continuous(breaks = pretty_breaks(10), trans = "log") +
    geom_vline(xintercept = 1/nrow(dat) * 100, col = "red") +
    geom_hline(yintercept = 1/nrow(dat) * 100, col = "red") +
    geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
    ylab("Teams Play Rate (%)") +
    xlab("Solo Play Rate (%)")


save_plot(
    filename = "outputs/g_pr.png",
    plot = p
)

