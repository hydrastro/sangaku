; The GENERAL multi-algebraic SECTION tower: a point whose coordinates form an iterated algebraic extension
; Q < Q(a_1) < Q(a_1,a_2) < ... , each a genuine algebraic number over the field below -- NOT merely a polynomial in
; the previous coordinate (docs/CAS.md -- the frontier past cadsecn, which decided only explicit triangular sections;
; this decides the implicit tower of nested radicals like sqrt(2) -> 2^(1/4) -> 2^(1/8), the n-dimensional
; generalization of algpoint's two-level construction).
;
; Each level's defining polynomial relates consecutive coordinates (a simple/iterated extension), bivariate in the
; cadproj form.  The sign of a polynomial at the point uses two exact mechanisms: VANISHING by reducing down the
; chain with iterated resultants to a univariate base polynomial, tested at the base algebraic number; the NONZERO
; sign by interval arithmetic over a box refined TOP-DOWN (base first, then each fiber), which converges where an
; n-box's coupled refinement cannot.
(import "cas/cadtower.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "An exact point in a tower of nested radicals: x = sqrt(2), y = 2^(1/4), z = 2^(1/8).") (newline) (newline)

; x = sqrt(2): root of x^2 - 2 in (1, 2)
; y = 2^(1/4): root of y^2 - x in (1, 3/2)   -- y^2 = x = sqrt(2), so y is algebraic over Q(sqrt 2), not rational in it
; z = 2^(1/8): root of z^2 - y in (1, 6/5)   -- another genuine extension
(define f2 (list (list 0 -1) (list) (list 1)))   ; y^2 - x  (bivariate: y over x)
(define f3 (list (list 0 -1) (list) (list 1)))   ; z^2 - y  (bivariate: z over y)
(define p (cadtower-make (list -2 0 1) 1 2 (list (list f2 1 (/ 3 2)) (list f3 1 (/ 6 5)))))

(display "the tower has three coordinates, each a genuine algebraic extension of the one below:") (newline)
(must "the height is 3" (= (cadtower-height p) 3))

(display "the defining radical identities hold exactly (decided by reducing down the chain):") (newline)
(must "2z^2 - 2y = 0 at the point (z^2 = y)" (cadtower-vanishes? (list (list 0 -2) (list) (list 2)) p))

(display "and the coordinates' signs and comparisons are exact (decided by the top-down box):") (newline)
(must "z > 0" (= (cadtower-top-sign (list (list) (list 1)) p) 1))
(must "z - 1 > 0 (since 2^(1/8) is about 1.09)" (= (cadtower-top-sign (list (list -1) (list 1)) p) 1))
(must "z - 6/5 < 0 (since 2^(1/8) < 1.2)" (= (cadtower-top-sign (list (list (/ -6 5)) (list 1)) p) -1))
(must "z does not vanish" (if (cadtower-vanishes? (list (list) (list 1)) p) #f #t))

(display "the honest scope is named:") (newline)
(must "simple iterated towers decided; the general regular chain remains"
  (equal? (cadtower-chain-caveat) (quote simple-iterated-towers-decided-general-regular-chain-remains)))

(newline)
(display "A point in a genuine tower of algebraic extensions -- nested radicals, each coordinate algebraic over the") (newline)
(display "field below -- now has exact signs and vanishing, by iterated-resultant reduction down the chain and a") (newline)
(display "top-down refining box.  This is algpoint's two-level construction generalized to any height: the implicit") (newline)
(display "multi-algebraic section the triangular decider could not reach.  The fully general regular chain, whose") (newline)
(display "defining polynomials couple all lower coordinates at once, is the deepest residual generality.") (newline)
