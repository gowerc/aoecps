pkgload::load_all()
library(rstan)
library(dplyr)

rstan_options(auto_write = TRUE)

adat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL)

# adat <- adat %>% sample_n(7000)

mod <- stan_model("./analysis/models/bradleyterry.stan")

start <- Sys.time()
fit <- sampling(
    mod,
    data = list(
        K = length(unique(adat$p1_civ)),
        N = nrow(adat),
        player1 = adat$p1_civ,
        player0 = adat$p2_civ,
        delo = adat$delo,
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


saveRDS(
    object = fit,
    file = "./data/m_iae12_bt.Rds"
)
