Interpreting breakpoint fits
================

## An idea

Look specifically at the predictions from the best-fitting breakpoint
model. (This model could be: no breakpoints + no slope, no breakpoints +
slope, n breakpoints + no slope, n breakpoints + slopes).

There’s some qualitative behaviors we can extract from the predictions
(that come logically but less elegantly from the parameters, etc).

Two axes:

1.  **Monotonic or squiggly:** Monotonic can encompass all linear
    (no-break) models, *and* any models with breakpoints that do not
    result in changes in direction.
2.  **Net change or net 0:** The ratio of the end:beginning
    *prediction*.

The 2x2:

1.  **Monotonic** and **net change**: This would be some kind of overall
    trend, either steady (probably would show as a 1-segment linear
    model), possibly accelerating or decelerating across the timeseries
    (would show as multiple segments with slopes), or even as a series
    of abrupt changes (would show as multiple segments with *no*
    slopes).
2.  **Monotonic** and **no net change**: This can basically only be
    accomplished as a one-segment linear model with a slope very close
    to 0. (Theoretically you could have many verrrrry gently sloping
    segments, but I doubt we have the statistical power such that
    something like that would emerge as the best fit). I think this is
    either very stable or *so* variable that not even many breakpoints
    can adequately capture the variability.
3.  **Turnpoints** and **net change**: The TS changes direction at least
    once, and ends up somewhere other than where it started. This *must*
    involve breakpoints. At the moment I think I have less confidence in
    such an outcome as evidence of systematic directional change - it
    seems potentially sensitive to, if we stopped surveying 5 years
    earlier, would we have a totally different trend?
4.  **Turnpoints** and **no net change**: Qualitatively different from,
    monotonic and no net change….Again, I am not sure how confident I am
    in this as a signal of any kind of regulation/buffering. But maybe.

### Illustration via a few real datasets

    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)

    ## Loading in data version 2.18.0

    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)
    ## `summarise()` ungrouping output (override with `.groups` argument)

![](fit_taxonomy_files/figure-gfm/loading%20some%20real%20datasets-1.png)<!-- -->

![](fit_taxonomy_files/figure-gfm/multiple%20datasets-1.png)<!-- -->![](fit_taxonomy_files/figure-gfm/multiple%20datasets-2.png)<!-- -->

### Monotonic and net change

![](fit_taxonomy_files/figure-gfm/monotonic%20net-1.png)<!-- -->

### Monotonic and no net change

![](fit_taxonomy_files/figure-gfm/monotonic%20no%20net-1.png)<!-- -->

### Turnpoints and net change

![](fit_taxonomy_files/figure-gfm/turns%20net-1.png)<!-- -->

<!-- ## Comparison to first/last 5 years -->

<!-- ```{r get first and last five years} -->

<!-- all_datasets_caps <- all_datasets %>% -->

<!--   group_by(site_name) %>% -->

<!--   mutate(time_step = row_number()) %>% -->

<!--   mutate(ntimesteps = max(time_step)) %>% -->

<!--   mutate(first_fifth = 5, -->

<!--          last_fifth = ntimesteps - 4) %>% -->

<!--   mutate(in_beginning = time_step <= first_fifth, -->

<!--          in_end = time_step >= last_fifth) %>% -->

<!--   mutate(in_cap = (in_beginning + in_end) > 0) %>% -->

<!--   mutate(which_cap = ifelse(in_beginning, 1, ifelse(in_end, 2, NA))) %>% -->

<!--   ungroup() -->

<!-- ggplot(all_datasets_caps, aes(year, abundance, color = in_cap)) + -->

<!--   geom_point() + -->

<!--   theme_bw() + -->

<!--   facet_wrap(vars(site_name), scales = "free") -->

<!-- ggplot(all_datasets_caps, aes(year, energy, color = in_cap)) + -->

<!--   geom_point() + -->

<!--   theme_bw() + -->

<!--   facet_wrap(vars(site_name), scales = "free") -->

<!-- all_caps <- lapply(unique(all_datasets$site_name), FUN = filter_caps, datasets_to_pass = all_datasets_caps) -->

<!-- all_caps_comparisons <- lapply(all_caps, FUN = compare_caps) -->

<!-- all_caps_energy <- lapply(unique(all_datasets$site_name), FUN = filter_caps, datasets_to_pass = all_datasets_caps, currency = "energy") -->

<!-- all_caps_energy_comparisons <- lapply(all_caps_energy, FUN = compare_caps) -->

<!-- all_caps_comparisons <- bind_rows(all_caps_comparisons) -->

<!-- all_caps_energy_comparisons <- bind_rows(all_caps_energy_comparisons) -->

<!-- all_caps_comparisons <- bind_rows(all_caps_comparisons, all_caps_energy_comparisons) -->

<!-- #all_datasets <- left_join(all_datasets, all_caps_comparisons) -->

<!-- ggplot(all_caps_comparisons, aes(which_cap, mean, color = pval < .05)) + -->

<!--   geom_point() + -->

<!--   geom_errorbar(aes(ymin = response_lower, ymax = response_upper)) + -->

<!--   facet_grid(rows = vars(currency), cols = vars(site_name), scales = "free") + -->

<!--   theme_bw() -->

<!-- ggplot(all_caps_comparisons, aes(which_cap, mean, color = wilcox_pval < .05)) + -->

<!--   geom_point() + -->

<!--   geom_errorbar(aes(ymin = response_lower, ymax = response_upper)) + -->

<!--   facet_grid(rows = vars(currency), cols = vars(site_name), scales = "free") + -->

<!--   theme_bw() -->

<!-- ``` -->

<!-- ### Net change via lm -->

<!-- ```{r select lm fit} -->

<!-- abund_slope_plots <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "abundance", all_datasets = all_datasets) -->

<!--   abund_slope_plots[[i]] <- plot_lm_change(thisdat) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = abund_slope_plots) -->

<!-- energy_slope_plots <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "energy", all_datasets = all_datasets) -->

<!--   energy_slope_plots[[i]] <- plot_lm_change(thisdat) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = energy_slope_plots) -->

<!-- ``` -->

<!-- ```{r select lm fit with p} -->

<!-- abund_slope_plots_p <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "abundance", all_datasets = all_datasets) -->

<!--   abund_slope_plots_p[[i]] <- plot_lm_change(thisdat, use_p = T) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = abund_slope_plots_p) -->

<!-- energy_slope_plots_p <- list() -->

<!-- for(i in 1:nrow(datasets)) { -->

<!--   thisdat <- subset_all_datasets(site = datasets$dataset_name[i], curr = "energy", all_datasets = all_datasets) -->

<!--   energy_slope_plots_p[[i]] <- plot_lm_change(thisdat, use_p=T) -->

<!-- } -->

<!-- gridExtra::grid.arrange(grobs = energy_slope_plots_p) -->

<!-- ``` -->
