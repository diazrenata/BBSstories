Rescale energy to compare to abundance
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
library(ggplot2)
load_mgcv()

ts <- read.csv(here::here("gams", "working_datasets.csv"))

unique_sites <- unique(ts$site_name)

site_dfs <- lapply(unique_sites, FUN = function(site, full_ts) return(filter(full_ts, site_name == site)), full_ts = ts)

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))
```

#### With portal

  - This is energy rescaled to be on a similar scale to abundance.
  - They **kind of** track, but note:
  - Abundance starts lower and ends higher than energy
  - There is decoupling in the late 90s

<!-- end list -->

    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"

![](compare_energy_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-2-2.png)<!-- -->

![](compare_energy_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->

![](compare_energy_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

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

![](compare_energy_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-6-2.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-6-3.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-6-4.png)<!-- -->![](compare_energy_files/figure-gfm/unnamed-chunk-6-5.png)<!-- -->
