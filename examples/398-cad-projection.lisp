; The CAD PROJECTION primitive: bivariate resultants and discriminants that eliminate one variable, producing the
; univariate projection polynomials whose real roots mark every x at which the structure of the y-fibers changes
; (docs/CAS.md -- the heart of cylindrical algebraic decomposition, the projection phase that reduces a two-variable
; problem to the one-variable real-QE base, and so the first genuine rung from univariate toward MULTIVARIATE real
; quantifier elimination).
;
; A bivariate p(x,y) is a polynomial in y whose coefficients are polynomials in x, stored low-to-high in y. The
; resultant Res_y(p,q) -- the determinant of the Sylvester matrix over Q[x], computed exactly by cofactor expansion
; -- vanishes at exactly the x where p(x,y) and q(x,y) share a y-root; the discriminant disc_y(p) = Res_y(p, dp/dy)
; vanishes where p has a repeated y-root. Their real roots cut the x-axis into intervals over which the fiber
; structure is constant -- the cells a cylindrical decomposition lifts.
(import "cas/cadproj.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (trim p) (cond ((null? p) (quote ())) ((= (car (rv p)) 0) (trim (fr p))) (else p)))
(define (rv l) (rva l (quote ()))) (define (rva l a) (if (null? l) a (rva (cdr l) (cons (car l) a))))
(define (fr l) (if (null? (cdr l)) (quote ()) (cons (car l) (fr (cdr l)))))

(display "Projection eliminates y, leaving the x-polynomials whose roots are the critical x-values.") (newline) (newline)

(display "the parabola y^2 = x and the line y = x meet where x = 0 or x = 1:") (newline)
(define parab (list (list 0 -1) (list) (list 1)))
(define line (list (list 0 -1) (list 1)))
(display "  Res_y(y^2-x, y-x) = ") (display (trim (cad-resultant parab line))) (display " (= x^2 - x = x(x-1)):") (newline)
(must "the resultant is x^2 - x" (equal? (trim (cad-resultant parab line)) (list 0 -1 1)))
(must "it vanishes at x = 0" (= (poly-eval (cad-resultant parab line) 0) 0))
(must "and at x = 1" (= (poly-eval (cad-resultant parab line) 1) 0))

(display "the parabola's fiber y^2 = x degenerates (double y-root) where its discriminant vanishes:") (newline)
(display "  disc_y(y^2 - x) = ") (display (trim (cad-discriminant parab))) (display " (a multiple of x):") (newline)
(must "the discriminant vanishes at x = 0" (= (poly-eval (cad-discriminant parab) 0) 0))
(must "but not at x = 1" (if (= (poly-eval (cad-discriminant parab) 1) 0) #f #t))

(display "the unit circle x^2 + y^2 = 1 meets the x-axis (y = 0) at x = +-1:") (newline)
(define circle (list (list -1 0 1) (list) (list 1)))
(define yaxis (list (list) (list 1)))
(must "Res_y(circle, y) = x^2 - 1" (equal? (trim (cad-resultant circle yaxis)) (list -1 0 1)))

(display "the projection of the family {circle} captures its critical x-values:") (newline)
(must "the circle's projection has exactly two critical x-values (x = +-1)" (= (cad-projection-roots (list circle)) 2))

(display "y-degrees are read honestly (trailing zero y-coefficients ignored):") (newline)
(must "deg_y(parabola) = 2" (= (cad-bivar-deg parab) 2))
(must "deg_y(line) = 1" (= (cad-bivar-deg line) 1))

(newline)
(display "The projection phase of cylindrical algebraic decomposition is now built exactly over Q: eliminate y, and") (newline)
(display "the real roots of the projection polynomials cut the x-axis into fiber-invariant cells -- ready for the") (newline)
(display "one-variable real-QE base.  The LIFTING phase (sample points in the plane over each x-cell) and the recursion") (newline)
(display "to n variables are the frontier ahead; this is the indispensable first half.") (newline)
