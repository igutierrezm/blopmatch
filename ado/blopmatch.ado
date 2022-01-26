capture program drop blopmatch
program blopmatch, eclass sortpreserve byable(recall)
    version 13.0
    syntax anything(name=teffects) [if] [in] [fweight/] [, *]

    // Create marker variable
    marksample touse

    // Create weight variable
    tempvar wvar

    // Create key variable for exact ematch
    tempvar gvar

    // Parse inputs
    local options "wvar(`wvar') wexp(`exp') touse(`touse') `options'"
    blopmatch_parse `teffects', `options'

	// Create _cons variable
    tempvar _cons
    generate `_cons' = 1

    // Drop collinear covariates
    mata : blopmatch_rmcoll("`_cons' `s(evar)'", "`s(xvar)'", "`touse'")
    drop `_cons'

    // Create group variable
    blopmatch_parse_gvar, gvar(`gvar')

    // Sort dataset
    sort `s(tvar)' `s(gvar)', stable

    // Estimate ate/atet
    mata : blopmatch_estimate()

    // Display results
    blopmatch_report `"`0'"'
end

//==============================================================================
// LP functions
//==============================================================================

// Class definition
version 13.0
mata:
class lp {
    // Variables
    real matrix    A
    real rowvector col_sf
    real colvector B, b, p, xB, row_sf
    real scalar    z, btol, flag, imax, otol, scaling, pricing
    // Methods
    void           new(), scale(), updateBasisInv()
    real scalar    solve()
}
end

// Class constructor
mata:
void lp::new()
{
    otol    = 1e-8
    btol    = 1e-8
    imax    = 2e+3
    col_sf  = 1
    row_sf  = 1
    scaling = 0
    pricing = 0
}
end

/**
    Re-scale the linear program

    p.scale() re-scale a linear program p, returning the re-scaled matrix
    in p.A, the row-scaling factors in p.row_sf, and the column-scaling
    factors in p.col_sf. By default, the scaling technique is
    equilbration. See Ploskas & Samaras (2017) for details.

    @param  nothing
    @return nothing

    References

    Ploskas, N. & Samaras, N. (2017).
        Linear Programming Using MATLAB.
        Springer.
*/
version 13.0
mata:
void lp::scale()
{
    // Equilibration (default)
    if (scaling == 0) {
        _equilrc(A, row_sf, col_sf)
        b = b :* row_sf
        p = p :/ col_sf'
    }
}
end

version 13.0
mata:
real scalar lp::solve()
{
   // Initializations
    real scalar    n, m, s, r, swap
    real colvector N

    // Problem dimensions
    n = cols(A)
    m = rows(A)

    // Scaling (see lp::scale())
    scale()

    // Basis complement
    N    = 1::n;
    N[B] = J(m, 1, 0);
    N    = select(N, N :!= 0);
    
    // Corner case: n == m
    if (n == m) {
        xB = qrsolve(A[., B], b)
        if (any(xB :< -otol)) {
            xB = J(m, 1, .)
            B  = J(m, 1, .)
            return(-2)
        }
        else {
            return(1)
        }
    }
    
    // Main loop (update the basis until passing the optimality test)
    for (iter = 1; iter <= imax; iter++) {
        // Optimality test
        lud(A[., B], L = ., U = ., perm = .)
        h   = lusolve(U,  lusolve(L, b[invorder(perm)])) // (A_B)⁻¹b
        u   = lusolve(L', lusolve(U', p[B]))[perm]       // (p_B)'(A_B)⁻¹
        ctr = p[N]' - u' * A[., N]                       // reduced costs
        if (all(ctr :> -otol) == 1) {
            B  = B
            xB = h :* (col_sf[B])'
            z  = u'*b
            return(1)
        }

        // Entering variable (according to each pivot rule)
        if (pricing == 0) {
            minindex(ctr, 1, s = ., .) // Dantzig
            s = s[1]
        }

        // Boundedness test
        d = lusolve(U, lusolve(L, A[invorder(perm), N[s]])) // pivot column
        if (all(d :< btol) == 1) {
            xB = J(m, 1, .)
            B  = J(m, 1, .)
            return(-1)
        }

        // Outcoming variable
        blocking = selectindex(d :>= btol)
        minindex(h[blocking] :/ d[blocking], 1, index_r = ., .)
        r = blocking[index_r[1]]

        // Basis updating
        swap = B[r]
        B[r] = N[s]
        N[s] = swap
    }
    B  = B
    xB = h :* (col_sf[B])'
    z  = u'*b    
    return(0)
}
end

version 13.0
mata:
void lp::updateBasisInv(real colvector d, real r)
{
    // Calculate eta column vector
    eta    = - d / d[r]
    eta[r] = 1 / d[r]
    
    // Calculate eta matrix
    Einv    = I(m)
    Einv[r] = eta

    // Update basis inverse
    BasisInv = Einv * BasisInv
}
end

//==============================================================================
// BLOP functions
//==============================================================================

mata: mata clear
version 13.0
mata:
void ///
function blopmatch_estimate()
{
    // Import data from Stata
    blopmatch_get_data(Y = ., G = ., X = ., N = .)

    // get stat, v(stat) foreach G-category
    pnts = J(s("Ngroups"), 1, .)
    vars = J(s("Ngroups"), 1, .)
	wgts = J(s("Ngroups"), 1, .)
    for (group = 1; group <= s("Ngroups"); group++) {
        // Update data block
        blopmatch_get_subdata(Y, G, X, N, Ysub = ., Xsub = ., Nsub = ., group)
        wgts[group] = (*Nsub[1]) / (*Nsub[4])

        // Get weights for point estimation
        blopmatch_get_pnt_weights(Xsub, Nsub, W = ., B = .)

        // Get ate/ate point estimate
        pnts[group] = blopmatch_get_pnt(Ysub, Nsub, W, B, Yb = .)

		// Provide a simple solution when some N[g] is lower than 2
        // TODO: Explore a better solution for this case
		if (*Nsub[1] < 2 || *Nsub[2] < 2) {
			vars[group] = 0
		} 
		else {		
			// Get "c-coefficients" (required for variance estimation)
			blopmatch_get_c_coefficients(Nsub, W, B, C = .)

			// Get weights for variance estimation
			blopmatch_get_var_weights(Xsub, Nsub, W, B, F = .)

			// Get ate/ate variance estimate
			vars[group] = blopmatch_get_var(Ysub, Nsub, W, B, C, F, Yb, pnts[group])
		}
    }

    // Combined result
	st_rclear()
	st_numscalar("r(b)", mean(pnts, wgts))
	st_numscalar("r(V)", mean(vars, wgts) + variance(pnts, wgts))
}

transmorphic scalar ///
function s(string scalar x)
{
    y = sprintf("s(%s)", x)
    y = st_global(y)
    z = strtoreal(y)
    if (z != .) return(z)
    if (z == .) return(y)
}

void ///
function blopmatch_get_data(
    pointer vector Y,
    pointer vector G,
    pointer vector X,
    pointer vector N
)
{
    // Creates a pointer for each variable
    Y = J(2, 1, NULL) // outcome variable
    G = J(2, 1, NULL) // group variable (exact match)
    X = J(2, 1, NULL) // covariates in the outcome model
    N = J(2, 1, NULL) // number of observations

    // Create a matrix for each variable
    yvector = st_data(., s("yvar"), s("touse"))
    gvector = st_data(., s("gvar"), s("touse"))
    wvector = st_data(., s("wvar"), s("touse"))
    tvector = st_data(., s("tvar"), s("touse"))
    Xmatrix = st_data(., s("xvar"), s("touse"))

    // Remove any remaining ld variable
    XX = cross(Xmatrix, Xmatrix)
    XX = invsym(XX)
    c = (diagonal(XX) :!= 0)
    Xmatrix = Xmatrix[., selectindex(c :== 1)]

    // Partition the data, according to tvar
    info = panelsetup(tvector, 1)
    for (h = 1; h < 3; h++) {
        Y[h] = &(panelsubmatrix(yvector, h, info))
        G[h] = &(panelsubmatrix(gvector, h, info))
        X[h] = &(panelsubmatrix(Xmatrix, h, info)')
        N[h] = &(J(s("Ngroups"), 1, 0))
    }

    // Standardize data (according to s("metric"))
    if (s("metric") != "euclidean") {
        if (s("metric") == "mahalanobis") {
            S = quadvariance(Xmatrix, wvector)
        }
        if (s("metric") == "ivariance") {
            S = quadvariance(Xmatrix, wvector)
            S = diag(S)
        }
        L = cholesky(S)
        X[1] = &solvelower(L, *X[1])
        X[2] = &solvelower(L, *X[2])
    }
}

void ///
function blopmatch_get_subdata(
    pointer vector Y,
    pointer vector G,
    pointer vector X,
    pointer vector N,
    pointer vector Ysub,
    pointer vector Xsub,
    pointer vector Nsub,
    real scalar group
)
{
    // Creates a pointer for each variable
    Ysub = J(2, 1, NULL) // outcome variable
    Xsub = J(2, 1, NULL) // covariates in the outcome model
    Nsub = J(4, 1, NULL) // number of observations

    // Filter data
    for (h = 1; h <= 2; h++) {
        idx     = selectindex(*G[h] :== group)
        Ysub[h] = &((*Y[h])[idx])
        Xsub[h] = &((*X[h])[., idx])
        Nsub[h] = &(rows(*Ysub[h]))
    }
    Nsub[3] = &max((*Nsub[1], *Nsub[2]))
    Nsub[4] = &(*Nsub[1] + *Nsub[2])
	
// 	// Check that each group have a least 2 observations
// 	if (*Nsub[1] < 2 || *Nsub[2] < 2) {
// 		printf(
// 			"{err}fewer than 2 nearest-neighbor matches for some " +
// 			"observations when in-group matching for variance estimation; " +
// 			"use \noption " +
// 			"{helpb teffects_ipw##osample:osample}{bf:(`osample')} to " +
// 			"identify all observations with deficient matches\n"
// 		)
// 		exit(459)
// 	}
	
	// Check that each group have a least 1 observation
	if (*Nsub[1] < 1 || *Nsub[2] < 1) {
		printf(
			"{err}no exact matches for some observations; use " +
			"{helpb teffects_ipw##osample:osample}{bf:(`osample')} to " +
			"identify all observations with deficient matches\n"
		)
		exit(459)
	}

    // Save sample size in a common table
    for (q = 1; q <= 2; q++) {
        (*N[q])[group] = *Nsub[q]
    }
}

void ///
function blopmatch_get_pnt_weights(
    pointer vector X,
    pointer vector N,
    pointer matrix W,
    pointer matrix B
)
{
    // Declarations
    real scalar g       // Treatment group (1: control, 2: treatment)
    real scalar h       // Complement (3 - g)
    real scalar f       // Exit flag
    real colvector x_gi // Covariate vector,         unit (g, i)
    real colvector b_gi // Optimal weights (basis),  unit (g, i)
    real colvector w_gi // Optimal weights (values), unit (g, i)
    real matrix X_gi    // Covariate matrix of potencial matches, unit (g, i)

    // Creates a pointer for the (matching) weights
    W = J(2, *N[3], NULL)
    B = J(2, *N[3], NULL)
    for (g = 1; g < 3; g++) {
        for (i = 1; i <= *N[g]; i++) {
            W[g, i] = &.
            B[g, i] = &.
        }
    }

    // Loop over treatment groups and observations, finding the weights
    for (g = 1; g < 3; g++) {
        h = 3 - g
        X_gi = *X[h]
        for (i = 1; i <= *N[g]; i++) {
            // Solves the blop, level-by-level
            x_gi = (*X[g])[., i]
            f = blopmatch_blop1(X_gi, x_gi, w_gi = ., b_gi = .)
            f = blopmatch_blop2(X_gi, x_gi, w_gi, b_gi)
            // Stores the output
            (*W[g, i]) = w_gi
            (*B[g, i]) = b_gi
        }
    }
}

real scalar ///
function blopmatch_blop1(
    real matrix X,
    real matrix x,
    real matrix w,
    real matrix B
)
{
    // Problem dimensions
    K = rows(X) // covariates
    N = cols(X) // observations

    // Problem initialization
    class lp scalar P1
    P1 = lp()
	
    // Problem parameters
    P1.A  = (I(K), -I(K), X \ J(1, 2 * K, 0), J(1, N, 1))
    P1.p  = (J(2 * K, 1, 1) \ J(N, 1, 0))
    P1.b  = (x \ 1)

    // Initial feasible basis, see Gutiérrez (2018)
    muID = (0 + 1) :: (1 * K)            // b columns related to mu (inic)
    nuID = (K + 1) :: (2 * K)            // b columns related to nu (inic)
    cri  = (x - X[., N]) :>  0           // entering criteria for mu/nu
    muID = muID[selectindex(cri :== 1)]  // if cri[i] >  0, then mu[i] is basic
    nuID = nuID[selectindex(cri :== 0)]  // if cri[i] <= 0, then nu[i] is basic
    if (sum(cri) == 0) muID = J(0, 1, .) // neccesary if muID is empty
    if (sum(cri) == K) nuID = J(0, 1, .) // neccesary if nuID is empty
    P1.B = (muID \ nuID \ N + 2 * K)

    // Problem solution
    f = P1.solve()
    w = P1.xB
    B = P1.B
    return(f)
}

real scalar ///
function blopmatch_blop2(
    real matrix X,
    real matrix x,
    real matrix w,
    real matrix B
)
{
    // Problem dimensions
    K = rows(X)
    N = cols(X)

	// Vector projection
	mu_idx = selectindex((0 :< B :- 0) :& (B :- 0 :<= K))
	nu_idx = selectindex((0 :< B :- K) :& (B :- K :<= K))
	mu     = I(K)[., B[mu_idx] :- 0] * w[mu_idx]
	nu     = I(K)[., B[nu_idx] :- K] * w[nu_idx]
	Px0    = x - mu + nu
	
	// Problem initialization
	class lp scalar P2
	P2 = lp()
	
	// If rank(A) > K, use the standard method:
	A = (X \ J(1, N, 1))
	rkA = rank(A)	
	if (rkA == K + 1) {
		// Problem parameters (b and A)
		P2.b = (Px0 \ 1)
		P2.A = A

		// Problem parameters (p)
		p = J(N, 1, 0)
		for (j = 1; j <= N; j++) {
			p[j] = norm(x - X[., j])^2
		}
		P2.p = p
	
		// Problem parameters (B)
		Q = sum(B :> 2 * K)
		B = select(B, B :> (2 * K)) - J(Q, 1, (2 * K))
		if (Q < (1 + K)) {
			// B complement (N0)
			N0    = 1::N
			N0[B] = J(Q, 1, 0)
			N0    = select(N0, N0 :!= 0)
			// Method A (simple yet fragile)
			B_A = (B \ N0[1::(1 + K - Q)])
			if (rank(P2.A[., B_A]) == (1 + K)) {
				B = B_A
			}
			else {
				col = 1
				rk0 = rank(P2.A[., B])
				while (rk0 < 1 + K) {
					if (col > rows(N0)) {
                        // A short term solution for this pathological case
						w = J(rows(B), 1, 1) / rows(B)
						return(10)
					}
					B_B = (B \ N0[col])
					rk1 = rank(P2.A[., B_B])
					if (rk1 > rk0) {
						B   = B_B
						rk0 = rk1
					}
					col++
				}
			}
		}
		P2.B = B

		// Problem solution
		f = P2.solve()
		w = P2.xB
		B = P2.B
		return(f)
	}
	else {
		if (rkA == N) {
			w = w[selectindex(2 * K :< B)]
			B = B[selectindex(2 * K :< B)] :- 2 * K
			return(1)
		}
		if (rkA < N) {
			// Find a basis for the null space of A (let us call it Q)
			Qfactor = Rfactor = .
			qrd(A', Qfactor, Rfactor)
			Q = Qfactor[., (rkA + 1)::N]
			P2.A = (-Q, Q, I(rows(Q)))
			P2.b = J(N, 1, 0)
			for (j = 1; j <= K + 1; j++) {
				if (B[j] > 2 * K) P2.b[B[j] - 2 * K] = w[j]
			}
			
			// Problem parameters (p)
			p = J(N, 1, 0)
			for (j = 1; j <= N; j++) {
				p[j] = norm(x - X[., j])^2
			}
			P2.p = (Q' * p \ - Q' * p \ J(N, 1, 0))
			
			// Problem parameters (B)
			P2.B = (2 * (N - rkA) + 1)::(2 * (N - rkA) + N)
			
			// Problem solution
			f = P2.solve()
			c1 = N - rkA
			wsol = J(c1, 1, 0)
			for (j = 1; j <= N; j++) {
				if      (P2.B[j] <= c1)     wsol[P2.B[j]]      = P2.xB[j]
				else if (P2.B[j] <= 2 * c1) wsol[P2.B[j] - c1] = P2.xB[j]
			}
			w = P2.b + Q * wsol
			B = 1::N
			return(f)
		}
	}
}

real scalar ///
function blopmatch_get_pnt(
    pointer vector Y,
    pointer vector N,
    pointer matrix W,
    pointer matrix B,
    pointer vector Yb
)
{
    // Imputations
    Yb = J(2, 1, NULL)
    for (g = 1; g < 3; g++) {
        h = 3 - g
        Yb[g] = &J(*N[g], 1, .)
        for (i = 1; i <= *N[g]; i++) {
            w_gi = *W[g, i]
            m_gi = (*Y[h])[*B[g, i]] // aquí falla!
            (*Yb[g])[i] = cross(w_gi, m_gi)
        }
    }
    // Treatment effect
    if (s("stat") == "ate") {
        N0   = *N[1] + *N[2]
        stat = sum(*Y[2] - *Yb[2]) / N0 - sum(*Y[1] - *Yb[1]) / N0
    }
    if (s("stat") == "atet") {
        N0   = *N[2]
        stat = sum(*Y[2] - *Yb[2]) / N0
    }
    return(stat)
}

void ///
function blopmatch_get_c_coefficients(
    pointer vector N,
    pointer matrix W,
    pointer matrix B,
    pointer matrix C
)
{
    C = J(2, 2, NULL)
    for (a = 1; a < 3; a++) {
        for (g = 1; g < 3; g++) {
            h = 3 - g
            C[a, g] = &J(*N[g], 1, 0)
            for (i = 1; i <= *N[g]; i++) {
                for (j = 1; j <= *N[h]; j++) {
                    row = selectindex(*B[h, j] :== i)
                    if (sizeof(row) > 0) {
                        (*C[a, g])[i] = (*C[a, g])[i] + ((*W[h, j])[row])^(a)
                    }
                }
            }
        }
    }
}

void ///
function blopmatch_get_var_weights(
    pointer vector X,
    pointer vector N,
    pointer matrix W,
    pointer matrix B,
	pointer vector F
)
{
    // Declarations
    real scalar g       // Treatment group (1: control, 2: treatment)
    real scalar h       // Complement (3 - g)
    real scalar f       // Exit flag
    real colvector x_gi // Covariate vector,         unit (g, i)
    real colvector b_gi // Optimal weights (basis),  unit (g, i)
    real colvector w_gi // Optimal weights (values), unit (g, i)
    real matrix X_gi    // Covariate matrix of potencial matches, unit (g, i)

    // Loop over treatment groups and observations, finding the weights
    F = J(2, 1, NULL)
    for (g = 1; g < 3; g++) {
        cols = 2::(*N[g])
		F[g] = &J(*N[g], 1, 0)
        for (i = 1; i <= *N[g]; i++) {
            // Solves the blop, level-by-level
            x_gi = (*X[g])[., i]
            X_gi = (*X[g])[., cols]
            f = blopmatch_blop1(X_gi, x_gi, w_gi = ., b_gi = .)
            (*F[g])[i] = blopmatch_blop2(X_gi, x_gi, w_gi, b_gi)
            // Stores the output
            (*W[g, i]) = w_gi
            (*B[g, i]) = b_gi
            // Update cols
            if (i < *N[g]) cols[i] = i
        }
    }
}

real scalar ///
function blopmatch_get_var(
    pointer vector Y,
    pointer vector N,
    pointer matrix W,
    pointer matrix B,
    pointer matrix C,
	pointer vector F,
    pointer vector Yb,
    real    vector tau
)
{	
    // Imputations (using other observations in the same group)
    Yt = J(2, 1, NULL)
    for (g = 1; g < 3; g++) {
        idx = 2::(*N[g])
        Yt[g] = &J(*N[g], 1, .)
        for (i = 1; i <= *N[g]; i++) {
            w_gi = *W[g, i]
            m_gi = (*Y[g])[idx[*B[g, i]]]
            (*Yt[g])[i] = cross(w_gi, m_gi)
			if ((*F[g])[i] == 10) {
				(*Yt[g])[i] = 0.0
			}
            if (i < *N[g]) {
                idx[i] = i
            }
        }
    }

    // Conditional variances
    s2 = J(2, 1, NULL)
    for (g = 1; g < 3; g++) {
        s2[g] = &J(*N[g], 1, .)
        for (i = 1; i <= *N[g]; i++) {
            s2i         = (*Y[g])[i] - (*Yt[g])[i]
            s2i         = s2i^2
            s2i         = s2i / (1 + norm(*W[g, i])^2)
            (*s2[g])[i] = s2i
			if ((*F[g])[i] == 10) {
				(*s2[g])[i] = 0.0
			}
        }
    }

    // Marginal variance
    variance = 0
	(*N[1]) = sum(*F[1] :!= 10)
	(*N[2]) = sum(*F[2] :!= 10)
	(*N[4]) = *N[1] + *N[2]
    if (s("stat") == "ate") {
        for (g = 1; g < 3; g++) {
        	ones = J(*N[g], 1, 1)
        	variance = variance + sum((*Y[g] - *Yb[g]):^2)
        	variance = variance + cross((*C[1, g] + ones):^2, *s2[g])
        	variance = variance - cross((*C[2, g] + ones),    *s2[g])
        }
        variance = (variance / *N[4] - tau^2) / *N[4]
    }
    else {
        // 11.B. Varianza del ATT:
        variance = 0
        variance = variance + sum((*Y[1] - *Yb[1]):^2)
        variance = variance + cross((*C[1, 2]):^2, *s2[2])
        variance = variance - cross((*C[2, 2]),    *s2[2])
        variance = (variance / *N[1] - tau^2) / *N[1]
    }
    return(variance)
}
end

version 13.0
mata:
void ///
function blopmatch_rmcoll(
    string scalar evar,
    string scalar xvar,
    string scalar touse
)
{
    // Create a view of (evar, xvar)
    vars = invtokens((evar, xvar), " ")
    st_view(X, ., vars, touse)

    // Find collinear columns of X
    k = max((cols(tokens(evar)), 1))
    X = cross(X, X)
    X = invsym(X, 1..k)
    c = (diagonal(X) :!= 0)

    // Update evar and xvar
    kevar = cols(tokens(evar))
    kxvar = cols(tokens(xvar))
    if (kevar > 1) {
        k0   = 2
        k1   = kevar
        evar = invtokens(select(tokens(evar), (0 \ c[k0..k1])'), " ")
        st_global("s(evar)", evar)
    }
    if (kxvar > 0) {
        k0   = kevar + 1
        k1   = kevar + kxvar
        xvar = invtokens(select(tokens(xvar), c[k0..k1]'), " ")
        st_global("s(xvar)", xvar)
    }

    // Display the variables being dropped
    vars = select(tokens(vars), 1 :- c')
    for(i = 1; i <= cols(vars); i++) {
        printf("{txt}note: %s omitted because of collinearity\n", vars[i])
    }
}
end
