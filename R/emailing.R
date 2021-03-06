#' Send email at a step or at the end of an interrogation
#' 
#' The `email_blast()` function is useful for sending an email message that
#' explains the result of a **pointblank** validation. It is powered by the
#' **blastula** and **glue** packages. This function should be invoked as part
#' of the `end_fns` argument of [create_agent()]. It's also possible to invoke
#' `email_blast()` as part of the `fns` argument of the [action_levels()]
#' function (to possibly send an email message at one or more steps).
#'
#' To better get a handle on emailing with `email_blast()`, the analogous
#' [email_preview()] can be used with a **pointblank** agent object or the
#' output obtained from using the [get_agent_x_list()] function.
#' 
#' @param x A reference to list object prepared by the agent. It's only
#'   available in an internal evaluation context.
#' @param to,from The email addresses for the recipients and the sender.
#' @param credentials A credentials list object that is produced by either of
#'   the [blastula::creds()], [blastula::creds_anonymous()],
#'   [blastula::creds_key()], or [blastula::creds_file()] functions. Please
#'   refer to the **blastula** documentation for details on each of these helper
#'   functions.
#' @param msg_subject The subject line of the email message.
#' @param msg_header,msg_body,msg_footer Content for the header, body, and
#'   footer components of the HTML email message.
#' @param send_condition An expression that should evaluate to a logical vector
#'   of length 1. If `TRUE` then the email will be sent, if `FALSE` then that
#'   won't happen. The expression can use x-list variables (e.g., `x$notify`,
#'   `x$type`, etc.) and all of those variables can be viewed using the
#'   [get_agent_x_list()] function. The default expression is `~TRUE %in% x$notify`,
#'   which results in `TRUE` if there are any `TRUE` values in the `x$notify`
#'   logical vector (i.e., any validation step results in a 'notify'
#'   condition).
#'   
#' @examples
#' # Create a simple table with two
#' # columns of numerical values
#' tbl <-
#'   dplyr::tibble(
#'     a = c(5, 7, 6, 5, 8, 7),
#'     b = c(7, 1, 0, 0, 0, 3)
#'   )
#'
#' # Create an `action_levels()` list
#' # with absolute values for the
#' # `warn`, and `notify` states (with
#' # thresholds of 1 and 2 'fail' units)
#' al <- 
#'   action_levels(
#'     warn_at = 1,
#'     notify_at = 2
#'   )
#' 
#' # Validate that values in column
#' # `a` from `tbl` are always > 5 and
#' # that `b` values are always < 5;
#' # first, apply the `actions_levels()`
#' # directive to `actions` and set up
#' # an `email_blast()` as one of the
#' # `end_fns` (by default, the email
#' # will be sent if there is a single
#' # 'notify' state across all
#' # validation steps)
#' # agent <-
#' #   create_agent(
#' #     tbl = tbl,
#' #     actions = al,
#' #     end_fns = list(
#' #       ~ email_blast(
#' #         x,
#' #         to = "joe_public@example.com",
#' #         from = "pb_notif@example.com",
#' #         msg_subject = "Table Validation",
#' #         credentials = blastula::creds_key(
#' #           id = "gmail"
#' #         ),
#' #       )
#' #     )
#' #   ) %>%
#' #   col_vals_gt(vars(a), 5) %>%
#' #   col_vals_lt(vars(b), 5) %>%
#' #   interrogate()
#' 
#' # This example was intentionally
#' # not run because email credentials
#' # aren't available and the `to`
#' # and `from` email addresses are
#' # nonexistent; to look at the email
#' # message before sending anything of
#' # the like, we can use the 
#' # `email_preview()` function
#' email_object <-
#'   create_agent(
#'     tbl = tbl,
#'     actions = al
#'   ) %>%
#'   col_vals_gt(vars(a), 5) %>%
#'   col_vals_lt(vars(b), 5) %>%
#'   interrogate() %>%
#'   email_preview()
#'   
#' @family Emailing
#' @section Function ID:
#' 3-1
#' 
#' @export 
email_blast <- function(x,
                        to,
                        from,
                        credentials = NULL,
                        msg_subject = NULL,
                        msg_header = NULL,
                        msg_body = stock_msg_body(),
                        msg_footer = stock_msg_footer(),
                        send_condition = ~TRUE %in% x$notify) {

  # nocov start
  
  # Evaluate condition for sending email
  condition_result <- rlang::f_rhs(send_condition) %>% rlang::eval_tidy()
  
  if (!is.logical(condition_result)) {
    warning("The `send_condition` expression must resolve to a logical value",
            call. = FALSE)
    return()
  }
  
  if (is.logical(condition_result) && condition_result) {
    
    check_msg_components_all_null(msg_header, msg_body, msg_footer)

    # Preparation of the message
    blastula_message <- 
      blastula::compose_email(
        header = glue::glue(msg_header) %>% blastula::md(),
        body = glue::glue(msg_body) %>% blastula::md(),
        footer = glue::glue(msg_footer) %>% blastula::md(),
      )
    
    # Sending of the message
    blastula::smtp_send(
      email = blastula_message,
      to = to,
      from = from,
      subject = msg_subject,
      credentials = credentials
    )
  }
}

#' Get a preview of an email before actually sending that email
#' 
#' The `email_preview()` function provides a preview of an email that would
#' normally be produced and sent through the [email_blast()] function. The `x`
#' that we need for this is the agent x-list that is produced by the
#' [get_agent_x_list()] function. Or, we can supply an agent object. In both
#' cases, the email message with appear in the Viewer and a **blastula**
#' `email_message` object will be returned.
#'
#' @param x A pointblank agent or an agent x-list. The x-list object can be
#'   created with the [get_agent_x_list()] function. It is recommended that the
#'   `i = NULL` and `generate_report = TRUE` so that the agent report is
#'   available within the email preview.
#' @param msg_header,msg_body,msg_footer Content for the header, body, and
#'   footer components of the HTML email message.
#'   
#' @return A **blastula** `email_message` object.
#' 
#' @examples
#' # Create a simple table with two
#' # columns of numerical values
#' tbl <-
#'   dplyr::tibble(
#'     a = c(5, 7, 6, 5, 8, 7),
#'     b = c(7, 1, 0, 0, 0, 3)
#'   )
#'
#' # Create an `action_levels()` list
#' # with absolute values for the
#' # `warn`, and `notify` states (with
#' # thresholds of 1 and 2 'fail' units)
#' al <- 
#'   action_levels(
#'     warn_at = 1,
#'     notify_at = 2
#'   )
#' 
#' # In a workflow that involves an
#' # `agent` object, we can set up a
#' # series of `end_fns` and have report
#' # emailing with `email_blast()` but,
#' # first, we can look at the email
#' # message object beforehand by using
#' # the `email_preview()` function
#' # on an `agent` object
#' # email_object <-
#' #   create_agent(
#' #     tbl = tbl,
#' #     actions = al
#' #   ) %>%
#' #   col_vals_gt(vars(a), 5) %>%
#' #   col_vals_lt(vars(b), 5) %>%
#' #   interrogate() %>%
#' #   email_preview()
#' 
#' # The `email_preview()` function can
#' # also be used on an agent x-list to
#' # get the same email message object
#' # email_object <-
#' #   create_agent(
#' #     tbl = tbl,
#' #     actions = al
#' #   ) %>%
#' #   col_vals_gt(vars(a), 5) %>%
#' #   col_vals_lt(vars(b), 5) %>%
#' #   interrogate() %>%
#' #   get_agent_x_list() %>%
#' #   email_preview()
#' 
#' # We can view the HTML email just
#' # by printing `email_object`; it
#' # should appear in the Viewer
#' 
#' @family Emailing
#' @section Function ID:
#' 3-2
#' 
#' @export 
email_preview <- function(x,
                          msg_header = NULL,
                          msg_body = stock_msg_body(),
                          msg_footer = stock_msg_footer()) {
  
  if (inherits(x, "ptblank_agent")) {
    x <- get_agent_x_list(agent = x)
  }

  blastula::compose_email(
    header = glue::glue(msg_header) %>% blastula::md(),
    body = glue::glue(msg_body) %>% blastula::md(),
    footer = glue::glue(msg_footer) %>% blastula::md(),
  )
}

check_msg_components_all_null <- function(msg_header, msg_body, msg_footer) {
  
  if (is.null(msg_header) & is.null(msg_body) & is.null(msg_footer)) {
    warning("There is no content provided for the email message")
  }
}

#' Provide simple email message body components: body
#' 
#' The `stock_msg_body()` function simply provides some stock text for an email
#' message sent via [email_blast()] or previewed through [email_preview()].
#'
#' @return Text suitable for the `msg_body` arguments of [email_blast()] and
#'   [email_preview()].
#' 
#' @family Emailing
#' @section Function ID:
#' 3-3
#' 
#' @export
stock_msg_body <- function() {

paste0(
  blastula::add_image(
    system.file("img", "pointblank_logo.png", package = "pointblank"),
    width = 150
  ),
"
<br>
<div style=\"text-align: center; font-size: larger;\">
This <strong>pointblank</strong> validation report, \\
containing <strong>{nrow(x$validation_set)}</strong> validation step\\
{ifelse(nrow(x$validation_set) != 1, 's', '')},<br>\\
was initiated on {blastula::add_readable_time(x$time_start)}.
</div>
<br><br>
{x$report_html_small}
<br>
<div style=\"text-align: center; font-size: larger;\">
&#9678;
</div>
"
)
}

#' Provide simple email message body components: footer
#' 
#' The `stock_msg_footer()` functions simply provide some stock text for an
#' email message sent via [email_blast()] or previewed through
#' [email_preview()].
#'
#' @return Text suitable for the `msg_footer` argument of [email_blast()] and
#'   [email_preview()].
#' 
#' @family Emailing
#' @section Function ID:
#' 3-4
#' 
#' @export
stock_msg_footer <- function() {
  
"
<br>
Validation performed via the <code>pointblank</code> <strong>R<strong> package.
<br><br><br>
<div>
<a style=\"background-color: #999999; color: white; padding: 1em 1.5em; \\
position: relative; text-decoration: none; text-transform: uppercase; \\
cursor: pointer;\" href=\"https://rich-iannone.github.io/pointblank/\">Information and package documentation</a></div>
"
}

# nocov end
