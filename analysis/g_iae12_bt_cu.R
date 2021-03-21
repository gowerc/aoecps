pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)
library(tidyr)


adat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL)


civunit <- get_civunit()

civunit <- read_csv(file = "./data/raw/civunit2.csv")


units <- civunit %>%
    transmute(
        civ = civ,
        archer = archer > 3 | (archer == 3 & range_attack == 3  & archer_armor == 3),
        skirmisher = skirmisher > 2,
        cannoneer = cannoneer,
        cavarcher = cavarcher > 2 | (cavarcher == 2 & range_attack == 3 & bloodlines == 1),
        militia = militia > 5 | (militia == 5 & infantry_armor == 3 & melee_attack == 3),
        spearman = spearman > 3 | (spearman == 3 & infantry_armor == 3 & melee_attack == 3),
        knights = knights > 2,
        eagles = eagles > 1, 
        scouts = (horse_armor==3) & ((scouts == 2 & bloodlines == 1 ) | (scouts == 3)) ,
        camels = camels >= 2,
        elephants = elephants >= 2,
        lancer = lancer >= 2,
        ram = ram >= 3,
        onager = (onager >= 3),
        scorpion = scorpion > 2 | (scorpion == 2 & siege_engineers == 1),
        bbc = bbc >= 1 ,
        monk = (monk > 1) | (monk & redemption),
        naval = naval, 
        structures = structures,
        eco_food = eco_food,
        eco_wood = eco_wood,
        eco_gold = eco_gold
    ) 

units %>% 
    summarise(across(where(function(x) !is.character(x)), function(x) mean(x))) %>%
    pivot_longer(everything()) %>% 
    print(n=999)



s1dat <- adat %>%
    select(rating = s1_rating, civ = s1_civ) %>%
    mutate(rating = rating / 25) %>% 
    left_join(units, by = "civ") %>%
    mutate(across(where(is.logical), as.numeric)) %>% 
    select(-civ)

s2dat <- adat %>%
    select(rating = s2_rating, civ = s2_civ) %>%
    mutate(rating = rating / 25) %>%
    left_join(units, by = "civ") %>%
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
    name = c("ELO Delta (25)", colnames(units)[-1]),
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
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    labs( caption = footnotes)


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_bt_cu.png",
    height = 6,
    width = 9
)