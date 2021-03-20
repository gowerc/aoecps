pkgload::load_all()
library(stringr)
library(dplyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)
library(purrr)


adat <- readRDS("./data/iae12.Rds") %>%
    filter(ANLFL)




res <- bind_rows(
    adat %>% select(match_id, civ = s1_civ, result = s1_won),
    adat %>% select(match_id, civ = s2_civ, result = s2_won)
)


get_civ_dat <- function(CIV){
    cdat <- res %>% filter(civ == CIV)
    res %>%
        filter(civ != CIV, match_id %in% cdat$match_id) %>%
        mutate(op = civ) %>%
        mutate(civ = CIV) %>% 
        mutate(result = !result) 
}

civlist <- res %>%
    distinct(civ) %>%
    arrange(civ) %>%
    pull(civ)

civdat <- map_df(civlist, get_civ_dat)

civdat_p <- civdat %>%
    group_by(civ, op) %>%
    summarise(
        p = mean(result),
        n = n()
    )

for(i in civlist){
    civdat_p <- civdat_p %>%
        bind_rows(
            tibble(
                civ = i,
                op = i, 
                p = 0.5,
                n = 5000
            )
        )
}


pmat <- matrix(nrow = length(civlist), ncol = length(civlist))

for(i in seq_along(civlist)){
    ci <- civlist[i]
    for(j in seq_along(civlist)){
        cj <- civlist[j]
        if(i != j){
            pmat[i, j] <- civdat_p %>%
                filter(civ == ci, op == cj) %>%
                pull(p)
        } else {
            pmat[i, j] <- 0.5
        }
    }
}

colnames(pmat) <- civlist
rownames(pmat) <- civlist



x <- hclust(
    dist(pmat - 0.5),
    method = "ward.D2"
)

clust_levels <- x$labels[x$order]


pdat <- civdat_p %>%
    mutate(civ = factor(civ, levels = clust_levels)) %>% 
    mutate(op = factor(op, levels = clust_levels)) %>% 
    mutate(
        se = sqrt(p * (1 - p) / n),
        lci = p - 1.96 * se,
        uci = p + 1.96 * se
    )


ggplot(data = pdat, aes(x = civ, y = op, fill = p)) +
    geom_tile() +
    scale_fill_continuous(type = "viridis") +
    ylab("Opposition Civilisation") +
    xlab("Player Chosen Civilisation") +
    theme(axis.text.x = element_text(angle = 50 , hjust= 1))

pdat2 <- pdat %>%
    filter(civ == "Vietnamese") %>%
    arrange(desc(p)) %>%
    mutate(op = fct_inorder(op)) 

ggplot(data = pdat2, aes(x = op, y = p, ymin = lci, ymax = uci)) +
    geom_point() +
    geom_errorbar(width = 0.3) +
    geom_hline(yintercept = 0.5, col = "red") +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 50, hjust = 1)) +
    xlab("") +
    ylab("Win Rate")



for(i in seq_along(civlist)){
    cat(round(pmat[i, ], 4))
    cat("\n")
}

cat(civlist, sep = " ")


tibble(
    names = civlist,
    p = c(0,0.24384,0,0,0,0,0,0.07409,0,0,0,0.09956,0,0,0.49186,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.09064)
) %>%
    filter(p != 0) %>% 
    knitr::kable()


library(HyRiM)

G <- mosg(
    n = length(civlist),
    m = length(civlist),
    goals = 1,
    losses = as.vector(pmat), 
    byrow = TRUE
)

G2 <- mgss(G)

OW <- tibble(
    names = civlist,
    p = round(G2$optimalAttacks[, 1], 4)
) 

OW %>%
    filter(p != 0) %>% 
    knitr::kable()

sum(pmat["Berbers", ] * OW$p)
sum(pmat["Incas", ] * OW$p)
sum(pmat["Franks", ] * OW$p)
sum(pmat["Celts", ] * OW$p)
sum(pmat["Vikings", ] * OW$p)



x <- list()
k <- 0
for(i in seq_along(civlist)){
    for( j in seq_along(civlist)){
        k <- k + 1
        fdat <- pdat %>% filter(civ == civlist[i], op == civlist[j])
        d <- 1 + rnorm(500, fdat$p, fdat$se)
        d[d < 1] <- 1
        x[[k]] <- lossDistribution(dat = d ,  bw = bw.nrd(d))
    }
}

G <- mosg(
    n = length(civlist),
    m = length(civlist),
    goals = 1,
    losses = x, 
    byrow = TRUE
)

G2 <- mgss(G)

tibble(
    names = civlist,
    p = round(G2$optimalAttacks[, 1], 3)
) %>%
    filter(p != 0) %>% 
    knitr::kable()

