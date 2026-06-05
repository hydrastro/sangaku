; A THREE-VARIABLE cylindrical algebraic decomposition decider by genuine LIFTING (docs/CAS.md -- the lifting phase
; carried one dimension past the two-variable decider; descend with projection, ascend by building sample points
; level by level; the construction that, iterated, is the ascending half of Collins' CAD in n variables).
;
; A 3-variable polynomial is nested in x (a list of (y,z)-polynomials).  To decide a family over the full-dimensional
; cells: sample the x-axis (sectors); over each x = a substitute to a (y,z)-fiber and sample its y-axis; over each
; (a,b) substitute to a z-fiber and sample the z-line; evaluate phi at (a,b,c).  Each lower coordinate is fixed
; before the next is sampled -- that is what makes the decomposition cylindrical -- and all coordinates are exact
; rational sector samples.  "exists" iff some sample satisfies phi; "for all" by duality.
(import "cas/cadlift.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Three-variable real decision by lifting: project down to x, then lift back up through y and z.") (newline) (newline)

(define yz-ball (list (list -1 0 1) (list) (list 1)))                 ; y^2 + z^2 - 1, as a (y,z)-polynomial
(define ball (list yz-ball (list (list)) (list (list 1))))            ; x^2 + y^2 + z^2 - 1

(display "the open unit ball x^2 + y^2 + z^2 < 1 is nonempty:") (newline)
(must "exists x,y,z: x^2 + y^2 + z^2 - 1 < 0" (cadlift-decide (quote exists) (cons (quote neg) ball)))

(display "x^2 + y^2 + z^2 + 1 < 0 has no real solution:") (newline)
(define ballp (list (list (list 1 0 1) (list) (list 1)) (list (list)) (list (list 1))))
(must "exists x,y,z: x^2 + y^2 + z^2 + 1 < 0 is false" (if (cadlift-decide (quote exists) (cons (quote neg) ballp)) #f #t))

(display "x^2 + y^2 + z^2 >= 0 holds for all (x,y,z); subtracting 1 breaks it:") (newline)
(define sumsq (list (list (list 0 0 1) (list) (list 1)) (list (list)) (list (list 1))))
(must "forall x,y,z: x^2 + y^2 + z^2 >= 0" (cadlift-decide (quote forall) (cons (quote nonneg) sumsq)))
(must "forall x,y,z: x^2 + y^2 + z^2 - 1 >= 0 is false" (if (cadlift-decide (quote forall) (cons (quote nonneg) ball)) #f #t))

(display "the bounded positive region {x>0, y>0, z>0, x+y+z<2} is nonempty:") (newline)
(define xpos (list (list) (list (list 1))))
(define ypos (list (list (list) (list 1))))
(define zpos (list (list (list 0 1))))
(define slab (list (list (list -2 1) (list 1)) (list (list 1))))
(must "exists x,y,z: x>0 and y>0 and z>0 and x+y+z-2<0"
  (cadlift-decide (quote exists) (list (quote and) (cons (quote pos) xpos) (cons (quote pos) ypos) (cons (quote pos) zpos) (cons (quote neg) slab))))
(must "exists x,y,z: x>0 and x<0 is contradictory"
  (if (cadlift-decide (quote exists) (list (quote and) (cons (quote pos) xpos) (cons (quote neg) xpos))) #f #t))

(newline)
(display "A three-variable real decider by lifting now works over the full-dimensional cells: project the family") (newline)
(display "down to the x-axis, and lift sample points back up through the y- and z-fibers, evaluating the formula on") (newline)
(display "each cylindrical cell.  The tower is finite -- two projections down, two liftings up.  The complete 3-D") (newline)
(display "treatment of lower-dimensional sections (the algebraic-sample-point machinery of nbox lifted through every") (newline)
(display "level) and the fully general n remain the frontier; this rung is the lifting phase, exact, one step past two.") (newline)
