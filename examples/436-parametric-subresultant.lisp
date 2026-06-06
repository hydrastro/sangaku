; The PARAMETRIC subresultant tower (docs/CAS.md): the multivariate lift of the subresultant chain, computing
; principal subresultant coefficients whose entries are POLYNOMIALS IN A PARAMETER rather than rational constants --
; exactly what the CAD projection consumes at each elimination level.  The polynomials being projected are in the
; main variable x with coefficients that are polynomials in the remaining variables; the psc tower of two such
; polynomials is a set of polynomials in those remaining variables whose VANISHING defines the cell boundaries one
; level down.  subresultant.lisp built and verified the univariate-over-Q core; this lifts the identical recurrence
; to coefficients in Q[t] (the single-parameter case, the workhorse of a projection step), with the exact division
; over Q[t] that the subresultant theory guarantees.
(import "cas/psubres.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
; evaluate a Q[t] polynomial (low->high) at t = v
(define (peval p v) (if (null? p) 0 (+ (car p) (* v (peval (cdr p) v)))))

(display "The subresultant tower with parametric coefficients -- the projection's actual input.") (newline) (newline)

; the parabola x^2 - a and the line x - 1: representation is low->high in x, each coefficient a poly in a (low->high)
(define parab (list (list 0 -1) (quote ()) (list 1)))   ; x^2 - a
(define line  (list (list -1) (list 1)))                ; x - 1
(define two-x (list (quote ()) (list 2)))               ; 2x = derivative of x^2 - a

; the parametric resultant is a polynomial in the parameter
(must "Res_x(x^2 - a, x - 1) is a nonempty polynomial in a"
  (> (length (psubres-resultant parab line)) 0))

; its VANISHING LOCUS is exactly the parameter values where the specialisations share a root
(must "Res_x(x^2 - a, x - 1) vanishes at a = 1 (where x = 1 lies on the parabola)"
  (= (peval (psubres-resultant parab line) 1) 0))
(must "Res_x(x^2 - a, x - 1) is nonzero at a = 2 (no shared root)"
  (not (= (peval (psubres-resultant parab line) 2) 0)))
(must "Res_x(x^2 - a, x - 1) is nonzero at a = 0"
  (not (= (peval (psubres-resultant parab line) 0) 0)))

; the discriminant-like resultant with the derivative marks the double-root parameter
(must "Res_x(x^2 - a, 2x) vanishes at a = 0 (where the parabola acquires a double root)"
  (= (peval (psubres-resultant parab two-x) 0) 0))
(must "Res_x(x^2 - a, 2x) is nonzero at a = 5"
  (not (= (peval (psubres-resultant parab two-x) 5) 0)))

; two parabolas x^2 - a and x^2 - 1 share a root exactly at a = 1
(define parab1 (list (list -1) (quote ()) (list 1)))    ; x^2 - 1
(must "Res_x(x^2 - a, x^2 - 1) vanishes at a = 1 and not at a = 3"
  (and (= (peval (psubres-resultant parab parab1) 1) 0) (not (= (peval (psubres-resultant parab parab1) 3) 0))))

; the generic gcd degree over Q(a) distinguishes coprime from identical
(must "gcd-degree(x^2 - a, 2x) is 0 generically (coprime over Q(a))"
  (= (psubres-gcd-degree parab two-x) 0))
(must "gcd-degree(x^2 - a, x^2 - a) is 2 (identical)"
  (= (psubres-gcd-degree parab parab) 2))

(newline)
(display "The parametric resultant's vanishing locus is exactly the parameter values at which the fiber structure") (newline)
(display "changes -- the cell-boundary information a projection step produces, now as polynomials in the parameter") (newline)
(display "rather than constants.  This lifts the subresultant tower from the univariate core to the multivariate") (newline)
(display "setting the CAD projection needs (psubres-caveat: single-parameter Q[t], the projection-step workhorse).") (newline)
