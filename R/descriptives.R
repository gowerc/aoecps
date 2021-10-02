
#######################################
#
# Hist plot of ELo counts
#
#######################################

plot_dist_elo <- function(matchmeta){
    strings <- matchmeta %>%
        mutate(elo = rating_mean) %>% 
        summarise(
            n = length(elo),
            min = min(elo),
            lower.q = quantile(elo, 0.25),
            median = quantile(elo, 0.5),
            mean = mean(elo),
            upper.q = quantile(elo, 0.75),
            max = max(elo)
        ) %>%
        pivot_longer(everything()) %>%
        mutate(string = sprintf( "%s = %7.0f", name, value) %>% str_pad(width = 12)) %>%
        pull(string) %>%
        paste0(collapse = "\n")


    footnotes <- c(
        "The mean match Elo is calculated as the mean Elo of all players in the match"
    ) %>%
        as_footnote()


    ggplot(matchmeta, aes(x = rating_mean)) +
        geom_histogram(bins = 30) +
        theme_bw() +
        ylab("Count") +
        scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
        scale_x_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
        xlab("Mean Match Elo") +
        annotate(
            geom = "text",
            label = strings,
            x = max(matchmeta$rating_mean),
            y = Inf,
            hjust = 1,
            vjust = 1.1
        ) +
        theme(plot.caption = element_text(hjust = 0)) + 
        labs( caption = footnotes)

}




#######################################
#
# Hist plot of Patch version
#
#######################################

plot_dist_patch <- function(matchmeta){
    ggplot(data = matchmeta, aes(x = version)) +
        geom_bar() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
        xlab("Patch Version") +
        ylab("Number of Games")
}





#######################################
#
# Map distribtuons
#
#######################################

plot_dist_map <- function(matchmeta){

    pdat <- matchmeta %>% 
        mutate(bign = n()) %>% 
        group_by(map_name) %>% 
        summarise(
            n = n(),
            p = sprintf("%5.2f%%", n / unique(bign) * 100),
            bign = unique(bign),
            .group = "drop"
        ) %>% 
        mutate(yjust = n + max(n)/50) 

    ggplot(data = pdat, aes(x = map_name, y = n)) +
            geom_bar(stat = "identity") +
            geom_text(aes(label = p, y = yjust)) + 
            theme_bw() +
            scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
            xlab("Map") +
            ylab("Number of Games")
}


