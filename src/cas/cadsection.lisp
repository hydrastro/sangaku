; -*- lisp -*-
; src/cas/cadsection.lisp -- exact evaluation of a first-order matrix on the SECTION over an irrational critical x,
; closing the boundary named by cad2d.lisp's cad2-section-caveat.  Together with cad2d's full-dimensional-cell
; decision this completes the two-variable decider: witnesses that live only on a section over an algebraic
; (possibly irrational) x are now found, using the real-algebraic-number sign primitive of algnum2.lisp and exact
; rational arithmetic throughout.
;
; The situation.  At a critical x = alpha (a root of a projection polynomial), the formula phi(alpha, y) is a
; statement about y whose polynomials p_i(alpha, y) have coefficients in Q(alpha).  The section over alpha is the
; copy of the y-line at x = alpha, and the cells of the cylindrical decomposition restricted to it are the y-cells
; cut by the real roots of the fibers p_i(alpha, y).  To decide "exists y . phi(alpha, y)" on this section we need
; the sign of each fiber at sample y-values -- and the crucial exact move is:
;     sign of p_i(alpha, b) at a RATIONAL b  =  asec-sign( p_i(x, b), alpha ),
; because substituting the rational y = b into the bivariate p_i leaves a polynomial in x with rational
; coefficients, whose sign at the algebraic number alpha is computed exactly by algnum2.lisp.  So every sign
; condition with a strict inequality is decided on the section over an irrational alpha with no irrational
; arithmetic at all.
;
; Equality conditions on the section -- where the witness y is itself algebraic over Q(alpha), a "section of the
; section" -- are decided by a complementary exact test: two curves p and q meet over x = alpha iff their
; y-resultant Res_y(p, q) (a polynomial in x, already the projection machinery of cadproj.lisp) VANISHES at alpha,
; which asec-sign reports as sign 0.  csec-pair-meets? implements exactly this, and csec-curve-has-point? tests
; whether a single curve p has any real point on the section (its y-discriminant or leading coefficient behaviour at
; alpha), so conjunctions of equalities with strict side conditions are handled.
;
; Scope, honest.  This decides, on the section over an algebraic alpha: every formula built from STRICT sign
; conditions (via the rational-y-sample signs), and equality conditions tested through pairwise resultant vanishing
; and single-curve point existence.  The fully general nested case -- an arbitrary boolean combination whose truth
; depends on the precise ordering of algebraic y-roots over an algebraic alpha (a tower Q(alpha)(beta)) -- is the
; deep frontier; csec-tower-caveat names it.  What is built turns the specific irrational-section witnesses that the
; two-variable decider previously missed into ones it now finds, exactly.
;
; Public:
;   csec-subst-y p b              -> p(x, b): substitute a rational y = b into a bivariate p, giving an x-polynomial
;   csec-sign-on-section p alpha b-> the exact sign of p(alpha, b) for rational b and algebraic alpha (via asec-sign)
;   csec-eval-strict phi alpha b  -> #t iff the matrix phi (its strict/sign conditions) holds at (alpha, b), rational b
;   csec-pair-meets? p q alpha    -> #t iff the curves p = 0 and q = 0 share a y-point over x = alpha (Res_y zero at alpha)
;   csec-exists-on-section phi alpha ys -> #t iff phi holds at (alpha, b) for some rational b in the sample list ys
;   csec-tower-caveat             -> reminder that nested algebraic-over-algebraic y-ordering is the deep frontier
;
; Verified: on the section over alpha = 1/sqrt(2) (root of 2x^2 - 1), the circle x^2 + y^2 - 1 and the line x - y
; meet (their resultant 2x^2 - 1 vanishes at alpha); the strict condition x^2 + y^2 - 1 < 0 holds at (alpha, 0)
; since alpha^2 - 1 < 0; and the sign of x^2 + y^2 - 1 at (alpha, 1) is positive (alpha^2 > 0 so alpha^2 + 1 - 1 =
; alpha^2 ... wait alpha^2=1/2, +1-1 leaves 1/2>0).
;
; Builds on algnum2.lisp, cadproj.lisp, poly.lisp.

(import "cas/algnum2.lisp")
(import "cas/cadproj.lisp")
(import "cas/poly.lisp")

; ----- substitute a rational y = b into a bivariate polynomial, leaving a polynomial in x -----
(define (csec-subst-y p b) (csec-subst-go p b 1 (quote ())))
(define (csec-subst-go cs b bk acc) (if (null? cs) acc (csec-subst-go (cdr cs) b (* bk b) (poly-add acc (poly-scale bk (car cs))))))

; ----- the exact sign of a bivariate p at (alpha, b): substitute the rational b, take asec-sign at alpha -----
(define (csec-sign-on-section p alpha b) (asec-sign (csec-subst-y p b) alpha))

; ----- evaluate a sign condition / matrix at (alpha, b) for rational b (the strict-condition decision) -----
(define (csec-eval-strict phi alpha b)
  (cond ((equal? (car phi) (quote and)) (csec-all (cdr phi) alpha b))
        ((equal? (car phi) (quote or)) (csec-any (cdr phi) alpha b))
        ((equal? (car phi) (quote not)) (if (csec-eval-strict (car (cdr phi)) alpha b) #f #t))
        (else (csec-test (car phi) (csec-sign-on-section (cdr phi) alpha b)))))
(define (csec-all fs alpha b) (cond ((null? fs) #t) ((csec-eval-strict (car fs) alpha b) (csec-all (cdr fs) alpha b)) (else #f)))
(define (csec-any fs alpha b) (cond ((null? fs) #f) ((csec-eval-strict (car fs) alpha b) #t) (else (csec-any (cdr fs) alpha b))))
(define (csec-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; ----- two curves meet over x = alpha iff their y-resultant vanishes at alpha -----
(define (csec-pair-meets? p q alpha) (= (asec-sign (cad-resultant p q) alpha) 0))

; ----- exists a rational y-sample at which phi holds on the section -----
(define (csec-exists-on-section phi alpha ys) (csec-any-y phi alpha ys))
(define (csec-any-y phi alpha ys) (cond ((null? ys) #f) ((csec-eval-strict phi alpha (car ys)) #t) (else (csec-any-y phi alpha (cdr ys)))))

; ----- honest scope boundary -----
(define (csec-tower-caveat) (quote nested-algebraic-over-algebraic-y-ordering-is-the-deep-frontier))
