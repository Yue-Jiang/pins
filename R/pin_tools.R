pin_split_owner <- function(name) {
  parts <- strsplit(name, "/")[[1]]
  list(
    owner = if (length(parts) > 1) paste(parts[1:length(parts) - 1], collapse = "/") else NULL,
    name = if (length(parts) > 0) parts[length(parts)] else NULL
  )
}

pin_content_name <- function(name) {
  if (is.character(name)) pin_split_owner(name)$name else name
}

pin_content_owner <- function(name) {
  if (is.character(name)) pin_split_owner(name)$owner else NULL
}

pin_results_from_rows <- function(entries) {
  results_field <- function(entries, field, default) {
    sapply(entries,
           function(e) if (is.null(e[[field]])) default else e[[field]])
  }

  names <- sapply(entries, function(e) if (is.null(e$name)) basename(e$path) else e$name)
  descriptions <- results_field(entries, "description", "")
  types <- results_field(entries, "type", "files")
  metadata <- sapply(entries, function(e) as.character(
    jsonlite::toJSON(e[setdiff(names(e), c("name", "description", "type"))], auto_unbox = TRUE)))

  data.frame(
    name = names,
    description = descriptions,
    type = types,
    metadata = metadata,
    stringsAsFactors = FALSE
  )
}

pin_results_extract_column <- function(df, column) {
  df[[column]] <- sapply(df$metadata, function(e) jsonlite::fromJSON(e)[[column]])
  df
}

pin_reset_cache <- function(board, name) {
  # clean up name in case it's a full url
  name <- gsub("^https?://", "", name)

  index <- tryCatch(pin_registry_retrieve(name, board), error = function(e) NULL)
  if (!is.null(index)) {
    index$cache <- list()
    pin_registry_update(name, board, params = index)
  }
}

pin_entries_to_dataframe <- function(entries) {
  jsonlite::fromJSON(jsonlite::toJSON(entries, null = "null", auto_unbox = TRUE))
}

pin_results_merge <- function(r1, r2, merge) {
  if (nrow(r1) > 0) {
    col_diff <- setdiff(names(r2), names(r1))
    if (length(col_diff) > 0) r1[, col_diff] <- ""
  }

  if (nrow(r2) > 0) {
    col_diff <- setdiff(names(r1), names(r2))
    if (length(col_diff) > 0) {
      r2[, col_diff] <- ""
      rownames(r2) <- c()
    }
  }

  rbind(r1, r2)
}
