

data {
  int<lower = 0> K;                     // players
  int<lower = 0> N;                     // games
  int<lower=1, upper = K> player1[N];   // player 1 for game n
  int<lower=1, upper = K> player0[N];   // player 0 for game n
  int<lower = 0, upper = 1> y[N];       // player 1 result
  vector[N] delo;
}

parameters {
  vector[K - 1] alpha_raw;              // ability for players 1:K-1
  real beta;
}

transformed parameters {
  // enforces sum(alpha) = 0 for identifiability
  vector[K] alpha = append_row(alpha_raw, 0);
}

model {
  y ~ bernoulli_logit(alpha[player1] - alpha[player0] + (delo * beta));
}
