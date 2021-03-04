pkgload::load_all()
library(rstan)
library(stringr)
library(dplyr)
library(forcats)
library(readr)

rstan_options(auto_write = TRUE)

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
)













mod <- stan_model("./analysis/models/bradleyterry.stan")


start <- Sys.time()

fit <- sampling(
    mod,
    data = list(
        K = ncol(diff_mat),
        N = nrow(diff_mat),
        M = diff_mat,
        y = adat2$p1_result
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

pmat <- efit$alpha
colnames(pmat) <- c(civ_levels[-1], "ELO Delta (25)")
pdat <- as_tibble(pmat) %>% mutate(index = row_number())
pdat[civ_levels[1]] <- 0


saveRDS(
    object = pdat,
    file = "./data/m_iae12_bt.Rds"
)


