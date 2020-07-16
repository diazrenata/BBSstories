
fit_breakpoints <- function(dat, h = 4) {


  bp_int <- breakpoints(formula = response ~ 1, data = dat, h =h)

  bp_slope <- breakpoints(formula = response ~ time, data = dat, h = h)

  int_BIC <- BIC(bp_int)
  slope_BIC <- BIC(bp_slope)

  if(int_BIC < slope_BIC) {
    return(bp_int)
  } else {
    return(bp_slope)
  }

}

count_breakpoints <- function(breakpoint_fit) {
  if(is.na(breakpoint_fit$breakpoints[1])) {
    return(0)
  }
return(length(breakpoint_fit$breakpoints))
}

predict_breakpoints <- function(dat, breakpoints_fit) {

  dat <- dat %>%
    dplyr::mutate(fitted = fitted(breakpoints_fit),
                  breakpoints = dplyr::row_number() %in% breakpoints_fit$breakpoints)

  return(dat)
}


summarize_breakpoints <- function(dat, breakpoints_fit) {

  dat <- dat  %>%
    dplyr::mutate(fitted = fitted(breakpoints_fit),
                  breakpoints = dplyr::row_number() %in% breakpoints_fit$breakpoints,
                  nbp = length(breakpoints_fit$breakpoints [ which(!is.na(breakpoints_fit$breakpoints))]),
                  has_slope = any(grepl("time", breakpoints_fit$call)))

  dat$net_change <- dat$fitted[ nrow(dat)] / dat$fitted[1]

  if(isTRUE(all.equal(dat$net_change[1], 1))) {
    dat$net_change <- 1
  }


  changes <- data.frame(
    t = dat$fitted[1: (nrow(dat) - 1)],
    t_plus_1 = dat$fitted[2:nrow(dat)]
  )

  for(i in 1:nrow(changes)) {
    if(isTRUE(all.equal(changes$t[i], changes$t_plus_1[i]))) {
      changes$change[i] <- 0
    } else {
      changes$change[i] <- changes$t_plus_1[i] - changes$t[i]
    }
  }
     changes <- changes %>%
    dplyr::mutate(pos_or_0 = change >= 0,
                  neg_or_0 = change <= 0)

  dat$monotonic <- any(
    sum(changes$pos_or_0) == nrow(changes),
    sum(changes$neg_or_0) == nrow(changes)
  )



  first_five <- dat$response[1:5]
  last_five <- dat$response[(nrow(dat)-4):nrow(dat)]

  dat$cap_ratio <- mean(last_five) / mean(first_five)

  while(any(first_five %in% last_five)) {
    first_five <- first_five + rnorm(n = 5,
                                     0, .05)
    last_five <- last_five + rnorm(n = 5,
                                   0, .05)
  }

  dat$cap_p_wilcox <- wilcox.test(first_five, last_five)$p.value

  dat$lm_ratio<- get_lm_change(thisdat)

  dat$lm_p_ratio<- get_lm_change(thisdat, use_p = T)
  return(dat)

}


plot_breakpoint_fit <- function(dat, h = 4) {

  if(!("fitted" %in% colnames(dat))) {
    bps <- fit_breakpoints(dat, h = h)
    dat <- predict_breakpoints(dat, bps)
  }

  return(ggplot(dat, aes(x = time, y = response)) +
           geom_point() +
           geom_line(aes(x = time, y = fitted)) +
           theme_bw() +
           geom_vline(xintercept = dat$time[which(dat$breakpoints)]) +
           ggtitle(paste0(dat$site_name[1], " ", dat$currency[1])))

}

subset_all_datasets <- function(site, curr, all_datasets) {

  dat <- all_datasets[ , c("site_name", "year", curr)]

  dat <- dat[ which(dat$site_name == site), ]

  colnames(dat)[ which(colnames(dat) == curr)]  <- "response"
  colnames(dat)[ which(colnames(dat) == "year")] <- "time"

  dat$currency <- curr

  return(dat)

}

filter_caps <- function(datasets_to_pass, site, currency = "abundance") {

  colnames(datasets_to_pass)[ which(colnames(datasets_to_pass) == currency)] <- "response"

  some_caps <- filter(datasets_to_pass, site_name == site, in_cap) %>%
    select(which_cap,
           response,
           site_name,
           ntimesteps) %>%
    mutate(currency = currency)
  return(some_caps)
}

compare_caps <- function(some_caps) {

  caps_lm <- lm((response) ~ which_cap, some_caps)

  # add a VERY SMALL AMOUNT of noise to avoid ties
  if(length(unique(some_caps$response)) < length(some_caps$response)) {
    some_caps$response = some_caps$response +
      rnorm(n = length(some_caps$response),
            0, .05)
  }

  caps_wilcox <- wilcox.test(response ~ which_cap, some_caps)

  some_caps_results <- some_caps %>%
    mutate(site_name= as.character(site_name)) %>%
    group_by(which_cap, site_name, currency) %>%
    summarize(mean = mean(response),
              sd = sd(response)) %>%
    ungroup()


  some_caps_results <- some_caps_results %>%
    mutate(pval = summary(caps_lm)$coefficients[2, 4],
           ratio = some_caps_results$mean[2] /
             some_caps_results$mean[1],
           wilcox_pval = caps_wilcox$p.value,
           response_lower = mean - sd,
           response_upper = mean + sd)



  return(some_caps_results)
}



get_lm_change <- function(this_dat, use_p = F) {


  int_lm <- lm(response ~ 1, this_dat)
  slope_lm <- lm(response ~ time, this_dat)

  if(BIC(int_lm) < BIC(slope_lm)) {
    best_lm <- (int_lm)
  } else {
    best_lm <- (slope_lm)
  }

  if(use_p) {

    lm_compare <- anova(int_lm, slope_lm)

    lm_p <- lm_compare$`Pr(>F)`[2]

    if(lm_p < .05) {
      best_lm <- (slope_lm)
    } else {
      best_lm <- (int_lm)
    }
  }
  preds <- predict(best_lm)

  pred_ratio <- preds[ length(preds)] / preds[1]

  return(pred_ratio)
}

plot_lm_change <- function(this_dat, use_p = F) {

  int_lm <- lm(response ~ 1, this_dat)
  slope_lm <- lm(response ~ time, this_dat)

  if(BIC(int_lm) < BIC(slope_lm)) {
    best_lm <- (int_lm)
    lm_color <- "blue"
  } else {
    best_lm <- (slope_lm)
    lm_color <- "red"
  }

  if(use_p) {

    lm_compare <- anova(int_lm, slope_lm)

    lm_p <- lm_compare$`Pr(>F)`[2]

    if(lm_p < .05) {
      best_lm <- (slope_lm)
      lm_color <- "red"

    } else {
      best_lm <- (int_lm)
      lm_color <- "blue"

    }
  }

  this_dat$preds <- predict(best_lm)


  this_plot <- ggplot(this_dat, aes(time, response)) +
    geom_point() +
    geom_line(aes(time, preds), color = lm_color) +
    theme_bw() +
    ggtitle(this_dat$site_name[1])

  return(this_plot)
}
