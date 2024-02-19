# Housing in New Jersey

Where in NJ is new housing getting built most intensely? This project seeks to answer this question using several data sources. So far it includes:

- [`dca/permits/`](./dca/permits/) - NJ Dept of Community Affairs (DCA) data on permits for [new housing construction](https://www.nj.gov/dca/divisions/codes/reporter/building_permits.html) and [demolitions](https://www.nj.gov/dca/divisions/codes/reporter/demo_permits.html).

- [`dca/warranties/`](./dca/warranties/) - NJ DCA data on [new home warranties](https://www.nj.gov/dca/codes/reporter/nhw.shtml).

## Future Data Sources

There are [many](https://www.census.gov/construction/nrc/index.html) ways to measure changing housing stock. The Decennial Census and [American Housing Survey](https://www.census.gov/programs-surveys/ahs/) count housing units, though the AHS only covers the most populous states. HUD [used to](https://ask.census.gov/prweb/PRServletCustom?pyActivity=pyMobileSnapStart&ArticleID=KCP-3695) make demolitions data from the AHS more visible, but [hasn't since 2017](https://www.huduser.gov/portal/datasets/cinch.html). The [Building Permits Survey](https://www.census.gov/construction/bps/) reports newly permitted housing, while the [Survey of Construction](https://www.census.gov/construction/chars/microdata.html) reports actual starts and completions. The BPS doesn't report demolitions, but NJ's Department of Community Affairs [does](https://www.nj.gov/dca/divisions/codes/reporter/demo_permits.html).
