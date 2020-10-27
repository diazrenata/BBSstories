source(here::here("gams", "gam_fxns", "fd_fxns.R"))

# Given a TS, fit a Poisson GAM with k = 5
# Extract the derivatives

mod_wrapper <- function(ts, response_variable = c("abundance", "energy", "biomass"), identifier = c("species", "site_name"), k = 3) {

  response <- (match.arg(response_variable))
  ts_id <- match.arg(identifier)

  ts <- ts %>%
    dplyr::rename(dependent = response,
                  identifier = ts_id)

  ts_mod <- gam(dependent ~ s(year, k = k), data = ts, method = "REML", family = "poisson")

  ts_mod$identifier <- ts$identifier[1]


  return(ts_mod)
}

fit_wrapper <- function(mod) {

  ts_fit <- add_fitted(model = mod, data = mod$model)

  ts_fit <- ts_fit %>%
    mutate(identifier = mod$identifier) %>%
    rename(fitted_value = .value)

  return(ts_fit)

}

deriv_wrapper <- function(mod, seed_seed = NULL) {


  if(is.null(seed_seed)) {
    seed_seed = sample.int(n = 1000, size = 1)
  }

  ts_derivs <- get_many_fd(mod, eps = .1, seed_seed = seed_seed)

  ts_derivs$identifier <- mod$identifier

  return(ts_derivs)
}

derivs_summary <- function(derivs_df) {


  derivs_df <- derivs_df %>%
    mutate(abs_derivative = abs(derivative)) %>%
    mutate(increment = derivative * eps,
           abs_increment = abs_derivative * eps)


  derivs_summary <- derivs_df %>%
    group_by(seed, identifier, first_value) %>%
    summarize(net_change = sum(increment),
              abs_change = sum(abs_increment)) %>%
    mutate(abs_v_net_change = log(abs(abs_change / net_change)),
           net_percent_of_start = (net_change) / first_value)

  return(derivs_summary)
}

sign_summary <- function(derivs_df) {
  nincrements <- length(unique(derivs_df$year))

  sign_df <- derivs_df %>%
    select(year, lower, upper, eps, identifier) %>%
    distinct() %>%
    group_by_all() %>%
    mutate(ci_sign = ifelse(all(upper < 0, lower < 0), "negative",
                            ifelse(all(upper > 0, lower > 0), "positive", "zero"))) %>%
    ungroup() %>%
    group_by(ci_sign) %>%
    summarize(proportion_of_time = dplyr::n() / nincrements) %>%
    mutate(proportion_of_time = ifelse(is.na(proportion_of_time), 0, proportion_of_time)) %>%
    tidyr::pivot_wider(names_from = ci_sign, values_from = proportion_of_time, values_fill = 0) %>%
    mutate(identifier = derivs_df$identifier[1])

  return(sign_df)
}
