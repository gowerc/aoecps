library(dplyr)
library(purrr)
library(parallel)
library(knitr)

set.seed(40130)

CIVS <- c("A", "B", "C", "D", "E")
true_score_mean <- 0
true_score_sd <- 0.5

WR_A_B <- 0.62
WR_A_C <- 0.67
WR_A_D <- 0.45
WR_A_E <- 0.54

WR_B_A <- 1 - WR_A_B
WR_B_C <- 0.56
WR_B_D <- 0.63
WR_B_E <- 0.55

WR_C_A <- 1 - WR_A_C
WR_C_B <- 1 - WR_B_C
WR_C_D <- 0.67
WR_C_E <- 0.41

WR_D_A <- 1 - WR_A_D
WR_D_B <- 1 - WR_B_D
WR_D_C <- 1 - WR_C_D
WR_D_E <- 0.45

WR_E_A <- 1 - WR_A_E
WR_E_B <- 1 - WR_B_E
WR_E_C <- 1 - WR_C_E
WR_E_D <- 1 - WR_D_E

wrmat <- matrix(
    c(
        0.5,    WR_A_B, WR_A_C, WR_A_D, WR_A_E,
        WR_B_A, 0.5,    WR_B_C, WR_B_D, WR_B_E,
        WR_C_A, WR_C_B, 0.5,    WR_C_D, WR_C_E,
        WR_D_A, WR_D_B, WR_D_C, 0.5   , WR_D_E,
        WR_E_A, WR_E_B, WR_E_C, WR_E_D, 0.5   
    ),
    byrow = TRUE,
    nrow = 5
)
colnames(wrmat) <- CIVS
rownames(wrmat) <- CIVS


wrmat2 <- wrmat
diag(wrmat2) <- 0
wrmat3 <- wrmat2 * (1 / (ncol(wrmat) -1))
real_wr <- rowSums(wrmat3)



get_new_elo <- function( old_elo, op_elo, won){
    RA <- old_elo
    RB <- op_elo
    EA <- 1 / ( 1 + 10 ^((RB-RA)/400))
    new_elo <- RA + 32 * ( won - EA)
    return(new_elo)
}

logistic <- binomial()$linkinv
logit <- binomial()$linkfun


play_matches <- function(n_games, players) {

    n_players <- length(players)
    index_range <- 1:n_players

    min_elo_init <- 0
    max_elo_init <- 2600

    player_names <- names(players)
    true_scores <- map_dbl(players, "true_score")
    names(true_scores) <- player_names
    elos <- qunif(
        pnorm(true_scores, mean = true_score_mean, sd = true_score_sd),
        min_elo_init,
        max_elo_init
    )
    names(elos) <- player_names

    matches <- vector(mode = "list", length = n_games)

    for(i in 1:n_games){

        next_player <- sample(player_names, 1)
        next_player_elo <- elos[next_player]
        next_player_index <- which(names(elos) == next_player)
        other_players_elos <- elos[-next_player_index]

        elo_diff <- other_players_elos - next_player_elo

        weight <- dnorm(elo_diff, mean = 0, sd = 35)

        op_player <- sample(
            names(other_players_elos),
            prob = weight, size = 1
        )
        op_elo <- elos[op_player]

        p1_ts <- true_scores[next_player]
        p2_ts <- true_scores[op_player]
        p1_civ <- players[[next_player]]$pick_fun()
        p2_civ <- players[[op_player]]$pick_fun()

        civ_prob <- wrmat[p1_civ, p2_civ]

        res <- rbinom(
            n = 1,
            size = 1,
            p = logistic(logit(civ_prob) + (p1_ts - p2_ts) * 25)
        )

        matches[[i]] <- list(
            p1 = next_player,
            p2 = op_player,
            p1_elo = next_player_elo,
            p2_elo = op_elo,
            p1_civ = p1_civ,
            p2_civ = p2_civ,
            result = res
        )

        elos[next_player] <- get_new_elo(next_player_elo, op_elo, res)
        elos[op_player] <- get_new_elo(op_elo, next_player_elo, 1- res)

    }

    dat <- map_df(matches, as_tibble)
    return(dat)
}


summarise_match_results <- function(results){
    bind_rows(
        results %>% mutate(civ = p1_civ, result = result),
        results %>% mutate(civ = p2_civ, result = 1 - result)
    ) %>%
    filter(p1_civ != p2_civ) %>%
    group_by(civ) %>%
    summarise(
        bign = n(),
        nwin = sum(result),
        p = nwin / bign * 100
    )
}




initialise_players <- function(n_players, allo_fun){
    players <- vector(mode = "list", length = n_players)
    for (i in 1:n_players) {
        true_score = rnorm(1, mean = true_score_mean, sd = true_score_sd)
        players[[i]] <- list(
            true_score = true_score,
            pick_fun = allo_fun(true_score = true_score)
        )
    }
    names(players) <- paste0("p", 1:n_players)
    return(players)
}


selection_type_0 <- function(true_score){
    function(){
        sample(CIVS, 1)
    }
}


selection_type_1 <- function(true_score) {
    function(){
        sample(CIVS, 1, prob = c(0.45, 0.2, 0.1, 0.25))
    }
}


selection_type_2 <- function(true_score){
    x <- list(
        function(){
            "A"
        },
        function(){
            sample(CIVS, 1)
        }
    )
    index <- sample(1:length(x), 1, p=c(0.4, 0.6))
    x[[index]]
}

selection_type_3 <- function(true_score){
    x <- list(
        function(){
            "A"
        },
        function(){
            "C"
        },
        function(){
            sample(CIVS, 1)
        }
    )
    index <- sample(1:length(x), 1, p=c(0.4, 0.4, 0.2))
    x[[index]]
}




get_results <- function(scenario, n_match = 1000000, n_player = 5000){
    players_0 <- initialise_players(n_player, scenario)
    play_matches(n_match, players_0)
}


scenarios <- list(
    selection_type_0,
    selection_type_1,
    selection_type_2,
    selection_type_3
)

cl <- makeCluster(4)
clusterEvalQ(cl, {
    library(dplyr)
    library(purrr)
})
clusterExport(cl, c(
    "CIVS", "wrmat", "initialise_players", "play_matches",
    "summarise_match_results", "true_score_mean", "true_score_sd",
    "logistic", "logit", "get_new_elo"
))

match_results <- clusterApply(cl = cl, fun = get_results, x = scenarios)
stopCluster(cl)


results_summary <- lapply(
    match_results,
    summarise_match_results
)
    


results_summary2 <- tibble(
    civ = CIVS,
    real_score = real_wr,
)
for(i in 1:length(scenarios)){
    nam <- paste0("scenario_", i - 1)
    results_summary2[[nam]] <- results_summary[[i]]$p
}


results_summary2 %>%
    mutate_if(is.numeric, round, 2) %>%
    kable()

wrmat %>% kable()
