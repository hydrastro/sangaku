; A DISPATCHER for real existential decision problems (docs/CAS.md): it routes each problem to the cheapest COMPLETE
; method, so the decision layer is fast in practice without ever sacrificing correctness.  General real quantifier
; elimination is doubly exponential (Davenport-Heintz, a theorem); the only honest way to be fast is to recognise the
; structured cases and send them to a cheaper complete procedure, reserving full cylindrical algebraic decomposition
; for the genuinely hard nonlinear ones.  A linear conjunction goes to Fourier-Motzkin (single-exponential); a
; problem an inexpensive non-negativity certificate refutes goes to the UNSAT filter; everything else goes to the
; complete CAD-based decider.  Because every branch is complete for what it accepts, the dispatcher's verdict equals
; the full decider's verdict on every problem -- only faster.
(import "cas/qedispatch.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (agrees? phi) (equal? (qedispatch-decide phi) (qe-decide (quote exists) phi)))

(display "Routing each decision problem to the cheapest complete method, verdict-preserving.") (newline) (newline)

; the routes are chosen correctly
(must "a linear conjunction is routed to Fourier-Motzkin"
  (equal? (qedispatch-route (list (quote and) (cons (quote nonneg) (list -1 1)) (cons (quote nonneg) (list 3 -1)))) (quote linear-fourier-motzkin)))
(must "a sum-of-squares-refutable problem is routed to the UNSAT filter"
  (equal? (qedispatch-route (cons (quote neg) (list 1 0 1))) (quote unsat-filter)))
(must "a genuinely nonlinear satisfiable problem is routed to the complete CAD decider"
  (equal? (qedispatch-route (cons (quote zero) (list -2 0 1))) (quote cad-complete)))

; the dispatcher's verdict MATCHES the full decider on every case -- the correctness guarantee
(must "linear SAT (1 <= x <= 3) agrees with the full decider"
  (and (agrees? (list (quote and) (cons (quote nonneg) (list -1 1)) (cons (quote nonneg) (list 3 -1)))) (qedispatch-decide (list (quote and) (cons (quote nonneg) (list -1 1)) (cons (quote nonneg) (list 3 -1))))))
(must "linear UNSAT (2 < x < 2) agrees with the full decider (strictness preserved)"
  (and (agrees? (list (quote and) (cons (quote gt) (list -2 1)) (cons (quote gt) (list 2 -1)))) (not (qedispatch-decide (list (quote and) (cons (quote gt) (list -2 1)) (cons (quote gt) (list 2 -1)))))))
(must "mixed strict/nonstrict (x >= 2 and x < 2) agrees and is unsatisfiable"
  (and (agrees? (list (quote and) (cons (quote nonneg) (list -2 1)) (cons (quote gt) (list 2 -1)))) (not (qedispatch-decide (list (quote and) (cons (quote nonneg) (list -2 1)) (cons (quote gt) (list 2 -1)))))))
(must "nonlinear UNSAT (x^2 + 1 < 0) agrees with the full decider"
  (and (agrees? (cons (quote neg) (list 1 0 1))) (not (qedispatch-decide (cons (quote neg) (list 1 0 1))))))
(must "nonlinear SAT (x^2 - 2 = 0) agrees with the full decider"
  (and (agrees? (cons (quote zero) (list -2 0 1))) (qedispatch-decide (cons (quote zero) (list -2 0 1)))))
(must "always-true (x^2 >= 0) agrees with the full decider"
  (and (agrees? (cons (quote nonneg) (list 0 0 1))) (qedispatch-decide (cons (quote nonneg) (list 0 0 1)))))

(newline)
(display "The dispatcher sends linear problems down a single-exponential route and refutable ones to a certificate") (newline)
(display "check, reserving the doubly-exponential CAD for the hard nonlinear cases -- and its verdict equals the full") (newline)
(display "decider's on every problem, so speed never costs correctness (qedispatch-caveat).") (newline)
