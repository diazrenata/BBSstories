size_files <- list.files("C:/Users/diaz.renata/Documents/GitHub/BBSsize/analysis/isd_data/", full.names = T)

energy_files <- size_files[grepl(size_files, pattern = "energy")][1:100]

new_file_names <- substr(energy_files, 65, nchar(energy_files) - 4)

site_ids <- substr(new_file_names, 8, nchar(new_file_names))

all_dfs <- list()

for(i in 1:length(energy_files)) {

  energydat <- readRDS(energy_files[i])

  thisroute <- as.integer(strsplit(site_ids[i], split = "_")[[1]][3])
  thisregion <- as.integer(strsplit(site_ids[i], split = "_")[[1]][4])


  abunddat <- MATSS::get_bbs_route_region_data(route = thisroute,
                                               region = thisregion)

  all_dfs[[i]] <- data.frame(year = abunddat$covariates$year,
                        abundance = rowSums(abunddat$abundance),
                        energy = rowSums(energydat$abundance),
                        site_name = site_ids[i])

}

saveRDS(all_dfs, file = here::here("gams", "bbs_100_sites.Rds"))
