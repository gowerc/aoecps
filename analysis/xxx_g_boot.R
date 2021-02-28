pkgload::load_all()
library(parallel)
library(doParallel)
library(languageserver)
library(doRNG)
library(scales)
library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)
library(tidyr)

dat3 <- readRDS("./data/ad_results.Rds")
meta <- readRDS("./data/meta.Rds")

RATING_LIMIT <- 1150

dat_limit <- dat3 %>%
    filter(p1_rating >= RATING_LIMIT, p2_rating >= RATING_LIMIT)



# dat_limit %>%
#     get_wr() %>%
#     select(civ, n, p) %>%
#     mutate(p = round(p,2)) %>%
#     mutate( pr = n / sum(n) * 100) %>%
#     mutate( pr = round(pr, 2)) %>%
#     knitr::kable()


cl <- makeCluster(8)

devnull <- clusterEvalQ(cl, {
    library(tidyverse)
    pkgload::load_all()
})

doParallel::registerDoParallel(cl)

set.seed(123)

start <- Sys.time()

x <- foreach(
    i = c(1:4000),
    .combine = bind_rows
) %dorng%
    {
        get_bs_wr(dat_limit, i)
    }

stop <- Sys.time()

difftime(stop, start, units = "secs")

stopCluster(cl)


x2 <- x %>%
    group_by(index) %>%
    mutate(rank = rank(-p)) %>%
    group_by(civ) %>%
    summarise(
        lci = quantile(rank, 0.025),
        med = quantile(rank, 0.5),
        uci = quantile(rank, 0.975)
    ) %>%
    arrange(med) %>%
    mutate( civ = fct_inorder(civ))

wr <- x %>%
    group_by(civ) %>%
    summarise(
        lci = quantile( p, 0.025),
        med = quantile( p, 0.5),
        uci = quantile( p, 0.975)
    ) %>%
    arrange(desc(med)) %>%
    mutate( civ = fct_inorder(civ))



p_rate <- ggplot( wr, aes(x = civ, ymin = lci, ymax = uci, y = med)) +
    geom_errorbar() +
    geom_point() +
    theme_bw() +
    theme(axis.text.x = element_text(angle= 40, hjust = 1)) +
    scale_y_continuous(breaks = pretty_breaks(10))+
    xlab("Civilisation") +
    ylab("Win Rate") +
    geom_hline(yintercept = 0.5, col = "red")

p_rank <- ggplot( x2, aes(x = civ, ymin = lci, ymax = uci, y = med)) +
    geom_errorbar() +
    geom_point() +
    theme_bw() +
    theme(axis.text.x = element_text(angle= 40, hjust = 1)) +
    scale_y_continuous(breaks = pretty_breaks(10), trans = "reverse")+
    xlab("Civilisation") +
    ylab("Rank") +
    geom_hline(yintercept = length(meta$civ$string)/2, col = "red")


hdat <- tibble(x = c(dat_limit$p1_rating, dat_limit$p2_rating))

elodist <- ggplot(hdat, aes(x = x)) +
    geom_density(fill = "grey") +
    scale_x_continuous(breaks = pretty_breaks(10)) +
    theme_bw() +
    ylab("Density") +
    xlab("ELO") +
    scale_y_continuous(breaks = pretty_breaks(5), expand = expansion(c(0,0.05)))



ggsave(
    "output/g_boot_WR.png",
    plot = p_rate,
    height = 6,
    width = 9
)

ggsave(
    "output/g_boot_RK.png",
    plot = p_rank,
    height = 6,
    width = 9
)

ggsave(
    "output/g_boot_ED.png",
    plot = elodist,
    height = 6,
    width = 9
)


# as_datetime(1612970323)
# as_datetime(1612971527)
# as_datetime(1612972712)

