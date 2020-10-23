library(gratia)
load_mgcv()

library(dplyr)
library(ggplot2)


datasets <- data.frame(
  dataset_name = c("rockies",
                   "hartland",
                   "alberta",
                   "cochise_birds",
                   "salamonie",
                   "tilden",
                   #"gainesville",
                   #"gainesville_nooutlier",
                   "portal_rats",
                   "mccoy",
                   "cranbury"),
  rtrg_code = c("rtrg_304_17",
                "rtrg_102_18",
                "rtrg_105_4",
                "rtrg_133_6",
                "rtrg_19_35",
                "rtrg_172_14",
                #"rtrg_113_25",
                #"rtrg_113_25",

                NA,
                "rtrg_63_25",
                "rtrg_26_59")
)

ibd <- readRDS(("C:\\Users\\diaz.renata\\Documents\\GitHub\\BBSsize\\analysis\\isd_data\\ibd_isd_bbs_rtrg_304_17.Rds"))

sv <- ibd %>%
  group_by(year) %>%
  summarize(richness = length(unique(id)),
            abundance = dplyr::n(),
            biomass = sum(ind_size),
            energy = sum(ind_b)) %>%
  ungroup() %>%
  mutate(mean_energy = energy / abundance,
         mean_mass = biomass/abundance)

#### abundance

realplot <- ggplot(sv, aes(year, abundance)) + geom_line()

nmod <-  gam(abundance ~ s(year), data = sv, method = "REML")

abund_fit <- add_fitted(sv, nmod)

fitplot <- ggplot(abund_fit, aes(year, abundance)) +
  geom_point() +
  geom_line(aes(year, .value))

derivs <- derivatives(nmod, n = 200)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)

#### energy

realplot <- ggplot(sv, aes(year, energy)) + geom_line()

nmod <-  gam(energy ~ s(year), data = sv, method = "REML")

mod_fit <- add_fitted(sv, nmod)

fitplot <- ggplot(mod_fit, aes(year, energy)) +
  geom_point() +
  geom_line(aes(year, .value))

derivs <- derivatives(nmod, n = 200)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)

#### biomass

realplot <- ggplot(sv, aes(year, scale(biomass))) + geom_line()

nmod <-  gam(scale(biomass) ~ s(year), data = sv, method = "REML")

mod_fit <- add_fitted(sv, nmod)

fitplot <- ggplot(mod_fit, aes(year, scale(biomass))) +
  geom_point() +
  geom_line(aes(year, .value))

derivs <- derivatives(nmod, n = 200)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)


#### richness


realplot <- ggplot(sv, aes(year, richness)) + geom_line()

nmod <-  gam(richness ~ s(year), data = sv, method = "REML")

mod_fit <- add_fitted(sv, nmod)

fitplot <- ggplot(mod_fit, aes(year, richness)) +
  geom_point() +
  geom_line(aes(year, .value))

derivs <- derivatives(nmod, n = 200)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)


# predicted_samples_df <- predicted_samples(nmod, n = 3, seed = 1977) %>%
#   mutate(draw = as.factor(draw))
#
#
#
# ggplot(predicted_samples_df, aes(row, response, group = draw, color = draw)) +
#   geom_line()

#### playing with derivs ####
# this is gross and I don't understand
# stepwidth = 1
#
# fine_years <- data.frame(year = seq(min(sv$year), max(sv$year), by = stepwidth))
#
# fine_samples <- predicted_samples(nmod, n = 1, newdata = fine_years, seed = 1977)
#
# fine_samples_offset <- fine_samples %>%
#   filter(row < max(row)) %>%
#   mutate(next_response = fine_samples$response[-1]) %>%
#   mutate(incremental_slope = (next_response - response) / stepwidth)
#
# sampleplot <- ggplot(fine_samples_offset, aes(row, response)) +
#   geom_line()
#
# derivplot <- ggplot(fine_samples_offset, aes(row, incremental_slope)) +
#   geom_line()
#
# gridExtra::grid.arrange(grobs = list(sampleplot, derivplot), ncol = 1)


nmod <-  gam(scale(energy) ~ s(year), data = sv, method = "REML")

derivs <- derivatives(nmod, n = 200)

head(derivs)

derivs_fit <- derivs %>%
  select(data, derivative) %>%
  rename(year = data) %>%
  mutate(abs_derivative = abs(derivative))

derivs_increments <- derivs_fit$year[ 2:nrow(derivs_fit)] - derivs_fit$year[1:(nrow(derivs_fit)-1)]

net_change <- sum(derivs_fit$derivative) * mean(derivs_increments)

mean_slope <- net_change / (max(derivs_fit$year) - min(derivs_fit$year))

mean(derivs_fit$derivative)

total_change <- sum(derivs_fit$abs_derivative) * mean(derivs_increments)

mean_magnitude <- total_change / (max(derivs_fit$year) - min(derivs_fit$year))

median(derivs_fit$derivative)
median(derivs_fit$abs_derivative)
hist(derivs_fit$derivative)
hist(derivs_fit$abs_derivative)

#
# derivs_sim <- derivs %>%
#   mutate(derivative = rnorm(1, mean = derivative, sd = ))
#   select(data, derivative) %>%
#   rename(year = data) %>%
#   mutate(abs_derivative = abs(derivative))
#
# derivs_increments <- derivs_sim$year[ 2:nrow(derivs_sim)] - derivs_sim$year[1:(nrow(derivs_sim)-1)]
#
# net_change <- sum(derivs_sim$derivative) * mean(derivs_increments)
#
# mean_slope <- net_change / (max(derivs_sim$year) - min(derivs_sim$year))
#
# mean(derivs_sim$derivative)
#
# total_change <- sum(derivs_sim$abs_derivative) * mean(derivs_increments)
#
# mean_magnitude <- total_change / (max(derivs_sim$year) - min(derivs_sim$year))
#
# median(derivs_sim$derivative)
# median(derivs_sim$abs_derivative)
# hist(derivs_sim$derivative)
# hist(derivs_sim$abs_derivative)
