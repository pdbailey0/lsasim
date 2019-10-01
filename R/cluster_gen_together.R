#' @title Generate cluster samples with lowest-level questionnaires
#' @description This is a subfunction of `cluster_gen` that performs cluster sampling where only the lowest-level individuals (e.g. students) fill out questionnaires.
#' @param n_levels number of cluster levels
#' @param n numeric vector with the number of sampled observations (clusters or subjects) on each level
#' @param cluster_labels character vector with the names of each cluster level
#' @param resp_labels character vector with the names of the questionnaire respondents on each level
#' @param collapse if `TRUE`, function output contains only one data frame with all answers
#' @param N list of numeric vector with the population size of each *sampled* cluster element on each level
#' @param sum_pop total population at the lowest level (sampled or not)
#' @param calc_weights if `TRUE`, sampling weights are calculated
#' @param sampling_method can be "SRS" for Simple Random Sampling or "PPS" for Probabilities Proportional to Size
#' @param n_X list of `n_X` per cluster level
#' @param n_W list of `n_W` per cluster level
#' @param c_mean vector of means for the continuous variables or list of vectors for the continuous variables for each level
#' @seealso cluster_gen cluster_gen_separate cluster_gen_together
#' @param verbose if `TRUE`, prints output messages
#' @param ... Additional parameters to be passed to `questionnaire_gen()`
#' @export
cluster_gen_together <- function(n_levels, n, N, sum_pop, calc_weights, 
                                 sampling_method, cluster_labels, resp_labels,
                                 collapse, n_X, n_W, c_mean, verbose, ...)
{
  # Creating basic elements ----------------------------------------------------
	sample <- list()  # will store all BG questionnaires
  c_mean_list <- c_mean
  if (class(c_mean_list) == "list") {
    c_mean_list <- c_mean_list[[n_levels - 1]]
  }
  id_combos <- label_respondents(n, cluster_labels)  # level label combinations
  num_questionnaires <- nrow(id_combos)

  # Generating questionnaire data for lowest level -----------------------------
  for (l in seq(num_questionnaires)) {
    respondents <- n[[n_levels]][l]
    mu <- NULL
    if (!is.null(c_mean_list) & class(c_mean_list) == "list") {
      mu <- c_mean_list[[l]]
    } else {
      mu <- c_mean_list
    }
    cluster_bg <- questionnaire_gen(
      respondents, n_X = n_X, n_W = n_W, c_mean = mu, verbose = FALSE,...
    )

    # Adding weights
    if (calc_weights) {
      cluster_bg <- weight_responses(
        cluster_bg, n, N, n_levels, l, previous_sublvl = 0,
        sampling_method, cluster_labels, resp_labels, sum_pop, verbose
      )
    }

    # Creating new ID variable
    studentID <- paste0("student", seq(nrow(cluster_bg)))
    clusterID <- paste(rev(id_combos[l, ]), collapse = "_")
    cluster_bg$uniqueID <- paste(studentID, clusterID, sep = "_")

    # Saving the questionnaire to the final list (sample)
    cluster_bg -> sample[[l]]
  }

  # Collapsing data and creating output ----------------------------------------
  if (collapse == "none") {
    names(sample) <- paste0(cluster_labels[n_levels - 1], seq(length(sample)))
  } else {
    sample <- do.call(rbind, sample)
    sample$subject <- seq(nrow(sample))
  }

  return(sample)
}