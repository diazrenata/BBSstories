a trimmed-ish draft
================

``` r
knitr::opts_chunk$set(echo = FALSE)
#knitr::opts_chunk$set(fig.dim = c(5,3))

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

ts <- read.csv(here::here("gams", "results", "ts_w_rescaled_e.csv"))
```

![](sr_plots_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

![](sr_plots_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

![](sr_plots_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![](sr_plots_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

![](sr_plots_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

![](sr_plots_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->![](sr_plots_files/figure-gfm/unnamed-chunk-7-2.png)<!-- -->

    ## Joining, by = c("draw", "currency", "identifier", "k")

![](sr_plots_files/figure-gfm/unnamed-chunk-7-3.png)<!-- -->![](sr_plots_files/figure-gfm/unnamed-chunk-7-4.png)<!-- -->
