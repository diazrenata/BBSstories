# Following https://fromthebottomoftheheap.net/2016/12/15/simultaneous-interval-revisited/

library(dplyr)
library(ggplot2)

ibd <- readRDS(("C:\\Users\\diaz.renata\\Documents\\GitHub\\BBSsize\\analysis\\isd_data\\ibd_isd_bbs_rtrg_304_17.Rds"))

sv <- ibd %>%
  group_by(year) %>%
  summarize(richness = length(unique(id)),
            abundance = dplyr::n(),
            biomass = sum(ind_size),
            energy = sum(ind_b)) %>%
  ungroup() %>%
  mutate(mean_energy = energy / abundance,
         mean_mass = biomass/abundance,
         site_name = "hartland")

ggplot(sv, aes(year, abundance)) + geom_line()

library(mgcv)

m <- gam(abundance ~ s(year), data = sv, method = "ML")


summary(m)

plot(m, shade = T, seWithMean = T, residuals = T)



rmvn <- function(n, mu, sig) { ## MVN random deviates
  L <- mroot(sig)
  m <- ncol(L)
  t(mu + L %*% matrix(rnorm(m*n), m, n))
}

Vb <- vcov(m)
newd <- with(sv, data.frame(year = seq(min(year), max(year), length = 25)))
pred <- predict(m, newd, se.fit = TRUE)
se.fit <- pred$se.fit



set.seed(42)
N <- 10000



BUdiff <- rmvn(N, mu = rep(0, nrow(Vb)), sig = Vb)

Cg <- predict(m, newd, type = "lpmatrix")
simDev <- Cg %*% t(BUdiff)

absDev <- abs(sweep(simDev, 1, se.fit, FUN = "/"))

masd <- apply(absDev, 2L, max)


crit <- quantile(masd, prob = 0.95, type = 8)


pred <- transform(cbind(data.frame(pred), newd),
                  uprP = fit + (2 * se.fit),
                  lwrP = fit - (2 * se.fit),
                  uprS = fit + (crit * se.fit),
                  lwrS = fit - (crit * se.fit))
ggplot(pred, aes(x = year)) +
  geom_ribbon(aes(ymin = lwrS, ymax = uprS), alpha = 0.2, fill = "red") +
  geom_ribbon(aes(ymin = lwrP, ymax = uprP), alpha = 0.2, fill = "red")





sims <- rmvn(N, mu = coef(m), sig = Vb)
fits <- Cg %*% t(sims)




nrnd <- 30
rnd <- sample(N, nrnd)
stackFits <- stack(as.data.frame(fits[, rnd]))
stackFits <- transform(stackFits, year = rep(newd$year, length(rnd)))




ggplot(pred, aes(x = year, y = fit)) +
  geom_ribbon(aes(ymin = lwrS, ymax = uprS), alpha = 0.2, fill = "red") +
  geom_ribbon(aes(ymin = lwrP, ymax = uprP), alpha = 0.2, fill = "red") +
  geom_path(lwd = 2) +
  geom_path(data = stackFits, mapping = aes(y = values, x = year, group = ind),
            alpha = 0.4, colour = "grey20")


