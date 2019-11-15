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
    k = max((ustrwordcount(evar), 1))
    X = cross(X, X)
    X = invsym(X, 1..k)
    c = (diagonal(X) :!= 0)

    // Update evar and xvar
    kevar = ustrwordcount(evar)
    kxvar = ustrwordcount(xvar)
    if (kevar > 0) {
        k0   = 1
        k1   = kevar
        evar = invtokens(select(tokens(evar), c[k0..k1]'), " ")
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
