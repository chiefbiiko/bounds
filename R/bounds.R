# bounds

#' Bind parameters to a function.
#'  
#' \code{bind} returns a closure with given parameters bound to it.
#' 
#' @param func Function prototype object \strong{required}.
#' @param ... Unnamed or named parameters to bind \strong{required}.
#' @return 
#' 
#' @examples
#' lie <- bind(cat, 'FRAUD REPORT:')  # bind
#' lie('looking for investors')       # have fun
#' lie('quick returns guaranteed')
#' 
#' @export
bind <- function(func, ...) {  # func proto
  stopifnot(!missing(func), !missing(...))
  bound <- list(...)  # static defaults
  function(...) {  # closure
    new <- list(...)
    do.call(func, c(bound, new))
  }
}

#' Check whether a function is bound to its enclosure
#' 
#' \code{isBound} scans its input function's frame checking if there are any 
#' names not bound within its own scope - free variables. It returns a logical value 
#' indicating whether the input function is bound, aka a closure.
#' 
#' @param func Function to check \strong{required}.
#' @return Logical indicating whether func is bound, a closure.
#'
#' @details \code{func} can be any function except primitives. \code{isBound(func)} 
#' translates to: Is \code{func} bound to any names in its enclosing environment?
#'
#' @export
isBound <- function(func) {
  stopifnot(is.function(func))
  if (is.primitive(func)) return(FALSE)  # early exit
  # scan input to character vectors
  params <- names(formals(func))
  fbody <- paste0(deparse(body(func)), sep='\n', collapse='')
  # tokenize function body
  token_df <- sourcetools::tokenize_string(fbody)
  token <- split(token_df, 1L:nrow(token_df))                 # df to list
  token <- Filter(function(t) t$type != 'whitespace', token)  # toss whitespace
  token <- Filter(function(t) !t$value %in% params, token)    # toss params
  token <- lapply(token, function(t) {
    if (t$type == 'symbol' && t$value %in% builtins()) t$type <- 'builtin'
    t
  })
  # peep through
  token_TF <- sapply(1L:length(token), function(i) {
    if (token[[i]]$type == 'symbol' &&  # double & required here!!!
        (!grepl('(base::)?assign$', token[[i - 1L]]$value, perl=TRUE) &&
         !grepl('(<)?<-', token[[i + 1L]]$value, perl=TRUE))) {
      TRUE
    } else { FALSE }
  })
  # exit
  return(any(token_TF))
}