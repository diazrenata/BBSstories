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
