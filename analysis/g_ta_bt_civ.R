pkgload::load_all()
library(ggplot2)
library(dplyr)
library(tidyr)
library(assertthat)
library(forcats)
library(scales)
library(ggrepel)

adat <- readRDS("./data/ta.Rds") %>%
    filter(ANLFL)

civ_levels <- adat %>%
    pull(civ_name) %>%
    fct_relevel("Vikings") %>%
    levels()


adat_wide <- adat %>%
    select(civ_name, team, match_id) %>%
    group_by(civ_name, match_id, team) %>%
    tally() %>%
    spread(civ_name, n) %>%
    ungroup()

result <- adat %>%
    filter(team == 1) %>%
    arrange(match_id) %>%
    distinct(match_id, won) %>% 
    pull(won) %>%
    as.numeric()

elo_delta <- adat %>% 
    group_by(match_id, team) %>% 
    mutate(team = paste0("team", team)) %>% 
    summarise(melo = mean(rating)) %>% 
    spread(team, melo) %>% 
    mutate( delo = (team1 - team2)/25) %>% 
    arrange(match_id) %>% 
    pull(delo)

replace_na_0 <- function(x) replace_na(x, 0)

sdat <- adat_wide %>%
    mutate(across(where(is.numeric), replace_na_0)) %>%
    arrange(match_id, team)


team_1 <- sdat %>% filter(team == 1)
team_2 <- sdat %>% filter(team == 2)

assert_that(
    nrow(team_1) == nrow(team_2),
    all(team_1$match_id %in% team_2$match_id),
    nrow(team_1) == length(result),
    nrow(team_1) == length(elo_delta)
)

team_1_c <- team_1 %>% select(-match_id, -team)
team_2_c <- team_2 %>% select(-match_id, -team)

team_1_mat <- model.matrix( ~ . -1 , data = team_1_c)
team_2_mat <- model.matrix( ~ . -1 , data = team_2_c)

dmat <- team_1_mat - team_2_mat

mdat <- as_tibble(dmat) %>%
    mutate( result = result) %>% 
    mutate( delo = elo_delta) %>% 
    select(-Vikings)

mod <- glm(
    family = binomial(),
    formula = result ~ . -1,
    data = mdat
)


est <- c(0, coef(mod))
se <- c(0, sqrt(diag(vcov(mod))))

dat <- tibble(
    name = c(civ_levels, "ELO Delta (25)"),
    est = est,
    se = se,
    lci = est - 1.96 * se,
    uci = est + 1.96 * se
) %>%
    arrange(desc(est)) %>%
    mutate(name = fct_inorder(name))

saveRDS(
    object = dat, 
    file = "data/ta_bt_civ.Rds"
)



performance_mid <- dat %>%
    filter(name != "ELO Delta (25)") %>%
    pull(est) %>%
    median()

performance_upper <- performance_mid + logit(0.55)
performance_lower <- performance_mid + logit(0.45)


footnotes <- c(
    "Performance scores represent the relative difference from the reference civilisation (Vikings)<br/>",
    "The solid red line represents the median performance score across all civilisations"
) %>%
    as_footnote()


p <- ggplot(data = dat, aes(x = name, group = name, ymin = lci, ymax = uci, y = est)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    geom_hline(yintercept = performance_mid, col = "red") +
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
    filename = "./outputs/g_ta_bt_civ.png"
)


#######################################
#
# BT Score vs Win Rates
#
#######################################

prdat <- readRDS("./data/ta_pr.Rds")


prdat2 <- dat %>%
    filter(name != "ELO Delta (25)") %>%
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
    filename = "./outputs/g_ta_bt_civ_PR.png"
)