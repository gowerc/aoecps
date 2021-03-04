
data {
  int<lower = 0> K;                     // # of Variables
  int<lower = 0> N;                     // # of Matches
  matrix[N,K] M;                        // Matrix of covariate differences
  int<lower = 0, upper = 1> y[N];       // Result from Team A
}

parameters {
    vector[K] alpha;            // Coeficents
}

model {
    alpha ~ normal(0., 0.2);
    y ~ bernoulli_logit(M * alpha);
}
