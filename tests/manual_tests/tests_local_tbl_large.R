library(pointblank)
library(intendo)

# Make a vector of known product types
intendo_products <-
  c(
    "gems1", "gems2", "gems3", "gems4", "gems5",
    "gold1", "gold2", "gold3", "gold4", "gold5", "gold6", "gold7",
    "offer1", "offer2", "offer3", "offer4", "offer5",
    "ad_5sec", "pass"
  )

# Generate an expected schema for the table
revenue_tbl_schema <- 
  col_schema(
    user_id = "character",
    session_id = "character",
    time = c("POSIXct", "POSIXt"),
    name = "character",
    size = "character",
    type = "character",
    price = "numeric",
    revenue = "numeric"
  )

# Create an `action_levels` object, setting
# *warn* and *stop* thresholds at 0.01 and 0.10
al <- action_levels(warn_at = 0.01, stop_at = 0.10, notify_at = 0.15)

agent <-
  create_agent(
    tbl = intendo_revenue,
    tbl_name = "intendo::intendo_revenue",
    label = "The **intendo** revenue table.", 
    actions = al
  ) %>%
  col_vals_between(
    vars(revenue),
    left = 0.01, right = 150
  ) %>%
  col_vals_not_null(vars(user_id, session_id, time, name, type, revenue)) %>%
  col_vals_between(
    vars(time),
    left = "2015-01-01", right = "2016-01-01"
  ) %>%
  col_vals_lt(
    vars(revenue),
    value = vars(price),
    preconditions = ~ . %>% dplyr::filter(type != "ad")
  ) %>%
  col_vals_in_set(
    vars(type),
    set = c(
      "ad", "currency", "season_pass",
      "offer_agent", NA
    ),
  ) %>%
  col_vals_in_set(
    vars(name), set = intendo_products
  ) %>%
  col_vals_regex(
    vars(user_id), regex = "[A-Y]{12}"
  ) %>%
  col_vals_regex(
    vars(session_id), regex = "[A-Z]{5}_[a-z]{8}"
  ) %>%
  col_is_character(vars(user_id, session_id)) %>%
  col_schema_match(schema = revenue_tbl_schema) %>%
  interrogate()

agent

get_agent_report(agent, arrange_by = "severity")

get_agent_report(agent, arrange_by = "severity", keep = "fail_states")

extracts <- agent %>% get_data_extracts()

x_list <- get_agent_x_list(agent)

email <- email_preview(agent)

sundered <- get_sundered_data(agent)
