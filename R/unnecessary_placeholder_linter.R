#' Block usage of pipeline placeholders if unnecessary
#'
#' The argument placeholder `.` in magrittr pipelines is unnecessary if
#'   passed as the first positional argument; using it can cause confusion
#'   and impacts readability.
#'
#' This is true for forward (`%>%`), assignment (`%<>%`), and tee (`%T>%`) operators.
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "x %>% sum(., na.rm = TRUE)",
#'   linters = unnecessary_placeholder_linter()
#' )
#'
#' # okay
#' lint(
#'   text = "x %>% sum(na.rm = TRUE)",
#'   linters = unnecessary_placeholder_linter()
#' )
#'
#' lint(
#'   text = "x %>% lm(data = ., y ~ z)",
#'   linters = unnecessary_placeholder_linter()
#' )
#'
#' lint(
#'   text = "x %>% outer(., .)",
#'   linters = unnecessary_placeholder_linter()
#' )
#'
#' @evalRd rd_tags("unnecessary_placeholder_linter")
#' @seealso [linters] for a complete list of linters available in lintr.
#' @export
unnecessary_placeholder_linter <- function() {
  # TODO(michaelchirico): handle R4.2.0 native placeholder _ as well
  xpath <- "
  //SPECIAL[text() = '%>%' or text() = '%T>%' or text() = '%<>%']
    /following-sibling::expr[
      expr/SYMBOL_FUNCTION_CALL
      and not(expr[
        position() > 2
        and descendant-or-self::expr/SYMBOL[text() = '.']
      ])
    ]
    /expr[2][
      SYMBOL[text() = '.']
      and not(preceding-sibling::*[1][self::EQ_SUB])
    ]
  "

  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "expression")) {
      return(list())
    }

    xml <- source_expression$xml_parsed_content

    bad_expr <- xml2::xml_find_all(xml, xpath)

    xml_nodes_to_lints(
      bad_expr,
      source_expression = source_expression,
      lint_message = paste(
        "Don't use the placeholder (`.`) when it's not needed,",
        "i.e., when it's only used as the first positional argument in a pipeline step."
      ),
      type = "warning"
    )
  })
}
