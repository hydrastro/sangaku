; The n-VARIABLE PROJECTION operator: the recursion backbone of cylindrical algebraic decomposition in arbitrarily
; many variables (docs/CAS.md -- cadproj eliminated y from bivariate polynomials; this eliminates one variable from
; polynomials in n variables, building the projection tower R^n -> R^(n-1) -> ... -> R, whose base is the
; one-variable real-QE decision and whose ascent is lifting; this tower is the backbone of multivariate real
; quantifier elimination, the open-research summit).
;
; A polynomial in n variables is a polynomial in the last variable whose coefficients are multivariate polynomials
; (groebner.lisp's mpoly) in the rest.  Eliminating the last variable is the resultant -- the determinant of the
; Sylvester matrix over the multivariate coefficient ring, by exact cofactor expansion with mpoly arithmetic.
(import "cas/cadnd.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Eliminating a variable from polynomials in several variables, by the multivariate resultant.") (newline) (newline)

(display "the planes z = x and z = y meet where x = y -- Res_z(z - x, z - y) = x - y:") (newline)
(define p (list (list (cons -1 (list 1 0))) (list (cons 1 (list 0 0)))))
(define q (list (list (cons -1 (list 0 1))) (list (cons 1 (list 0 0)))))
(must "the elimination of z yields a polynomial in x, y with two terms (x - y up to sign)" (= (cadn-len (cadn-resultant p q)) 2))
(must "deg_z(z - x) = 1" (= (cadn-deg p) 1))

(display "the surface z^2 = x degenerates where its z-discriminant vanishes (a multiple of x):") (newline)
(define zsq (list (list (cons -1 (list 1 0))) (quote ()) (list (cons 1 (list 0 0)))))
(must "deg_z(z^2 - x) = 2" (= (cadn-deg zsq) 2))
(must "disc_z(z^2 - x) is a single-term multiple of x" (= (cadn-len (cadn-discriminant zsq)) 1))

(display "a 3-variable existence check, projecting and sampling the full-dimensional cells:") (newline)
(define ball (cons (quote neg) (lambda (x y z) (- (+ (+ (* x x) (* y y)) (* z z)) 1))))
(must "the open unit ball x^2 + y^2 + z^2 < 1 is nonempty" (cadn-exists3 (list ball)))
(define ballpos (cons (quote neg) (lambda (x y z) (+ (+ (+ (* x x) (* y y)) (* z z)) 1))))
(must "x^2 + y^2 + z^2 + 1 < 0 has no solution" (if (cadn-exists3 (list ballpos)) #f #t))

(display "the interior of the positive simplex {x>0, y>0, z>0, x+y+z<1} is nonempty:") (newline)
(must "positive simplex interior nonempty"
  (cadn-exists3 (list (cons (quote pos) (lambda (x y z) x)) (cons (quote pos) (lambda (x y z) y))
                      (cons (quote pos) (lambda (x y z) z)) (cons (quote neg) (lambda (x y z) (- (+ (+ x y) z) 1))))))
(must "x > 0 and x < 0 is contradictory"
  (if (cadn-exists3 (list (cons (quote pos) (lambda (x y z) x)) (cons (quote neg) (lambda (x y z) x)))) #f #t))

(newline)
(display "The projection tower -- eliminating variables one at a time by the multivariate resultant -- is built") (newline)
(display "exactly for any n, the descending phase of a general CAD.  The fully worked decider is the two-variable") (newline)
(display "case (example 399, now complete with irrational sections); for n >= 3 this delivers the exact projection") (newline)
(display "backbone and a full-dimensional 3-variable decider.  The n-dimensional algebraic-tower LIFTING -- stacking") (newline)
(display "sample points with coordinates in Q(alpha_1)(alpha_2)... through every level -- is the deep frontier, the") (newline)
(display "part a general real-QE engine is truly made of.") (newline)
