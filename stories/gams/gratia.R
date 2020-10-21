library(gratia)
load_mgcv()
# # \dontshow{
# set.seed(42)
# op <- options(cli.unicode = FALSE)
# # }
# dat <- gamSim(1, n = 400, dist = "normal", scale = 2, verbose = FALSE)
# mod <- gam(y ~ s(x0), data = dat, method = "REML")
#
# ## first derivatives of all smooths using central finite differences
# derivs <- derivatives(mod, type = "central")
# #> # A tibble: 800 x 8
# #>    smooth var       data derivative    se  crit lower upper
# #>    <chr>  <chr>    <dbl>      <dbl> <dbl> <dbl> <dbl> <dbl>
# #>  1 s(x0)  x0    0.000239       7.41  3.33  1.96 0.874  13.9
# #>  2 s(x0)  x0    0.00525        7.41  3.33  1.96 0.875  13.9
# #>  3 s(x0)  x0    0.0103         7.40  3.33  1.96 0.884  13.9
# #>  4 s(x0)  x0    0.0153         7.40  3.31  1.96 0.902  13.9
# #>  5 s(x0)  x0    0.0203         7.39  3.30  1.96 0.929  13.8
# #>  6 s(x0)  x0    0.0253         7.38  3.27  1.96 0.965  13.8
# #>  7 s(x0)  x0    0.0303         7.36  3.24  1.96 1.01   13.7
# #>  8 s(x0)  x0    0.0353         7.34  3.20  1.96 1.07   13.6
# #>  9 s(x0)  x0    0.0403         7.32  3.15  1.96 1.14   13.5
# #> 10 s(x0)  x0    0.0453         7.29  3.10  1.96 1.21   13.4
# #> # ... with 790 more rows# \dontshow{


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

ibd <- readRDS(("C:\\Users\\diaz.renata\\Documents\\GitHub\\BBSsize\\analysis\\isd_data\\ibd_isd_bbs_rtrg_19_35.Rds"))

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

derivs <- derivatives(nmod, n = 100)

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

derivs <- derivatives(nmod, n = 100)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)

#### biomass

realplot <- ggplot(sv, aes(year, biomass)) + geom_line()

nmod <-  gam(biomass ~ s(year), data = sv, method = "REML")

mod_fit <- add_fitted(sv, nmod)

fitplot <- ggplot(mod_fit, aes(year, biomass)) +
  geom_point() +
  geom_line(aes(year, .value))

derivs <- derivatives(nmod, n = 100)

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

derivs <- derivatives(nmod, n = 100)

derivplot <- ggplot(derivs, aes(data, derivative)) +
  geom_point() +
  geom_errorbar(aes( ymin=lower, ymax = upper)) +
  geom_hline(yintercept = 0)

# derivplot

gridExtra::grid.arrange(grobs = list(realplot, fitplot, derivplot), ncol = 1)

