## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(TensorPreAve)

## -----------------------------------------------------------------------------
value_weight_tensor@modes

## -----------------------------------------------------------------------------
# Setting tensor dimensions and parameters related to data generation
K = 2                     # The number of modes for the tensor time series
n = 100                   # Length of time series.
d = c(10,10)              # Dimensions of each mode of the tensor
r = c(2,2)                # Rank of core tensors
re = c(2,2)               # Rank of the cross-sectional common error core tensors
eta = list(c(0,0),c(0,0)) # Control factor strengths in each factor loading matrix
u = list(c(-2,2),c(-2,2)) # Control the range of elements in each factor loading matrix

set.seed(10)
Data_test = tensor_data_gen(K,n,d,r,re,eta,u)

X = Data_test$X
A = Data_test$A
F_ts = Data_test$F_ts
E_ts = Data_test$E_ts

X@modes
F_ts@modes
dim(A[[1]])

## -----------------------------------------------------------------------------
X = value_weight_tensor
set.seed(10)
Q_PRE_2 = pre_est(X, z = c(2,2))
Q_PRE_2

## -----------------------------------------------------------------------------
set.seed(10)
Q_PRE_1 = pre_est(X)
Q_PRE_1

## -----------------------------------------------------------------------------
set.seed(7)
pre_eigenplot(X, k = 2)

## -----------------------------------------------------------------------------
set.seed(10)
pre_est(X, eigen_j = c(3,3))

## -----------------------------------------------------------------------------
set.seed(10)
Q_PROJ_2 = iter_proj(X, initial_direction = Q_PRE_1, z = c(2,2))
Q_PROJ_2

## -----------------------------------------------------------------------------
set.seed(10)
Q_PROJ_1 = iter_proj(X, initial_direction = Q_PRE_1)
Q_PROJ_1

## -----------------------------------------------------------------------------
set.seed(10)
bs_rank = bs_cor_rank(X, initial_direction = Q_PROJ_1)
bs_rank

## -----------------------------------------------------------------------------
set.seed(10)
bs_rank = bs_cor_rank(X, initial_direction = Q_PROJ_1, B = 10)
bs_rank

## -----------------------------------------------------------------------------
set.seed(10)
results = rank_factors_est(X)
results

## -----------------------------------------------------------------------------
set.seed(10)
results = rank_factors_est(X, input_r = c(2,2))
results

