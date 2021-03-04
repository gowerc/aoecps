pkgload::load_all()
library(rstan)
library(stringr)
library(dplyr)
library(forcats)
library(readr)

rstan_options(auto_write = TRUE)

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
    formula = result ~ . -1,
    data = ddat,
    family = binomial()
)

est <- coef(mod))
se <- sqrt(diag(vcov(mod)))

mdat <- tibble(
    name = names(se),
    est = est,
    se = se,
    lci = est - 1.96 * se,
    uci = est + 1.96 * se
)


mod <- stan_model("./analysis/models/bradleyterry.stan")


start <- Sys.time()

fit <- sampling(
    mod,
    data = list(
        K = ncol(diff_mat),
        N = nrow(diff_mat),
        M = diff_mat,
        y = adat$p1_result
    ),
    chains = 6,
    warmup = 1000,
    iter = 3000,
    cores = 6,
    refresh = 500
)

stop <- Sys.time()
difftime(stop, start, units = "secs")



efit <- extract(fit)


cnames <- colnames(diff_mat)
cnames[str_detect(cnames, "cavalry archer")] <- "cavalry archer"
cnames <- str_to_title(cnames)

pmat <- efit$alpha
colnames(pmat) <- cnames
pdat <- as_tibble(pmat) %>% mutate(index = row_number())




library(ggplot2)
library(tidyr)

pdat2 <- pdat %>%
    pivot_longer(cols = -index, ) %>%
    group_by(name) %>%
    summarise(
        lci = quantile(value, 0.025),
        med = quantile(value, 0.5),
        uci = quantile(value, 0.975)
    ) %>%
    arrange(med) %>%
    mutate( name = fct_inorder(name))


ggplot(data = pdat2, aes(x = KEY, group = KEY, ymin = lci, ymax = uci, y = med)) +
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



matrix(c(1, -1, 0, 1, 0, -1, 0, 1, -1), nrow = 3)