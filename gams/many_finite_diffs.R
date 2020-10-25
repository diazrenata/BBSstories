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

many_fd <- lapply(seeds[1:5000], FUN = get_one_fd, model = pb_mod, eps = EPS)

many_fd <- bind_rows(many_fd)

many_fd <- mutate(many_fd, seed = as.character(seed))

ggplot(many_fd, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none")

# HUH SO APPARENTLY THIS WORKS

pp_mod <-  gam(((pocketmouse)) ~ s(year, k =  5), data = ts, method = "REML", family = "poisson")

many_pp_fd <- lapply(seeds[1:5000], FUN = get_one_fd, model = pp_mod, eps = EPS)

many_pp_fd <- bind_rows(many_pp_fd)

many_pp_fd <- mutate(many_pp_fd, seed = as.character(seed))

ggplot(many_pp_fd, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none")


dm_mod <-  gam(((merriami)) ~ s(year, k = 3), data = ts, method = "REML", family = "poisson")

dm_fit <- add_fitted(select(ts, year, merriami), dm_mod)

ggplot(dm_fit, aes(year, (merriami))) +
  geom_line() +
  geom_line(aes(year, .value))

many_dm_fd <- lapply(seeds[1:5000], FUN = get_one_fd, model = dm_mod, eps = EPS)

many_dm_fd <- bind_rows(many_dm_fd)

many_dm_fd <- mutate(many_dm_fd, seed = as.character(seed))

ggplot(many_dm_fd, aes(year, derivative, group = seed)) + geom_line(alpha = .2) + theme(legend.position = "none")

