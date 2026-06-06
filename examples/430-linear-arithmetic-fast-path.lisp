; LINEAR real arithmetic by Fourier-Motzkin elimination -- a COMPLETE decision procedure for the linear fragment and
; the fast path that lets Sangaku avoid the doubly-exponential cost of full cylindrical algebraic decomposition when
; every constraint is linear (docs/CAS.md).  General real quantifier elimination is doubly exponential
; (Davenport-Heintz, a theorem), but conjunctions of linear inequalities, existentially quantified, are decidable
; far more cheaply: partition the constraints by the sign of the eliminated variable's coefficient, assert every
; lower bound is at most every upper bound, and carry the rest -- iterating eliminates all quantified variables and
; leaves a ground verdict or a residual system in the free parameters.  Complete, exact, single-exponential.
(import "cas/lra.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Deciding the linear fragment exactly, the cheap route past the doubly-exponential wall.") (newline) (newline)

; a constraint (op c0 c1 ... cn) means c0 + c1 v1 + ... + cn vn  (op)  0, with v1 the first quantified variable
(must "exists x. 1 <= x <= 3 is satisfiable"
  (lra-sat? 1 (list (list (quote ge) -1 1) (list (quote ge) 3 -1))))
(must "exists x. 3 <= x <= 1 is unsatisfiable"
  (not (lra-sat? 1 (list (list (quote ge) -3 1) (list (quote ge) 1 -1)))))

; strictness composes correctly: an open empty interval is unsatisfiable, a half-open point is decided precisely
(must "exists x. x > 2 and x < 5 is satisfiable"
  (lra-sat? 1 (list (list (quote gt) -2 1) (list (quote gt) 5 -1))))
(must "exists x. x > 2 and x < 2 is unsatisfiable (empty open interval)"
  (not (lra-sat? 1 (list (list (quote gt) -2 1) (list (quote gt) 2 -1)))))
(must "exists x. x >= 2 and x < 2 is unsatisfiable (strict upper excludes the boundary the lower allows)"
  (not (lra-sat? 1 (list (list (quote ge) -2 1) (list (quote gt) 2 -1)))))

; equalities are solved and substituted, the cheaper route
(must "exists x. 2x = 4 and x >= 2 is satisfiable (x = 2)"
  (lra-sat? 1 (list (list (quote eq) -4 2) (list (quote ge) -2 1))))
(must "exists x. 2x = 4 and x >= 3 is unsatisfiable"
  (not (lra-sat? 1 (list (list (quote eq) -4 2) (list (quote ge) -3 1)))))

; multivariable elimination: a bounded sum against floors decides feasibility
(must "exists x,y,z. x>=1, y>=2, z>=3, x+y+z<=10 is satisfiable"
  (lra-sat? 3 (list (list (quote ge) 10 -1 -1 -1) (list (quote ge) -1 1 0 0) (list (quote ge) -2 0 1 0) (list (quote ge) -3 0 0 1))))
(must "exists x,y,z. the same with x+y+z<=5 is unsatisfiable (the floors force the sum to at least 6)"
  (not (lra-sat? 3 (list (list (quote ge) 5 -1 -1 -1) (list (quote ge) -1 1 0 0) (list (quote ge) -2 0 1 0) (list (quote ge) -3 0 0 1)))))

(newline)
(display "The linear fragment is decided completely in single-exponential time, the route a dispatcher takes when a") (newline)
(display "problem is purely linear -- the hard nonlinear problems still go to the CAD spine, where the") (newline)
(display "doubly-exponential cost is inherent and unavoidable (lra-caveat).") (newline)
