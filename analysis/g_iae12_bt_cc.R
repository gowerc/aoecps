pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)


adat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL)

# adat <- adat %>% sample_n(6000)

civclass <- get_civclass()

s1dat <- adat %>%
    select(rating = s1_rating, civ = s1_civ) %>%
    mutate(rating = rating / 25) %>% 
    left_join(civclass, by = "civ") %>%
    select(-civ) %>%
    mutate(across(where(is.logical), as.numeric))

s2dat <- adat %>%
    select(rating = s2_rating, civ = s2_civ) %>%
    mutate(rating = rating / 25) %>%
    left_join(civclass, by = "civ") %>%
    select(-civ) %>%
    mutate(across(where(is.logical), as.numeric))



team_a_mat <- model.matrix(~ -1 + ., data = s1dat)
team_b_mat <- model.matrix(~ -1 + ., data = s2dat)

stopifnot(
    nrow(team_a_mat) == nrow(team_b_mat),
    ncol(team_a_mat) == ncol(team_b_mat)
)

diff_mat <- team_a_mat - team_b_mat

ddat <- as_tibble(diff_mat) %>%
    mutate(result = adat$s1_won) 

mod <- glm(
    family = binomial(),
    formula = result ~ . -1,
    data = ddat
)

est <- coef(mod)
se <- sqrt(diag(vcov(mod)))



dat <- tibble(
    name = c("ELO Delta (25)", str_to_title(colnames(civclass)[-1])),
    est = est,
    se = se,
    lci = est - 1.96 * se,
    uci = est + 1.96 * se
) %>%
    arrange(desc(est)) %>%
    mutate(name = fct_inorder(name))


performance_mid <- dat %>%
    filter(name != "ELO Delta (25)") %>%
    pull(est) %>%
    mean()



footnotes <- c(
    "Performance scores represent the relative difference from the reference civilisation (Vikings).<br/>",
    "The red line represents the median performance score across all civilisations."
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
    filename = "./outputs/g_iae12_bt_cc.png"
)

