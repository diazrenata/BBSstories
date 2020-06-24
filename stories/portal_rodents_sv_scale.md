Another route
================

### Load rats

    ## Loading in data version 2.18.0

Here are the species present in this route over the past 25 years:

    ## # A tibble: 13 x 2
    ##    id    mean_size
    ##    <chr>     <dbl>
    ##  1 PF         8.05
    ##  2 RM        10.3 
    ##  3 RF        14   
    ##  4 PP        16.7 
    ##  5 PI        20   
    ##  6 PM        20.9 
    ##  7 PE        21.3 
    ##  8 PL        23   
    ##  9 PB        31.0 
    ## 10 PH        32   
    ## 11 DM        43.6 
    ## 12 DO        47.8 
    ## 13 DS       118.

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![](portal_rodents_sv_scale_files/figure-gfm/species%20list%20for%20fun-1.png)<!-- -->

Here is how species richness, abundance, biomass, and energy have
changed over those years:

![](portal_rodents_sv_scale_files/figure-gfm/state%20variables-1.png)<!-- -->

### Trends/tradeoffs in E and N

We can do some (crude) linear model fitting. I’ve generally been finding
that lms are OK, with caveats:

  - you do want to check for autocorrelation
  - the normal q-q plots are often kind of wonky

<!-- end list -->

    ## 
    ## Call:
    ## lm(formula = scaled_value ~ year, data = filter(sv_long, currency == 
    ##     "abundance"))
    ## 
    ## Residuals:
    ##      Min       1Q   Median       3Q      Max 
    ## -2.10677 -0.45642  0.04213  0.49320  2.56007 
    ## 
    ## Coefficients:
    ##               Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) -1.421e+02  3.368e+01  -4.218 0.000109 ***
    ## year         7.139e-03  1.692e-03   4.218 0.000109 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.863 on 48 degrees of freedom
    ## Multiple R-squared:  0.2704, Adjusted R-squared:  0.2552 
    ## F-statistic: 17.79 on 1 and 48 DF,  p-value: 0.0001086

    ##                     2.5 %       97.5 %
    ## (Intercept) -2.097956e+02 -74.34919952
    ## year         3.735881e-03   0.01054167

![](portal_rodents_sv_scale_files/figure-gfm/lms-1.png)<!-- -->![](portal_rodents_sv_scale_files/figure-gfm/lms-2.png)<!-- -->

    ## 
    ## Call:
    ## lm(formula = scaled_value ~ year, data = filter(sv_long, currency == 
    ##     "energy"))
    ## 
    ## Residuals:
    ##      Min       1Q   Median       3Q      Max 
    ## -2.26234 -0.49120 -0.07352  0.57981  2.67250 
    ## 
    ## Coefficients:
    ##               Estimate Std. Error t value Pr(>|t|)
    ## (Intercept) -30.293809  39.190658  -0.773    0.443
    ## year          0.001522   0.001969   0.773    0.443
    ## 
    ## Residual standard error: 1.004 on 48 degrees of freedom
    ## Multiple R-squared:  0.0123, Adjusted R-squared:  -0.008282 
    ## F-statistic: 0.5975 on 1 and 48 DF,  p-value: 0.4433

    ##                     2.5 %       97.5 %
    ## (Intercept) -1.090919e+02 48.504290604
    ## year        -2.437192e-03  0.005481566

![](portal_rodents_sv_scale_files/figure-gfm/lms-3.png)<!-- -->![](portal_rodents_sv_scale_files/figure-gfm/lms-4.png)<!-- -->

![](portal_rodents_sv_scale_files/figure-gfm/abund%20v%20compensation-1.png)<!-- -->

    ## 
    ## Call:
    ## lm(formula = scale(mean_energy) ~ scale(abundance), data = sv)
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -2.0335 -0.5554 -0.2521  0.5369  2.0817 
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error t value Pr(>|t|)   
    ## (Intercept)       1.884e-16  1.281e-01   0.000  1.00000   
    ## scale(abundance) -4.428e-01  1.294e-01  -3.422  0.00128 **
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.9059 on 48 degrees of freedom
    ## Multiple R-squared:  0.1961, Adjusted R-squared:  0.1793 
    ## F-statistic: 11.71 on 1 and 48 DF,  p-value: 0.001281

    ## [1] "energy sd/mean"

    ## [1] 0.2917237

    ## [1] "abundance sd/mean"

    ## [1] 0.3454639

Another notion is that energy should maybe track abundance? We have
already seen that energy is more variable than abundance and that the
overall trend for energy is not the same as the one for abundance. Here
is the extent to which abundance predicts energy:

![](portal_rodents_sv_scale_files/figure-gfm/abund%20v%20energy-1.png)<!-- -->

    ## 
    ## Call:
    ## lm(formula = scale(energy) ~ scale(abundance), data = sv)
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -0.8491 -0.3656 -0.1066  0.2779  1.0888 
    ## 
    ## Coefficients:
    ##                   Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)      2.669e-16  6.964e-02    0.00        1    
    ## scale(abundance) 8.732e-01  7.035e-02   12.41   <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.4924 on 48 degrees of freedom
    ## Multiple R-squared:  0.7625, Adjusted R-squared:  0.7575 
    ## F-statistic: 154.1 on 1 and 48 DF,  p-value: < 2.2e-16

![](portal_rodents_sv_scale_files/figure-gfm/abund%20v%20energy-2.png)<!-- -->

### Fixed or variable ISDs

![](portal_rodents_sv_scale_files/figure-gfm/compare%20ur%20isd%20methods-1.png)<!-- -->![](portal_rodents_sv_scale_files/figure-gfm/compare%20ur%20isd%20methods-2.png)<!-- -->

The plots above are both constructed based on KDEs. There are
assumptions and artefacts in there I’m not quite 100% on: the weighting
of samples from different time steps. I also have a well-worn mental
module that likes to construct ISDs via kdes or GMMs and then get
started comparing them via overlap, etc. I’d like to explore something a
little different at the moment, so I’m going to actually put a pin in
things derived from KDEs and work instead off of pools of individuals.

![](portal_rodents_sv_scale_files/figure-gfm/unaltered%20individuals-1.png)<!-- -->

This is the distribution of sizes of all the individuals we’ve ever seen
on this route.

One possibility is that we’re equally likely to draw any of these
individuals at any time step, and so we expect the ISD we observe at any
time step to be a random sample of \(N_t\) of all of these individuals.
Alternatively, there could be substantively different underlying ISDs we
are drawing our \(N_t\) individuals from, and the underlying ISDs could
vary systematically over time or orthogonal/not-detectably-parallel-to
time.

These possibilities go fairly deep in their implications. We can start
by thinking about it in terms of energy?

Energy could vary without a systematic trend if the ISD at each time
step is generated via the random draws from an ur-ISD. But that
variation might or might not rise to the magnitude we observe here.

### Energy variability from a randomized isd

    ## Joining, by = "year"

![](portal_rodents_sv_scale_files/figure-gfm/randomize%20isd-1.png)<!-- -->![](portal_rodents_sv_scale_files/figure-gfm/randomize%20isd-2.png)<!-- -->

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![](portal_rodents_sv_scale_files/figure-gfm/randomize%20isd-3.png)<!-- -->

The cloud of lines represent the distribution of *total energy values*
for 1000 bootstrap sampled ISDs. The histogram is the coefficient of
variation (sd/mean) for E over every simulation; the red line is the
observed. The observed E time series is way more variable than any of
the ones that we generated by resampling from a stable ISD.

Similarly, the cloud of dots visualizes the variation in
energy-abundance relation obtained via sampling. Compared to the red
dots, which are observed.
