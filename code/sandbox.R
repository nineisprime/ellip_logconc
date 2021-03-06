library(Matrix)
source("fit_1d_density.R")
source("active_set_newton_largep.R")
source("active_set_newton.R")

n = 300
p = 1e9

## X = matrix(rnorm(n*p), n, p)

## Y = sqrt(apply(X^2, 1, sum))

Y = rgamma(n=n, shape=p, scale=1/sqrt(p))
Y = sort(Y)


##I = c(1, 100, 500, 700, 1000)
I = c(1, 100, n)
A = setdiff(1:n, I)

phi = active_set_newton_largep(Y, A, p, diagnostic=TRUE)


phi = expand_phi(phi, Y, A)


I = c(1, 537, n)
#I = c(1, 100, 200, 500, n)
A = setdiff(1:n, I)
phi2 = active_set_newton(Y, A, p, init_phi=phi[I], diagnostic=TRUE)


eps = 1e-6
num_int_res = numerical_integration_helper(Y, M=30000, eps)

evalpts = num_int_res$evalpts
bdpts = num_int_res$bdpts
y_rvec = num_int_res$y_rvec
y_lvec = num_int_res$y_lvec
gap_vec = num_int_res$gap_vec
ind_vec2 = num_int_res$ind_vec2
kepler_global_wts = num_int_res$kepler_global_wts
kepler_ls = num_int_res$kepler_ls
ixs_ls = num_int_res$ixs_ls
grad = compute_gradient_phi(phi, y_lvec=y_lvec, y_rvec=y_rvec, ind_vec2=ind_vec2,
    gap_vec=gap_vec, kepler_ls=kepler_ls, evalpts=evalpts, ixs_ls=ixs_ls, p=p)





ygap = Y[2:n] - Y[1:(n-1)]

## create V matrix representing constraints
## V'phi <= 0
diffmat = bandSparse(n-1, n, k=c(0,1),
    diagonals=list( -1/ygap, 1/ygap ))

diffmat2 = bandSparse(n-2, n-1, k=c(0,1),
    diagonals=list(rep(-1,n-2), rep(1, n-2)))

sec_diffmat = diffmat2 %*% diffmat
sec_diffmat = rBind(c(-1/ygap[1], 1/ygap[1], rep(0,n-2)), sec_diffmat, rep(1, n))
V = sec_diffmat

## rows of B represent dual-vectors
## B_i'V_i = -1
## B_i'V_j = 0

B = -t(solve(V))


V = V[1:(n-1), ]
B = B[1:(n-1), ]



tmp = B %*% grad
