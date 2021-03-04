pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(forcats)
library(stringr)
library(purrr)


dat <- readRDS("./data/iae12.Rds") %>%
    filter(s1_rating >= 800 & s2_rating >= 800)

dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, won = s1_won, elo = s1_rating),
    dat %>% select(civ = s2_civ, won = s2_won, elo = s2_rating)
) %>%
    mutate(elo = as.numeric(elo))


get_slice <- function(y, dat, spread = 0.1){
    ub <- exp(log(y) + 0.1)
    lb <- exp(log(y) - 0.1)
    
    dat %>%
        filter(elo >= lb, elo <= ub) %>%
        group_by(civ) %>%
        summarise(n = n(), p = mean(won)) %>%
        ungroup() %>%
        mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(pr = (n / sum(n)) * 100) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}

cuts <- seq(
    from = signif(min(dat2$elo), 2),
    to = signif(max(dat2$elo), 2),
    by = 20
)


res <- map_df(cuts, get_slice, dat = dat2, spread = spread) 

res2 <- res %>%
    filter(limit_lower >= min(dat2$elo), limit_upper <= max(dat2$elo))

footnotes <- c(
    "Win rates are calculated at each point X after filtering the data to",
    "only include matches where log(x) - 0.1 <= log(x) <= log(x) + 0.1<br/>",
    "All matches where both players have a known ELO > 800 are considered"
) %>%
    as_footnote()


p <- ggplot(data = res2, aes(ymin = plci, y = p, ymax = puci, x = y, group = civ, col = civ, fill = civ)) +
    geom_ribbon() +
    geom_hline(yintercept = 0.5, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(4)) +
    scale_x_continuous(breaks = pretty_breaks(4)) +
    ggtitle("Civilisation Win Rate by ELO") + 
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




