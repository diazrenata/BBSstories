Third draft scaling residual variation
================

questions I have about these ts…

1.  what is their trajectory? ideally in interpretable units
2.  how narrowly or broadly are observations distributed around this
    trajectory? a slope of 0 is qualiatively different if it’s 0
    narrowly or broadly. again, ideally in interpretable units.

by interpretable units, I mean I want to be able to read the slope and
make comparisons across ts of different scales. So if x\_t = 10 and
x\_(t+1) = 11, that’s a 10% increase. If x\_t = 100 and x\_(t+1) = 110,
I want that to be more comparable to if x\_(t+1) = 101. similarly, I
want to be able to look at the goodness of fit/variability metric and
understand how large the residuals are, relative to the values involved.
So if x\_obs = 110 and x\_predicted = 100, I want that to be more
comparable to if x\_obs = 11 and x\_predicted = 10, than if x\_obs = 11
and x\_predicted = 10.1.

``` r
datasets <- data.frame(
  dataset_name = c("rockies",
                   "hartland",
                   "alberta",
                   "cochise_birds",
                   "salamonie",
                   "tilden",
              #     "gainesville",
                   "portal_rats"),
  rtrg_code = c("rtrg_304_17",
                "rtrg_102_18",
                "rtrg_105_4",
                "rtrg_133_6",
                "rtrg_19_35",
                "rtrg_172_14",
           #     "rtrg_113_25",
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

    ## Loading in data version 2.18.0

``` r
all_datasets <- bind_rows(all_datasets)


hartland <- filter(all_datasets, site_name == "hartland") %>%
  select(year, abundance, energy) %>% 
  tidyr::pivot_longer(-year, names_to = "currency", values_to = "values") %>%
  group_by(currency) %>%
  mutate(raw = values,
    scaled = scale(values),
         centered = scale(values, scale = F),
    bymean = values / mean(values)) %>%
  ungroup() %>%
  tidyr::pivot_wider(id_cols = year, names_from = currency, values_from = c(scaled, centered, raw, bymean))
```

``` r
abund_lm <- lm(bymean_abundance ~ year, hartland)
abund_predict <- predict(abund_lm)
abund_resid <- resid(abund_lm)

energy_lm <- lm(bymean_energy ~ year, hartland)
energy_predict <- predict(energy_lm)
energy_resid <- resid(energy_lm)

hartland <- cbind(hartland, abund_predict, abund_resid, energy_predict, energy_resid)

ggplot(hartland, aes(year, bymean_abundance)) +
  geom_point() +
  geom_line(aes(year, abund_predict)) +
  geom_point(aes(year, abs(abund_resid)), color = "red")
```

![](fuzz_third_draft_files/figure-gfm/by%20mean-1.png)<!-- -->

``` r
mean(abs(hartland$abund_resid))
```

    ## [1] 0.08572404

``` r
ggplot(hartland, aes(year, bymean_energy)) +
  geom_point() +
  geom_line(aes(year, energy_predict)) +
  geom_point(aes(year, abs(energy_resid)), color = "red")
```

![](fuzz_third_draft_files/figure-gfm/by%20mean-2.png)<!-- -->

``` r
mean(abs(hartland$energy_resid))
```

    ## [1] 0.2261424
