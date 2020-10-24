library(dplyr)
library(ggplot2)
library(gratia)
load_mgcv()
raw_portal_data <- portalr::abundance(time = "date")

abundance_ts <- data.frame(
  censusdate = raw_portal_data$censusdate,
  total_abund = rowSums(raw_portal_data[, 2:22])
)


spectab_ts <- raw_portal_data %>%
  select(censusdate, DS, PP, DM, PB)


ts <- left_join(abundance_ts, spectab_ts)
ts <- ts %>%
  mutate(year = as.character(censusdate)) %>%
  mutate(year = substr(year, 0, 4)) %>%
  mutate(year = as.numeric(year)) %>%
  filter(year > 1980) %>%
  filter(year < 2019) %>%
  group_by(year) %>%
  summarize(total_abundance = sum(total_abund),
            bannertail = sum(DS),
            merriami = sum(DM),
            pocketmouse = sum(PP),
            baileys = sum(PB))
ts_long <- ts %>%
  tidyr::pivot_longer(-year, names_to = "species", values_to ="value")

ggplot(ts_long, aes(year, value, color= species)) +
  geom_line() +
  theme_bw() +
  facet_wrap(vars(species), ncol = 1, scales = "free_y")

pb_real_plot <- ggplot(ts, aes(year, (baileys))) + geom_line()

pb_mod <-  gam(((baileys)) ~ s(year), data = ts, method = "REML", family = "gaussian")
#' considerable unknowns w.r.t. correct model fitting.
#' abundance/count data I believe should be poisson. in this instance using gaussian results in negative predicted values for the number of rats, which is not possible
#' derivatives for poisson behave VERY ODDLY
#' do we include term for year without the smooth? here we are not super interested in the significance, etc of various predictors
#' how does one select k?
#' for now proceeding bc I am primarily interested in what we can do with the time series of DERIVATIVES

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

# for now let's look only at the predicted derivative. we have a way to work with samples from the posterior later.

pb_deriv_hist <- ggplot(pb_derivs, aes(derivative)) +
  geom_histogram()

pb_abs_deriv_hist <- ggplot(pb_derivs, aes(abs_derivative)) +
  geom_histogram()

gridExtra::grid.arrange(grobs = list(pb_deriv_hist, pb_abs_deriv_hist))

pb_deriv_eps <- mean(pb_derivs$year[2:200] - pb_derivs$year[1:199])

pb_deriv_net <- sum(pb_derivs$derivative) * pb_deriv_eps

pb_deriv_abs <- sum(pb_derivs$abs_derivative) * pb_deriv_eps

pb_deriv_results <- pb_derivs %>%
  select(year, derivative, abs_derivative, upper, lower) %>%
  mutate(deriv_eps = pb_deriv_eps,
         deriv_net = pb_deriv_net,
         deriv_abs = pb_deriv_abs,
         species = "baileys")


#### pb samples from posterior ####

newd <- with(pb_fit, data.frame(year = seq(min(year), max(year), length = 200)))

pb_fd <- gratia:::fderiv(pb_mod, newdata = newd, eps = 1e-07, unconditional = FALSE)

pb_Vb <- vcov(pb_mod, unconditional = FALSE)
set.seed(1977)
pb_sims <- MASS::mvrnorm(300, mu = coef(pb_mod), Sigma = pb_Vb)
pb_X0 <- predict(pb_mod, newd, type = "lpmatrix")
newd <- newd + 1e-07
pb_X1 <- predict(pb_mod, newd, type = "lpmatrix")
pb_Xp <- (pb_X1 - pb_X0) / 1e-07
pb_derivs_draws <- pb_Xp %*% t(pb_sims)


pb_derivs_draws <- as.data.frame(pb_derivs_draws)
pb_derivs_draws$year <- newd$year
pb_derivs_draws <- pb_derivs_draws %>%
  tidyr::pivot_longer(-year, names_to = "draw", names_prefix = "V", values_to = "pred_deriv") %>%
  mutate(draw = as.numeric(draw),
         species = "baileys")

pb_deriv_draw_plot <- ggplot(filter(pb_derivs_draws, draw < 100), aes(year, pred_deriv, group = as.factor(draw), color =as.factor(draw))) +
  geom_line(alpha = .2) +
  theme_bw() +
  geom_hline(yintercept = 0)  +
  theme(legend.position = "none")


pb_deriv_eps <- mean(newd$year[2:200] - newd$year[1:199])

pb_deriv_net <- sum(pb_derivs$derivative) * pb_deriv_eps

pb_deriv_abs <- sum(pb_derivs$abs_derivative) * pb_deriv_eps


pb_deriv_draw_results <- pb_derivs_draws %>%
  rename(derivative = pred_deriv) %>%
  mutate(deriv_eps = pb_deriv_eps,
         abs_derivative = abs(derivative)) %>%
  group_by(draw) %>%
  mutate(deriv_net = sum(derivative) * pb_deriv_eps,
         deriv_abs = sum(abs_derivative) * pb_deriv_eps,
         source = "sim") %>%
  ungroup()

all_pb_deriv <- bind_rows(pb_deriv_draw_results, mutate(pb_deriv_results, draw = -99, source = "fitted")) %>%
  mutate(abs_v_net = deriv_abs / abs(deriv_net))

pb_net_plot <- ggplot(all_pb_deriv, aes(source, y = deriv_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 0)
pb_abs_plot <- ggplot(all_pb_deriv, aes(source, y = deriv_abs)) +
  geom_boxplot()
pb_abs_v_net_plot <- ggplot(all_pb_deriv, aes(source, y = abs_v_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 1)

gridExtra::grid.arrange(grobs = list(pb_real_plot, pb_fit_plot, pb_deriv_plot, pb_deriv_draw_plot), ncol = 1)
gridExtra::grid.arrange(grobs = list(pb_net_plot, pb_abs_plot, pb_abs_v_net_plot), ncol = 3)

#### pp ####
pp_real_plot <- ggplot(ts, aes(year, (pocketmouse))) + geom_line()

pp_mod <-  gam(((pocketmouse)) ~ s(year), data = ts, method = "REML", family = "gaussian")
#' considerable unknowns w.r.t. correct model fitting.
#' abundance/count data I believe should be poisson. in this instance using gaussian results in negative predicted values for the number of rats, which is not possible
#' derivatives for poisson behave VERY ODDLY
#' do we include term for year without the smooth? here we are not super interested in the significance, etc of various predictors
#' how does one select k?
#' for now proceeding bc I am primarily interested in what we can do with the time series of DERIVATIVES

pp_fit <- add_fitted(select(ts, year, pocketmouse), pp_mod)

pp_fit_plot <- ggplot(pp_fit, aes(year, (pocketmouse))) +
  geom_point() +
  geom_line(aes(year, .value))

pp_derivs <- derivatives(pp_mod, n = 200)

pp_derivs <- pp_derivs %>%
  rename(year = data) %>%
  mutate(abs_derivative = abs(derivative))

pp_deriv_plot <- ggplot(pp_derivs, aes(year, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(pp_real_plot, pp_fit_plot, pp_deriv_plot), ncol = 1)

# for now let's look only at the predicted derivative. we have a way to work with samples from the posterior later.

pp_deriv_hist <- ggplot(pp_derivs, aes(derivative)) +
  geom_histogram()

pp_abs_deriv_hist <- ggplot(pp_derivs, aes(abs_derivative)) +
  geom_histogram()

gridExtra::grid.arrange(grobs = list(pp_deriv_hist, pp_abs_deriv_hist))

pp_deriv_eps <- mean(pp_derivs$year[2:200] - pp_derivs$year[1:199])

pp_deriv_net <- sum(pp_derivs$derivative) * pp_deriv_eps

pp_deriv_abs <- sum(pp_derivs$abs_derivative) * pp_deriv_eps

pp_deriv_results <- pp_derivs %>%
  select(year, derivative, abs_derivative, upper, lower) %>%
  mutate(deriv_eps = pp_deriv_eps,
         deriv_net = pp_deriv_net,
         deriv_abs = pp_deriv_abs,
         species = "pocketmouse")
#### pp samples from posterior ####

pp_fd <- gratia:::fderiv(pp_mod, newdata = newd, eps = 1e-07, unconditional = FALSE)

pp_Vb <- vcov(pp_mod, unconditional = FALSE)
set.seed(1977)
pp_sims <- MASS::mvrnorm(300, mu = coef(pp_mod), Sigma = pp_Vb)
pp_X0 <- predict(pp_mod, newd, type = "lpmatrix")
newd <- newd + 1e-07
pp_X1 <- predict(pp_mod, newd, type = "lpmatrix")
pp_Xp <- (pp_X1 - pp_X0) / 1e-07
pp_derivs_draws <- pp_Xp %*% t(pp_sims)


pp_derivs_draws <- as.data.frame(pp_derivs_draws)
pp_derivs_draws$year <- newd$year
pp_derivs_draws <- pp_derivs_draws %>%
  tidyr::pivot_longer(-year, names_to = "draw", names_prefix = "V", values_to = "pred_deriv") %>%
  mutate(draw = as.numeric(draw),
         species = "pocketmouse")

pp_deriv_draw_plot <- ggplot(filter(pp_derivs_draws, draw < 100), aes(year, pred_deriv, group = as.factor(draw), color =as.factor(draw))) +
  geom_line(alpha = .2) +
  theme_bw() +
  geom_hline(yintercept = 0)  +
  theme(legend.position = "none")


pp_deriv_eps <- mean(newd$year[2:200] - newd$year[1:199])

pp_deriv_net <- sum(pp_derivs$derivative) * pp_deriv_eps

pp_deriv_abs <- sum(pp_derivs$abs_derivative) * pp_deriv_eps


pp_deriv_draw_results <- pp_derivs_draws %>%
  rename(derivative = pred_deriv) %>%
  mutate(deriv_eps = pp_deriv_eps,
         abs_derivative = abs(derivative)) %>%
  group_by(draw) %>%
  mutate(deriv_net = sum(derivative) * pp_deriv_eps,
         deriv_abs = sum(abs_derivative) * pp_deriv_eps,
         source = "sim") %>%
  ungroup()

all_pp_deriv <- bind_rows(pp_deriv_draw_results, mutate(pp_deriv_results, draw = -99, source = "fitted")) %>%
  mutate(abs_v_net = deriv_abs / abs(deriv_net))

pp_net_plot <- ggplot(all_pp_deriv, aes(source, y = deriv_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 0)
pp_abs_plot <- ggplot(all_pp_deriv, aes(source, y = deriv_abs)) +
  geom_boxplot()
pp_abs_v_net_plot <- ggplot(all_pp_deriv, aes(source, y = abs_v_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 1)

gridExtra::grid.arrange(grobs = list(pp_real_plot, pp_fit_plot, pp_deriv_plot, pp_deriv_draw_plot), ncol = 1)
gridExtra::grid.arrange(grobs = list(pp_net_plot, pp_abs_plot, pp_abs_v_net_plot), ncol = 3)


#### merriams ####
dm_real_plot <- ggplot(ts, aes(year, (merriami))) + geom_line()

dm_mod <-  gam(((merriami)) ~ s(year), data = ts, method = "REML", family = "gaussian")
#' considerable unknowns w.r.t. correct model fitting.
#' abundance/count data I believe should be poisson. in this instance using gaussian results in negative predicted values for the number of rats, which is not possible
#' derivatives for poisson behave VERY ODDLY
#' do we include term for year without the smooth? here we are not super interested in the significance, etc of various predictors
#' how does one select k?
#' for now proceeding bc I am primarily interested in what we can do with the time series of DERIVATIVES

dm_fit <- add_fitted(select(ts, year, merriami), dm_mod)

dm_fit_plot <- ggplot(dm_fit, aes(year, (merriami))) +
  geom_point() +
  geom_line(aes(year, .value))

dm_derivs <- derivatives(dm_mod, n = 200)

dm_derivs <- dm_derivs %>%
  rename(year = data) %>%
  mutate(abs_derivative = abs(derivative))

dm_deriv_plot <- ggplot(dm_derivs, aes(year, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(dm_real_plot, dm_fit_plot, dm_deriv_plot), ncol = 1)

# for now let's look only at the predicted derivative. we have a way to work with samples from the posterior later.

dm_deriv_hist <- ggplot(dm_derivs, aes(derivative)) +
  geom_histogram()

dm_abs_deriv_hist <- ggplot(dm_derivs, aes(abs_derivative)) +
  geom_histogram()

gridExtra::grid.arrange(grobs = list(dm_deriv_hist, dm_abs_deriv_hist))

dm_deriv_eps <- mean(dm_derivs$year[2:200] - dm_derivs$year[1:199])

dm_deriv_net <- sum(dm_derivs$derivative) * dm_deriv_eps

dm_deriv_abs <- sum(dm_derivs$abs_derivative) * dm_deriv_eps

dm_deriv_results <- dm_derivs %>%
  select(year, derivative, abs_derivative, upper, lower) %>%
  mutate(deriv_eps = dm_deriv_eps,
         deriv_net = dm_deriv_net,
         deriv_abs = dm_deriv_abs,
         species = "merriami")

#### dm samples from posterior ####

dm_fd <- gratia:::fderiv(dm_mod, newdata = newd, eps = 1e-07, unconditional = FALSE)

dm_Vb <- vcov(dm_mod, unconditional = FALSE)
set.seed(1977)
dm_sims <- MASS::mvrnorm(300, mu = coef(dm_mod), Sigma = dm_Vb)
dm_X0 <- predict(dm_mod, newd, type = "lpmatrix")
newd <- newd + 1e-07
dm_X1 <- predict(dm_mod, newd, type = "lpmatrix")
dm_Xp <- (dm_X1 - dm_X0) / 1e-07
dm_derivs_draws <- dm_Xp %*% t(dm_sims)


dm_derivs_draws <- as.data.frame(dm_derivs_draws)
dm_derivs_draws$year <- newd$year
dm_derivs_draws <- dm_derivs_draws %>%
  tidyr::pivot_longer(-year, names_to = "draw", names_prefix = "V", values_to = "pred_deriv") %>%
  mutate(draw = as.numeric(draw),
         species = "merriami")

dm_deriv_draw_plot <- ggplot(filter(dm_derivs_draws, draw < 100), aes(year, pred_deriv, group = as.factor(draw), color =as.factor(draw))) +
  geom_line(alpha = .2) +
  theme_bw() +
  geom_hline(yintercept = 0)  +
  theme(legend.position = "none")


dm_deriv_eps <- mean(newd$year[2:200] - newd$year[1:199])

dm_deriv_net <- sum(dm_derivs$derivative) * dm_deriv_eps

dm_deriv_abs <- sum(dm_derivs$abs_derivative) * dm_deriv_eps


dm_deriv_draw_results <- dm_derivs_draws %>%
  rename(derivative = pred_deriv) %>%
  mutate(deriv_eps = dm_deriv_eps,
         abs_derivative = abs(derivative)) %>%
  group_by(draw) %>%
  mutate(deriv_net = sum(derivative) * dm_deriv_eps,
         deriv_abs = sum(abs_derivative) * dm_deriv_eps,
         source = "sim") %>%
  ungroup()

all_dm_deriv <- bind_rows(dm_deriv_draw_results, mutate(dm_deriv_results, draw = -99, source = "fitted")) %>%
  mutate(abs_v_net = deriv_abs / abs(deriv_net))

dm_net_plot <- ggplot(all_dm_deriv, aes(source, y = deriv_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 0)
dm_abs_plot <- ggplot(all_dm_deriv, aes(source, y = deriv_abs)) +
  geom_boxplot()
dm_abs_v_net_plot <- ggplot(all_dm_deriv, aes(source, y = abs_v_net)) +
  geom_boxplot() +
  geom_hline(yintercept = 1)

gridExtra::grid.arrange(grobs = list(dm_real_plot, dm_fit_plot, dm_deriv_plot, dm_deriv_draw_plot), ncol = 1)
gridExtra::grid.arrange(grobs = list(dm_net_plot, dm_abs_plot, dm_abs_v_net_plot), ncol = 3)


#### spectabs ####
ds_real_plot <- ggplot(ts, aes(year, (bannertail))) + geom_line()

ds_mod <-  gam(((bannertail)) ~ s(year), data = ts, method = "REML", family = "gaussian")
#' considerable unknowns w.r.t. correct model fitting.
#' abundance/count data I believe should be poisson. in this instance using gaussian results in negative predicted values for the number of rats, which is not possible
#' derivatives for poisson behave VERY ODDLY
#' do we include term for year without the smooth? here we are not super interested in the significance, etc of various predictors
#' how does one select k?
#' for now proceeding bc I am primarily interested in what we can do with the time series of DERIVATIVES

ds_fit <- add_fitted(select(ts, year, bannertail), ds_mod)

ds_fit_plot <- ggplot(ds_fit, aes(year, (bannertail))) +
  geom_point() +
  geom_line(aes(year, .value))

ds_derivs <- derivatives(ds_mod, n = 200)

ds_derivs <- ds_derivs %>%
  rename(year = data) %>%
  mutate(abs_derivative = abs(derivative))

ds_deriv_plot <- ggplot(ds_derivs, aes(year, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(ds_real_plot, ds_fit_plot, ds_deriv_plot), ncol = 1)

# for now let's look only at the predicted derivative. we have a way to work with samples from the posterior later.

ds_deriv_hist <- ggplot(ds_derivs, aes(derivative)) +
  geom_histogram()

ds_abs_deriv_hist <- ggplot(ds_derivs, aes(abs_derivative)) +
  geom_histogram()

gridExtra::grid.arrange(grobs = list(ds_deriv_hist, ds_abs_deriv_hist))

ds_deriv_eps <- mean(ds_derivs$year[2:200] - ds_derivs$year[1:199])

ds_deriv_net <- sum(ds_derivs$derivative) * ds_deriv_eps

ds_deriv_abs <- sum(ds_derivs$abs_derivative) * ds_deriv_eps

ds_deriv_results <- ds_derivs %>%
  select(year, derivative, abs_derivative, upper, lower) %>%
  mutate(deriv_eps = ds_deriv_eps,
         deriv_net = ds_deriv_net,
         deriv_abs = ds_deriv_abs,
         species = "bannertail")

#### all together ####

all_deriv_results <- bind_rows(list(pp_deriv_results, pp_deriv_results, dm_deriv_results, ds_deriv_results))

all_deriv_results <- all_deriv_results %>%
  mutate(deriv_abs_v_net = deriv_abs / (abs(deriv_net))) %>%
  group_by_all() %>%
  mutate(deriv_not_zero = ifelse(any(all(upper > 0, lower > 0), all(upper < 0, lower < 0)), TRUE, FALSE)) %>%
  ungroup() %>%
  group_by(species) %>%
  mutate(prop_not_zero = mean(deriv_not_zero),
         prop_increasing = mean(derivative > 0),
         prop_decreasing = mean(derivative < 0))


all_real_plot <- ggplot(filter(ts_long, species != "total_abundance"), aes(year, value, color= species)) +
  geom_line() +
  theme_bw() +
  facet_wrap(vars(species), nrow = 1, scales = "fixed")
all_deriv_plot <- ggplot(all_deriv_results, aes(year, derivative, color = species)) +
  geom_line() +
  facet_wrap(vars(species), nrow = 1, scales = "fixed") +
  geom_hline(yintercept = 0)
net_change_plot <- ggplot(all_deriv_results, aes(x = 0, color = species, y = deriv_net)) +
  geom_point()+
  geom_point(aes(x = 1, y = deriv_abs), shape = 3) +
  geom_point(aes(x = .5, y = deriv_abs_v_net), shape = 5) +
  facet_wrap(vars(species), nrow = 1, scales = "free_y") +
  xlim(-.5, 1.5) +
  geom_hline(yintercept = 0)
prop_not0_plot <- ggplot(all_deriv_results, aes(deriv_not_zero, fill = species)) +
  geom_bar() +  facet_wrap(vars(species), nrow = 1, scales = "fixed")
  #ylim(0,1)

deriv_hist_plot <- ggplot(all_deriv_results, aes(x = abs_derivative, fill = species, color = species)) +
  geom_histogram() +
  facet_wrap(vars(species), nrow = 1, scales = "free_y") +
  geom_vline(xintercept = 0)



gridExtra::grid.arrange(grobs = list(all_real_plot, all_deriv_plot, net_change_plot, prop_not0_plot), ncol = 1)


### can I get draws for the derivatives direct from posterior?
#
# ### from https://fromthebottomoftheheap.net/2017/03/21/simultaneous-intervals-for-derivatives-of-smooths/
# ### not successful
# ### I suspect gavin has not implemented this stuff for poisson
#
# m <- pb_mod
#
# ## parameters for testing
# UNCONDITIONAL <- FALSE # unconditional or conditional on estimating smooth params?
# N <- 500             # number of posterior draws
# n <- 200               # number of newdata values
# EPS <- 1e-07           # finite difference
#
#
#
#
# newd <- with(pb_fit, data.frame(year = seq(min(year), max(year), length = n)))
#
#
# fd <- fderiv(m, newdata = newd, eps = EPS, unconditional = UNCONDITIONAL)
#
#
#
#
# set.seed(42)                            # set the seed to make this repeatable
# sint <- confint(fd, type = "simultaneous", nsim = N)
#
# Vb <- vcov(m, unconditional = UNCONDITIONAL)
# set.seed(24)
# sims <- MASS::mvrnorm(N, mu = coef(m), Sigma = Vb)
# X0 <- predict(m, newd, type = "lpmatrix")
# newd <- newd + EPS
# X1 <- predict(m, newd, type = "lpmatrix")
# Xp <- (X1 - X0) / EPS
# derivs <- Xp %*% t(sims)
#
#
# derivs <- as.data.frame(derivs)
# derivs$year <- newd$year
# derivs <- derivs %>%
#   tidyr::pivot_longer(-year, names_to = "draw", names_prefix = "V", values_to = "pred_deriv") %>%
#   mutate(draw = as.numeric(draw))
#
# pb_deriv_draw_plot <- ggplot(filter(derivs, draw < 100), aes(year, pred_deriv, group = as.factor(draw), color =as.factor(draw))) +
#   geom_line(alpha = .2) +
#   theme_bw() +
#   geom_hline(yintercept = 0)  +
#   theme(legend.position = "none")
#
#
# gridExtra::grid.arrange(grobs = list(pb_real_plot, pb_fit_plot, pb_deriv_plot, pb_deriv_draw_plot), ncol = 1)
#

# cool, so, this is a way to get draws for the derivatives
