
library(rstan)
library(dplyr)
library(ggplot2)
library(tidyr)


invlogit <- function(x) 1 / (1 + exp(-x))
logit <- function(x)log(x / (1-x))

n <- 2000
dat <- tibble(
    p1 = 1,
    p0 = 2,
    delo = rnorm(n, 0, 40),
    result = rbinom(n, 1, invlogit(0.2 + 1/60 * delo ) )
) %>% 
    mutate(delo = delo / 50)



mod <- stan_model("./analysis/models/xxx_test.stan")


start <- Sys.time()
fit <- sampling(
    mod,
    data = list(
        K = 2,
        N = n,
        player1 = dat$p1,
        player0 = dat$p0,
        delo = dat$delo,
        y = dat$result
    ),
    chains = 6,
    warmup = 1000,
    iter = 3000,
    cores = 6,
    refresh = 0
)
stop <- Sys.time()
difftime(stop, start, units = "secs")


efit <- rstan::extract(fit)
print(names(efit))

traceplot(
    fit,
    pars = c("alpha", "alpha_raw"), 
    inc_warmup = FALSE,
    nrow = 2
)

x <- as.matrix(efit$alpha)
dat <- tibble(index = 1:nrow(x))
for (i in 1:ncol(x)) dat[paste0("Alpha_", i)] <- x[, i]
dat["beta"] <- efit$beta


dat2 <- dat %>% 
    pivot_longer( -index, names_to = "KEY", values_to = "VAL") %>% 
    group_by(KEY) %>% 
    summarise(
        lci = quantile(VAL, 0.025),
        med = quantile(VAL, 0.5),
        uci = quantile(VAL, 0.975)
    )

ggplot(data = dat2, aes(x = KEY, group = KEY, ymin = lci, ymax=uci, y = med)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw()

