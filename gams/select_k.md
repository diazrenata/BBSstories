selecting nb of basis fxns
================

``` r
knitr::opts_chunk$set(echo = FALSE)
knitr::opts_chunk$set(fig.dim = c(5,3))

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

ts <- ts %>%
  group_by(site_name) %>%
  mutate(totale = sum(energy),
         totaln = sum(abundance)) %>%
  mutate(avg_perc_e = totale/totaln) %>%
  mutate(rescaled_energy = energy / avg_perc_e) %>%
  ungroup() %>%
  select(-totale, -totaln, -avg_perc_e) %>%
  mutate(rescaled_energy = round(rescaled_energy))

unique_sites <- unique(ts$site_name)

site_dfs <- lapply(unique_sites, FUN = function(site, full_ts) return(filter(full_ts, site_name == site)), full_ts = ts)

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))
source(here::here("gams", "gam_fxns", "sunrise_fxns.R"))
```

## Alberta energy

![](select_k_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

    ##   k smooth      aic deviance     kscore k_pass
    ## 1 0  FALSE 732.1417 476.4970 100.000000   TRUE
    ## 2 3   TRUE 526.1741 266.5317   1.067366   TRUE

![](select_k_files/figure-gfm/unnamed-chunk-2-2.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-2-3.png)<!-- -->

## Alberta abundance

![](select_k_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

    ##   k smooth      aic deviance     kscore k_pass
    ## 1 0  FALSE 803.6922 547.9684 100.000000   TRUE
    ## 2 9   TRUE 486.5885 215.1430   1.031742   TRUE

![](select_k_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-3-3.png)<!-- -->

# everything

    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"

![](select_k_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->![](select_k_files/figure-gfm/unnamed-chunk-5-2.png)<!-- -->

# Rockies

![](select_k_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

    ##   k smooth      aic deviance    kscore k_pass site_name currency
    ## 1 0  FALSE 439.6797 258.3695 100.00000   TRUE   rockies   energy
    ## 2 2   TRUE 439.8673 257.2508   1.14416   TRUE   rockies   energy

![](select_k_files/figure-gfm/unnamed-chunk-6-2.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-6-3.png)<!-- -->![](select_k_files/figure-gfm/unnamed-chunk-6-4.png)<!-- -->

    ##   k smooth      aic deviance     kscore k_pass site_name  currency
    ## 1 0  FALSE 760.3815 579.7590 100.000000   TRUE   rockies abundance
    ## 2 3   TRUE 482.0903 297.4695   1.037864   TRUE   rockies abundance

![](select_k_files/figure-gfm/unnamed-chunk-6-5.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-6-6.png)<!-- -->

# Rockies, k = 10

![](select_k_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

    ##   k smooth      aic deviance    kscore k_pass site_name currency
    ## 1 0  FALSE 439.6797 258.3695 100.00000   TRUE   rockies   energy
    ## 2 2   TRUE 439.8673 257.2508   1.14416   TRUE   rockies   energy

![](select_k_files/figure-gfm/unnamed-chunk-7-2.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-7-3.png)<!-- -->![](select_k_files/figure-gfm/unnamed-chunk-7-4.png)<!-- -->

    ##   k smooth      aic deviance     kscore k_pass site_name  currency
    ## 1 0  FALSE 760.3815 579.7590 100.000000   TRUE   rockies abundance
    ## 2 3   TRUE 482.0903 297.4695   1.037864   TRUE   rockies abundance

![](select_k_files/figure-gfm/unnamed-chunk-7-5.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

    ## Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning -
    ## Inf

![](select_k_files/figure-gfm/unnamed-chunk-7-6.png)<!-- -->
