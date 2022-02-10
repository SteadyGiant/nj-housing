library(dplyr)
library(purrr)
library(readr)
library(readxl)
library(stringr)
library(tidycensus)
library(tidyr)

options(scipen = 999)

readRenviron(".env")
tidycensus::census_api_key(Sys.getenv("CENSUS_API_KEY"))

# DCA permits data lacks municipality FIPS, so get them from this set of standardized
# municipality names and DCA codes:
# (https://data.nj.gov/Reference-Data/Municipalities-of-New-Jersey/k9xb-zgh4
muni = readr::read_csv(
  "data/input/Municipalities_of_New_Jersey.csv",
  col_types = readr::cols(.default = readr::col_character())
) %>%
  dplyr::select(
    dca_id = MUNICIPALITY_CODE_DCA,
    muni_fips = MUNICIPALITY_CODE_FIPS,
    muni = MUNICIPALITY_NAME_COMMON
  )

# View(tidycensus::load_variables(2010, "sf1"))
dec10 = tidycensus::get_decennial(
  geography = "county subdivision",
  variables = c("pop" = "P001001"),
  year = 2010,
  state = "NJ"
) %>%
  tidyr::pivot_wider(id_cols = GEOID, names_from = variable, values_from = value) %>%
  dplyr::rename(muni_fips = GEOID)


combine_files = function(type = c("new", "demo")) {
  type = type[1]
  if (type == "new") {
    dir_path = "data/input/newhse"
    sheet = "newhse"
    suffix = "_new"
  } else if (type == "demo") {
    dir_path = "data/input/demo"
    sheet = "demos"
    suffix = "_demo"
  } else {
    stop("type must be 'new' or 'demo'")
  }
  files = list.files(dir_path, full.names = TRUE)
  names(files) = stringr::str_extract_all(files, "[0-9]{2}(?=\\.xls)") %>%
    paste0("20", .)
  new = files %>%
    purrr::map_dfr(
      readxl::read_excel,
      sheet = sheet,
      range = "B31:I599",
      col_types = "text",
      col_names = FALSE,
      .id = "year"
    ) %>%
    `names<-`(c(
      "year", "fed_id", "dca_id", "county", "muni", "total", "fam_1_2", "multi", "mixed"
    )) %>%
    dplyr::filter(
      # The range specified above is too big for some files. Remove resultant blank
      # rows.
      !is.na(dca_id),
      # Remove state buildings records.
      dca_id != "9999"
    ) %>%
    dplyr::mutate(
      # Princeton Borough + Princeton Township = Princeton
      dplyr::across(dca_id, dplyr::recode, "1109" = "1114", "1110" = "1114"),
      dplyr::across(
        muni,
        dplyr::recode,
        "Princeton Borough" = "Princeton",
        "Princeton Township" = "Princeton",
        "Princeton (1114)" = "Princeton"
      ),
      dplyr::across(total:mixed, as.numeric),
      region = dplyr::case_when(
        county %in% c(
          "Bergen", "Essex", "Hudson", "Morris", "Passaic", "Sussex", "Union", "Warren"
        ) ~ "North",
        county %in% c(
          "Hunterdon", "Mercer", "Middlesex", "Monmouth", "Somerset", "Ocean"
        ) ~ "Central",
        county %in% c(
          "Atlantic",
          "Burlington",
          "Camden",
          "Cape May",
          "Cumberland",
          "Gloucester",
          "Salem"
        ) ~ "South"
      )
    ) %>%
    # Drop rows w/ NA data bcs those munis don't exist anymore:
    # Princeton Borough, Princeton Township, Pahaquary Township
    dplyr::filter(!is.na(total)) %>%
    # Combine the old Princeton Borough & Township rows.
    dplyr::group_by(year, dca_id, region, county, muni) %>%
    dplyr::summarise(dplyr::across(total:mixed, sum)) %>%
    dplyr::ungroup() %>%
    # Remove non-standard muni names from permits files.
    dplyr::select(-muni) %>%
    # Add standard muni names from Open Data site.
    dplyr::left_join(muni, by = "dca_id") %>%
    dplyr::select(muni_fips, region, county, muni, year, total:mixed) %>%
    dplyr::arrange(county, muni, year) %>%
    dplyr::rename_with(~paste0(.x, suffix), total:mixed)
}


newhse = combine_files("new")
demo = combine_files("demo")
permits = dplyr::inner_join(
  newhse,
  demo %>%
    dplyr::select(-c(region, county, muni)),
  by = c("muni_fips", "year")
)

permits_agg = permits %>%
  dplyr::group_by(muni_fips, region, county, muni) %>%
  dplyr::summarise(dplyr::across(c(total_new, total_demo), sum)) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(dec10, by = "muni_fips") %>%
  dplyr::mutate(
    # Net new permitted housing units.
    net_new = total_new - total_demo,
    # Permit rate: Net new permitted housing units per 1,000 residents.
    permit_rate = (net_new / pop) * 1000,
    permit_rate_rank = dplyr::min_rank(dplyr::desc(permit_rate))
  ) %>%
  dplyr::relocate(pop, .after = net_new) %>%
  dplyr::arrange(permit_rate_rank)

# The combined (long) muni-year data.
readr::write_csv(permits, "data/output/permits_time.csv")
# The aggregated muni data.
readr::write_csv(permits_agg, "data/output/permits_rate.csv")
