library(dplyr)
library(gratia)
library(ggplot2)
load_mgcv()

#ts <- read.csv(here::here("gams", "working_datasets.csv"))

#unique_sites <- unique(ts$site_name)

k_to_use <- 5

site_dfs <- readRDS(here::here("gams", "bbs_100_sites.Rds"))

source(here::here("gams", "gam_fxns", "wrapper_fxns.R"))
source(here::here("gams", "gam_fxns", "sunrise_fxns.R"))

re_e_dfs <- list()
re_e_mods <- list()
n_mods <- list()
e_samples <- list()
n_samples <- list()
joint_samples <- list()
both_change <- list()
both_summary <- list()
both_instant_change <- list()
both_ichange_summary <- list()
both_ichange_ts_summary <- list()

for(i in 1:length(site_dfs)) {
  this_df <- site_dfs[[i]]


  mean_perc_e <- sum(this_df$energy) / sum(this_df$abundance)

  this_df <- this_df %>%
    mutate(scaled_energy = energy / mean_perc_e)

  re_e_dfs[[i]] <- this_df

  re_e_mods[[i]] <- mod_wrapper(this_df, response_variable = "scaled_energy", identifier = "site_name", k = k_to_use)
  n_mods[[i]] <- mod_wrapper(this_df, response_variable = "abundance", identifier = "site_name", k = k_to_use)

  e_samples[[i]] <- samples_wrapper(re_e_mods[[i]], seed_seed = 1994)
  n_samples[[i]] <- samples_wrapper(n_mods[[i]], seed_seed = 1990)

  joint_samples[[i]] <- bind_rows(e_samples, n_samples) %>%
    select(year, currency, mean, upper, lower, identifier) %>%
    distinct()


  e_change <- net_change_wrapper(e_samples[[i]])
  n_change <- net_change_wrapper(n_samples[[i]])

  both_change[[i]] <- bind_rows(e_change, n_change)

  both_summary[[i]] <- change_summary_wrapper(both_change[[i]])


  e_instant_change <- instant_change_wrapper(e_samples[[i]])
  n_instant_change <- instant_change_wrapper(n_samples[[i]])

  both_instant_change[[i]] <- bind_rows(e_instant_change, n_instant_change)

  both_ichange_summary[[i]] <- instant_change_summary_wrapper(both_instant_change[[i]])

  both_ichange_ts_summary[[i]] <- instant_change_absolute_summary_wrapper(both_instant_change[[i]])
}

re_e_dfs <- bind_rows(re_e_dfs)

write.csv(re_e_dfs, here::here("gams", "results", "ts_w_rescaled_e_100bbs.csv"), row.names = F)
joint_samples <- bind_rows(joint_samples) %>%
  mutate(k = k_to_use)

write.csv(joint_samples, here::here("gams", "results", paste0("joint_samples_", k_to_use, "_100bbs.csv")), row.names = F)

both_change <- bind_rows(both_change)%>%
  mutate(k = k_to_use)

both_summary <- bind_rows(both_summary)

both_summary_wide <- both_summary %>%
  tidyr::pivot_wider(id_cols = identifier, names_from = currency, values_from = c(mean_net_proportional, lower_net_proportional, upper_net_proportional))%>%
  mutate(k = k_to_use)

both_summary <- both_summary %>%
  mutate(k = k_to_use)

write.csv(both_change, here::here("gams", "results", paste0("both_change_", k_to_use, "_100bbs.csv")), row.names = F)

write.csv(both_summary, here::here("gams", "results", paste0("both_summary_", k_to_use, "_100bbs.csv")), row.names = F)



both_ichange_summary <- bind_rows(both_ichange_summary)%>%
  mutate(k = k_to_use)
both_ichange_ts_summary <- bind_rows(both_ichange_ts_summary)%>%
  mutate(k = k_to_use)


write.csv(both_ichange_summary, here::here("gams", "results", paste0("both_ichange_summary_", k_to_use, "_100bbs.csv")), row.names = F)

write.csv(both_ichange_ts_summary, here::here("gams", "results", paste0("both_ichange_ts_summary_", k_to_use, "_100bbs.csv")), row.names = F)
