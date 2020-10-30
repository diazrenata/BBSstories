# Obtain one esitmate of the derivatives of a GAM
# using finite differencing, to allow for non-gaussian fits
# args
# model: fitted gAM
# eps: time interval for finite differencing
# seed: seed to pass

get_one_fd <- function(model, eps = 1e-02, seed) {

  newdat <- data.frame(year = seq(min(model$model$year), max(model$model$year), by = eps))

  this_sim <- fitted_samples(model, n = 1, newdata = newdat, seed = seed)

  vals1 <- this_sim$fitted[ 1:nrow(this_sim) - 1]
  vals2 <- this_sim$fitted[ 2:nrow(this_sim)]

  this_fd <- (vals2 - vals1)/eps

  years1 <- newdat$year[ 1:nrow(newdat) - 1]
  years2 <- newdat$year[ 2:nrow(newdat)]

  this_years <- as.matrix(cbind(years1, years2))
  this_years <- apply(this_years, MARGIN = 1, FUN = mean)

  return(data.frame(
    year = this_years,
    derivative = this_fd,
    seed = seed,
    eps = eps,
    first_value = this_sim$fitted[1],
    last_value = this_sim$fitted[nrow(this_sim)]
  ))

}


# Obtain numerous estimates of the derivatives for a GAM
# Using finite differencing
# args
# model: fitted GAM
# eps: time interval for finite diffs
# nsamples: how many estimates to draw
# seed_seed: set the seed TO USE TO DRAW THE SEEDS TO PASS TO get_one_fd.

get_many_fd <- function(model, eps = 1e-02, nsamples = 200, seed_seed = 1977) {

  set.seed(seed_seed)
  seeds <- sample.int(n = 5 * nsamples, size = nsamples, replace = F)

  many_fd <- lapply(seeds, FUN = get_one_fd, model = model, eps = eps)

  many_fd <- dplyr::bind_rows(many_fd)

  many_fd <- dplyr::mutate(many_fd, seed = as.character(seed)) %>%
    group_by(year) %>%
    mutate(upper = quantile(derivative, probs = .975),
           lower = quantile(derivative, probs = .025),
           mean = mean(derivative))

  return(many_fd)
}
