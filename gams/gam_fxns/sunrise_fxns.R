
instant_change_wrapper <- function(samples_df) {

  samples_plus_one <- samples_df %>%
    select(row, draw, fitted, identifier, currency) %>%
    mutate(row = row + 1) %>%
    rename(fitted_t_minus_one = fitted)

  samples_df_change <- left_join(samples_df, samples_plus_one) %>%
    filter(row != 1) %>%
    mutate(tstep_change = fitted - fitted_t_minus_one) %>%
    mutate(instant_change_proportional = tstep_change / fitted_t_minus_one) %>%
    select(row, draw, year, instant_change_proportional, tstep_change, identifier, currency)

  samples_df_change
}


instant_change_summary_wrapper <- function(instant_change_df) {

  instant_change_df <- instant_change_df %>%
    group_by(currency, identifier, row, year) %>%
    summarize(mean_ichange_proportional = mean(instant_change_proportional),
              lower_ichange_proportional = quantile(instant_change_proportional, probs = .025),
              upper_ichange_proportional = quantile(instant_change_proportional, probs = .975))

  instant_change_df

}

instant_change_absolute_summary_wrapper <- function(instant_change_df) {
  instant_change_df <- instant_change_df %>%
    mutate(absolute_change = abs(instant_change_proportional)) %>%
    group_by(currency, identifier, draw) %>%
    summarize(mean_ichange_over_ts = mean(instant_change_proportional),
              mean_abs_ichange_over_ts = mean(absolute_change)) %>%
    ungroup()

  instant_change_df
}
  net_change_wrapper <- function(samples_df) {
    curr = samples_df$currency[1]
    identif = samples_df$identifier[1]

    start_row <- min(samples_df$row)
    end_row <- max(samples_df$row)

    change_df <- samples_df %>%
      filter(row %in% c(start_row, end_row)) %>%
      mutate(order = ifelse(row == start_row, "start", "end")) %>%
      select(order, draw, fitted) %>%
      tidyr::pivot_wider(id_cols = draw, names_from = order, values_from = fitted) %>%
      mutate(net_change = end - start) %>%
      mutate(net_proportional = net_change / start) %>%
      mutate(currency = curr,
             identifier = identif)

    return(change_df)

  }

  change_summary_wrapper <- function(change_df) {

    change_df <- change_df %>%
      group_by(currency, identifier) %>%
      summarize(mean_net_proportional = mean(net_proportional),
                lower_net_proportional = quantile(net_proportional, probs = .025),
                upper_net_proportional = quantile(net_proportional, probs = .975))

    change_df

  }
