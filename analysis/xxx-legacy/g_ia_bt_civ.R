pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)
library(ggrepel)


adat <- readRDS("./data/ia.Rds") %>%
    filter(ANLFL)


civ_levels <- adat %>%
    pull(s1_civ) %>%
    fct_relevel("Vikings") %>%
    levels()


adat2 <- adat %>%
    mutate(s1_civ = factor(s1_civ, levels = civ_levels)) %>%
    mutate(s2_civ = factor(s2_civ, levels = civ_levels)) %>%
    mutate(s1_rating = s1_rating / 25) %>%
    mutate(s2_rating = s2_rating / 25)


team_a_mat <- model.matrix(~ s1_civ + s1_rating, data = adat2)[,-1]
team_b_mat <- model.matrix(~ s2_civ + s2_rating, data = adat2)[,-1]


stopifnot(
    nrow(team_a_mat) == nrow(team_b_mat),
    ncol(team_a_mat) == ncol(team_b_mat)
)


diff_mat <- team_a_mat - team_b_mat


mdat <- as_tibble(diff_mat) %>%
    mutate( result = adat2$s1_won)


mod <- glm(
    family = binomial(),
    formula = result ~ . -1,
    data = mdat
)


est <- c(0, coef(mod))
se <- c(0, sqrt(diag(vcov(mod))))


dat <- tibble(
    name = c(civ_levels, "Elo Delta (25)"),
    est = est,
    se = se,
    lci = est - 1.96 * se,
    uci = est + 1.96 * se
) %>%
    arrange(desc(est)) %>%
    mutate(name = fct_inorder(name))


saveRDS(
    object = dat, 
    file = "data/ia_bt_civ.Rds"
)



performance_mid <- dat %>%
    filter(name != "Elo Delta (25)") %>%
    pull(est) %>%
    median()

performance_upper <- performance_mid + logit(0.55)
performance_lower <- performance_mid + logit(0.45)


footnotes <- c(
    "Performance scores represent the relative difference from the reference civilisation (Vikings)<br/>",
    "The solid red line represents the median performance score across all civilisations<br/>",
    "The dashed lines represent scores that have a 45% and 55% chance of beating the median score"
) %>%
    as_footnote()

p <- ggplot(data = dat, aes(x = name, group = name, ymin = lci, ymax = uci, y = est)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    geom_hline(yintercept = performance_mid, col = "red") +
    geom_hline(yintercept = c(performance_upper,performance_lower), lty = 2, col = "red") +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs( caption = footnotes) + 
    ylab("Performance Score Delta") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10))
    


save_plot(
    plot = p,
    filename = "./outputs/g_ia_bt_civ.png"
)




#######################################
#
# BT Score vs Win Rates
#
#######################################

prdat <- readRDS("./data/ia_pr.Rds")


prdat2 <- dat %>%
    filter(name != "Elo Delta (25)") %>%
    mutate(civ = name) %>% 
    left_join(prdat, by = "civ")


footnotes <- c(
    "Performance scores represent the relative difference from the reference civilisation (Vikings)<br/>",
    "The vertical reference line represents the median performance score across all civilisations<br/>",
    "The horizontal reference line represents the expected play rate if civilisations were chosen randomly"
) %>%
    as_footnote()

p2 <- ggplot(data = prdat2, aes(x = est, y = pr, label = name)) +
    geom_point() +
    geom_vline(xintercept = performance_mid, col = "red") +
    geom_hline(yintercept = 1 / nrow(prdat2) * 100, alpha = 0.6, col = "red") +
    geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) + 
    xlab("Performance Score Delta") +
    ylab("Play Rate (%)") +
    scale_x_continuous(breaks = pretty_breaks(10)) +
    scale_y_continuous(breaks = pretty_breaks(10))

save_plot(
    plot = p2,
    filename = "./outputs/g_ia_bt_civ_PR.png"
)