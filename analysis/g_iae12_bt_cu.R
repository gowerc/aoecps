pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)


adat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL)


civunit <- get_civunit()


unit_levels <- civunit %>% 
    select(-civ) %>% 
    colnames()

s1dat <- adat %>%
    select(rating = s1_rating, civ = s1_civ) %>%
    mutate(rating = rating / 25) %>% 
    left_join(civunit, by = "civ") %>%
    mutate(across(where(is.logical), as.numeric)) %>% 
    select(-civ)

s2dat <- adat %>%
    select(rating = s2_rating, civ = s2_civ) %>%
    mutate(rating = rating / 25) %>%
    left_join(civunit, by = "civ") %>%
    mutate(across(where(is.logical), as.numeric)) %>% 
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
    name = c("ELO Delta (25)", unit_levels),
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
    "score from the a hypotherical civilisation which has no access to any of the given units<br/>",
    "The red line represents the mean performance rating across all of the given units"
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
    ggtitle("Bradley-Terry Performance Scores By Unit") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    labs( caption = footnotes)


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_bt_cu.png",
    height = 6,
    width = 9
)