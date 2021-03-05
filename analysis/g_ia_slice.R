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


get_slice <- function(y, dat){
    ub <- exp(log(y) + 0.1)
    lb <- exp(log(y) - 0.1)
    
    dat2 <- dat %>%
        filter(elo >= lb, elo <= ub) 
        
    tab <- dat2 %>%
        summarise(nelo = n(), pelo = mean(won)) %>%
        mutate(y = y) 
    
    gdat <- dat2 %>%
        group_by(civ) %>%
        summarise(n = n(), p = mean(won)) %>%
        ungroup() %>%
        mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb) %>% 
        left_join(tab, by = "y")
    return(gdat)
}

cuts <- seq(
    from = signif(min(dat2$elo), 2),
    to = signif(max(dat2$elo), 2),
    by = 10
)


res <- map_df(cuts, get_slice, dat = dat2) 

res2 <- res %>%
    filter(limit_lower >= min(dat2$elo), limit_upper <= max(dat2$elo)) %>%
    mutate(
        p_adj = p - pelo,
        plci_adj = plci - pelo,
        puci_adj = puci - pelo
    )
    

# res2 %>%
#     select(
#         elo = y, 
#         n = nelo, 
#         p = pelo, 
#         elo_lower_limit = limit_lower,
#         elo_upper_limit = limit_upper
#     ) %>% 
#     distinct() %>%
#     filter(elo %in% seq(700, 2800, by = 100))
    


footnotes <- c(
    "Win rates are calculated at each point X after filtering the data to",
    "only include matches where log(x) - 0.1 <= log(x) <= log(x) + 0.1<br/>",
    "All matches where both players have a known ELO > 800 are considered"
) %>%
    as_footnote()


p <- ggplot(data = res2, aes(ymin = plci_adj, ymax = puci_adj, x = y, group = civ, col = civ, fill = civ)) +
    geom_ribbon() +
    geom_hline(yintercept = 0, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(4)) +
    scale_x_continuous(breaks = pretty_breaks(4)) +
    ggtitle("Difference in Civilisation Win Rate from the Mean by ELO") + 
    ylab("Win Rate Delta") +
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
    height = 6,
    width = 9
)




