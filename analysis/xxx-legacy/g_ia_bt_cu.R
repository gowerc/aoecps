pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)
library(tidyr)


adat <- readRDS("./data/ia.Rds") %>%
    filter(ANLFL)

mapdat <- read_csv(
    file = "./data-raw/civ_unit_map.csv",
    col_types = cols(
        .default = col_character()
    )
) %>%
    pivot_longer(names_to = "civ", values_to = "flag", -name) %>%
    mutate(flag = if_else(!is.na(flag), 1, 0)) %>%
    pivot_wider(names_from = "name", values_from = "flag")


s1dat <- adat %>%
    select(rating = s1_rating, civ = s1_civ) %>%
    mutate(rating = rating / 25) %>% 
    left_join(mapdat, by = "civ") %>%
    select(-civ)


s2dat <- adat %>%
    select(rating = s2_rating, civ = s2_civ) %>%
    mutate(rating = rating / 25) %>%
    left_join(mapdat, by = "civ") %>%
    select(-civ)


team_a_mat <- model.matrix(~   rating  + . , data = s1dat)[,-1]
team_b_mat <- model.matrix(~   rating  + . , data = s2dat)[,-1]

stopifnot(
    nrow(team_a_mat) == nrow(team_b_mat),
    ncol(team_a_mat) == ncol(team_b_mat)
)

diff_mat <- team_a_mat - team_b_mat

mdat <- as_tibble(diff_mat) %>%
    mutate( result = adat$s1_won) 

mod <- glm(
    family = binomial(),
    formula = result ~ . -1,
    data = mdat
)

est <- coef(mod)
se <- sqrt(diag(vcov(mod)))

dat <- tibble(
    name = c("Elo Delta (25)", colnames(mapdat)[-1]),
    est = est,
    se = se,
    lci = est - 1.96 * se,
    uci = est + 1.96 * se
) %>%
    arrange(desc(est)) %>%
    mutate(name = fct_inorder(name))


footnotes <- c(
    "Performance scores represent the relative difference from",
    "a hypothetical civilisation that doesn't have any specilisation"
) %>%
    as_footnote()

p <- ggplot(data = dat, aes(x = name, group = name, ymin = lci, ymax = uci, y = est)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    ylab("Performance Score Delta") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    labs( caption = footnotes)


save_plot(
    plot = p,
    filename = "./outputs/g_ia_bt_cu.png"
)
