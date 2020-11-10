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

![](select_k_files/figure-gfm/unnamed-chunk-2-3.png)<!-- -->

## Alberta abundance

![](select_k_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

    ##   k smooth      aic deviance     kscore k_pass
    ## 1 0  FALSE 803.6922 547.9684 100.000000   TRUE
    ## 2 9   TRUE 486.5885 215.1430   1.031742   TRUE

![](select_k_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

![](select_k_files/figure-gfm/unnamed-chunk-3-3.png)<!-- -->
![](select_k_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->![](select_k_files/figure-gfm/unnamed-chunk-4-2.png)<!-- -->

![](select_k_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

    ## Joining, by = "row"
    ## Joining, by = "row"

![](select_k_files/figure-gfm/unnamed-chunk-5-2.png)<!-- -->
