library(dplyr)
library(readr)
library(tidycensus)

IN_DIR = "dca/warranties/data/prep"
OUT_DIR = "dca/warranties/data/final"

tidycensus::census_api_key(Sys.getenv("CENSUS_API_KEY"))

d = readr::read_csv(
  file.path(IN_DIR, "new_home_warranties__county__2000-2022.csv"),
  col_types = readr::cols(census_geoid = readr::col_character())
)

var = tidycensus::load_variables(2000) %>%
  dplyr::filter(
    grepl("^P", name),
    grepl("^TOTAL POPULATION", concept),
    label == "Total") %>%
  dplyr::pull(name)

pop = tidycensus::get_decennial(
  geography = "county", variables = var, year = 2000, state = "NJ"
) %>%
  dplyr::select(census_geoid = GEOID, pop_2000 = value)

cou = d %>%
  dplyr::group_by(county, census_geoid, region) %>%
  dplyr::summarise(sum_new_houses = sum(sum_new_houses)) %>%
  dplyr::left_join(pop, by = "census_geoid") %>%
  dplyr::mutate(new_housing_rate = (sum_new_houses / pop_2000) * 100) %>%
  dplyr::arrange(dplyr::desc(new_housing_rate))

reg = cou %>%
  dplyr::group_by(region) %>%
  dplyr::summarise(dplyr::across(c(sum_new_houses, pop_2000), sum)) %>%
  dplyr::mutate(new_housing_rate = (sum_new_houses / pop_2000) * 100) %>%
  dplyr::arrange(dplyr::desc(new_housing_rate))

readr::write_csv(
  cou, file.path(OUT_DIR, "new_housing_rate__county__2000-2022.csv")
)

readr::write_csv(
  reg, file.path(OUT_DIR, "new_housing_rate__region__2000-2022.csv")
)
