#' Function to plot survival curve
#' @param dataframe dataframe from SQL query
#' @param survival_time_col numberic variable that indicates survival time
#' @param event_col boolean variable that indicates event occurrence
#' @param cohort_cols variable names of length 1 or greater that indicates grouping variables for output
#' @param pval TRUE if pval is to be included in the plot
#' @param median_survival_time TRUE if median survival time should be returned
#' @import dplyr
#' @import ggplot2
#' @import survminer
#' @importFrom crayon red
#' @export
plot_survival <- function(dataframe,
                         survival_time_col,
                         event_col,
                         cohort_cols,
                         pval = FALSE,
                         median_survival_time = FALSE) {

        survival_time_col <- dplyr::enquo(survival_time_col)
        event_col <- dplyr::enquo(event_col)
        cohort_cols <- dplyr::enquos(cohort_cols)

        #dataframe <- dataframe %>% rename(cohort_definition = !!cohort_col)

        dataframe <- dataframe %>% dplyr::mutate_at(vars(!!survival_time_col, !!event_col),
                                                                  as.numeric) %>%
                                mutate_at(vars(!!!cohort_cols), as.factor)

        survival_object <<- try_catch_error_as_na(Surv(time = dataframe %>% select(!!survival_time_col) %>% unlist(),
                                                       event = dataframe %>% select(!!event_col) %>% unlist(),
                                                       type = "right"))

        if (is.vector(survival_object)) {
                cat(crayon::red("\n\tError: survival_time and/or event_occurred not in correct format. Please check and try again.\n"))
        } else {
                km_fit_01 <- try_catch_error_as_na(survfit(survival_object ~ !!cohort_cols,
                                                           data = dataframe))
                if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                        cat(crayon::red("\n\tError: cohort_object and/or dataframe not in correct format. Please check and try again.\n"))

                } else {
                        medsurv <- surv_median(km_fit_01)

                        OUTPUT <- ggsurvplot(km_fit_01,
                                             data = dataframe,
                                             pval = pval,
                                             xscale = 12,
                                             break.x.by = 6,
                                             legend = c(0.8, 0.9),
                                             surv.median.line = "hv",
                                             legend.title = "Cohort",
                                             legend.labs = levels(dataframe %>%
                                                                          select(!!cohort_col) %>% unlist())) + xlab("Survival Time (Years)") + ylab("Survival Probability") + ggtitle("Kaplan-Meier Curves")

                        OUTPUT$plot + ggplot2::annotate("text",
                                                        x = medsurv$median + 2,
                                                        y = (1:nrow(medsurv))/20,
                                                        label = round(medsurv$median/12, 2),
                                                        parse = TRUE)

                        if (median_survival_time == TRUE) {
                                return(surv_median(km_fit_01))
                        }

                        if (pval == TRUE) {
                                return(surv_pvalue(km_fit_01))
                        }
                }

        }
}


