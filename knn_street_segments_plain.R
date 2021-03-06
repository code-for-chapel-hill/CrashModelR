library(tidyverse)
library(sf)
library(RANN)


pedestrian_crashes <- read_sf("https://www.chapelhillopendata.org/explore/dataset/pedestrian-crashes-chapel-hill-region/download/?format=geojson&timezone=America/New_York")

bicycle_crashes <- read_sf("https://www.chapelhillopendata.org/explore/dataset/bicycle-crash-data-chapel-hill-region/download/?format=geojson&timezone=America/New_York")

chapel_hill_streets <- read_sf("https://www.chapelhillopendata.org/explore/dataset/streets/download/?format=geojson&timezone=America/New_York")


street_nodes_sf <- chapel_hill_streets %>%
  group_by(objectid) %>%
  st_cast("POINT")


street_nodes_df <- data.frame(st_coordinates(street_nodes_sf), street_nodes_sf$objectid) %>%
  rename(objectid = street_nodes_sf.objectid) %>%
  mutate(seg = 1:nrow(.))


closest <- data.frame(nn2(street_nodes_df[,1:2], st_coordinates(pedestrian_crashes), k = 1))


merged <- closest %>%
  left_join(street_nodes_df, by = c("nn.idx" = "seg")) %>%
  group_by(objectid) %>%
  summarise(count = n()) %>%
  ungroup() %>%
  right_join(chapel_hill_streets)


merged$count[is.na(merged$count)] <- 0


st_write(merged, dsn = "geojson/street_counts.geojson")

