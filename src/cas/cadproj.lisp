; -*- lisp -*-
; src/cas/cadproj.lisp -- the CAD PROJECTION primitive: bivariate resultants and discriminants that eliminate one
; variable, producing the univariate "projection polynomials" whose real roots mark every x at which the structure
; of the y-fibers can change.  This is the heart of cylindrical algebraic decomposition -- the projection phase that
; reduces a two-variable problem to the one-variable real-QE base already in place (realqe.lisp) -- and so the first
; genuine rung of the climb from univariate to MULTIVARIATE real quantifier elimination (the open frontier).
;
; A bivariate polynomial p(x, y) is represented as a polynomial in y whose coefficients are polynomials in x: a
; list of x-coefficient-polynomials, LOW-to-HIGH in y.  For example y^2 - x is (((0 -1)) for the y^0 coefficient -x,
; () for y^1, (1) for y^2) -> ((0 -1) () (1)).  Each x-coefficient is an ordinary coefficient list (low->high in x).
;
; The projection works through the Sylvester matrix over the ring Q[x]: for p of y-degree m and q of y-degree n the
; Sylvester matrix is (m+n) x (m+n) with polynomial entries, and its determinant -- computed by exact cofactor
; expansion with polynomial addition and multiplication, no division -- is the resultant Res_y(p, q), a polynomial in
; x.  Res_y(p, q)(a) = 0 exactly when p(a, y) and q(a, y) share a common y-root (or both drop degree), so the real
; roots of Res_y(p, q) are precisely the x-values where two curves meet or a curve is tangent to the elimination
; direction.  The DISCRIMINANT disc_y(p) = Res_y(p, dp/dy) (up to the leading coefficient) vanishes at the x where
; p(x, y) has a repeated y-root -- where the number of real y-roots of the fiber can change.  Together with the
; leading y-coefficients, these are the McCallum/Collins projection factors: the union of their real roots cuts the
; x-axis into intervals over which the fiber structure of the given curves is constant -- exactly the cells a
; cylindrical decomposition lifts.
;
; This module supplies the projection primitive exactly over Q.  It does NOT yet perform the full lifting phase
; (building sample points in the (x, y) plane over each x-cell and assembling the two-dimensional decomposition);
; that lifting, and the recursion to n variables, is the remaining frontier, and cad-lifting-caveat names it rather
; than overstating what is built.  What is built is exact and is the indispensable first half: the projection set.
;
; Public:
;   cad-bivar-deg p             -> the degree of p in y (the number of y-coefficients minus one)
;   cad-resultant p q           -> Res_y(p, q): the resultant eliminating y, a polynomial in x (coeff list low->high)
;   cad-discriminant p          -> disc_y(p) = Res_y(p, dp/dy): the y-discriminant, a polynomial in x
;   cad-dy p                    -> dp/dy as a bivariate polynomial (the y-derivative), for inspection
;   cad-projection (p_1 ... p_k)-> the PROJECTION SET: the list of univariate x-polynomials whose roots mark every
;                                  x where the fiber structure changes -- each curve's y-discriminant and each pair's
;                                  resultant (the Collins projection of the family)
;   cad-projection-roots ps     -> the real-root count of the product of the projection set (the number of distinct
;                                  critical x-values, via Sturm) -- a summary of how finely the x-axis is cut
;   cad-lifting-caveat          -> a reminder that this is the projection phase; lifting and the n-variable recursion
;                                  remain the frontier
;
; Verified: Res_y(y^2 - x, y - x) = x^2 - x (the parabola meets the line where x = 0 or x = 1); disc_y(y^2 - x) = x
; (a multiple of it; the parabola's fiber degenerates at x = 0); Res_y(y^2 + x^2 - 1, y) = x^2 - 1 (the circle meets
; the x-axis at x = +-1); the projection of {y^2 + x^2 - 1} has its critical x at +-1.
;
; Builds on poly.lisp and sturm.lisp.

(import "cas/poly.lisp")
(import "cas/sturm.lisp")

; ----- bivariate basics: p is a list of x-polys, low->high in y -----
(define (cad-len l) (if (null? l) 0 (+ 1 (cad-len (cdr l)))))
(define (cad-bivar-deg p) (- (cad-trim-y-len p) 1))
; trim trailing all-zero y-coefficients so the y-degree is honest
(define (cad-trim-y-len p) (cad-tyl-go p (cad-len p)))
(define (cad-tyl-go p k) (cond ((= k 0) 0) ((cad-zero-poly? (cad-ynth p (- k 1))) (cad-tyl-go p (- k 1))) (else k)))
(define (cad-ynth p k) (if (= k 0) (car p) (cad-ynth (cdr p) (- k 1))))
(define (cad-zero-poly? c) (cad-allz c))
(define (cad-allz c) (cond ((null? c) #t) ((= (car c) 0) (cad-allz (cdr c))) (else #f)))

; ----- the y-derivative dp/dy: coefficient of y^k becomes k * (coeff of y^k), shifted down -----
(define (cad-dy p) (cad-dy-go (cdr p) 1))     ; drop y^0; coefficient of y^k (k>=1) scaled by k
(define (cad-dy-go cs k) (if (null? cs) (quote ()) (cons (poly-scale k (car cs)) (cad-dy-go (cdr cs) (+ k 1)))))

; ----- the Sylvester matrix over Q[x], with polynomial entries, then its determinant by cofactor expansion -----
; p, q given low->high in y; for the Sylvester matrix we use high->low rows. Build m+n rows for deg(q)=n shifts of p
; and deg(p)=m shifts of q.
(define (cad-resultant p q) (cad-res (cad-clip p) (cad-clip q)))
(define (cad-clip p) (cad-take p (cad-trim-y-len p)))
(define (cad-take l k) (if (= k 0) (quote ()) (cons (car l) (cad-take (cdr l) (- k 1)))))
(define (cad-res p q)
  (cond ((< (cad-bivar-deg p) 0) (quote ()))
        ((< (cad-bivar-deg q) 0) (quote ()))
        ((= (cad-bivar-deg p) 0) (cad-pow (car p) (cad-bivar-deg q)))   ; res(const_in_y, q) = const^deg q
        ((= (cad-bivar-deg q) 0) (cad-pow (car q) (cad-bivar-deg p)))
        (else (cad-det (cad-sylvester p q)))))
(define (cad-pow c e) (if (<= e 0) (list 1) (poly-mul c (cad-pow c (- e 1)))))

; coefficients high->low in y (reverse of the low->high storage)
(define (cad-hi-coeffs p) (cad-reverse (cad-clip p) (quote ())))
(define (cad-reverse l acc) (if (null? l) acc (cad-reverse (cdr l) (cons (car l) acc))))

; Sylvester matrix: n rows from p, m rows from q, each a length-(m+n) list of x-polys
(define (cad-sylvester p q)
  (cad-append (cad-shift-rows (cad-hi-coeffs p) (cad-bivar-deg q) (+ (cad-bivar-deg p) (cad-bivar-deg q)))
              (cad-shift-rows (cad-hi-coeffs q) (cad-bivar-deg p) (+ (cad-bivar-deg p) (cad-bivar-deg q)))))
(define (cad-append a b) (if (null? a) b (cons (car a) (cad-append (cdr a) b))))
; produce `count` rows, each the coefficient list placed with i leading zero-polys then the coeffs then trailing zeros to width
(define (cad-shift-rows coeffs count width) (cad-sr-go coeffs count width 0))
(define (cad-sr-go coeffs count width i)
  (if (= i count) (quote ())
      (cons (cad-row coeffs width i) (cad-sr-go coeffs count width (+ i 1)))))
(define (cad-row coeffs width i)
  (cad-pad-front i (cad-pad-back coeffs (- width (+ i (cad-len coeffs))))))
(define (cad-pad-front k row) (if (= k 0) row (cons (quote ()) (cad-pad-front (- k 1) row))))
(define (cad-pad-back row k) (if (= k 0) row (cad-append row (cad-zeros k))))
(define (cad-zeros k) (if (= k 0) (quote ()) (cons (quote ()) (cad-zeros (- k 1)))))

; ----- determinant of a matrix of x-polys, by cofactor expansion along the first row (exact, no division) -----
(define (cad-det m) (if (= (cad-len m) 1) (car (car m)) (cad-det-go m 0 (list 1) (quote ()))))
; sum over first-row columns j of (-1)^j * m[0][j] * det(minor_0j)
(define (cad-det-go m j sign acc) (if (= j (cad-len m)) acc (cad-det-cont m j sign acc)))
(define (cad-det-cont m j sign acc)
  (cad-det-go m (+ j 1) (poly-scale -1 sign)
              (poly-add acc (poly-mul sign (poly-mul (cad-mget m 0 j) (cad-det (cad-minor m 0 j)))))))
(define (cad-mget m i j) (cad-ynth (cad-ynth m i) j))
; minor with row i and column j removed
(define (cad-minor m i j) (cad-drop-col (cad-drop-row m i) j))
(define (cad-drop-row m i) (cad-dr-go m i 0))
(define (cad-dr-go m i k) (cond ((null? m) (quote ())) ((= k i) (cdr m)) (else (cons (car m) (cad-dr-go (cdr m) i (+ k 1))))))
(define (cad-drop-col m j) (if (null? m) (quote ()) (cons (cad-drop-at (car m) j) (cad-drop-col (cdr m) j))))
(define (cad-drop-at row j) (cad-da-go row j 0))
(define (cad-da-go row j k) (cond ((null? row) (quote ())) ((= k j) (cdr row)) (else (cons (car row) (cad-da-go (cdr row) j (+ k 1))))))

; ----- the y-discriminant disc_y(p) = Res_y(p, dp/dy) -----
(define (cad-discriminant p) (cad-resultant p (cad-dy p)))

; ----- the projection set of a family: each curve's discriminant and each pair's resultant -----
(define (cad-projection ps) (cad-append (cad-discs ps) (cad-pair-res ps)))
(define (cad-discs ps) (if (null? ps) (quote ()) (cons (cad-discriminant (car ps)) (cad-discs (cdr ps)))))
(define (cad-pair-res ps) (if (null? ps) (quote ()) (cad-append (cad-pairs-with (car ps) (cdr ps)) (cad-pair-res (cdr ps)))))
(define (cad-pairs-with p rest) (if (null? rest) (quote ()) (cons (cad-resultant p (car rest)) (cad-pairs-with p (cdr rest)))))

; ----- a summary: how many distinct critical x-values the projection produces (Sturm root count of the product) -----
(define (cad-projection-roots ps) (num-real-roots (cad-sqfree-product (cad-projection ps))))
(define (cad-sqfree-product polys) (sqfree-part (cad-nz-product polys)))
(define (cad-nz-product polys) (cad-prod-go polys (list 1)))
(define (cad-prod-go ps acc) (if (null? ps) acc (cad-prod-go (cdr ps) (poly-mul acc (cad-nz (car ps))))))
(define (cad-nz p) (if (cad-allz p) (list 1) p))

; ----- honest scope boundary -----
(define (cad-lifting-caveat) (quote projection-phase-only-lifting-and-n-variable-recursion-remain))
