#include <R.h>
#include <Rinternals.h>

SEXP calculate_parent(SEXP start, SEXP end) {
    int n = length(start);
    SEXP nstart = PROTECT(coerceVector(start, REALSXP));
    SEXP nend = PROTECT(coerceVector(end, REALSXP));
    SEXP group = PROTECT(allocVector(INTSXP, n));
    SEXP vec = PROTECT(allocVector(VECSXP, 3));

    int grp = 0;
    int* pgroup = INTEGER(group);
    double* pnend = REAL(nend);
    double* pnstart = REAL(nstart);

    pgroup[0]=1;
    for (int i = 1; i < n; ++i) {
        if (pnstart[i] > pnend[i-1]) {
            ++grp;
        } else if (pnend[i-1] > pnend[i]) {
            pnend[i] = pnend[i-1];
            pnstart[i] = pnstart[i-1];
        } else {
            pnstart[i] = pnstart[i-1];
            pnend[i-1] = pnend[i];
        }
        pgroup[i] = grp + 1;
    }

    SET_VECTOR_ELT(vec, 0, nstart);
    SET_VECTOR_ELT(vec, 1, nend);
    SET_VECTOR_ELT(vec, 2, group);

    UNPROTECT(4);
    return vec;
}
