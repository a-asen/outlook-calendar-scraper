library(tidyverse)


# Get data                      ======
# Get the files with a txt filename and read data:
# Read in your file name, might be different
list.files(pattern = "outlook-calendar-scraper.txt", full.names = T) -> fname

raw <- 
  read_delim(fname, delim = "¤", col_names = F) |>
  pivot_longer(everything()) |> 
  select(value)

# Split event by a common pattern: 
# str_view(d$value[1:10], ", \\d{2}:\\d{2} |, heldagsarrangement")
event_split <- str_split(raw$value, ", \\d{2}:\\d{2} |, heldagsarrangement" ) 

# Get the excluded data from the splitted pattern above
event_remain <- str_extract_all(raw$value, ", \\d{2}:\\d{2} |, heldagsarrangement" ) |> 
  map_chr(1) |>
  str_remove_all(",") |>
  trimws()

# Tidy                    ======
## Gather                 ======
raw_df <- 
  tibble(
  num = seq(1, nrow(raw),1),
  title = event_split |> map_chr(1),
  info = paste( event_remain, event_split |> map_chr(2))
)

## Day events:                                     =====
day_events <- 
  raw_df |>
  filter(str_detect(info, "\\d{2}:\\d{2} til ")) |>
  separate_wider_delim(info, ",", names=letters, too_few = "align_start") |>
  select(where(~all(!is.na(.x)))) |>
  mutate(
    .before=3,
    across( c(everything(), -num), trimws),
    from = str_split(a, " til ") |> map_chr(1),
    to = str_split(a, " til ") |> map_chr(2),
    start = c,
    end = c,
    description = if_else(!d=="Busy", d, NA),
    all_day_event = FALSE,
  ) |> 
  select(num, title, start, end, from, to, description, all_day_event)

## All day events:                                 =====
all_day_events <- 
  raw_df |>
  filter(str_detect(info, "heldagsarrangement ,"))  |> 
  separate_wider_delim(info, ",", names=letters, too_few = "align_start") |>
  select(where(~all(!is.na(.x)))) |>
  mutate(
    across(a:d, trimws),
    start = str_extract(c, "\\d{1,2}. \\w{3,9} \\d{4}"),
    end = str_extract(d, "\\d{1,2}. \\w{3,9} \\d{4}"),
    end = if_else( is.na(end), start, end),
    all_day_event = TRUE
  ) |>
  mutate(
    d_ti = duplicated(title),
    d_st = duplicated(start),
    d_en = duplicated(end)
  ) |> 
  rowwise() |>
  mutate(
    test = if_else(all(d_ti, d_st, d_en), T, F)
  ) |>
  ungroup() |>
  filter(!test) |>
  select(num, title, start, end, all_day_event) 


## Multi-day-long events                           ======
# There is a second split that is necessary here, for some reason. 
multi_day_events <- 
  raw_df |>
  filter( str_detect(info, "heldagsarrangement") ) |>
  filter( str_detect(info, "\\d{4} til ") ) |>
  separate_wider_delim( info, ",", names=letters, too_few = "align_start" ) |>
  select( where(~all(!is.na(.x))) ) |>
  mutate(
    across( c(everything(), -num), trimws ), 
    start = str_split(c, " til ") |> map_chr(1),
    end = d,
    all_day_event = TRUE,
  ) |>
  mutate(
    d_ti = duplicated(title),
    d_st = duplicated(start),
    d_en = duplicated(end)
  ) |> 
  rowwise() |>
  mutate(
    test = if_else(all(d_ti, d_st, d_en), T, F)
  ) |>
  ungroup() |>
  filter(!test) |>
  select(num, title, start, end, all_day_event)


## Combine                       ======
data <- 
  day_events |>
  bind_rows(
    all_day_events
  ) |>
  bind_rows(
    multi_day_events
  ) |>
  # Remove duplicates by "num" (there cannot be multiple of these)
  mutate(
    test = duplicated(num)
  ) |>
  filter(!test) |>
  select(-test)
  

#  TO .ics         ======
## Variables and params:        ======
months <- tibble(
  m = c("januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober","november", "desember"),
  n = c("01","02","03","04","05","06","07","08","09","10","11","12")
)

ics_start <- "BEGIN:VCALENDAR
PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Oslo
X-TZINFO:Europe/Oslo[2024a]
END:VTIMEZONE"

ics_end <- "END:VCALENDAR"

fn_fix_month <- function(data){
  map_vec(data, \(x){
    months[["n"]][which(x == months[["m"]]) ]
  })
}

## Transform:          =====
data |>
  mutate(
    start = str_remove(start, "\\."),
    end = str_remove(end, "\\."),
    from = str_remove(from, ":"),
    to = str_remove(to, ":"),
  ) |>
  separate_wider_delim(c(start,end), " ", names=c("day","month","year"), names_sep = "_") |>
  mutate(
    start_month = fn_fix_month(start_month),
    end_month = fn_fix_month(end_month),
    start_day = ifelse(str_length(start_day)<=1, paste0("0",start_day), start_day),
    end_day = ifelse(str_length(end_day)<=1, paste0("0",end_day), end_day),
    description = ifelse(is.na(description), "", description),
    filt = as.POSIXct( paste0( start_year,"/",start_month,"/",start_day,"/" ) )
  ) |>
  # filter for this round
  filter(filt > as.POSIXct("2023/03/05")) |> 
  reframe(
    A = ifelse(
      all_day_event, 
      paste0(
        "BEGIN:VEVENT", "\n", 
        "DTSTART;VALUE=DATE:", start_year, start_month, start_day, "\n",
        "DTEND;VALUE=DATE:", end_year, end_month, end_day, "\n",
        "SUMMARY:", title, "\n",
        "DESCRIPTION:", description,"\n",
        "END:VEVENT"
      ),
      paste0(
        "BEGIN:VEVENT", "\n", 
        "DTSTART;TZID=Europe/Berlin:", start_year, start_month, start_day, "T",from, "00","\n",
        "DTEND;TZID=Europe/Berlin:", end_year, end_month, end_day, "T", to, "00","\n",
        "SUMMARY:", title, "\n",
        "DESCRIPTION:", description, "\n",
        "END:VEVENT")
    ) 
  ) |> pull(A) -> calendar


##  Save          ======
write_lines(c(ics_start, calendar, ics_end), "calendar.ics")

