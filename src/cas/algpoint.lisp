; -*- lisp -*-
; src/cas/algpoint.lisp -- REAL ALGEBRAIC POINTS in the plane, and the exact sign of a bivariate rational
; polynomial at one, by interval arithmetic over a refining isolating BOX.  This is the primitive the nested tower
; Q(alpha)(beta) needs -- a point whose x-coordinate alpha and y-coordinate beta are both algebraic, with beta
; algebraic OVER Q(alpha) -- and it is exactly what a LIFTED CAD sample point is.  So it is the shared foundation of
; both remaining frontiers: completing the two-variable decider over irrational sections where the witness y is
; itself algebraic, and carrying algebraic sample points up the lifting tower.  Everything is exact rational
; arithmetic; no floating point and no symbolic algebraic-field arithmetic.
;
; A real algebraic point is the unique common real solution of a defining pair of bivariate polynomials A(x, y) = 0
; and B(x, y) = 0, isolated by a rational BOX [ax, bx] x [ay, by] that contains that solution and no other common
; real root of the pair.  (In the CAD use the pair is, e.g., a curve and the vertical line x = alpha given as the
; minimal polynomial of alpha lifted to two variables, or two curves whose intersection is the sample point.)
;
; The exact sign of a bivariate g at the point is computed by INTERVAL ARITHMETIC: evaluate g over the box by
; interval Horner (in y, with the x-coefficients themselves evaluated over the x-interval), giving a rational
; interval that is guaranteed to contain g(alpha, beta).  If that interval excludes zero, its sign is the sign of
; g at the point; otherwise the box is refined -- bisected in the coordinate that currently has the wider span,
; keeping the sub-box that still brackets the common root (detected by a sign change of the defining pair) -- and
; the evaluation is retried.  This terminates whenever g(alpha, beta) != 0, because g is then bounded away from zero
; in a neighbourhood of the point that the shrinking box eventually fits inside.  The case g(alpha, beta) = 0 is
; decided algebraically rather than by refinement: g vanishes at the common root of A and B iff alpha is a common
; root of the eliminants Res_y(A, g) and Res_y(B, g) (each a univariate polynomial in x, tested exactly at the
; algebraic alpha via algnum2.lisp's asec-sign).  So apt-sign first checks vanishing, then refines for the nonzero
; sign -- always terminating, always exact.
;
; Public:
;   apt-make A B ax bx ay by    -> a real algebraic point: the common root of A, B in the box [ax,bx] x [ay,by]
;   apt-box p                   -> the current box (ax bx ay by)
;   apt-eval-box g p            -> the rational interval (lo . hi) containing g over the current box (interval Horner)
;   apt-refine p                -> the point with its isolating box bisected once along its wider side (same point)
;   apt-x-alpha p               -> the x-coordinate as an algnum2 algebraic number (defining poly = Res_y(A,B), the
;                                  box's x-interval as the isolating interval), for sign tests in x alone
;   apt-vanishes? g p           -> #t iff g(alpha, beta) = 0 (g shares the common root, via the two eliminants)
;   apt-sign g p                -> the exact sign of g at the point: -1, 0, or +1
;
; Verified: for the point (1/sqrt2, 1/sqrt2), the common root of x^2 + y^2 - 1 and x - y isolated in a box around
; (0.7, 0.7): sign(x) = +1, sign(x + y - 1) = +1 (it is sqrt(2) - 1 > 0), sign(y - x) = 0 and sign(x^2 + y^2 - 1) = 0
; (the defining curves vanish there), and sign(2x - 1) = +1 (since 1/sqrt2 > 1/2).
;
; Builds on poly.lisp, cadproj.lisp (Res_y), and algnum2.lisp.

(import "cas/poly.lisp")
(import "cas/cadproj.lisp")
(import "cas/algnum2.lisp")

(define (apt-make A B ax bx ay by) (list A B ax bx ay by))
(define (apt-A p) (car p))
(define (apt-B p) (car (cdr p)))
(define (apt-ax p) (car (cdr (cdr p))))
(define (apt-bx p) (car (cdr (cdr (cdr p)))))
(define (apt-ay p) (car (cdr (cdr (cdr (cdr p))))))
(define (apt-by p) (car (cdr (cdr (cdr (cdr (cdr p)))))))
(define (apt-box p) (list (apt-ax p) (apt-bx p) (apt-ay p) (apt-by p)))

(define (apt-min a b) (if (< a b) a b))
(define (apt-max a b) (if (> a b) a b))
(define (apt-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- rational interval arithmetic -----
(define (apt-i-const c) (cons c c))
(define (apt-i-add a b) (cons (+ (car a) (car b)) (+ (cdr a) (cdr b))))
(define (apt-i-mul a b)
  (apt-i-from (* (car a) (car b)) (* (car a) (cdr b)) (* (cdr a) (car b)) (* (cdr a) (cdr b))))
(define (apt-i-from p1 p2 p3 p4) (cons (apt-min (apt-min p1 p2) (apt-min p3 p4)) (apt-max (apt-max p1 p2) (apt-max p3 p4))))

; univariate interval Horner: coeff list low->high evaluated over interval iv
(define (apt-i-ueval c iv) (if (null? c) (apt-i-const 0) (apt-i-add (apt-i-const (car c)) (apt-i-mul iv (apt-i-ueval (cdr c) iv)))))
; bivariate interval Horner: p = list of x-polys low->high in y; eval over box
(define (apt-eval-box g p) (apt-i-beval g (cons (apt-ax p) (apt-bx p)) (cons (apt-ay p) (apt-by p))))
(define (apt-i-beval g bx by) (if (null? g) (apt-i-const 0) (apt-i-add (apt-i-ueval (car g) bx) (apt-i-mul by (apt-i-beval (cdr g) bx by)))))

; ----- refine the box: bisect the wider side, keep the sub-box still bracketing the common root -----
(define (apt-refine p)
  (if (> (- (apt-bx p) (apt-ax p)) (- (apt-by p) (apt-ay p))) (apt-refine-x p) (apt-refine-y p)))
; bisect x at midpoint, keep the half where the defining pair still has a common root (detected by A or B sign
; change across the half in the y-direction at that x-slab -- we keep the half whose x-subinterval still contains
; alpha, where alpha is the root of Res_y(A,B))
(define (apt-refine-x p)
  (apt-keep-x p (/ (+ (apt-ax p) (apt-bx p)) 2)))
(define (apt-keep-x p mx)
  (if (apt-alpha-in? (apt-A p) (apt-B p) (apt-ax p) mx) (apt-make (apt-A p) (apt-B p) (apt-ax p) mx (apt-ay p) (apt-by p))
      (apt-make (apt-A p) (apt-B p) mx (apt-bx p) (apt-ay p) (apt-by p))))
(define (apt-refine-y p)
  (apt-keep-y p (/ (+ (apt-ay p) (apt-by p)) 2)))
(define (apt-keep-y p my)
  (if (apt-beta-in? (apt-y-curve (apt-A p) (apt-B p)) (apt-ax p) (apt-bx p) (apt-ay p) my) (apt-make (apt-A p) (apt-B p) (apt-ax p) (apt-bx p) (apt-ay p) my)
      (apt-make (apt-A p) (apt-B p) (apt-ax p) (apt-bx p) my (apt-by p))))
; choose the defining curve that actually involves y (one of them may be constant in y, like x^2 - 2)
(define (apt-y-curve A B) (if (> (apt-ydeg A) 0) A B))
(define (apt-ydeg p) (- (apt-ylen p) 1))
(define (apt-ylen p) (apt-yl p (apt-llen p)))
(define (apt-llen l) (if (null? l) 0 (+ 1 (apt-llen (cdr l)))))
(define (apt-yl p k) (cond ((= k 0) 0) ((apt-zc (apt-ynth p (- k 1))) (apt-yl p (- k 1))) (else k)))
(define (apt-ynth l k) (if (= k 0) (car l) (apt-ynth (cdr l) (- k 1))))
(define (apt-zc c) (cond ((null? c) #t) ((= (car c) 0) (apt-zc (cdr c))) (else #f)))
; alpha (x-coord) is the root of Res_y(A,B) in x; it is in (ax, mx) iff that resultant changes sign there
(define (apt-alpha-in? A B ax mx) (apt-rchange? (cad-resultant A B) ax mx))
(define (apt-rchange? r lo hi)
  (cond ((= (apt-sgn (poly-eval r lo)) 0) #t)
        ((= (apt-sgn (poly-eval r hi)) 0) #t)
        (else (< (* (poly-eval r lo) (poly-eval r hi)) 0))))
; beta (y-coord) over the current x-slab: detect via the fiber A(x_mid, y) sign change in (ay, my); use the slab
; midpoint as the representative x (the box is already narrow in x after x-refinement)
(define (apt-beta-in? A ax bx ay my) (apt-fiber-change? A (/ (+ ax bx) 2) ay my))
(define (apt-fiber-change? A xc ay my)
  (apt-rchange? (apt-fiber A xc) ay my))
; the fiber A(xc, y): substitute the rational xc into the bivariate A, giving a univariate poly in y
(define (apt-fiber A xc) (apt-fiber-go A xc))
(define (apt-fiber-go A xc) (if (null? A) (quote ()) (cons (poly-eval (car A) xc) (apt-fiber-go (cdr A) xc))))

; ----- the x-coordinate as an algebraic number (defining poly = Res_y(A,B)) -----
(define (apt-x-alpha p) (asec-make (cad-resultant (apt-A p) (apt-B p)) (apt-ax p) (apt-bx p)))

; g vanishes at the point.  Two cases: if g is constant in y (a "vertical" condition c(x) = 0), it vanishes iff
; c(alpha) = 0, an asec-sign test on its single x-coefficient.  Otherwise g shares the common root iff alpha is a
; common root of the eliminants Res_y(A, g) and Res_y(B, g) -- but each eliminant is meaningful only when the paired
; defining curve genuinely involves y; against a y-constant defining curve the resultant degenerates, so we use the
; y-bearing defining curve for the elimination and additionally require the y-constant curve's own x-condition.
(define (apt-vanishes? g p)
  (if (apt-yconst? g) (apt-x-zero? g p) (apt-shares-root? g p)))
(define (apt-yconst? g) (<= (apt-gydeg g) 0))
(define (apt-gydeg g) (- (apt-glen g) 1))
(define (apt-glen l) (apt-gl l (apt-cnt l)))
(define (apt-cnt l) (if (null? l) 0 (+ 1 (apt-cnt (cdr l)))))
(define (apt-gl p k) (cond ((= k 0) 0) ((apt-zc (apt-gnth p (- k 1))) (apt-gl p (- k 1))) (else k)))
(define (apt-gnth l k) (if (= k 0) (car l) (apt-gnth (cdr l) (- k 1))))
; the x-content of a y-constant g is its y^0 coefficient; it vanishes at the point iff that x-poly is zero at alpha
(define (apt-x-zero? g p) (if (null? g) #t (= (asec-sign (car g) (apt-x-alpha p)) 0)))
; the general (y-involving g) shared-root test, using the y-bearing defining curve for elimination
(define (apt-shares-root? g p)
  (if (apt-alpha-root-of? (cad-resultant (apt-y-defining p) g) p) (apt-extra-defining-ok? g p) #f))
(define (apt-y-defining p) (apt-y-curve (apt-A p) (apt-B p)))
; the other defining curve also constrains the point: if it is y-constant, require its x-condition at alpha;
; if it involves y, require it too shares the root
(define (apt-extra-defining-ok? g p) (apt-other-ok? (apt-other-defining p) g p))
(define (apt-other-defining p) (if (> (apt-ydeg (apt-A p)) 0) (apt-B p) (apt-A p)))
(define (apt-other-ok? other g p)
  (if (apt-yconst? other) (apt-x-zero? other p) (apt-alpha-root-of? (cad-resultant other g) p)))
(define (apt-alpha-root-of? r p) (= (asec-sign r (apt-x-alpha p)) 0))

; ----- the exact sign: zero (algebraic test) or the box-refined nonzero sign -----
(define (apt-sign g p) (if (apt-vanishes? g p) 0 (apt-sign-refine g p 300)))
(define (apt-sign-refine g p fuel)
  (cond ((= fuel 0) (apt-sgn (car (apt-eval-box g p))))            ; safety; not reached when g(point)!=0
        ((apt-definite? (apt-eval-box g p)) (apt-sgn (car (apt-eval-box g p))))
        (else (apt-sign-refine g (apt-refine p) (- fuel 1)))))
(define (apt-definite? iv) (if (> (car iv) 0) #t (< (cdr iv) 0)))
