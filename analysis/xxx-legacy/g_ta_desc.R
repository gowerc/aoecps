pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(stringr)
library(forcats)
library(tidyr)
library(ggrepel)

dat <- readRDS("./data/ta.Rds") %>%
    filter(ANLFL) %>%
    mutate(elo = rating)




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
    mutate(p = n / sum(n) * 100)

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
        



p <- ggplot(pdat, aes(x = elocat, y = p)) +
    geom_bar(stat = "identity") +
    theme_bw() +
    ylab("Percentage") +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
    scale_x_discrete(expand = expansion(c(0, 0.06))) +
    xlab("Elo") +
    annotate(
        geom = "text",
        label = strings,
        x = max(as.numeric(pdat$elocat)),
        y = Inf,
        hjust = 1,
        vjust = 1.1
    ) +
    theme(
        axis.text.x = element_text(hjust = 1, angle = 35),
        plot.caption = element_text(hjust = 0)
    )



save_plot(
    plot = p,
    filename = "./outputs/g_ta_desc_ELODIST.png"
)




#######################################
#
# Hist plot of Patch version
#
#######################################

vdat <- dat %>%
    distinct(match_id, version)


p <- ggplot(data = vdat, aes(x = version)) +
    geom_bar() +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
    xlab("Patch Version") +
    ylab("Number of Games") 

save_plot(
    plot = p,
    filename = "./outputs/g_ta_desc_VERDIST.png"
)




#######################################
#
# Naive Win rates
#
#######################################


wrdat <- dat %>%
    mutate(civ = civ_name) %>% 
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
    filename = "./outputs/g_ta_desc_WR.png"
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
    filename = "./outputs/g_ta_desc_PR.png"
)

saveRDS(
    object = prdat %>%
        mutate(civ = as.character(civ)) %>%
        select(civ, n, pr),
    file = "./data/ta_pr.Rds"
)



