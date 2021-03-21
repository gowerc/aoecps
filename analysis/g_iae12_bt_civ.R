pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)


adat <- readRDS("./data/iae12.Rds") %>%
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
    name = c(civ_levels, "ELO Delta (25)"),
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
    "The Y-axis represents the difference in the performance",
    "rating from the reference civilisation (Vikings).<br/>",
    "The red line represents the mean performance rating across all",
    "civilisations."
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


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_bt_civ.png",
    height = 6,
    width = 9
)

