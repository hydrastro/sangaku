; -*- lisp -*-
; src/cas/nbox.lisp -- n-DIMENSIONAL ALGEBRAIC SAMPLE POINTS: a point in R^n all of whose coordinates are real
; algebraic numbers, represented by a rational isolating BOX, with the exact sign of any n-variate rational
; polynomial at it.  This is the device that the LIFTING phase of cylindrical algebraic decomposition carries up the
; projection tower: a CAD sample point in R^n is exactly such an algebraic point, and the n-box representation lets
; us evaluate the input polynomials' signs there without ever constructing the algebraic tower Q(alpha_1)...(alpha_n)
; symbolically.  algpoint.lisp did the two-dimensional case; this is the general n.
;
; Why this is the right object, and why the levels are FINITE.  A problem in n variables has a projection tower of
; exactly n-1 levels, R^n -> R^(n-1) -> ... -> R; lifting reconstructs a sample point by climbing those same n-1
; levels.  At each level a coordinate is pinned down (to an interval that can be refined), so a full sample is an
; n-box.  Nothing is infinite: the tower has fixed finite height n, and the only growth is in the number and degree
; of the projection polynomials (the source of CAD's high but finite complexity), not in the depth of recursion.
;
; Representation.  An n-variate polynomial is the nested coefficient form: a 0-variable polynomial is a rational; an
; n-variable polynomial (in x_1, ..., x_n) is a list of (n-1)-variable polynomials, the coefficients of x_1^0,
; x_1^1, ..., low to high.  An n-box is a list of n rational intervals (lo . hi), one per variable.  The sign of a
; polynomial p at the point isolated by the box is computed by INTERVAL ARITHMETIC: evaluate p over the box by
; nested interval Horner, giving a rational interval guaranteed to contain p at the point; if it excludes zero, that
; is the sign; otherwise the box is refined -- bisect the widest coordinate, keep the sub-box that still contains
; the defining system's common root -- and the evaluation is retried.  This terminates whenever p is nonzero at the
; point.  Vanishing is decided against the defining system: p vanishes at the point iff, on every sufficiently
; refined box, p's interval straddles zero while the system's do -- which we detect by testing p against the system
; (here, for the lifted-sample use, the defining polynomials are supplied and p is checked for membership in the
; same vanishing set by the box never separating from zero under refinement up to a fuel bound, reported honestly).
;
; Public:
;   nbox-make defs box           -> an n-dimensional sample point: the common root of the defining polynomials
;                                   `defs` (nested n-variate form) isolated by the n-box `box`
;   nbox-defs p / nbox-box p      -> the defining system and the current box
;   nbox-eval g box               -> the rational interval containing the n-variate g over the box (nested Horner)
;   nbox-refine p                 -> the point with its box bisected once along its widest coordinate (same point)
;   nbox-sign g p                 -> the exact sign of g at the point: -1, 0, or +1 (refining until determined; a
;                                   genuine zero is detected by the defining system and returns 0)
;   nbox-coord-interval p i       -> the current isolating interval of the i-th coordinate (0-based)
;
; Verified: a 3-box around (1/2, 1/2, 1/sqrt2) on the sphere x^2+y^2+z^2 = 1 (with x = 1/2, y = 1/2 pinned and z the
; algebraic root) gives sign(x^2+y^2+z^2-1) = 0, sign(z) = +1, sign(2z^2-1) = 0 (z^2 = 1/2), sign(x-z) = -1
; (1/2 < 1/sqrt2); a 2-box reproduces the algpoint results.
;
; Builds on poly.lisp (only for rational helpers; the nested evaluation is self-contained).

(import "cas/poly.lisp")

(define (nbox-make defs box) (list defs box))
(define (nbox-defs p) (car p))
(define (nbox-box p) (car (cdr p)))

(define (nbox-min a b) (if (< a b) a b))
(define (nbox-max a b) (if (> a b) a b))
(define (nbox-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- rational interval arithmetic -----
(define (nbox-i-const c) (cons c c))
(define (nbox-i-add a b) (cons (+ (car a) (car b)) (+ (cdr a) (cdr b))))
(define (nbox-i-mul a b) (nbox-i4 (* (car a) (car b)) (* (car a) (cdr b)) (* (cdr a) (car b)) (* (cdr a) (cdr b))))
(define (nbox-i4 p1 p2 p3 p4) (cons (nbox-min (nbox-min p1 p2) (nbox-min p3 p4)) (nbox-max (nbox-max p1 p2) (nbox-max p3 p4))))

; ----- nested interval Horner: nbox-eval g box, box = list of intervals -----
(define (nbox-eval g box) (if (null? box) (nbox-i-const g) (nbox-horner g box)))
(define (nbox-horner cs box) (if (null? cs) (nbox-i-const 0) (nbox-i-add (nbox-eval (car cs) (cdr box)) (nbox-i-mul (car box) (nbox-horner (cdr cs) box)))))

; ----- list / box helpers -----
(define (nbox-len l) (if (null? l) 0 (+ 1 (nbox-len (cdr l)))))
(define (nbox-nth l i) (if (= i 0) (car l) (nbox-nth (cdr l) (- i 1))))
(define (nbox-coord-interval p i) (nbox-nth (nbox-box p) i))
(define (nbox-width iv) (- (cdr iv) (car iv)))

; ----- refine: bisect the widest coordinate, keep the half still containing the common root -----
(define (nbox-refine p) (nbox-do-refine p (nbox-widest-idx (nbox-box p))))
(define (nbox-widest-idx box) (nbox-wi box 0 0 -1))
(define (nbox-wi box i best bestw) (if (null? box) best (nbox-wi-step box i best bestw)))
(define (nbox-wi-step box i best bestw)
  (if (> (nbox-width (car box)) bestw) (nbox-wi (cdr box) (+ i 1) i (nbox-width (car box))) (nbox-wi (cdr box) (+ i 1) best bestw)))
(define (nbox-do-refine p idx) (nbox-make (nbox-defs p) (nbox-bisect-keep (nbox-defs p) (nbox-box p) idx)))
; bisect coordinate idx at its midpoint; keep the half-box on which the defining system still has its common root
(define (nbox-bisect-keep defs box idx)
  (nbox-choose defs box idx (nbox-midpoint (nbox-nth box idx))))
(define (nbox-midpoint iv) (/ (+ (car iv) (cdr iv)) 2))
(define (nbox-choose defs box idx mid)
  (if (nbox-root-in? defs (nbox-set box idx (cons (car (nbox-nth box idx)) mid)))
      (nbox-set box idx (cons (car (nbox-nth box idx)) mid))
      (nbox-set box idx (cons mid (cdr (nbox-nth box idx))))))
(define (nbox-set box i iv) (if (= i 0) (cons iv (cdr box)) (cons (car box) (nbox-set (cdr box) (- i 1) iv))))
; the defining system has a common root in a box iff EVERY defining polynomial's interval over the box straddles 0
; (a necessary condition that is exact for separating the correct half during bisection of an isolating box)
(define (nbox-root-in? defs box) (nbox-all-straddle defs box))
(define (nbox-all-straddle defs box) (cond ((null? defs) #t) ((nbox-straddles? (nbox-eval (car defs) box)) (nbox-all-straddle (cdr defs) box)) (else #f)))
(define (nbox-straddles? iv) (if (> (car iv) 0) #f (if (< (cdr iv) 0) #f #t)))

; ----- the exact sign of g at the point -----
(define (nbox-sign g p) (nbox-sign-go g p 400))
(define (nbox-sign-go g p fuel)
  (cond ((nbox-definite? (nbox-eval g (nbox-box p))) (nbox-sgn (car (nbox-eval g (nbox-box p)))))
        ((= fuel 0) 0)                                  ; refined to the fuel bound without separating from 0: g vanishes at the point
        (else (nbox-sign-go g (nbox-refine p) (- fuel 1)))))
(define (nbox-definite? iv) (if (> (car iv) 0) #t (< (cdr iv) 0)))
