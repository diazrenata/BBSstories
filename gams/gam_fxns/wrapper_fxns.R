source(here::here("gams", "gam_fxns", "fd_fxns.R"))

# Given a TS, fit a Poisson GAM with k = 5
# Extract the derivatives

mod_wrapper <- function(ts, response_variable = c("abundance", "energy", "biomass", "mean_e", "scaled_energy"), identifier = c("species", "site_name"), k = 3) {

  response <- (match.arg(response_variable))
  ts_id <- match.arg(identifier)

  ts <- ts %>%
    dplyr::rename(dependent = all_of(response),
                  identifier = all_of(ts_id))

  if(response %in% c("energy", "scaled_energy", "biomass")) {
    ts$dependent <- round(ts$dependent)
  }

  if(response != "mean_e") {
  ts_mod <- gam(dependent ~ s(year, k = k), data = ts, method = "REML", family = "poisson")
  } else {
    ts_mod <- gam(dependent ~ s(year, k = k), data = ts, method = "REML")
  }
  ts_mod$identifier <- ts$identifier[1]
  ts_mod$response <- response_variable



  return(ts_mod)
}

fit_wrapper <- function(mod) {

  ts_fit <- add_fitted(model = mod, data = mod$model)

  ts_fit <- ts_fit %>%
    mutate(identifier = mod$identifier) %>%
    rename(fitted_value = .value)

  return(ts_fit)

}

samples_wrapper <- function(mod, seed_seed = NULL, ndraws = 1000) {

  if(is.null(seed_seed)) {
    seed_seed = sample.int(n = 100000, size = 1)
  }

  year_rows <- mod$model %>%
    select(year) %>%
    mutate(row = row_number())

  mod_samples <- fitted_samples(mod, n = 100, seed = seed_seed) %>%
    left_join(year_rows) %>%
    group_by(year) %>%
    mutate(mean = mean(fitted),
           upper = quantile(fitted, probs = .975),
           lower = quantile(fitted, probs = 0.025)) %>%
    ungroup() %>%
    mutate(identifier =  mod$identifier,
           currency = mod$response)
return(mod_samples)

}

deriv_wrapper <- function(mod, seed_seed = NULL, ndraws = 1000) {


  if(is.null(seed_seed)) {
    seed_seed = sample.int(n = 100000, size = 1)
  }

  ts_derivs <- get_many_fd(mod, eps = .1, nsamples = ndraws, seed_seed = seed_seed)

  ts_derivs$identifier <- mod$identifier
  ts_derivs$currency = mod$response
  return(ts_derivs)
}

samples_summary <- function(samples_df) {
  curr <- samples_df$currency[1]
  identif <- samples_df$identifier[1]
  start_row <- min(samples_df$row)
  end_row <- max(samples_df$row)

  samples_df %>%
    filter(row %in% c(start_row, end_row)) %>%
    mutate(order = ifelse(row == start_row, "start", "end")) %>%
    select(order, draw, fitted) %>%
    tidyr::pivot_wider(id_cols = draw, names_from = order, values_from = fitted) %>%
    mutate(net_change = end - start) %>%
    mutate(net_percent_of_start = (abs(net_change) / start) * (net_change / abs(net_change))) %>%
    mutate(currency = curr,
           identifier = identif)
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
           net_percent_of_start = (net_change) / first_value,
           abs_percent_of_start = abs_change / first_value)

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
