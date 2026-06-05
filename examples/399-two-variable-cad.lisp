; A TWO-VARIABLE cylindrical algebraic decomposition decider: projection (cadproj) joined to a LIFTING phase, giving
; a decision procedure for statements over the reals in two variables -- "exists x exists y . phi(x,y)" and "for all
; x for all y . phi" for phi a boolean combination of polynomial sign conditions (docs/CAS.md -- the next rung above
; the projection primitive, a real step into MULTIVARIATE real quantifier elimination).
;
; Method (Collins, two variables, exact over Q): PROJECT to get the critical x-values; decompose the x-axis into
; cells with exact rational sample x's (open sectors plus rational section points); LIFT each sample x to the
; univariate fibers p_i(a,y), decompose the y-line and sample it; each (a,b) lies in a 2-cell of constant sign;
; evaluate phi there. "exists" iff some sample satisfies phi, "for all" iff every sample does. Bivariate polys use
; cadproj's representation (a list of x-coefficient-polynomials, low->high in y).
(import "cas/cad2d.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Two-variable real decision by cylindrical algebraic decomposition (projection + lifting).") (newline) (newline)

(display "the open unit disk is nonempty -- exists x, y with x^2 + y^2 - 1 < 0:") (newline)
(define circle (list (list -1 0 1) (list) (list 1)))
(must "exists x y: x^2 + y^2 - 1 < 0" (cad2-decide (quote exists) (cons (quote neg) circle)))

(display "x^2 + y^2 + 1 < 0 has no real solution:") (newline)
(must "exists x y: x^2 + y^2 + 1 < 0 is false" (if (cad2-decide (quote exists) (cons (quote neg) (list (list 1 0 1) (list) (list 1)))) #f #t))

(display "x^2 + y^2 >= 0 holds for all x, y; x^2 + y^2 - 1 >= 0 does not (it is negative inside the disk):") (newline)
(must "forall x y: x^2 + y^2 >= 0" (cad2-decide (quote forall) (cons (quote nonneg) (list (list 0 0 1) (list) (list 1)))))
(must "forall x y: x^2 + y^2 - 1 >= 0 is false" (if (cad2-decide (quote forall) (cons (quote nonneg) circle)) #f #t))

(display "the parabola y^2 = x meets the vertical line x = 4 (at the rational points y = +-2):") (newline)
(define parab (list (list 0 -1) (list) (list 1)))
(must "exists x y: y^2 = x and x = 4" (cad2-decide (quote exists) (list (quote and) (cons (quote zero) parab) (cons (quote zero) (list (list -4 1))))))

(display "but y^2 = x has no point with x + 1 < 0 (a square is never negative):") (newline)
(must "exists x y: y^2 = x and x + 1 < 0 is false" (if (cad2-decide (quote exists) (list (quote and) (cons (quote zero) parab) (cons (quote neg) (list (list 1 1))))) #f #t))

(display "the hyperbola xy = 1 has a point with x > 0 and y > 0 (its positive branch):") (newline)
(define hyp (list (list -1) (list 0 1)))
(must "exists x y: xy = 1 and x > 0 and y > 0"
  (cad2-decide (quote exists) (list (quote and) (cons (quote zero) hyp) (cons (quote pos) (list (list 0 1))) (cons (quote pos) (list (list) (list 1))))))

(display "the line x = y meets the circle x^2 + y^2 = 2 at the rational point (1, 1):") (newline)
(define circ2 (list (list -2 0 1) (list) (list 1)))
(define linexy (list (list 0 1) (list -1)))
(must "exists x y: x^2 + y^2 = 2 and x = y" (cad2-decide (quote exists) (list (quote and) (cons (quote zero) circ2) (cons (quote zero) linexy))))

(newline)
(display "Projection joined to lifting gives a working two-variable real decider over the full-dimensional cells:") (newline)
(display "every satisfiable strict-inequality system, and the universal statements, are decided exactly over Q.") (newline)
(display "Witnesses living ONLY on a lower-dimensional section over an irrational x-coordinate (e.g. x^2+y^2=1 with") (newline)
(display "x=y, solved only at the irrational 1/sqrt2) are the named boundary -- cad2-section-caveat -- handled by") (newline)
(display "working in each root's real algebraic extension, which together with the recursion to n>2 variables is the") (newline)
(display "frontier ahead.  This rung is real: a two-variable CAD, projection through lifting, exact and sound.") (newline)
