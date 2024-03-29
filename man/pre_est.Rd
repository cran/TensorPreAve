% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pre_est.R
\name{pre_est}
\alias{pre_est}
\title{Pre-Averaging Estimator}
\usage{
pre_est(X, z = rep(1, X@num_modes - 1), M0 = 200, M = 5, eigen_j = NULL)
}
\arguments{
\item{X}{A 'Tensor' object defined in package \pkg{rTensor} with \eqn{K+1} modes. Mode-1 should correspond to the time mode.}

\item{z}{(Estimated) Rank of the core tensor, written as a vector of length \eqn{K}. For iterative projection purpose, we only need this to be 1's. Default is 1's.}

\item{M0}{Number of random samples to generate, should be a positive integer. Default is 200.}

\item{M}{Number of chosen samples for pre-averaging, should be a positive integer. Usually can be set as constants (5 or 10) or 2.5 percents of \code{M0}. Default is 5.}

\item{eigen_j}{The j-th eigenvalue to calculate eigenvalue-ratio for a randomly chosen sample, written as a vector of length \eqn{K}. Default is \eqn{d_k/2} for all modes. Can be manually tuned using function \code{pre_eigenplot}.}
}
\value{
A list of \eqn{K} estimated factor loading matrices.
}
\description{
Function for the initial Pre-Averaging Procedure.
}
\details{
Input a tensor time series and return the estimated factor loading matrices (or directions) using pre-averaging method.
}
\examples{
# Example of a real data set
set.seed(10)
Q_PRE = pre_est(value_weight_tensor)
Q_PRE

set.seed(10)
Q_PRE_2 = pre_est(value_weight_tensor, z = c(2,2))
Q_PRE_2

\donttest{
# Example using generated data
K = 2
T = 100
d = c(40,40)
r = c(2,2)
re = c(2,2)
eta = list(c(0,0),c(0,0))
u = list(c(-2,2),c(-2,2))
set.seed(10)
Data_test = tensor_data_gen(K,T,d,r,re,eta,u)
X = Data_test$X
Q_PRE = pre_est(X, z = r)
Q_PRE
}
}
