library(dplyr)
library(glue)
library(purrr)
library(readxl)
library(tidycensus)

IN_DIR = "dca/warranties/data/raw"
OUT_DIR = "dca/warranties/data/prep"

files = dplyr::tibble(year = 2000:2022) %>%
  dplyr::mutate(
    name = dplyr::case_when(
      year >= 2020                ~ glue::glue("new_home_warranty_{year}.xls"),
      year <= 2019 & year >= 2016 ~ glue::glue("new home warranty_{year - 2000}.xls"),
      year == 2015                ~ glue::glue("nhw_{year - 2000}.xls"),
      year <= 2014 & year >= 2000 ~ glue::glue("nhw_{year}.xls")
    ) %>%
      file.path(IN_DIR, .),
    cell_range = dplyr::case_when(
      year == 2014 ~ "C7:J27",
      year == 2013 ~ "B5:I25",
      TRUE         ~ "B7:I27"
    )
  )

fields = dplyr::tribble(
  ~name,                  ~excel_type,
  "county",               "text",
  "region",               "text",
  "sum_new_houses",       "numeric",
  "sum_sales_price",      "numeric",
  "avg_sales_price",      "numeric",
  "med_sales_price",      "numeric",
  "avg_sales_price_rank", "numeric",
  "med_sales_price_rank", "numeric"
)

fips = tidycensus::fips_codes %>%
  dplyr::filter(state == "NJ") %>%
  dplyr::mutate(
    county = gsub(" County$", "", county),
    census_geoid = paste0(state_code, county_code)
  ) %>%
  dplyr::select(county, county_code, census_geoid)

d = purrr::map2(
  files$name,
  files$cell_range,
  ~readxl::read_excel(
    path = .x,
    range = .y,
    col_names = fields$name,
    col_types = fields$excel_type
  )
) %>%
  `names<-`(files$year) %>%
  purrr::list_rbind(names_to = "year") %>%
  dplyr::left_join(fips, by = "county") %>%
  dplyr::relocate(county_code, .after = county)

# 21 counties for each year
stopifnot(
  d %>%
    dplyr::count(year) %>%
    .$n %>%
    all(. == 21)
)

readr::write_csv(
  d, file.path(OUT_DIR, "new_home_warranties__county__2000-2022.csv")
)
