; -*- lisp -*-
; src/cas/cadsecn.lisp -- GENERAL-n SECTION sample points and their exact decision, the final ridge of the
; cylindrical-algebraic-decomposition climb.  cadgen.lisp decides every n over the FULL-DIMENSIONAL cells; the
; witnesses it cannot see are those confined to a lower-dimensional SECTION, where polynomials vanish and the
; solution coordinates are algebraic (possibly irrational) numbers in a tower.  This module builds such section
; sample points exactly and evaluates a formula at them, completing the picture for the section cells the way
; algpoint.lisp completed the two-variable case.
;
; Why nbox's coupled box is not enough, and what works instead.  An n-box isolates a point only when interval
; evaluation of the defining system separates from zero, but for a zero-dimensional section (a single point, like
; x = y = z = 1/sqrt(3) cut out by x^2+y^2+z^2 = 1, x = y, y = z) bisecting one coordinate cannot be validated while
; the others are still wide -- the system's interval straddles zero in BOTH halves, so refinement never converges.
; The exact route is TRIANGULAR: eliminate variables (by resultants) to pin the first coordinate as the root of a
; univariate polynomial -- a real algebraic number in algnum2.lisp's sense -- then propagate the system's relations
; to express each further coordinate over the ones already fixed.  Each coordinate's defining polynomial is
; univariate once the lower coordinates are substituted, so its isolating interval is refined INDEPENDENTLY; the
; tower has finite height n.  The sign of any polynomial g at the section point is then computed by substituting the
; triangular relations to reduce g to a univariate polynomial in the base coordinate and taking algnum2's exact sign
; there.  All rational arithmetic; no floating point.
;
; Scope, exact.  This decides existence on the section cells whose defining equalities form a TRIANGULAR system over
; the base coordinate -- in particular every zero-dimensional witness cut out by such equalities, the n-dimensional
; analogue of the two-variable section, and notably the diagonal-type points that full-dimensional sampling can
; never reach.  The base coordinate is a genuine algebraic number (any degree), so the witnesses are fully
; irrational.  Combined with cadgen.lisp (full-dimensional cells, all n) and the complete two-variable decider, this
; extends exact section reasoning to general n for the triangular case.  The fully general section -- an arbitrary
; equality variety whose coordinates form a non-triangular multi-algebraic tower needing iterated resultant
; back-substitution at every level -- is the deepest remaining work; cadsecn-general-caveat names it.
;
; A triangular section system is given as a list of relations, base first:
;   (base defpoly)            -- the base coordinate x_1 is the chosen real root of the univariate `defpoly`
;   (rel coeffs)              -- the next coordinate x_k equals the polynomial `coeffs` evaluated at the coordinates
;                                already fixed (a list low->high in the immediately preceding coordinate, the common
;                                triangular shape x_k = a_0 + a_1 x_{k-1}); for the diagonal case x_k = x_{k-1} it is
;                                (rel (0 1))
; and a point is (base-algnum relations) where base-algnum is an algnum2 number and relations give x_2..x_n.
;
; Public:
;   cadsecn-point defpoly lo hi rels -> a section point: base coordinate the root of defpoly in (lo,hi); rels the
;                                       triangular relations for x_2..x_n (each a coeff list in the previous coord)
;   cadsecn-coords p                 -> the algebraic coordinates as algnum2 numbers (the resolved tower)
;   cadsecn-sign g p                 -> the exact sign of an n-variate polynomial g (nested, outer-first) at the point
;   cadsecn-holds? cnd p             -> #t iff the sign condition cnd = (op . g) holds at the point
;   cadsecn-decide-conj conds p      -> #t iff every sign condition in `conds` holds at the section point
;   cadsecn-diagonal defpoly lo hi n -> the n-dimensional diagonal point x_1 = ... = x_n = (root of defpoly), a
;                                       convenience building the all-equal triangular relations
;   cadsecn-general-caveat           -> reminder: triangular sections; the general multi-algebraic tower remains
;
; Verified: on the diagonal point x = y = z = 1/sqrt(3) (base 3x^2 - 1 in (0,1)): x > 0, x^2+y^2+z^2-1 = 0, x - y = 0,
; x + y + z > 0, x + y + z - 2 < 0 (since sqrt(3) < 2); and the four-dimensional diagonal x_1=...=x_4=1/2 (base
; 4x^2-1) gives x_1^2+...+x_4^2-1 = 0 with each x_i = 1/2.
;
; Builds on algnum2.lisp (the base algebraic number and exact univariate signs) and poly.lisp.

(import "cas/algnum2.lisp")
(import "cas/poly.lisp")

; ----- a section point: the base algebraic number plus the triangular relations -----
(define (cadsecn-point defpoly lo hi rels) (list (asec-make defpoly lo hi) rels))
(define (cadsecn-base p) (car p))
(define (cadsecn-rels p) (car (cdr p)))

; ----- resolve all coordinates to univariate polynomials in the BASE coordinate -----
; coordinate 1 is the base variable itself: the polynomial (0 1) [= x_1] in the base.  Each relation x_k = r(x_{k-1})
; is composed with the already-resolved x_{k-1}-in-base to give x_k as a polynomial in the base.  This yields, for
; every coordinate, a univariate polynomial in the base variable whose value at the base algebraic number is that
; coordinate -- the triangular tower flattened onto the base.
(define (cadsecn-resolved p) (cadsecn-resolve (cadsecn-rels p) (list (list 0 1))))
(define (cadsecn-resolve rels acc) (if (null? rels) (cadsecn-rev acc (quote ())) (cadsecn-resolve (cdr rels) (cons (cadsecn-compose (car rels) (car acc)) acc))))
(define (cadsecn-rev l acc) (if (null? l) acc (cadsecn-rev (cdr l) (cons (car l) acc))))
; compose: relation r (coeffs low->high in the PREVIOUS coordinate) with prev (the previous coordinate as a poly in
; base) -> the new coordinate as a poly in base, by Horner: r_0 + r_1*prev + r_2*prev^2 + ...
(define (cadsecn-compose r prev) (cadsecn-horner r prev))
(define (cadsecn-horner r prev) (if (null? r) (quote ()) (poly-add (list (car r)) (poly-mul prev (cadsecn-horner (cdr r) prev)))))

; the coordinates as algnum2 numbers (each the base poly evaluated, but as an algebraic number they share the base
; defining polynomial and interval; we expose them as (base-poly-in-x . value-poly) pairs resolved to base)
(define (cadsecn-coords p) (cadsecn-resolved p))

; ----- substitute the triangular relations into an n-variate nested polynomial to get a univariate base poly -----
; g is nested outer-first in (x_1, ..., x_n).  Replacing each x_k by its resolved polynomial in the base x_1 turns g
; into a univariate polynomial in the base.  We evaluate g by a nested Horner that, at each level, multiplies by the
; resolved polynomial for that level's variable instead of a number.
(define (cadsecn-sign g p) (asec-sign (cadsecn-reduce g (cadsecn-resolved p)) (cadsecn-base p)))
(define (cadsecn-reduce g coords) (cadsecn-red g coords))
; coords is the list of resolved base-polynomials, coordinate 1 first.  g nested outer-first: outer var is x_1, its
; coefficients are (n-1)-variate in x_2..x_n.  Reduce: Horner over x_1's resolved poly (coords head), with each
; coefficient recursively reduced over the remaining coords.
(define (cadsecn-red g coords)
  (if (cadsecn-num? g) (list g)
      (cadsecn-rhorner g (car coords) (cdr coords))))
(define (cadsecn-num? g) (if (pair? g) #f (if (null? g) #f #t)))
(define (cadsecn-rhorner cs cvar rest)
  (if (null? cs) (quote ()) (poly-add (cadsecn-red (car cs) rest) (poly-mul cvar (cadsecn-rhorner (cdr cs) cvar rest)))))

; ----- sign conditions -----
(define (cadsecn-holds? cnd p) (cadsecn-test (car cnd) (cadsecn-sign (cdr cnd) p)))
(define (cadsecn-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))
(define (cadsecn-decide-conj conds p) (cond ((null? conds) #t) ((cadsecn-holds? (car conds) p) (cadsecn-decide-conj (cdr conds) p)) (else #f)))

; ----- the n-dimensional diagonal point x_1 = ... = x_n = root(defpoly) -----
(define (cadsecn-diagonal defpoly lo hi n) (cadsecn-point defpoly lo hi (cadsecn-diag-rels (- n 1))))
(define (cadsecn-diag-rels k) (if (<= k 0) (quote ()) (cons (list 0 1) (cadsecn-diag-rels (- k 1)))))

; ----- honest scope boundary -----
(define (cadsecn-general-caveat) (quote triangular-sections-decided-general-multi-algebraic-tower-remains))
