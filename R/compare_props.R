#' Compare proportions across groups
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @param dataset Dataset name (string). This can be a dataframe in the global environment or an element in an r_data list from Radiant
#' @param var1 A grouping variable to split the data for comparisons
#' @param var2 The variable to calculate proportions for
#' @param levs The factor level selected for the proportion comparison
#' @param alternative The alternative hypothesis ("two.sided", "greater" or "less")
#' @param conf_lev Span of the confidence interval
#' @param adjust Adjustment for multiple comparisons ("none" or "bonf" for Bonferroni)
#' @param data_filter Expression entered in, e.g., Data > View to filter the dataset in Radiant. The expression should be a string (e.g., "price > 10000")
#'
#' @return A list of all variables defined in the function as an object of class compare_props
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#' result <- titanic %>% compare_props("pclass", "survived")
#'
#' @seealso \code{\link{summary.compare_props}} to summarize results
#' @seealso \code{\link{plot.compare_props}} to plot results
#'
#' @importFrom tidyr spread_
#'
#' @export
compare_props <- function(dataset, var1, var2,
                         levs = "",
                         alternative = "two.sided",
                         conf_lev = .95,
                         adjust = "none",
                         data_filter = "") {

	vars <- c(var1, var2)
	dat <- getdata(dataset, vars, filt = data_filter) %>% mutate_each(funs(as.factor))
	if (!is_string(dataset)) dataset <- "-----"

	lv <- levels(dat[,var2])
	if (levs != "") {
		# lv <- levels(dat[,var2])
		if (levs %in% lv && lv[1] != levs) {
			dat[,var2] %<>% as.character %>% as.factor %>% relevel(levs)
			lv <- levels(dat[,var2])
		}
	}

	# check variances in the data
  if (dat %>% summarise_each(., funs(var(.,na.rm = TRUE))) %>% min %>% {. == 0})
  	return("Test could not be calculated. Please select another variable.")

  rn <- ""
  dat %>%
  group_by_(var1, var2) %>%
  summarise(n = n()) %>%
  spread_(var2, "n") %>%
  { .[,1][[1]] %>% as.character ->> rn
	  select(., -1) %>%
	  as.matrix %>%
	  set_rownames(rn)
  } -> prop_input

	##############################################
	# flip the order of pairwise testing - part 1
	##############################################
  flip_alt <- c("two.sided" = "two.sided", "less" = "greater", "greater" = "less")
	##############################################

	res <- sshhr( pairwise.prop.test(prop_input, p.adjust.method = adjust,
	              alternative = flip_alt[alternative]) ) %>% tidy

	##############################################
	# flip the order of pairwise testing - part 2
	##############################################
	res[,c("group1","group2")] <- res[,c("group2","group1")]
	##############################################

	# from http://www.cookbook-r.com/Graphs/Plotting_props_and_error_bars_(ggplot2)/
	ci_calc <- function(se, conf.lev = .95)
	 	se * qnorm(conf.lev/2 + .5, lower.tail = TRUE)

	class(prop_input)

	prop_input %>%
		data.frame %>%
		mutate(n = .[,1:2] %>% rowSums, p = .[,1] / n,
					 se = (p * (1 - p) / n) %>% sqrt,
       		 ci = ci_calc(se, conf_lev)) %>%
		set_rownames({prop_input %>% rownames}) -> dat_summary

	vars <- paste0(vars, collapse = ", ")
  environment() %>% as.list %>% set_class(c("compare_props",class(.)))
}

#' Summary method for the compare_props function
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @param object Return value from \code{\link{compare_props}}
#' @param ... further arguments passed to or from other methods
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#' summary(result)
#' titanic %>% compare_props("pclass", "survived") %>% summary
#'
#' @seealso \code{\link{compare_props}} to calculate results
#' @seealso \code{\link{plot.compare_props}} to plot results
#'
#' @export
summary.compare_props <- function(object, ...) {

  cat("Pairwise proportion comparisons\n")
	cat("Data      :", object$dataset, "\n")
	if (object$data_filter %>% gsub("\\s","",.) != "")
		cat("Filter    :", gsub("\\n","", object$data_filter), "\n")
	cat("Variables :", object$vars, "\n")
	cat("Level     :", object$levs, "in", object$var2, "\n")
	cat("Confidence:", object$conf_lev, "\n")
	cat("Adjustment:", if (object$adjust == "bonf") "Bonferroni" else "None", "\n\n")

  object$dat_summary[,-1] %<>% round(3)
  print(object$dat_summary %>% as.data.frame, row.names = FALSE)
	cat("\n")

  hyp_symbol <- c("two.sided" = "not equal to",
                  "less" = "<",
                  "greater" = ">")[object$alternative]

  props <- object$dat_summary$p
  names(props) <- object$rn
	res <- object$res
	res$`Alt. hyp.` <- paste(res$group1,hyp_symbol,res$group2," ")
	res$`Null hyp.` <- paste(res$group1,"=",res$group2, " ")
	res$diff <- (props[res$group1 %>% as.character] - props[res$group2 %>% as.character]) %>% round(3)
	res <- res[,c("Alt. hyp.", "Null hyp.", "diff", "p.value")]
	res$` ` <- sig_stars(res$p.value)
	res$p.value <- round(res$p.value,3)
	res$p.value[ res$p.value < .001 ] <- "< .001"
	print(res, row.names = FALSE, right = FALSE)
	cat("\nSignif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1\n")
}

#' Plot method for the compare_props function
#'
#' @details See \url{http://vnijs.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @param x Return value from \code{\link{compare_props}}
#' @param plots One or more plots of proportions or counts ("props" or "counts")
#' @param shiny Did the function call originate inside a shiny app
#' @param ... further arguments passed to or from other methods
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#' plot(result, plots = c("props","counts"))
#'
#' @seealso \code{\link{compare_props}} to calculate results
#' @seealso \code{\link{summary.compare_props}} to summarize results
#'
#' @export
plot.compare_props <- function(x,
                               plots = "props",
                               shiny = FALSE,
                               ...) {

	object <- x; rm(x)

	dat <- object$dat
	v1 <- colnames(dat)[1]
	v2 <- colnames(dat)[-1]
	object$dat_summary[,v1] <- object$rn
	lev_name <- object$lv[1]

	## from http://www.cookbook-r.com/Graphs/Plotting_props_and_error_bars_(ggplot2)/
	plot_list <- list()
	if ("props" %in% plots) {
		## use of `which` allows the user to change the order of the plots shown
		plot_list[[which("props" == plots)]] <-
			ggplot(object$dat_summary, aes_string(x = v1, y = "p", fill = v1)) +
			geom_bar(stat = "identity") +
	 		geom_errorbar(width = .1, aes(ymin = p-ci, ymax = p+ci)) +
	 		geom_errorbar(width = .05, aes(ymin = p-se, ymax = p+se), colour = "blue") +
	 		theme(legend.position = "none")
	}

	if ("counts" %in% plots) {
		plot_list[[which("counts" == plots)]] <-
			ggplot(object$dat, aes_string(x = v1, fill = v2)) +
			geom_bar(position = "dodge")
	}

	sshhr( do.call(arrangeGrob, c(plot_list, list(ncol = 1))) ) %>%
 	  { if (shiny) . else print(.) }
}
