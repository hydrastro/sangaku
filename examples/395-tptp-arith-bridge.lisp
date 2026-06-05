; The TPTP-ARITHMETIC BRIDGE: a classifier and router that takes an arithmetic goal -- the kind posed in
; automated-theorem-proving benchmarks such as TPTP -- and dispatches it to the Sangaku decision procedure that can
; settle it, returning a verdict with that procedure's certificate (docs/CAS.md -- a side project connecting
; Sangaku's exact deciders to TPTP-style arithmetic; the syntax itself is parsed by the companion project tptptp).
;
; Honest premise: Sangaku is not a general first-order prover and does not compete in the FOF/CNF divisions -- its
; logic layer is an SLD resolver over Horn clauses.  But many TPTP ARITHMETIC problems reduce to shapes Sangaku
; decides exactly, and the bridge routes each shape to the right backend, returning 'outside-fragment (never a
; guess) for anything else.  Verdicts: 'theorem (proved, with certificate), 'countersat (refuted), 'unknown (in the
; fragment but not decided, e.g. multivariate nonnegativity without an SOS witness), 'outside-fragment.
(import "cas/tptp/core.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "TPTP-arith bridge: classify an arithmetic goal, route it to the right decider, return verdict + certificate.") (newline) (newline)

(display "a contradictory equation system x = 0 AND x = 1 -> the Nullstellensatz proves it:") (newline)
(define x (list (cons 1 (list 1))))
(define x-1 (list (cons 1 (list 1)) (cons -1 (list 0))))
(define g1 (list (quote poly-unsat) (list x x-1)))
(display "  verdict ") (display (tptp-decide g1)) (display ", via ") (display (tptp-route-name (tptp-shape g1))) (display ", certificate ") (display (tptp-certificate g1)) (newline)
(must "the contradictory system is a theorem" (equal? (tptp-decide g1) (quote theorem)))
(must "routed to the Nullstellensatz" (equal? (tptp-route-name (tptp-shape g1)) (quote nullstellensatz)))

(display "a SOLVABLE system x = 5 -> the claim of unsatisfiability is refuted:") (newline)
(must "x = 5 is countersatisfiable" (equal? (tptp-decide (list (quote poly-unsat) (list (list (cons 1 (list 1)) (cons -5 (list 0)))))) (quote countersat)))

(display "a polynomial identity (x+1)^2 = x^2 + 2x + 1 -> proved exactly:") (newline)
(must "the identity is a theorem" (equal? (tptp-decide (list (quote poly-identity) (list 1 2 1) (list 1 2 1))) (quote theorem)))
(must "a false identity is refuted" (equal? (tptp-decide (list (quote poly-identity) (list 1 2 1) (list 1 1 1))) (quote countersat)))

(display "a universal real inequality (forall x) x^2 + 1 >= 0 -> DECIDED by the univariate SOS procedure:") (newline)
(must "x^2 + 1 >= 0 is a theorem" (equal? (tptp-decide (list (quote nonneg) (list 1 0 1))) (quote theorem)))
(must "x^2 - 1 >= 0 is refuted (it changes sign)" (equal? (tptp-decide (list (quote nonneg) (list -1 0 1))) (quote countersat)))

(display "a multivariate inequality x^2 + y^2 >= 0 with an SOS witness -> proved; Motzkin without one -> unknown:") (newline)
(define qx (list (cons 1 (list 1 0))))
(define qy (list (cons 1 (list 0 1))))
(define p2 (list (cons 1 (list 2 0)) (cons 1 (list 0 2))))
(must "x^2+y^2 with witness {x, y} is a theorem" (equal? (tptp-decide (list (quote nonneg-sos) p2 (list qx qy))) (quote theorem)))
(define M (list (cons 1 (list 4 2)) (cons 1 (list 2 4)) (cons -3 (list 2 2)) (cons 1 (list 0 0))))
(must "Motzkin without an SOS witness is UNKNOWN, never falsely refuted" (equal? (tptp-decide (list (quote nonneg-sos) M (quote ()))) (quote unknown)))

(display "ground arithmetic 4 = 4, 5 <= 5, 3 < 2 -> evaluated directly:") (newline)
(must "4 = 4 is a theorem" (equal? (tptp-decide (list (quote ground) (quote =) 4 4)) (quote theorem)))
(must "5 <= 5 is a theorem" (equal? (tptp-decide (list (quote ground) (quote <=) 5 5)) (quote theorem)))
(must "3 < 2 is refuted" (equal? (tptp-decide (list (quote ground) (quote <) 3 2)) (quote countersat)))

(display "a goal outside the arithmetic fragment -> reported honestly, not guessed:") (newline)
(must "an unrecognized goal is outside-fragment" (equal? (tptp-decide (list (quote some-fol-formula) 1 2)) (quote outside-fragment)))

(newline)
(display "The bridge routes each arithmetic goal to an exact Sangaku decider and reports the verdict with its") (newline)
(display "certificate.  It is sound by construction: 'theorem and 'countersat come only from a decision procedure that") (newline)
(display "establishes them, multivariate nonnegativity without a witness is 'unknown, and non-arithmetic goals are") (newline)
(display "'outside-fragment.  This is the niche where Sangaku contributes to TPTP -- arithmetic with certificates --") (newline)
(display "not the FOF/CNF divisions, which need a saturation prover.") (newline)
