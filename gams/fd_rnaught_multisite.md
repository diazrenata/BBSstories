Use r0 of first derivative to make comparisons
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

unique_sites <- unique(ts$site_name)

site_dfs <- lapply(unique_sites, FUN = function(site, full_ts) return(filter(full_ts, site_name == site)), full_ts = ts)

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))
```

#### With mccoy

    ## Joining, by = "row"
    ## Joining, by = "row"
    ## Joining, by = "row"

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

E and N are on different scales. Rescaled energy divides energy by the
mean percapita metabolic rate, putting it in units **closer** to the
scale of the abundance values.

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-3-3.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-3-4.png)<!-- -->

    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## # A tibble: 3 x 4
    ##   currency      mean_derivative mean_rnaught rnaught_dev
    ##   <chr>                   <dbl>        <dbl>       <dbl>
    ## 1 abundance             -0.0583         1.00     0.00501
    ## 2 energy              1858.             1.00     0.00750
    ## 3 scaled_energy          5.93           1.00     0.00748

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

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

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-2.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-3.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-4.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-5.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-6.png)<!-- -->

    ## `summarise()` regrouping output by 'currency' (override with `.groups` argument)

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-7.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-8.png)<!-- -->

    ## Joining, by = "identifier"

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-9.png)<!-- -->![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-6-10.png)<!-- -->

``` 
```

## `summarise()` regrouping output by ‘seed’, ‘identifier’ (override with `.groups` argument)

``` 
```

## `summarise()` regrouping output by ‘identifier’ (override with `.groups` argument)

``` 
```

## `summarise()` regrouping output by ‘currency’ (override with `.groups` argument)

``` 
```

## Joining, by = c(“identifier”, “currency”)

\`\`\`

![](fd_rnaught_multisite_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->
