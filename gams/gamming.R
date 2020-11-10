library(dplyr)
library(gratia)
library(ggplot2)
load_mgcv()

ts <- read.csv(here::here("gams", "working_datasets.csv"))


rats <- filter(ts, site_name == "portal_rats")

portal_mean_perc_e <- sum(rats$energy) / sum(rats$abundance)

rats <- rats %>%
  mutate(rescaled_energy = energy / portal_mean_perc_e)

rats_long <- rats %>%
  select(year, energy, rescaled_energy, abundance) %>%
  tidyr::pivot_longer(-year, names_to = "currency", values_to = "value") %>%
  mutate(currency = as.factor(currency),
         value = round(value))

ggplot(rats_long, aes(year, value, color = currency)) +
  geom_line() +
  theme_bw() +
  scale_color_viridis_d() +
  facet_wrap(vars(currency), scales = "free_y")


# fitting by currency

both_mod <- gam(value ~ s(year, by = currency) + currency, data = filter(rats_long, currency != "energy"), method = "REML", family = "poisson")

# mod check

n_mod <- gam(value ~ s(year) + year, data = filter(rats_long, currency == "abundance"), method = "REML", family = "poisson")

gam.check(n_mod)

n_mod_20 <- gam(value ~ s(year, k =8), data = filter(rats_long, currency == "abundance"), method = "REML", family = "poisson")

gam.check(n_mod_20) # low k-index

AIC(n_mod)
AIC(n_mod_20)

#
# Overfitting
# Selecting significant terms (?)
# Selecting k
#
# Could try AIC plus kindex


n_s_year <- gam(value ~ s(year, k = 8),  data = filter(rats_long, currency == "rescaled_energy"), method = "REML", family = "poisson")
n_year <- gam(value ~ year,  data = filter(rats_long, currency == "rescaled_energy"), method = "REML", family = "poisson")
n_both <- gam(value ~ s(year, k =8) + year,  data = filter(rats_long, currency == "rescaled_energy"), method = "REML", family = "poisson")

gam.check(n_s_year)
gam.check(n_year)
gam.check(n_both)

AIC(n_s_year)
AIC(n_year)
AIC(n_both)

anova(n_s_year, n_year, test = "Chisq")

rats_fits <- gratia::add_fitted(rats, n_s_year, value = "smooth_year") %>%
  add_fitted(n_year, value = "just_year") %>%
  add_fitted(n_both, value = "smooth_and_linear") %>%
  select(year, rescaled_energy, smooth_year, just_year, smooth_and_linear) %>%
  tidyr::pivot_longer(-year, names_to = "fit_method", values_to = "val")


ggplot(rats_fits, aes(year, val, color = fit_method)) +
  geom_line(size = 4, alpha = .5) +
  theme_bw() +
  scale_color_viridis_d(end = .8) +
  geom_point() +
  facet_wrap(vars(fit_method))

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))

smooth_samples <- samples_wrapper(n_s_year) %>%
  mutate(method = "s")
year_samples <- samples_wrapper(n_year) %>%
  mutate(method = "l")
# both_samples <- samples_wrapper(n_both) # fails


joint_samples <- bind_rows(smooth_samples, year_samples) %>%
  select(year, mean, upper, lower, method) %>%
  distinct()

ggplot(joint_samples, aes(year, mean, color = method, fill = method)) +
  geom_line(aes(year, mean)) +
  geom_ribbon(aes(year, ymin = lower, ymax = upper),  alpha = .25) +
  ggtitle("Fits for linear and smooth") +
  theme_bw() +
  scale_color_viridis_d() +
  scale_fill_viridis_d()



### selecting k

ks <- c(4:30)

candidate_mods <- lapply(ks, FUN = function(k) return( gam(value ~ s(year, k = k),  data = filter(rats_long, currency == "rescaled_energy"), method = "REML", family = "poisson")))
linear_mod <- gam(value ~ year,  data = filter(rats_long, currency == "rescaled_energy"), method = "REML", family = "poisson")

candidate_aics <- lapply(candidate_mods, FUN = function(mod) return(data.frame(aic = AIC(mod), deviance = mod$deviance, k = length(mod$coefficients), smooth = T, kscore =  k.check(mod)[,"k-index"]))) %>%
  bind_rows()
linear_aic <- data.frame(k = 0, smooth = F, aic = AIC(linear_mod), deviance = linear_mod$deviance) %>%
  bind_rows(candidate_aics) %>%
  mutate(k_pass = kscore > 1)

ggplot(linear_aic, aes(k, aic, color = k_pass)) + geom_point()
ggplot(linear_aic, aes(k, deviance, color = k_pass)) + geom_point()


### aic does not necessarily bottom out with the lowest k that has a kindex > 1

### i am inclined to select TERMS (linear v smooth) using aic, and use the lowest k that results in a kindex > 1. probably this doesn't matter too much k = 8 v 9 or 10, but I don't want k = 20 if 8 is good enough


