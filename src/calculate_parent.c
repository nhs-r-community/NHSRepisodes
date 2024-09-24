#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

SEXP calculate_parent(SEXP start, SEXP end) {
    R_xlen_t n = XLENGTH(start);

    SEXP new_start = PROTECT(Rf_duplicate(start));
    SEXP new_end = PROTECT(Rf_duplicate(end));
    SEXP group = PROTECT(Rf_allocVector(INTSXP, n));
    SEXP vec = PROTECT(Rf_allocVector(VECSXP, 3));

    int grp = 0;
    int* p_group = INTEGER(group);
    double* p_new_end = REAL(new_end);
    double* p_new_start = REAL(new_start);

    p_group[0] = 1;
    for (R_xlen_t i = 1; i < n; ++i) {
        if (p_new_start[i] > p_new_end[i-1]) {
            // Even though very unlikely it's better to be safe than sorry
            if (grp > (INT_MAX - 1)) {
                Rf_error("The number of groups exceeds tha maximum integer value.");
            }
            ++grp;
        } else if (p_new_end[i-1] > p_new_end[i]) {
            p_new_end[i] = p_new_end[i-1];
            p_new_start[i] = p_new_start[i-1];
        } else {
            p_new_start[i] = p_new_start[i-1];
            p_new_end[i-1] = p_new_end[i];
        }
        p_group[i] = grp + 1;
    }

    SET_VECTOR_ELT(vec, 0, new_start);
    SET_VECTOR_ELT(vec, 1, new_end);
    SET_VECTOR_ELT(vec, 2, group);

    UNPROTECT(4);
    return vec;
}
