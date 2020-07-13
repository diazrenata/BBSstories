Exploring strucchange on several datasets
================

### Strucchange method

So I think there’s the bones of a potential method here, to code up and
gut-check on a handful of datasets…

1.  Fit:

`breakpoints(response ~ year)` and `breakpoints(response ~ 1)`

2.  Use BIC to select slope or intercept model

### Trying on a few real datasets

``` r
datasets <- data.frame(
  dataset_name = c("rockies",
                   "hartland",
                   "alberta",
                   "cochise_birds",
                   "salamonie",
                   "tilden",
                   "gainesville",
                   "gainesville_nooutlier",
                   "portal_rats"),
  rtrg_code = c("rtrg_304_17",
                "rtrg_102_18",
                "rtrg_105_4",
                "rtrg_133_6",
                "rtrg_19_35",
                "rtrg_172_14",
                "rtrg_113_25",
                "rtrg_113_25",
                
                NA)
)

all_datasets <- list()


for(i in 1:nrow(datasets)) {
  
  if(datasets$dataset_name[i] != "portal_rats") {
    
    ibd <- readRDS(paste0("C:\\Users\\diaz.renata\\Documents\\GitHub\\BBSsize\\analysis\\isd_data\\ibd_isd_bbs_", datasets$rtrg_code[i], ".Rds"))
    
    sv <- ibd %>%
      group_by(year) %>%
      summarize(richness = length(unique(id)),
                abundance = dplyr::n(),
                biomass = sum(ind_size),
                energy = sum(ind_b)) %>%
      ungroup() %>%
      mutate(mean_energy = energy / abundance,
             mean_mass = biomass/abundance,
             site_name = datasets$dataset_name[i])
    
    if(datasets$dataset_name[i] == "gainesville_nooutlier") {
      sv <- filter(sv, abundance < 3000)
    } 
  } else {
    
    individual_rats <- portalr::summarise_individual_rodents(clean = TRUE, type = "Granivores", time = "date", length = "Longterm")
    
    ibd <- individual_rats %>%
      filter(year %in% c(1978:2002), !is.na(wgt), treatment == "control") %>%
      mutate(six_mo = ifelse(month > 6, .5, 0)) %>%
      mutate(year_six_mo = (year + six_mo)) %>%
      mutate(bmr = 5.69 * (wgt ^ .75)) %>%
      select(year_six_mo, species, wgt, bmr) %>%
      rename(year= year_six_mo,
             id = species,
             ind_size = wgt,
             ind_b = bmr) %>%
      mutate(id = as.character(id))
    
    
    sv <- ibd %>%
      group_by(year) %>%
      summarize(richness = length(unique(id)),
                abundance = dplyr::n(),
                biomass = sum(ind_size),
                energy = sum(ind_b)) %>%
      ungroup() %>%
      mutate(mean_energy = energy / abundance,
             mean_mass = biomass/abundance,
             site_name = datasets$dataset_name[i]) %>%
      mutate(time = row_number())
    
  }
  
  all_datasets[[i]] <- sv
  
  
}
```

    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## Loading in data version 2.18.0

    ## `summarise()` ungrouping output (override with `.groups` argument)

``` r
all_datasets <- bind_rows(all_datasets)
gridExtra::grid.arrange(grobs = list(
  ggplot(all_datasets, aes(year, abundance, color = site_name)) +
    geom_line() +
    theme_bw() +
    facet_wrap(vars(site_name), scales = "free", ncol = 1) + 
    ggtitle("Abundance"
    ) +
    theme(legend.position = "top"),
  ggplot(all_datasets, aes(year, energy, color = site_name)) + 
    geom_line() +
    theme_bw() +
    facet_wrap(vars(site_name), scales = "free", ncol = 1) +
    ggtitle("Energy") +
    theme(legend.position = "top")),
  ncol = 2
)
```

![](strucchange_gut_files/figure-gfm/loading%20some%20real%20datasets-1.png)<!-- -->

``` r
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

predict_breakpoints <- function(dat, breakpoints_fit) {
  
  dat <- dat %>%
    dplyr::mutate(fitted = fitted(breakpoints_fit),
                  breakpoints = dplyr::row_number() %in% breakpoints_fit$breakpoints) 
  
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
           ggtitle(dat$site_name[1]))
  
}

subset_all_datasets <- function(site, curr, all_datasets) {
  
  dat <- all_datasets[ , c("site_name", "year", curr)]
  
  dat <- dat[ which(dat$site_name == site), ]
  
  colnames(dat)[ which(colnames(dat) == curr)]  <- "response"
  colnames(dat)[ which(colnames(dat) == "year")] <- "time"
  
  return(dat)
  
}

dat <- subset_all_datasets("portal_rats", "abundance", all_datasets)

rats_bp <- fit_breakpoints(dat)

dat <- predict_breakpoints(dat, rats_bp)

print(plot_breakpoint_fit(dat))
```

![](strucchange_gut_files/figure-gfm/breakpoints%20fxns-1.png)<!-- -->

``` r
abund_plots <- list()

for(i in 1:nrow(datasets)) {
  thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "abundance", all_datasets = all_datasets)
  
  abund_plots[[i]] <- plot_breakpoint_fit(thisdat)
}

gridExtra::grid.arrange(grobs = abund_plots)
```

![](strucchange_gut_files/figure-gfm/multiple%20datasets-1.png)<!-- -->

``` r
energy_plots <- list()

for(i in 1:nrow(datasets)) {
  thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "energy", all_datasets = all_datasets)
  
  energy_plots[[i]] <- plot_breakpoint_fit(thisdat)
}

gridExtra::grid.arrange(grobs = energy_plots)
```

![](strucchange_gut_files/figure-gfm/multiple%20datasets-2.png)<!-- -->

<!-- #### h -->

<!-- Above, I set the minimum number of observations in a segment to 4. This is because setting it to 2 is too few (needs to be > regressors), and setting it to 3 gave Extremely Complex results that tend to involve many tiny sections (see below). It's subjective, but my assessment is these are overfitting/overfitting relative to what I see as the major signals in the data.  -->

<!-- For example, I think 6 segments is excessive for the `cochise_birds` data, and am more comfortable with the 3 segments achieved via `h = 4`. `cochise_birds` only has 18 datapoints, and splitting it into 6 is a little absurd.... -->

<!-- Note also that the default in `strucchange` is `h = .15 * (nobs)`. For these timeseries, that's 3-4 depending on the length of the timeseries.  -->

<!-- ```{r h at 3} -->

<!-- abund_plots_h3 <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "abundance", all_datasets = all_datasets) -->

<!--   abund_plots_h3[[i]] <- plot_breakpoint_fit(thisdat, h = .33) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = abund_plots_h3) -->

<!-- energy_plots_h3 <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "energy", all_datasets = all_datasets) -->

<!--   energy_plots_h3[[i]] <- plot_breakpoint_fit(thisdat, h = .33) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = energy_plots_h3) -->

<!-- ``` -->

## Comparison to first/last 5 years

``` r
all_datasets_caps <- all_datasets %>%
  group_by(site_name) %>%
  mutate(time_step = row_number()) %>%
  mutate(ntimesteps = max(time_step)) %>%
  mutate(first_fifth = 5,
         last_fifth = ntimesteps - 4) %>%
  mutate(in_beginning = time_step <= first_fifth,
         in_end = time_step >= last_fifth) %>%
  mutate(in_cap = (in_beginning + in_end) > 0) %>%
  mutate(which_cap = ifelse(in_beginning, 1, ifelse(in_end, 2, NA))) %>%
  ungroup()

ggplot(all_datasets_caps, aes(year, abundance, color = in_cap)) +
  geom_point() +
  theme_bw() +
  facet_wrap(vars(site_name), scales = "free")
```

![](strucchange_gut_files/figure-gfm/get%20first%20and%20last%20five%20years-1.png)<!-- -->

``` r
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
    group_by(which_cap, site_name, currency, ntimesteps) %>%
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

all_caps <- lapply(unique(all_datasets$site_name), FUN = filter_caps, datasets_to_pass = all_datasets_caps)

all_caps_comparisons <- lapply(all_caps, FUN = compare_caps)
```

    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)

``` r
all_caps_energy <- lapply(unique(all_datasets$site_name), FUN = filter_caps, datasets_to_pass = all_datasets_caps, currency = "energy")

all_caps_energy_comparisons <- lapply(all_caps_energy, FUN = compare_caps)
```

    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)
    ## `summarise()` regrouping output by 'which_cap', 'site_name', 'currency' (override with `.groups` argument)

``` r
all_caps_comparisons <- bind_rows(all_caps_comparisons)
all_caps_energy_comparisons <- bind_rows(all_caps_energy_comparisons)

all_caps_comparisons <- bind_rows(all_caps_comparisons, all_caps_energy_comparisons)

#all_datasets <- left_join(all_datasets, all_caps_comparisons)

ggplot(all_caps_comparisons, aes(which_cap, mean, color = pval < .05)) +
  geom_point() +
  geom_errorbar(aes(ymin = response_lower, ymax = response_upper)) +
  facet_grid(rows = vars(currency), cols = vars(site_name), scales = "free") +
  theme_bw()
```

![](strucchange_gut_files/figure-gfm/get%20first%20and%20last%20five%20years-2.png)<!-- -->

``` r
ggplot(all_caps_comparisons, aes(which_cap, mean, color = wilcox_pval < .05)) +
  geom_point() +
  geom_errorbar(aes(ymin = response_lower, ymax = response_upper)) +
  facet_grid(rows = vars(currency), cols = vars(site_name), scales = "free") +
  theme_bw()
```

![](strucchange_gut_files/figure-gfm/get%20first%20and%20last%20five%20years-3.png)<!-- -->

``` r
ggplot(all_caps_comparisons, aes(site_name, ratio, color = pval < .05, shape = currency)) +
  geom_point() +
  theme_bw() +
  geom_hline(yintercept = 1) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
```

![](strucchange_gut_files/figure-gfm/get%20first%20and%20last%20five%20years-4.png)<!-- -->

``` r
ggplot(all_caps_comparisons, aes(site_name, ratio, color = wilcox_pval < .05, shape = currency)) +
  geom_point() +
  theme_bw() +
  geom_hline(yintercept = 1) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
```

![](strucchange_gut_files/figure-gfm/get%20first%20and%20last%20five%20years-5.png)<!-- -->