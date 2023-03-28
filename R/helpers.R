#' @keywords internal
.rescale <- function(x, x.min = min(x, na.rm = TRUE), x.max = max(x, na.rm = TRUE),
                     new.min = 0, new.max = 1) {
  if (all.equal(x.min, x.max)) {
    x
  } else {
    new.min + (x - x.min) * ((new.max - new.min) / (x.max - x.min))
  }
}
