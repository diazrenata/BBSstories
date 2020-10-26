source(here::here("gams", "gam_fxns", "fd_fxns.R"))

# Given a TS, fit a Poisson GAM with k = 5
# Extract the derivatives

mod_wrapper <- function(ts) {

  ts_mod <- gam(abundance ~ s(year, k = 3), data = ts, method = "REML", family = "poisson")

  ts_mod$species <- ts$species[1]


  return(ts_mod)
}

fit_wrapper <- function(mod) {

  ts_fit <- add_fitted(model = mod, data = mod$model)

  ts_fit <- ts_fit %>%
    mutate(species = mod$species) %>%
    rename(fitted_abundance = .value)

  return(ts_fit)

}

deriv_wrapper <- function(mod, seed_seed = NULL) {


  if(is.null(seed_seed)) {
    seed_seed = sample.int(n = 1000, size = 1)
  }

  ts_derivs <- get_many_fd(mod, eps = .1, seed_seed = seed_seed)

  ts_derivs$species <- mod$species

  return(ts_derivs)
}

derivs_summary <- function(derivs_df) {


  derivs_df <- derivs_df %>%
    mutate(abs_derivative = abs(derivative)) %>%
    mutate(increment = derivative * eps,
           abs_increment = abs_derivative * eps)


  derivs_summary <- derivs_df %>%
    group_by(seed, species) %>%
    summarize(net_change = sum(increment),
              abs_change = sum(abs_increment)) %>%
    mutate(abs_v_net_change = log(abs(abs_change / net_change)))

  return(derivs_summary)
}

sign_summary <- function(derivs_df) {
  nincrements <- length(unique(derivs_df$year))

  sign_df <- derivs_df %>%
    select(year, lower, upper, eps, species) %>%
    distinct() %>%
    group_by_all() %>%
    mutate(ci_sign = ifelse(all(upper < 0, lower < 0), "negative",
                            ifelse(all(upper > 0, lower > 0), "positive", "zero"))) %>%
    ungroup() %>%
    group_by(ci_sign) %>%
    summarize(proportion_of_time = dplyr::n() / nincrements) %>%
    mutate(proportion_of_time = ifelse(is.na(proportion_of_time), 0, proportion_of_time)) %>%
    tidyr::pivot_wider(names_from = ci_sign, values_from = proportion_of_time, values_fill = 0) %>%
    mutate(species = derivs_df$species[1])

  return(sign_df)
}
