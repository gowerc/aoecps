pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(forcats)
library(stringr)
library(purrr)
library(mgcv)


dat <- readRDS("./data/ta.Rds") %>%
    mutate(elo = rating) %>%
    mutate(civ = civ_name) %>% 
    filter( elo >= 1100)



get_slice <- function(y, dat){
    ub <- exp(log(y) + 0.1)
    lb <- exp(log(y) - 0.1)
    
    dat2 <- dat %>%
        filter(elo >= lb, elo <= ub) 
        
    tab <- dat2 %>%
        summarise(
            nelo = n(), 
            pelo = mean(won)
        ) %>%
        mutate(y = y) 
    
    gdat <- dat2 %>%
        group_by(civ) %>%
        summarise(n = n(), p = mean(won)) %>%
        ungroup() %>%
        mutate(plci = p - 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(puci = p + 1.96 * sqrt((p * (1 - p)) / n)) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb) %>% 
        left_join(tab, by = "y")
    return(gdat)
}

cuts <- seq(
    from = signif(min(dat$elo), 2),
    to = signif(max(dat$elo), 2),
    by = 10
)


res <- map_df(cuts, get_slice, dat = dat) 

res2 <- res %>%
    filter(limit_lower >= min(dat$elo), limit_upper <= max(dat$elo)) %>%
    mutate(
        p_adj = p - pelo,
        plci_adj = plci - pelo,
        puci_adj = puci - pelo
    )
    

civlist <- res2 %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()





get_slice_dat <- function(CIV, dat) {
    dat2 <- dat %>%
        filter(civ == CIV)


    # fit GAM model
    lci_m <- gam(plci_adj ~ s(y), data = dat2)
    med_m <- gam(p_adj ~ s(y), data = dat2)
    uci_m <- gam(puci_adj ~ s(y), data = dat2)

    pdat <- tibble(
        y = dat2$y,
        civ = dat2$civ,
        lci = predict(lci_m, newdata = data.frame(y = y)),
        med = predict(med_m, newdata = data.frame(y = y)),
        uci = predict(uci_m, newdata = data.frame(y = y)),
    )
    return(pdat)
}

pdat <- map_df(civlist, get_slice_dat, res2)

footnotes <- c(
    "Win rates are calculated at each point X after filtering the data to",
    "only include matches where log(x) - 0.1 <= log(x) <= log(x) + 0.1<br/>",
    "All matches where players Elo is >= 1100 are included.<br/>",
    "All lines have been smoothed using a GAM."
) %>%
    as_footnote()

p <- ggplot(data = pdat, aes(ymin = lci, ymax = uci, x = y, group = civ, fill = civ, y = med)) +
    geom_ribbon(alpha = 0.9, col = NA) +
    geom_line(col = "#383838") + 
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(4)) +
    scale_x_continuous(breaks = pretty_breaks(4)) +
    geom_hline(yintercept = 0, col = "red", alpha = 0.8) +
    ylab("Win Rate Delta") +
    xlab("Elo") +
    facet_wrap(~civ) + 
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)



save_plot(
    filename = "./outputs/g_ta_slice.png",
    plot = p
)

