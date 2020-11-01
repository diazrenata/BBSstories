library(dplyr)
library(gratia)
library(ggplot2)
load_mgcv()

ts <- read.csv(here::here("gams", "working_datasets.csv"))

rats <- filter(ts, site_name == "portal_rats")

a_mod <- gam(round(energy) ~ s(year, k = 5), data = rats, family = "poisson")

newdat <- data.frame(
  year = seq(min(rats$year), max(rats$year), by = 1)
)

a_sample <- fitted_samples(a_mod, n = 1, seed = 1977, newdata = newdat) %>%
  mutate(year = newdat$year)

head(a_sample)

plot(a_sample$row, a_sample$fitted)

samples1 <- a_sample[1:nrow(a_sample)-1,]
samples2 <- a_sample[2:nrow(a_sample),]

samples3 <- data.frame(
  year = (samples1$year + samples2$year) / 2,
  fd = samples2$fitted - samples1$fitted,
  fd_r0 = samples2$fitted / samples1$fitted
)

ggplot(samples3, aes(year, fd_r0)) +
  geom_point() +
  geom_hline(yintercept = 1)

ggplot(samples3, aes(year, fd)) +
  geom_point() +
  geom_hline(yintercept = 0)
