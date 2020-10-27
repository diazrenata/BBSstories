library(dplyr)
library(ggplot2)
library(gratia)
load_mgcv()

ts <- read.csv(here::here("gams", "rat_data.csv"))

pb_real_plot <- ggplot(ts, aes(year, (baileys))) + geom_line()

pb_mod <-  gam(((baileys)) ~ s(year, k =  5), data = ts, method = "REML", family = "poisson")

pb_fit <- add_fitted(select(ts, year, baileys), pb_mod)

pb_fit_plot <- ggplot(pb_fit, aes(year, (baileys))) +
  geom_point() +
  geom_line(aes(year, .value))

pb_derivs <- derivatives(pb_mod, n = 200)

pb_derivs <- pb_derivs %>%
  rename(year = data) %>%
  mutate(abs_derivative = abs(derivative))

pb_deriv_plot <- ggplot(pb_derivs, aes(year, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(pb_real_plot, pb_fit_plot, pb_deriv_plot), ncol = 1)

# The derivatives are bizarre, which I think is because Gavin didn't intend gratia::derivatives to be used wit poisson fits.

# We can try numerous finite differences on fits?
set.seed(1977)
EPS <- 1
NSAMPLES <- 10000
seeds <- sample.int(n = 5 * NSAMPLES, size = NSAMPLES, replace = F)
seed <- seeds[1]


get_one_fd <- function(model, eps, seed) {

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
    eps = eps
  ))

}

one_fd <- get_one_fd(pb_mod, EPS, seed)

ggplot(one_fd, aes(year, derivative)) + geom_point()

many_fd <- lapply(seeds[1:200], FUN = get_one_fd, model = pb_mod, eps = EPS)

many_fd <- bind_rows(many_fd)

many_fd <- mutate(many_fd, seed = as.character(seed))

ggplot(many_fd, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none")

# HUH SO APPARENTLY THIS WORKS


# Cross checking that this agrees with derivative() if you use the Gaussian

pb_g_mod <- gam(baileys ~ s(year, k = 5), data = ts, method = "REML", family = "gaussian")

# We can try numerous finite differences on fits?
set.seed(1977)
EPS <- 1
NSAMPLES <- 10000
seeds <- sample.int(n = 5 * NSAMPLES, size = NSAMPLES, replace = F)
seed <- seeds[1]

pb_g_finitedifs <- lapply(seeds[1:1000], FUN = get_one_fd, model = pb_g_mod, eps = EPS)

pb_g_finitedifs <- bind_rows(pb_g_finitedifs)

pb_g_finitedifs <- mutate(pb_g_finitedifs, seed = as.character(seed))

ggplot(pb_g_finitedifs, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none")

pb_g_derivs <- derivatives(pb_g_mod)


ggplot(pb_g_finitedifs, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none") +
  geom_line(data = pb_g_derivs, aes(data, derivative), color = "red")


# this appears to match. I'm not sure what my expectation would be w.r.t. whether the standard errors should match, because derivatives is working somehow simultaneously? but we can try.

pb_g_finitedifs <- pb_g_finitedifs %>%
  group_by(year) %>%
  mutate(upper = quantile(derivative, probs = .975),
         lower = quantile(derivative, probs = .025),
         mean = mean(derivative))


ggplot(pb_g_finitedifs, aes(year, upper)) +
  geom_line() +
  geom_line(aes(year, lower)) +
  geom_line(aes(year, mean)) +
  geom_line(data = pb_g_derivs, aes(data, derivative), color = "red") +
  geom_line(data = pb_g_derivs, aes(data, lower), color = "red") +
  geom_line(data = pb_g_derivs, aes(data, upper), color = "red")


# well that is PERFECT


