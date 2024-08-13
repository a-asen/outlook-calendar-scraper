library(tidyverse)

# Get the files with a txt filename and read data:
list.files(pattern = "outlook-calendar-scraper.txt", full.names = T) -> fname
raw <- 
  read_delim(fname, delim = ";,", col_names = F) |>
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

# Gather                    ======
raw_df <- 
  tibble(
  num = seq(1, nrow(raw),1),
  title = event_split |> map_chr(1),
  info = paste( event_remain, event_split |> map_chr(2))
)

# Day events:                                     =====
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

# All day events:                                 =====
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

# Multi-day-long events                           ======
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


# Combine                       ======
data <- 
  day_events |>
  bind_rows(
    all_day_event    
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
  
