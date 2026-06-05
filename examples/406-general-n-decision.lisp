; A GENERAL n-VARIABLE real decision procedure over the full-dimensional cells, by recursive cylindrical sampling
; (docs/CAS.md -- where the two- and three-variable deciders hand-unrolled their variables, this is the single
; RECURSIVE decider for ANY number of variables, the general-n shape of the ascending CAD phase).
;
; decide(family, n): if n = 1, a univariate sign-condition decision; else choose rational sample values for the
; outermost variable, substitute each, and recurse on the (n-1)-variable family.  The tower is finite -- n variables,
; n levels of recursion.  Every sample is an exact rational, so a positive verdict is always correct (sound), and
; the procedure is complete for FULL-DIMENSIONAL witnesses (a solution set of full dimension has nonempty interior,
; so a sufficiently fine rational sample set meets it).
(import "cas/cadgen.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))   ; the constant c as an n-variate nested polynomial

(display "One recursive decider for every n: substitute the outer variable, recurse, bottom out at one variable.") (newline) (newline)

(display "one variable:") (newline)
(must "exists x: x^2 - 1 < 0" (cadgen-decide (quote exists) (cons (quote neg) (list -1 0 1)) 1))
(must "for all x: x^2 + 1 > 0" (cadgen-decide (quote forall) (cons (quote pos) (list 1 0 1)) 1))
(must "for all x: x^2 - 1 >= 0 is false" (if (cadgen-decide (quote forall) (cons (quote nonneg) (list -1 0 1)) 1) #f #t))

(display "two variables (the open disk, and the interior of the unit triangle):") (newline)
(define disk (list (list -1 0 1) (list) (list 1)))
(must "exists x,y: x^2 + y^2 - 1 < 0" (cadgen-decide (quote exists) (cons (quote neg) disk) 2))
(must "for all x,y: x^2 + y^2 - 1 >= 0 is false" (if (cadgen-decide (quote forall) (cons (quote nonneg) disk) 2) #f #t))
(must "exists x,y: x > 0 and y > 0 and x + y - 1 < 0"
  (cadgen-decide (quote exists) (list (quote and) (cons (quote pos) (list (list) (list 1))) (cons (quote pos) (list (list 0 1))) (cons (quote neg) (list (list -1 1) (list 1)))) 2))

(display "three variables (the open ball):") (newline)
(define ball3 (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))
(must "exists x,y,z: x^2 + y^2 + z^2 - 1 < 0" (cadgen-decide (quote exists) (cons (quote neg) ball3) 3))
(must "for all x,y,z: x^2 + y^2 + z^2 >= 0" (cadgen-decide (quote forall) (cons (quote nonneg) (list (list (list 0 0 1) (list) (list 1)) (cn 0 2) (cn 1 2))) 3))

(display "four variables (the open 4-ball -- the recursion runs to depth four):") (newline)
(define s2 (list (list -1 0 1) (list) (list 1)))
(define ball4 (list (list s2 (cn 0 2) (cn 1 2)) (cn 0 3) (cn 1 3)))
(must "exists x1,x2,x3,x4: x1^2 + x2^2 + x3^2 + x4^2 - 1 < 0" (cadgen-decide (quote exists) (cons (quote neg) ball4) 4))

(display "the honest scope is named:") (newline)
(must "full-dimensional cells for all n; exact section lifting remains" (equal? (cadgen-section-caveat) (quote full-dimensional-cells-for-all-n-exact-section-lifting-remains)))

(newline)
(display "A single recursive procedure now decides real statements in ANY number of variables over the") (newline)
(display "full-dimensional cells: substitute the outer variable, recurse, bottom out at one.  The tower is finite") (newline)
(display "(n variables, n levels), the verdicts are sound (every sample is a real point), and full-dimensional") (newline)
(display "witnesses are found.  Exact treatment of lower-dimensional sections for general n -- lifting the algebraic") (newline)
(display "sample points of nbox through every level the way the two-variable decider does -- is the remaining frontier.") (newline)
