

data_pr <- function(matchmeta, players){
    players2 <- players %>% semi_join(matchmeta, by= "match_id")
    players2 %>%
        mutate(bign = n()) %>% 
        group_by(civ_name) %>% 
        summarise(
            n = n(),
            bign = unique(bign),
            pr = n/bign * 100,
            pr_format = sprintf("%5.2f %%", pr)
        )
}



plot_pr <- function(dat){
    footnotes <- c(
        "The red line represents the hypothetical play rate if civs were picked at random"
    ) %>%
        as_footnote()
    
    prdat <- dat %>%
        arrange(desc(n)) %>%
        mutate(civ_name = fct_inorder(civ_name))

    ggplot(data = prdat, aes(y = pr, x = civ_name)) +
        geom_bar(stat = "identity") +
        geom_hline(yintercept = 1 / nrow(prdat) * 100, col = "red") +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes) + 
        ylab("Play Rate (%)") +
        xlab("") 
}


plot_pr_wr <- function(wr, pr) {
    assert_that(
        nrow(wr) == nrow(pr)
    )

    pdat <- wr %>% 
        inner_join(select(pr, civ_name, pr), by = "civ_name")

    footnotes <- c(
        ""
    ) %>%
        as_footnote()

    ggplot(data = pdat, aes(y = pr, x = wr, label = civ_name)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        theme(
            plot.caption = element_text(hjust = 0)
        ) +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
        labs(caption = footnotes) + 
        ylab("Play Rate (%)") +
        xlab("Win Rate (%)")
}


