Birds - energy v abundance
================

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(gratia)
```

    ## Warning: package 'gratia' was built under R version 4.0.3

``` r
library(ggplot2)
load_mgcv()

ts <- read.csv(here::here("gams", "working_datasets.csv"))

unique_sites <- unique(ts$site_name)

site_dfs <- lapply(unique_sites, FUN = function(site, full_ts) return(filter(full_ts, site_name == site)), full_ts = ts)

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))
```

### Using Hartland

``` r
birds <- filter(ts, site_name == "hartland")

abund_real <- ggplot(birds, aes(year, abundance)) +
  geom_line()

energy_real <- ggplot(birds, aes(year, energy)) +
  geom_line()

meane_real <- ggplot(birds, aes(year, mean_energy)) +
  geom_line() 

gridExtra::grid.arrange(grobs = list(abund_real, energy_real, meane_real), nrow = 1)
```

![](birds_energy_files/figure-gfm/select%20hartland-1.png)<!-- -->

### Fit raw N and E and compare net

``` r
e_mod <- mod_wrapper(birds, response_variable = "energy", identifier = "site_name", k = 5)
```

    ## Note: Using an external vector in selections is ambiguous.
    ## i Use `all_of(response)` instead of `response` to silence this message.
    ## i See <https://tidyselect.r-lib.org/reference/faq-external-vector.html>.
    ## This message is displayed once per session.

    ## Note: Using an external vector in selections is ambiguous.
    ## i Use `all_of(ts_id)` instead of `ts_id` to silence this message.
    ## i See <https://tidyselect.r-lib.org/reference/faq-external-vector.html>.
    ## This message is displayed once per session.

``` r
n_mod <- mod_wrapper(birds, response_variable = "abundance", identifier = "site_name", k = 5)

e_fit <- fit_wrapper(e_mod)
n_fit <- fit_wrapper(n_mod)

e_derivs <- deriv_wrapper(e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

e_derivs_summary <- derivs_summary(e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(e_v_n_summary, aes(mean(net_percent_of_start_abundance), mean(net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  xlim(-.5, .5) +
  ylim(-.5, .5) +
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/raw%20separate-1.png)<!-- -->

If you had many points, this could show you…

  - If N or E increases/decreases/sits on 0 more
  - If the trend for E matches the trend for N

In this case, E and N are behaving differently…. N has declined by about
15% relative to its starting value, but E has increased about 10-12%.

``` r
ggplot(e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/raw%20derivs%20plots-1.png)<!-- -->

``` r
ggplot(e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/raw%20derivs%20plots-2.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/raw%20derivs%20plots-3.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/raw%20derivs%20plots-4.png)<!-- -->

``` r
many_summaries <- list()

for(i in 1:length(unique_sites)) {

e_mod <- mod_wrapper(filter(ts, site_name == unique_sites[i]), response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(filter(ts, site_name == unique_sites[i]), response_variable = "abundance", identifier = "site_name", k = 5)

e_derivs <- deriv_wrapper(e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

e_derivs_summary <- derivs_summary(e_derivs) %>%
  mutate(currency = "energy")
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

many_summaries[[i]] <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = c(seed, identifier), names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))
}
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
many_summaries <- bind_rows(many_summaries) %>%
  group_by(identifier) %>%
  mutate(mean_net_abund = mean(net_percent_of_start_abundance),
         mean_net_energy = mean(net_percent_of_start_energy))


ggplot(many_summaries, aes(net_percent_of_start_abundance, net_percent_of_start_energy, group = identifier, color = identifier)) +
  geom_point() +
  geom_label(aes(mean_net_abund, mean_net_energy, label = identifier)) +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/raw%20separate%20many-1.png)<!-- --> I
guess, often they are in the same quadrant at least. Notably, you never
see abundance increase and energy decline.

### Mean e

``` r
meane_real
```

![](birds_energy_files/figure-gfm/mean%20e-1.png)<!-- -->

``` r
mean_e_mod <- gam(round(mean_energy) ~ s(year), data = birds, method = "REML")
mean_e_mod$identifier <- "hartland"
mean_e_mod_p <- gam(round(mean_energy) ~ s(year), data= birds, method = "REML", family = "poisson")
AIC(mean_e_mod)
```

    ## [1] 279.5893

``` r
AIC(mean_e_mod_p)
```

    ## [1] 432.3691

``` r
mean_e_fit <- fit_wrapper(mean_e_mod)

ggplot(mean_e_fit, aes(year, `round(mean_energy)`)) +
  geom_line() +
  geom_line(aes(year, fitted_value), color = "blue")
```

![](birds_energy_files/figure-gfm/mean%20e-2.png)<!-- -->

``` r
mean_e_derivs <- deriv_wrapper(mean_e_mod, seed_seed = 1977, ndraws =100)

ggplot(mean_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) 
```

![](birds_energy_files/figure-gfm/mean%20e-3.png)<!-- -->

``` r
mean_e_derivs_summary <- derivs_summary(mean_e_derivs)
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
ggplot(mean_e_derivs_summary, aes(net_percent_of_start)) +
  geom_histogram()
```

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![](birds_energy_files/figure-gfm/mean%20e-4.png)<!-- -->

``` r
mean_e_summaries <- list() 

for(i in 1:length(unique_sites)) {
mean_e_mod <- gam((mean_energy) ~ s(year), data = filter(ts, site_name == unique_sites[i]), method = "REML")
mean_e_mod$identifier <- unique_sites[i]

mean_e_derivs <- deriv_wrapper(mean_e_mod, seed_seed = 1977, ndraws =100)

mean_e_summaries[[i]] <- derivs_summary(mean_e_derivs)
}
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
mean_e_summaries <- bind_rows(mean_e_summaries)

ggplot(mean_e_summaries, aes(identifier, net_percent_of_start)) +
  geom_boxplot() +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/mean%20e%20scale-1.png)<!-- -->

``` r
ggplot(ts, aes(year, mean_energy)) +
  geom_line() +
  facet_wrap(vars(site_name), scales = "free")
```

![](birds_energy_files/figure-gfm/mean%20e%20scale-2.png)<!-- -->

Anecdotally…. the only sites where mean\_e **appears** to change
directionally are tilden and portal\_rats. These are the only sites for
which the mean\_e net change entirely falls off of 0. These are also the
sites for which the net change in energy vs net change in abundance are
well off the 1:1 line.

### Scaled and compared directly

``` r
scaled_birds <- birds %>%
  mutate(energy = scale(energy),
         abundance = scale(abundance))

scaled_n_mod <- gam(abundance ~ s(year), data = scaled_birds, method = "REML")

scaled_n_mod$identifier = "hartland"

scaled_e_mod <- gam(energy ~ s(year), data = scaled_birds, method = "REML")
scaled_e_mod$identifier = "hartland"



scaled_n_fit <- fit_wrapper(scaled_n_mod) %>%
  mutate(currency = "abundance") %>%
  rename(response = abundance)
scaled_e_fit <- fit_wrapper(scaled_e_mod) %>%
  mutate(currency = "energy") %>%
  rename(response = energy)

twofits <- bind_rows(scaled_n_fit, scaled_e_fit)

ggplot(twofits, aes(year, response, color = currency, group = currency)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/scaled%20e%20and%20n-1.png)<!-- -->

``` r
scaled_e_derivs <- deriv_wrapper(scaled_e_mod, seed_seed = 1977, ndraws = 100)

scaled_n_derivs <- deriv_wrapper(scaled_n_mod, seed_seed = 1977, ndraws = 100)



e_scaled_summary <- derivs_summary(scaled_e_derivs) %>%
  mutate(currency  = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_scaled_summary <- derivs_summary(scaled_n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
scaled_summaries <- bind_rows(e_scaled_summary, n_scaled_summary) %>%
  tidyr::pivot_wider(id_cols = c(seed, identifier), names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

scaled_e_derivs <- scaled_e_derivs %>%
  select(year, upper, lower, mean) %>%
  distinct() %>%
  mutate(currency = "energy")

scaled_n_derivs <- scaled_n_derivs %>%
  select(year, upper, lower, mean) %>%
  distinct() %>%
  mutate(currency = "abundance")

scaled_derivs <- bind_rows(scaled_e_derivs, scaled_n_derivs) 


ggplot(scaled_derivs, aes(year, mean, color = currency, group = currency)) +
  geom_line() +
  geom_line(aes(year, upper)) +
  geom_line(aes(year, lower)) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/scaled%20e%20and%20n-2.png)<!-- -->

``` r
ggplot(scaled_summaries, aes(mean(net_percent_of_start_abundance), mean(net_percent_of_start_energy))) +
  geom_point() +
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0) +
  xlim(-10,10) +
  ylim(-10,10)
```

![](birds_energy_files/figure-gfm/scaled%20e%20and%20n-3.png)<!-- --> -
Scaling and using the gaussian model changes the ways the models fit -
no more wiggles. - Also changes the outcome for energy. - Unclear what
the magnitude means when you have a scaled response variable. - Does
however put the derivatives on the same scale so you can compare them a
little more directly.

### Rescaling just E

``` r
hartland_mean_perc_e <- sum(birds$energy) / sum(birds$abundance)

birds <- birds %>% 
  mutate(rescaled_energy = energy / hartland_mean_perc_e)


ggplot(birds, aes(year, energy)) +
  geom_line()
```

![](birds_energy_files/figure-gfm/just%20e-1.png)<!-- -->

``` r
ggplot(birds, aes(year, rescaled_energy)) +
  geom_line() +
  geom_line(aes(year, abundance, color = "abund"))
```

![](birds_energy_files/figure-gfm/just%20e-2.png)<!-- -->

``` r
birds_rs <- birds %>%
  mutate(energy = rescaled_energy)

re_e_mod <- mod_wrapper(birds_rs, response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(birds_rs, response_variable = "abundance", identifier = "site_name", k = 5)

re_e_fit <- fit_wrapper(re_e_mod)
n_fit <- fit_wrapper(n_mod)

re_e_derivs <- deriv_wrapper(re_e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

re_e_derivs_summary <- derivs_summary(re_e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

re_e_v_n_summary <- bind_rows(re_e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(re_e_v_n_summary, aes(mean(net_percent_of_start_abundance), mean(net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/just%20e-3.png)<!-- -->

``` r
ggplot(re_e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e-4.png)<!-- -->

``` r
ggplot(re_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e-5.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e-6.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e-7.png)<!-- -->

``` r
both_derivs <- bind_rows(energy = re_e_derivs, abund= n_derivs, .id = "currency")

ggplot(filter(both_derivs, currency == "energy"), aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) +
  geom_line(data = filter(both_derivs, currency == "abund"), inherit.aes = T, alpha = .1, color = "green")
```

![](birds_energy_files/figure-gfm/just%20e-8.png)<!-- -->

``` r
both_derivs %>%
  group_by(currency, seed) %>%
  summarize(sd = sd(derivative),
            cv = sd(derivative) / mean(derivative)) %>%
  ungroup() %>%
  group_by(currency) %>%
  summarize(mean_cv = mean(cv),
            mean_sd = mean(sd))
```

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 2 x 3
    ##   currency mean_cv mean_sd
    ##   <chr>      <dbl>   <dbl>
    ## 1 abund      -3.13    11.2
    ## 2 energy     15.0     27.2

#### With portal

``` r
rats <- filter(ts, site_name == "portal_rats")

portal_mean_perc_e <- sum(rats$energy) / sum(rats$abundance)

rats <- rats %>% 
  mutate(rescaled_energy = energy / portal_mean_perc_e)


ggplot(rats, aes(year, energy)) +
  geom_line()
```

![](birds_energy_files/figure-gfm/just%20e%20portal-1.png)<!-- -->

``` r
ggplot(rats, aes(year, rescaled_energy)) +
  geom_line() +
  geom_line(aes(year, abundance, color = "abund"))
```

![](birds_energy_files/figure-gfm/just%20e%20portal-2.png)<!-- -->

``` r
rats_rs <- rats %>%
  mutate(energy = rescaled_energy)

re_e_mod <- mod_wrapper(rats_rs, response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(rats_rs, response_variable = "abundance", identifier = "site_name", k = 5)

re_e_fit <- fit_wrapper(re_e_mod)
n_fit <- fit_wrapper(n_mod)

re_e_derivs <- deriv_wrapper(re_e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

re_e_derivs_summary <- derivs_summary(re_e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

re_e_v_n_summary <- bind_rows(re_e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(re_e_v_n_summary, aes(mean(net_percent_of_start_abundance), mean(net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/just%20e%20portal-3.png)<!-- -->

``` r
ggplot(re_e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20portal-4.png)<!-- -->

``` r
ggplot(re_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20portal-5.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20portal-6.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20portal-7.png)<!-- -->

``` r
both_derivs <- bind_rows(energy = re_e_derivs, abund= n_derivs, .id = "currency")

ggplot(filter(both_derivs, currency == "energy"), aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) +
  geom_line(data = filter(both_derivs, currency == "abund"), inherit.aes = T, alpha = .1, color = "green")
```

![](birds_energy_files/figure-gfm/just%20e%20portal-8.png)<!-- -->

``` r
both_derivs %>%
  group_by(currency, seed) %>%
  summarize(sd = sd(derivative),
            cv = sd(derivative) / mean(derivative)) %>%
  ungroup() %>%
  group_by(currency) %>%
  summarize(mean_cv = mean(cv),
            mean_sd = mean(sd))
```

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 2 x 3
    ##   currency mean_cv mean_sd
    ##   <chr>      <dbl>   <dbl>
    ## 1 abund      0.446    1.42
    ## 2 energy     4.80     2.62

#### With alberta (tracks)

``` r
alberta <- filter(ts, site_name == "alberta")

alberta_mean_perc_e <- sum(alberta$energy) / sum(alberta$abundance)

alberta <- alberta %>% 
  mutate(rescaled_energy = energy / alberta_mean_perc_e)


ggplot(alberta, aes(year, energy)) +
  geom_line()
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-1.png)<!-- -->

``` r
ggplot(alberta, aes(year, rescaled_energy)) +
  geom_line() +
  geom_line(aes(year, abundance, color = "abund"))
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-2.png)<!-- -->

``` r
alberta_rs <- alberta %>%
  mutate(energy = rescaled_energy)

re_e_mod <- mod_wrapper(alberta_rs, response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(alberta_rs, response_variable = "abundance", identifier = "site_name", k = 5)

re_e_fit <- fit_wrapper(re_e_mod)
n_fit <- fit_wrapper(n_mod)

re_e_derivs <- deriv_wrapper(re_e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

re_e_derivs_summary <- derivs_summary(re_e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

re_e_v_n_summary <- bind_rows(re_e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(re_e_v_n_summary, aes((net_percent_of_start_abundance), (net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-3.png)<!-- -->

``` r
ggplot(re_e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-4.png)<!-- -->

``` r
ggplot(re_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-5.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-6.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-7.png)<!-- -->

``` r
both_derivs <- bind_rows(energy = re_e_derivs, abund= n_derivs, .id = "currency")

ggplot(filter(both_derivs, currency == "energy"), aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) +
  geom_line(data = filter(both_derivs, currency == "abund"), inherit.aes = T, alpha = .1, color = "green")
```

![](birds_energy_files/figure-gfm/just%20e%20alberta-8.png)<!-- -->

``` r
both_derivs %>%
  group_by(currency, seed) %>%
  summarize(sd = sd(derivative),
            cv = sd(derivative) / mean(derivative)) %>%
  ungroup() %>%
  group_by(currency) %>%
  summarize(mean_cv = mean(cv),
            mean_sd = mean(sd))
```

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 2 x 3
    ##   currency mean_cv mean_sd
    ##   <chr>      <dbl>   <dbl>
    ## 1 abund      -1.26    13.4
    ## 2 energy     -1.23    17.1

#### With tilden

``` r
tilden <- filter(ts, site_name == "tilden")

tilden_mean_perc_e <- sum(tilden$energy) / sum(tilden$abundance)

tilden <- tilden %>% 
  mutate(rescaled_energy = energy / tilden_mean_perc_e)


ggplot(tilden, aes(year, energy)) +
  geom_line()
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-1.png)<!-- -->

``` r
ggplot(tilden, aes(year, rescaled_energy)) +
  geom_line() +
  geom_line(aes(year, abundance, color = "abund"))
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-2.png)<!-- -->

``` r
tilden_rs <- tilden %>%
  mutate(energy = rescaled_energy)

re_e_mod <- mod_wrapper(tilden_rs, response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(tilden_rs, response_variable = "abundance", identifier = "site_name", k = 5)

re_e_fit <- fit_wrapper(re_e_mod)
n_fit <- fit_wrapper(n_mod)

re_e_derivs <- deriv_wrapper(re_e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

re_e_derivs_summary <- derivs_summary(re_e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

re_e_v_n_summary <- bind_rows(re_e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(re_e_v_n_summary, aes((net_percent_of_start_abundance), (net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-3.png)<!-- -->

``` r
ggplot(re_e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-4.png)<!-- -->

``` r
ggplot(re_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-5.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-6.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-7.png)<!-- -->

``` r
both_derivs <- bind_rows(energy = re_e_derivs, abund= n_derivs, .id = "currency")

ggplot(filter(both_derivs, currency == "energy"), aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) +
  geom_line(data = filter(both_derivs, currency == "abund"), inherit.aes = T, alpha = .1, color = "green")
```

![](birds_energy_files/figure-gfm/just%20e%20tilden-8.png)<!-- -->

``` r
both_derivs %>%
  group_by(currency, seed) %>%
  summarize(sd = sd(derivative),
            cv = sd(derivative) / mean(derivative)) %>%
  ungroup() %>%
  group_by(currency) %>%
  summarize(mean_cv = mean(cv),
            mean_sd = mean(sd))
```

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 2 x 3
    ##   currency mean_cv mean_sd
    ##   <chr>      <dbl>   <dbl>
    ## 1 abund      -1.26    19.8
    ## 2 energy     14.4     24.2

#### With mccoy

``` r
mccoy <- filter(ts, site_name == "mccoy")

mccoy_mean_perc_e <- sum(mccoy$energy) / sum(mccoy$abundance)

mccoy <- mccoy %>% 
  mutate(rescaled_energy = energy / mccoy_mean_perc_e)


ggplot(mccoy, aes(year, energy)) +
  geom_line()
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-1.png)<!-- -->

``` r
ggplot(mccoy, aes(year, rescaled_energy)) +
  geom_line() +
  geom_line(aes(year, abundance, color = "abund"))
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-2.png)<!-- -->

``` r
mccoy_rs <- mccoy %>%
  mutate(energy = rescaled_energy)

re_e_mod <- mod_wrapper(mccoy_rs, response_variable = "energy", identifier = "site_name", k = 5)
n_mod <- mod_wrapper(mccoy_rs, response_variable = "abundance", identifier = "site_name", k = 5)

re_e_fit <- fit_wrapper(re_e_mod)
n_fit <- fit_wrapper(n_mod)

re_e_derivs <- deriv_wrapper(re_e_mod, ndraws = 100, seed_seed = 1977)
n_derivs <- deriv_wrapper(n_mod, ndraws = 100, seed_seed = 1977)

re_e_derivs_summary <- derivs_summary(re_e_derivs) %>%
  mutate(currency = "energy")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
n_derivs_summary <- derivs_summary(n_derivs) %>%
  mutate(currency = "abundance")
```

    ## `summarise()` regrouping output by 'seed', 'identifier' (override with `.groups` argument)

``` r
# 
# e_v_n_summary <- bind_rows(e_derivs_summary, n_derivs_summary) %>%
#   group_by(currency) %>%
#   summarize_at(vars(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start), .funs = mean)

re_e_v_n_summary <- bind_rows(re_e_derivs_summary, n_derivs_summary) %>%
  tidyr::pivot_wider(id_cols = seed, names_from = currency, values_from = c(net_change, abs_change, abs_v_net_change, net_percent_of_start, abs_percent_of_start))

ggplot(re_e_v_n_summary, aes((net_percent_of_start_abundance), (net_percent_of_start_energy))) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1)+
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0)
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-3.png)<!-- -->

``` r
ggplot(re_e_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-4.png)<!-- -->

``` r
ggplot(re_e_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-5.png)<!-- -->

``` r
ggplot(n_fit, aes(year, dependent)) +
  geom_point() +
  geom_line(aes(year, fitted_value))
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-6.png)<!-- -->

``` r
ggplot(n_derivs, aes(year, derivative, group = seed)) +
  geom_line(alpha = .1)
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-7.png)<!-- -->

``` r
both_derivs <- bind_rows(energy = re_e_derivs, abund= n_derivs, .id = "currency")

ggplot(filter(both_derivs, currency == "energy"), aes(year, derivative, group = seed)) +
  geom_line(alpha = .1) +
  geom_line(data = filter(both_derivs, currency == "abund"), inherit.aes = T, alpha = .1, color = "green")
```

![](birds_energy_files/figure-gfm/just%20e%20mccoy-8.png)<!-- -->

``` r
both_derivs %>%
  group_by(currency, seed) %>%
  summarize(sd = sd(derivative),
            cv = sd(derivative) / mean(derivative)) %>%
  ungroup() %>%
  group_by(currency) %>%
  summarize(mean_cv = mean(cv),
            mean_sd = mean(sd))
```

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 2 x 3
    ##   currency mean_cv mean_sd
    ##   <chr>      <dbl>   <dbl>
    ## 1 abund    -104.      21.2
    ## 2 energy      5.49    32.1

  - you don’t want cv or sd of derivatives. you maybe want the cv of the
    fitted/predicted estimates.
  - contrive nulls: one where e exactly tracks n (amplifying the same
    size structure); one where the ss trades off such that e does not
    change while n does
