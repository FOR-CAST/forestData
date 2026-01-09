#' @keywords internal
.rescale <- function(
  x,
  x.min = min(x, na.rm = TRUE),
  x.max = max(x, na.rm = TRUE),
  new.min = 0,
  new.max = 1
) {
  if (isTRUE(all.equal(x.min, x.max))) {
    return(x)
  } else {
    return(new.min + (x - x.min) * ((new.max - new.min) / (x.max - x.min)))
  }
}
