
# Outputs for 1v1 arabia games for elo > 12 
# looking at individual civ v civ statistics

pkgload::load_all()
library(stringr)
library(dplyr)
library(tidyr)
library(forcats)
library(readr)
library(ggplot2)
library(scales)
library(purrr)
library(ggdendro)
library(HyRiM)


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
                n = 40000
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

###################################
#
# Civ v Civ scatter plots
#
###################################


pdat <- civdat_p %>%
    mutate(
        se = sqrt(p * (1 - p) / n),
        lci = p - 1.96 * se,
        uci = p + 1.96 * se
    ) %>%
    filter(as.character(civ) != as.character(op)) %>%
    ungroup()

get_civ_plot <- function(CIV, dat){
    dat2 <- dat %>%
        filter(civ == CIV) %>%
        arrange(desc(p)) %>%
        mutate(op = fct_inorder(as.character(op)))

    p <- ggplot(data = dat2, aes(x = op, y = p, ymin = lci, ymax = uci)) +
        geom_point() +
        geom_errorbar(width = 0.3) +
        geom_hline(yintercept = 0.5, col = "red") +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 50, hjust = 1)) +
        xlab("") +
        ylab("Win Rate") +
        ggtitle(NULL, subtitle = glue::glue("Civilisation: {CIV}"))
    
    return(p)
}

civplots <- map(civlist, get_civ_plot, pdat)
names(civplots) <- civlist

saveRDS(
    civplots,
    file = "./outputs/g_iae12_cvc_civs.Rds"
)



###################################
#
# Hclust Plot
#
###################################


hmod <- hclust(
    dist(pmat - 0.5),
    method = "ward.D2"
)

dhc <- as.dendrogram(hmod)

ddata <- dendro_data(dhc, type = "rectangle") %>% 
    segment() %>% 
    as_tibble() %>% 
    mutate(nyend = if_else( yend == 0, y - 0.1, yend))

ldata <- ddata %>% 
    filter(yend == 0) %>% 
    mutate(labs = hmod$labels[hmod$order])

plot(hmod)



recur_get_group <- function(start, start_is_y, dat, grpdat = NULL){
    if (is.null(grpdat)) grpdat = tibble(id = numeric(), grp = numeric())
    
    if(start_is_y){
        next_start <- dat %>%
            filter(x != xend) %>%
            left_join( select(start, yend, grp, yx = x), by = "yend") %>%
            filter( x == yx | xend == yx) %>% 
            filter(!is.na(grp))
    } else {
        next_start <- dat %>%
            filter(y != yend) %>%
            left_join(select(start, xend, grp, xy=y), by = "xend") %>%
            filter( y == xy | yend == xy) %>% 
            filter(!is.na(grp))
    }
    if (nrow(next_start) == 0) {
        return(grpdat)
    }
    
    grpdat <- grpdat %>%
        bind_rows(select(next_start, id, grp))
    
    return(recur_get_group(next_start, !start_is_y, dat, grpdat))
}


ddata2 <- ddata %>%
    mutate(id = row_number())

cut <- 0.01
ngroups <- 99
while(ngroups > 8){
    init_grp <- ddata2 %>%
        filter(x == xend) %>%
        filter(y >= cut) %>%
        filter(!yend %in% y) %>%
        mutate(grp = row_number())
    ngroups <- length(unique(init_grp$grp))
    cut <- cut + 0.005
}

grpclass <- recur_get_group(init_grp, TRUE, ddata2)

ddata3 <- ddata2 %>%
    left_join(grpclass, by = "id") %>%
    mutate(grp = factor(grp))


footnotes <- c(
    "Distance is calculated based upon the Ward Method between civilisation v civilisation win rates.<br/>",
    "Civilisations are coloured based upon their group.<br/>",
    "Groups are formed by applying an arbitrary cutoff that ensures there are no more than 8 unique groups."
) %>%
    as_footnote()

p <- ggplot(ddata3, aes(x = x, y = y, xend = xend, yend = nyend, col = grp)) + 
    geom_segment() + 
    theme_bw() +
    scale_x_continuous(breaks = c(), labels = c()) + 
    scale_y_continuous(expand=  expansion(mult = c(0.25, 0.05)), breaks = pretty_breaks(10)) +
    xlab("") +
    ylab("Distance") +
    geom_text(
        aes(label = labs, y= nyend, x=x),
        inherit.aes = FALSE,
        data = ldata, 
        hjust = 1.1, 
        angle = 90
    ) + 
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)

save_plot(
    plot = p,
    filename = "./outputs/g_iae12_cvc_clust.png"
)

###################################
#
# Optimal Selection
#
###################################


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

saveRDS(
    OW, 
    file = "./outputs/t_iae12_cvc_opt.Rds"
)

OW %>%
    filter(p != 0) %>% 
    knitr::kable()
