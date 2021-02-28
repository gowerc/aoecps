pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(forcats)
library(stringr)
library(purrr)


dat <- readRDS("./data/iae12.Rds") %>%
    filter(s1_rating >= 600 & s2_rating >= 600)

dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, won = s1_won, elo = s1_rating),
    dat %>% select(civ = s2_civ, won = s2_won, elo = s2_rating)
) %>%
    mutate(elo = as.numeric(elo)) %>% 
    mutate(elo = if_else(elo >= 2200, 2200, elo))


get_slice <- function(y, dat, spread){
    ub <- y + spread
    lb <- y - spread
    
    dat %>%
        filter(elo >= lb, elo <= ub) %>%
        group_by(civ) %>%
        summarise(n = n(), p = mean(won)) %>%
        ungroup() %>%
        mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(pr = (n / sum(n)) * 100) %>%
        mutate(y = y)
}

spread = 150

cuts <- seq(
    from = signif(min(dat2$elo), 2),
    to = signif(max(dat2$elo), 2),
    by = 10
)

cuts <- cuts[
    (cuts - spread) >= min(dat2$elo) &
    (cuts + spread) <= max(dat2$elo)
]

res <- map_df(cuts, get_slice, dat = dat2, spread = spread) 

footnotes <- c(
    "Win rates are calculated at each point X after filtering the data using",
    "a +- 150 ELO margin. ELOs > 2200 have been set to 2200 to avoid",
    "spurious results.",
    "All matches have been included where both players have a known ELO > 600"
) %>%
    paste0(collapse = " ") %>%
    str_split("\\.") %>%
    flatten_chr() %>%
    paste0(".") %>% 
    str_trim() %>%
    str_wrap(width = 110) %>%
    paste0(collapse = "\n")


p <- ggplot(data = res, aes(ymin = plci, y = p, ymax = puci, x = y, group = civ, col = civ, fill = civ)) +
    geom_ribbon() +
    geom_hline(yintercept = 0.5, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(3)) +
    scale_x_continuous(breaks = pretty_breaks(3)) +
    ylab("Win Rate") +
    xlab("ELO") +
    facet_wrap(~civ) + 
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)


ggsave(
    filename = "./outputs/g_ia_slice.png",
    plot = p,
    height = 7,
    width = 7
)




