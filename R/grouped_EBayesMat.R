#' Grouped Empirical Bayes Matrix Estimator
#'
#' A user-friendly interface for \code{\link{EBayesMat}} that allows for the
#' inclusion of group side-information. For each level in \code{factor(group)} a
#' different prior is fit and used when computing the estimate. This is useful
#' for conveying side information, but should be used with caution because
#' unnecessary grouping may worsen the performance due to decreased sample size
#' within each group.
#' 
#' The data are assumed to be partially interval censored, so that each element
#' in the matrix is represented as a pair of lower and upper bounds (L_ij,
#' R_ij). If the bounds are equal then there is a direct observation, if the
#' bounds are different then the observation is known to lie in the specified
#' interval. This format allows for directly observed data along with left-,
#' right-, and interval-censored observations. Each rows of L and R are
#' observations or bounds in R^p.
#'
#' \code{s1} represents the Gaussian likelihood standard deviation for every
#' observation; it can be a scalar, vector, or matrix, so long as \code{L / s1}
#' is possible.
#'
#' @param L n x p matrix of lower bounds on observations
#' @param R n x p matrix of upper bounds on observations
#' @param gr m x p matrix of candidate means (MLE by default)
#' @param algorithm method to fit prior, see \code{\link{EBayesMat}} for more
#' details
#' @param s1 standard deviation for every observation
#' @param group grouping variable denoting which rows follow which priors,
#' refer to details for more
#' @param ... further arguments passed into fitting method
#'
#' @return a fitted posterior mean matrix (n x p)
#' @export
#'
#' @examples
#' set.seed(1)
#' n <- 100
#' p <- 2
#' TH <- cbind(rnorm(n), rnorm(n, mean = c(0,5)))
#' X <- TH + matrix(rnorm(n*p), n, p)
#' fit0 <- grouped_EBayesMat(X)
#' all.equal(fit0, fitted(EBayesMat(X)))
#' 
#' fit1 <- grouped_EBayesMat(X, group = TH[,2] > 2.5) # adding side information
#' mean((TH - fit0)^2) > mean((TH - fit1)^2)
grouped_EBayesMat <- function(L, R = L, gr = (L+R)/2, algorithm = "EM", s1 = 1,
                              group = integer(nrow(L)), ...) {
    # basic checks
    stopifnot(is.matrix(L))
    stopifnot(all(dim(L) == dim(R)))
    stopifnot(all(L <= R))
    stopifnot(all(s1 >= 0))
    stopifnot(length(group) == nrow(L))

    # set-up
    L <- L / s1
    R <- R / s1
    group <- as.factor(group)

    # fit models for each group separately
    est <- matrix(nrow = nrow(L), ncol = ncol(L))
    for (level in levels(group)) {
        # find rows to focus on
        group.idx <- which(levels(group)[group] == level)

        # subset data and pre-compute range
        L0 <- L[group.idx, , drop = FALSE]
        R0 <- R[group.idx, , drop = FALSE]

        # estimate posterior mean of group
        fit <- EBayesMat(
            L = L0,
            R = R0,
            gr = gr,
            algorithm = algorithm,
            ...
        )
        est[group.idx, ] <- posterior_mean.EBayesMat(fit)
    }

    est * s1
}
