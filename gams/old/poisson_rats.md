Rats with Poisson GAMs
================

## The data

``` r
ts <- read.csv(here::here("gams", "rat_data.csv"))

ts_long <- ts %>%
  select(year, baileys, bannertail, merriami, pocketmouse) %>%
  tidyr::pivot_longer(-year, names_to = "species", values_to = "abundance") %>%
  filter(species != "total_abundance")

ggplot(ts_long, aes(year, abundance, color = species)) +
  geom_line() +
  theme_bw() +
  facet_wrap(vars(species))
```

![](poisson_rats_files/figure-gfm/show%20rat%20ts-1.png)<!-- -->

## Baileys walkthrough

### Fit GAM and extract derivative

``` r
pb_real_plot <- ggplot(ts, aes(year, baileys)) +
  geom_line()

pb_mod <- gam(baileys ~ s(year, k = 5), data = ts, method = "REML", family = "poisson")

pb_fit <- add_fitted(select(ts, year, baileys), pb_mod)

pb_fit_plot <- ggplot(pb_fit, aes(year, (baileys))) +
  geom_point() +
  geom_line(aes(year, .value))

pb_derivs <- get_many_fd(pb_mod, eps = .1)

pb_deriv_plot <- ggplot(pb_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .01) +
  geom_hline(yintercept = 0) +
  geom_line(aes(year, mean), color = "red") +
  geom_line(aes(year, upper), color = "red") +
  geom_line(aes(year, lower), color = "red")

gridExtra::grid.arrange(grobs = list(pb_real_plot, pb_fit_plot, pb_deriv_plot), ncol = 1)
```

![](poisson_rats_files/figure-gfm/fit%20gam%20and%20get%20derivatives-1.png)<!-- -->

### Summarizing derivatives

#### Net and absolute change

``` r
pb_derivs <- pb_derivs %>%
  mutate(abs_derivative = abs(derivative)) %>%
  mutate(increment = derivative * eps,
         abs_increment = abs_derivative * eps)

pb_deriv_net <- sum(pb_derivs$increment)

pb_deriv_abs <- sum(pb_derivs$abs_increment)

pb_derivs_summary <- pb_derivs %>%
  group_by(seed) %>%
  summarize(net_change = sum(increment),
            abs_change = sum(abs_increment)) %>%
  mutate(abs_v_net_change = log(abs_change / net_change))
```

    ## `summarise()` ungrouping output (override with `.groups` argument)

``` r
net_plot <- ggplot(pb_derivs_summary, aes(net_change)) +
  geom_density() +
  geom_vline(xintercept = 0)


abs_plot <- ggplot(pb_derivs_summary, aes(abs_change)) +
  geom_density() +
  geom_vline(xintercept = 0)


net_v_abs_plot <- ggplot(pb_derivs_summary, aes(abs_v_net_change)) +
  geom_density() +
  geom_vline(xintercept = 0)

gridExtra::grid.arrange(grobs = list(net_plot, abs_plot, net_v_abs_plot), nrow = 1)
```

![](poisson_rats_files/figure-gfm/net%20and%20absolute%20change-1.png)<!-- -->

From left to right, the net change over the TS, the absolute change
(increasing + decreasing), and the log ratio of the absolute change to
the net change.

  - If the **net** change overlaps 0 to some confidence interval, an
    argument that we don’t confidently have an overall increase or
    decrease over the full timeseries.
  - If the **absolute** change **matches** the net change, whatever
    change occurred occurred in a consistent direction. The more the
    absolute change exceeds the net change, the more peaks and valleys
    occurred that may or may not be reflected in the net change.

#### Duration of change

``` r
pb_derivs <- pb_derivs %>%
  group_by_all() %>%
  mutate(ci_sign = ifelse(all(upper < 0, lower < 0), "negative", 
                          ifelse(all(upper > 0, lower > 0), "positive", "zero"))) %>%
  ungroup()

pb_derivs_sign <- select(pb_derivs, year, mean, eps, ci_sign) %>%
  distinct()

sign_plot <- ggplot(pb_derivs_sign, aes(year, mean, color = ci_sign)) +
  geom_line(size = 5) +
  theme(legend.position = "none")

sign_barplot <- ggplot(pb_derivs_sign, aes(ci_sign, fill = ci_sign)) +
  geom_bar() 

gridExtra::grid.arrange(grobs = list(sign_plot, sign_barplot), nrow = 1)
```

![](poisson_rats_files/figure-gfm/duration%20of%20change-1.png)<!-- -->

``` r
pb_derivs_sign %>%
  group_by(ci_sign) %>%
  summarize(proportion_of_time = dplyr::n() / nrow(pb_derivs_sign),
            total_time = sum(eps))
```

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 3 x 3
    ##   ci_sign  proportion_of_time total_time
    ##   <chr>                 <dbl>      <dbl>
    ## 1 negative            0.381         14.1
    ## 2 positive            0.614         22.7
    ## 3 zero                0.00541        0.2

``` r
pb_derivs_sign <- pb_derivs_sign %>%
  mutate(nind_over_ts = mean * eps * nrow(pb_derivs_sign)) %>%
  mutate(greater_than_10 = abs(nind_over_ts) > 10)

ggplot(pb_derivs_sign, aes(year, mean, color = ci_sign)) + 
  geom_line(size = 5, alpha = .2) + 
  geom_line(data = filter(pb_derivs_sign, greater_than_10), aes(year, mean, color = ci_sign), size = 5, alpha = .8)
```

![](poisson_rats_files/figure-gfm/nind%20over%20ts-1.png)<!-- -->

#### Gradual vs rapid change

I’m not sure how to do this.

``` r
ggplot(pb_derivs_sign, aes(abs(mean))) +
  geom_density() +
  geom_vline(xintercept = quantile(abs(pb_derivs_sign$mean), probs = c(.025, .1, .5, .9, .975, 1)))
```

![](poisson_rats_files/figure-gfm/variability%20of%20change-1.png)<!-- -->
