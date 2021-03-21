pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(forcats)
library(stringr)
library(purrr)
library(mgcv)


dat <- readRDS("./data/iae12.Rds") %>%
    filter(s1_rating >= 800 & s2_rating >= 800)

dat2 <- bind_rows(
    dat %>% select(civ = s1_civ, won = s1_won, elo = s1_rating),
    dat %>% select(civ = s2_civ, won = s2_won, elo = s2_rating)
) %>%
    mutate(elo = as.numeric(elo))


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
    from = signif(min(dat2$elo), 2),
    to = signif(max(dat2$elo), 2),
    by = 10
)


res <- map_df(cuts, get_slice, dat = dat2) 

res2 <- res %>%
    filter(limit_lower >= min(dat2$elo), limit_upper <= max(dat2$elo)) %>%
    mutate(
        p_adj = p - pelo,
        plci_adj = plci - pelo,
        puci_adj = puci - pelo
    )
    

civlist <- res2 %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()





get_slice_plot <- function(CIV, dat){
    
    dat2 <- dat %>%
        filter(civ == CIV)
    
    footnotes <- c(
        "Win rates are calculated at each point X after filtering the data to",
        "only include matches where log(x) - 0.1 <= log(x) <= log(x) + 0.1<br/>",
        "All matches where both players have a known ELO > 800 are considered.<br/>",
        "All lines have been smoothed using a GAM."
    ) %>%
        as_footnote(width=120)
        
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
    
    p <- ggplot(data = pdat, aes(ymin = lci, ymax = uci, x = y, group = civ, fill = civ, y = med)) +
        geom_ribbon(alpha = 0.6, col = NA) +
        geom_line(col = "#383838") + 
        geom_hline(yintercept = 0, col = "red") +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        ggtitle(
            label = NULL,
            subtitle = glue::glue("Civilisation = {CIV}")
        ) + 
        ylab("Win Rate Delta") +
        xlab("ELO") +
        theme(
            legend.position = "none",
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes)
    
    return(p)
}

slice_plots <- map(civlist, get_slice_plot, res2)
names(slice_plots) <- civlist

saveRDS(
    file = "./data/g_ia_slice.Rds",
    object = slice_plots
)

