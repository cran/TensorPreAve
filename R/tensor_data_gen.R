#' @title Tensor time series data generation.
#' @description Function to generate a random sample of time series tensor factor model, based on econometrics assumptions. (See Chen and Lam (2023) for more details on the assumptions.)
#' @details Input tensor dimension and rank of core tensor, return a sample of tensor time series generated by factor model.
#' @param K The number of modes for the tensor time series.
#' @param n Length of time series.
#' @param d Dimensions of each mode of the tensor, written in a vector of length \code{K}.
#' @param r Rank of the core tensors, written in a vector of length \code{K}.
#' @param re Rank of the cross-sectional common error core tensors, written in a vector of length \code{K}.
#' @param eta Quantities controlling factor strengths in each factor loading matrix, written in a list of \code{K} vectors.
#' @param u Quantities controlling range of elements in each factor loading matrix, written in a list of \code{K} vectors.
#' @param heavy_tailed Whether to generate data from heavy-tailed distribution. If FALSE, generate from N(0,1); if TRUE, generate from t-distribution. Default is FALSE.
#' @param t_df The degree of freedom for t-distribution if heavy_tailed = TRUE. Default is 3.
#' @return A list containing the following: \cr
#' \code{X}: the generated tensor time series, stored in a 'Tensor' object defined in \pkg{rTensor}, where mode-1 is the time mode \cr
#' \code{A}: a list of K factor loading matrices \cr
#' \code{F_ts}: time series of core tensor, stored in a 'Tensor' object, where mode-1 is the time mode \cr
#' \code{E_ts}: time series of error tensor, stored in a 'Tensor' object, where mode-1 is the time mode \cr
#' @export
#' @import rTensor MASS stats
#' @importFrom pracma randortho
#' @examples
#' \donttest{
#' set.seed(10)
#' K = 2
#' n = 100
#' d = c(40,40)
#' r = c(2,2)
#' re = c(2,2)
#' eta = list(c(0,0),c(0,0))
#' u = list(c(-2,2),c(-2,2))
#' Data_test = tensor_data_gen(K,n,d,r,re,eta,u)
#'
#' X = Data_test$X
#' A = Data_test$A
#' F_ts = Data_test$F_ts
#' E_ts = Data_test$E_ts
#'
#' X@modes
#' F_ts@modes
#' E_ts@modes
#' dim(A[[1]])
#' }













#################################### Function to Generate data #########################################
## This function generates a tensor time series in the form of a 'Tensor' object
tensor_data_gen = function(    K                     # the number of modes for the tensor time series
                             , n                     # length of time series
                             , d                     # dimensions in each mode, written in a vector of length K. e.g. c(40,40)
                             , r                     # rank of core tensors, written in a vector of length K. e.g. c(2,2)
                             , re                    # rank of the cross-sectional common error core tensors, written in a vector of length K. e.g. c(2,2)
                             , eta                   # quantities controlling factor strengths in A_k, written in a list of K vectors. e.g. eta = list(c(0,0.2),c(0,0.2)) for Setting (I). See the paper for more details
                             , u                     # quantities controlling range of elements in A_k, written in a list of K vectors. e.g. eta = list(c(-2,2),c(-2,2)) for Setting (a). See the paper for more details
                             , heavy_tailed = FALSE  # whether to generate data from heavy tailed distribution. If FALSE, generate from N(0,1); if TRUE, generate from t-distribution
                             , t_df = 3              # if heavy_tailed = TRUE, the degree of freedom for t-distribution
                             )

  # output : a list of four elements:
  # output$X: a 'Tensor' object, where mode-1 is the time mode.
  # output$A: a list of K factor loading matrices
  # output$F: time series of the core tensors
  # output$E: time series of the error tensors
{
  # Generate non-zero mean
  mu = rTensor::as.tensor(array(rnorm(prod(d)),d))


  ## Generate the core tensor (independent AR process)
  f_series = rTensor::as.tensor(array(numeric(),c(n,r)))
  unfold_f = rTensor::unfold(f_series,row_idx = 1, col_idx = 2:(K+1))
  for (j in 1:prod(r))
  {
    if (heavy_tailed == TRUE)
    {
      unfold_f[,j] = arima.sim(n = n, n.start = 6, list(ar = c(0.7,0.3,-0.4,0.2,-0.1)), innov = rt(n,df = t_df))
    }
    else
    {
      unfold_f[,j] = arima.sim(n = n, n.start = 6, list(ar = c(0.7,0.3,-0.4,0.2,-0.1)))
    }
  }
  f_series = rTensor::fold(unfold_f,row_idx = 1, col_idx = 2:(K+1),modes = c(n,r))


  ## Generate factor loading matrices
  A = list()

  for (k in 1:K)
  {
    U_k = matrix(runif(d[k] * r[k], u[[k]][1], u[[k]][2]), d[k], r[k])
    R_k = if (r[k] == 1) matrix(d[k]^-eta[[k]]) else {diag(d[k]^-eta[[k]])}
    A_k = U_k %*% R_k
    A[[k]] = A_k
  }


  ## Generate the error tensors

  # common error component
  common_e = rTensor::as.tensor(array(numeric(),c(n,re)))

  unfold_common_e = rTensor::unfold(common_e,row_idx = 1, col_idx = 2:(K+1))
  for (j in 1:prod(re))
  {
    if (heavy_tailed == TRUE)
    {
      unfold_common_e[,j] = arima.sim(n = n, n.start = 6, list(ar = c(-0.7,-0.3,-0.4,0.2,0.1)), innov = rt(n, df = t_df))
    }
    else
    {
      unfold_common_e[,j] = arima.sim(n = n, n.start = 6, list(ar = c(-0.7,-0.3,-0.4,0.2,0.1)))
    }

  }
  common_e = rTensor::fold(unfold_common_e,row_idx = 1, col_idx = 2:(K+1),modes = c(n,re))

  ## Generate sparse loading matrices for common error component
  A_e = list()

  for (k in 1:K)
  {
    A_k = matrix(rnorm(d[k] * re[k]) * rbinom(d[k]*re[k],1,0.3), d[k], re[k]) # each element has 0.7 probability to be 0
    A_e[[k]] = A_k
  }


  # idiosyncratic error component
  idio_e = rTensor::as.tensor(array(numeric(),c(n,d)))
  unfold_idio_e = rTensor::unfold(idio_e,row_idx = 1, col_idx = 2:(K+1))
  for (j in 1:prod(d))
  {
    if (heavy_tailed == TRUE)
    {
      standard_idio =  arima.sim(n = n, n.start = 6, list(ar = c(0.8,0.4, -0.4,0.2,-0.1)), innov = rt(n, df = t_df))
    }
    else
    {
      standard_idio =  arima.sim(n = n, n.start = 6, list(ar = c(0.8,0.4, -0.4,0.2,-0.1)))
    }

    # unfold_idio_e[,j] =  standard_idio
    unfold_idio_e[,j] =  standard_idio * abs(rnorm(1)) # multiply a (random) finite variance
  }
  idio_e = rTensor::fold(unfold_idio_e,row_idx = 1, col_idx = 2:(K+1),modes = c(n,d))


  # generate the whole error tensor time series
  e_series = rTensor::as.tensor(array(numeric(),c(n,d)))

  if (K == 2)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(common_e[t,,]@data,re))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A_e[[k]], m = k)
      }
      e_series[t,,] = temp_tensor + idio_e[t,,]
    }
  }
  else if (K == 3)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(common_e[t,,,]@data,re))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A_e[[k]], m = k)
      }
      e_series[t,,,] = temp_tensor + idio_e[t,,,]
    }
  }
  else if (K == 4)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(common_e[t,,,,]@data,re))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A_e[[k]], m = k)
      }
      e_series[t,,,,] = temp_tensor + idio_e[t,,,,]
    }
  }
  else if (K == 5)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(common_e[t,,,,,]@data,re))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A_e[[k]], m = k)
      }
      e_series[t,,,,,] = temp_tensor + idio_e[t,,,,,]
    }
  }
  else
  {
    print('K too large, need to modify last part of the function')
  }




  # generate the tensor time series X
  X = rTensor::as.tensor(array(numeric(),c(n,d)))

  # For now, we can only generate the data for K<=5, but can be easily extended with more codes if needed.
  if (K == 2)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(f_series[t,,]@data,r))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A[[k]], m = k)
      }
      X[t,,] = temp_tensor + e_series[t,,]  + mu
    }
  } else if (K == 3)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(f_series[t,,,]@data,r))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A[[k]], m = k)
      }
      X[t,,,] = temp_tensor + e_series[t,,,]  + mu
    }

  }
  else if (K == 4)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(f_series[t,,,,]@data,r))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A[[k]], m = k)
      }
      X[t,,,,] = temp_tensor + e_series[t,,,,]  + mu
    }

  }
  else if (K == 5)
  {
    for (t in 1:n)
    {
      temp_tensor = rTensor::as.tensor(array(f_series[t,,,,,]@data,r))
      for (k in 1:K)
      {
        temp_tensor = rTensor::ttm(tnsr = temp_tensor, mat = A[[k]], m = k)
      }
      X[t,,,,,] = temp_tensor + e_series[t,,,,,]  + mu
    }

  }
  else
  {
    print('K too large, need to modify last part of the function')
  }


  return(list('X'=X,'A'=A,'F_ts'=f_series,'E_ts'=e_series))
}
