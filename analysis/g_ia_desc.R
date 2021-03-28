pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(stringr)
library(forcats)
library(tidyr)
library(ggrepel)

dat <- readRDS("./data/ia.Rds") %>%
    filter(ANLFL) %>%
    mutate(elo = (s1_rating + s2_rating) / 2)




#######################################
#
# Hist plot of ELo counts
#
#######################################


cuts <- seq(min(dat$elo), max(dat$elo) + 100, by = 100)

pdat <- dat %>%
    mutate(elocat = cut(elo, cuts, right = FALSE, dig.lab = 4)) %>%
    group_by(elocat) %>%
    tally() %>%
    mutate(p = round(n / sum(n) * 100,2) %>% paste0("%")) %>%
    mutate(y = n + max(n) * 0.025)

strings <- dat %>%
    summarise(
        min = min(elo),
        lq = quantile(elo, 0.25),
        med = quantile(elo, 0.5),
        mean = mean(elo),
        uq = quantile(elo, 0.75),
        max = max(elo)
    ) %>%
    pivot_longer(everything()) %>%
    mutate(string = sprintf( "%s = %4.0f", name, value) %>% str_pad(width = 12)) %>%
    pull(string) %>%
    paste0(collapse = "\n")
        


footnotes <- c(
    "ELO is calculated as the mean of the two players in the match"
) %>%
    as_footnote()


p <- ggplot(pdat, aes(x = elocat, y = n)) +
    geom_bar(stat = "identity") +
    theme_bw() +
    ylab("Count") +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
    scale_x_discrete(expand = expansion(c(0, 0.06))) +
    xlab("ELO") +
    annotate(
        geom = "text",
        label = strings,
        x = max(as.numeric(pdat$elocat)),
        y = Inf,
        hjust = 1,
        vjust = 1.1
    ) +
    geom_text(aes(y = y, label = p), hjust = 0.2, angle = 35)+ 
    theme(
        axis.text.x = element_text(hjust = 1, angle = 35),
         plot.caption = element_text(hjust = 0)
    ) + 
    labs( caption = footnotes)



save_plot(
    plot = p,
    filename = "./outputs/g_ia_desc_ELODIST.png"
)




#######################################
#
# Hist plot of Patch version
#
#######################################



p <- ggplot(data = dat, aes(x = version)) +
    geom_bar() +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
    xlab("Patch Version") +
    ylab("Number of Games") 

save_plot(
    plot = p,
    filename = "./outputs/g_ia_desc_VERDIST.png"
)




#######################################
#
# Naive Win rates
#
#######################################


dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, won = s1_won, elo = s1_rating), 
    dat %>% select(civ = s2_civ, won = s2_won, elo = s2_rating)
)

wrdat <- dat2 %>%
    group_by(civ) %>%
    summarise(n = n(), p = mean(won)) %>%
    ungroup() %>%
    mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
    mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>% 
    mutate(pr = (n / sum(n)) * 100)

wrdat2 <- wrdat %>%
    arrange(desc(p)) %>%
    mutate(civ = fct_inorder(civ))

p <- ggplot(data = wrdat2, aes(ymin = plci, y = p, ymax = puci, x = civ)) +
    geom_point() +
    geom_errorbar() +
    geom_hline(yintercept = 0.5, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    ylab("Win Rate") +
    xlab("")


save_plot(
    plot = p,
    filename = "./outputs/g_ia_desc_WR.png"
)


#######################################
#
# Play Rates
#
#######################################


prdat <- wrdat %>%
    arrange(desc(n)) %>%
    mutate(civ = fct_inorder(civ)) 

p <- ggplot(data = prdat, aes(y = pr, x = civ)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 1 / nrow(prdat) * 100, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    ylab("Play Rate (%)") +
    xlab("") 


save_plot(
    plot = p,
    filename = "./outputs/g_ia_desc_PR.png"
)

saveRDS(
    object = prdat %>%
        mutate(civ = as.character(civ)) %>%
        select(civ, n, pr),
    file = "./data/ia_pr.Rds"
)



