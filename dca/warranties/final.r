library(dplyr)
library(readr)
library(tidycensus)

tidycensus::census_api_key(Sys.getenv("CENSUS_API_KEY"))

d = readr::read_csv(
  "data/prep/new_home_warranties__county__2000-2022.csv",
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

a = d %>%
  dplyr::group_by(county, census_geoid) %>%
  dplyr::summarise(sum_new_houses = sum(sum_new_houses)) %>%
  dplyr::left_join(pop, by = "census_geoid") %>%
  dplyr::mutate(new_housing_rate = (sum_new_houses / pop_2000) * 100) %>%
  dplyr::arrange(dplyr::desc(new_housing_rate))

readr::write_csv(a, "data/final/new_housing_rate__county__2000-2022.csv")
