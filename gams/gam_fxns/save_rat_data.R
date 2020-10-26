# Save annual abundances for Portal rodents from 1980-2018.
# Based on code I wrote for EVS lab. Hence the cute species names. Adding a few more species for fun & breadth.
# Note this is sitewide....not split by plot or treatment. So for methods development only, as toy but realistic timeseries.

library(dplyr)

raw_portal_data <- portalr::abundance(time = "date")

abundance_ts <- data.frame(
  censusdate = raw_portal_data$censusdate,
  total_abund = rowSums(raw_portal_data[, 2:22])
)


spectab_ts <- raw_portal_data %>%
  select(censusdate, DS, PP, DM, PB, DO, PE, PF)


ts <- left_join(abundance_ts, spectab_ts)
ts <- ts %>%
  mutate(year = as.character(censusdate)) %>%
  mutate(year = substr(year, 0, 4)) %>%
  mutate(year = as.numeric(year)) %>%
  filter(year > 1980) %>%
  filter(year < 2019) %>%
  group_by(year) %>%
  summarize(total_abundance = sum(total_abund),
            bannertail = sum(DS),
            merriami = sum(DM),
            pocketmouse = sum(PP),
            baileys = sum(PB),
            ord = sum(DO),
            cactus = sum(PE),
            silky = sum(PF))
write.csv(ts, file = here::here("gams", "rat_data.csv"), row.names = F)
