pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(stringr)
library(forcats)
library(tidyr)


dat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL) %>% 
    mutate(elo = (s1_rating + s2_rating)/ 2)


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
        



p <- ggplot(dat, aes(x = elo)) +
    geom_density(fill = "grey", alpha = 0.7) +
    theme_bw() +
    ylab("Density") +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.05))) +
    scale_x_continuous(breaks = pretty_breaks(10)) +
    xlab("ELO") +
    annotate( geom = "text", label = strings, x = 2600, y = Inf, hjust = 1, vjust = 1.1)


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_ELODIST.png",
    height = 6,
    width = 9
)



p <- ggplot(data = dat, aes(x = oversion)) +
    geom_bar() +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
    xlab("Patch Version") +
    ylab("Number of Games")

ggsave(
    plot = p,
    filename = "./outputs/g_iae12_VERDIST.png",
    height = 6,
    width = 9
)

dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, won = s1_won, elo = s1_rating), 
    dat %>% select(civ = s2_civ, won = s2_won, elo = s2_rating)
)

sdat <- dat2 %>%
    group_by(civ) %>%
    summarise(n = n(), p = mean(won)) %>%
    ungroup() %>%
    mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
    mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>% 
    mutate(pr = (n / sum(n)) * 100)

sdat2 <- sdat %>%
    arrange(desc(p)) %>%
    mutate(civ = fct_inorder(civ))

p <- ggplot(data = sdat2, aes(ymin = plci, y = p, ymax = puci, x = civ)) +
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


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_WR.png",
    height = 6,
    width = 9
)



sdat2 <- sdat %>%
    arrange(desc(n)) %>%
    mutate(civ = fct_inorder(civ))

p <- ggplot(data = sdat2, aes(y = pr, x = civ)) +
    geom_bar(stat = "identity") + 
    geom_hline(yintercept = 1/nrow(sdat2) * 100, col = "red") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.05))) +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    ylab("Play Rate") +
    xlab("")


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_PR.png",
    height = 6,
    width = 9
)

