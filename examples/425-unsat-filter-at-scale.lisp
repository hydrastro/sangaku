; A sound, dimension-independent UNSATISFIABILITY filter -- a partial answer to completeness AT SCALE (docs/CAS.md).
; The cost of a complete cylindrical algebraic decomposition is doubly exponential in the number of variables
; (Davenport-Heintz, a theorem), so staying fast on large problems means settling the easy instances without building
; the decomposition.  cadwit exhibits a witness for the satisfiable side by a single descent; cadunsat refutes a
; class of the unsatisfiable side by a Positivstellensatz-style non-negativity certificate that needs no
; decomposition and is independent of the dimension.  It is a one-directional sound FILTER -- 'unsat means genuinely
; empty, 'unknown means defer to the complete deciders -- so it never turns a satisfiable problem away.
(import "cas/cadunsat.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Refuting unsatisfiable existential problems cheaply, by non-negativity certificates.") (newline) (newline)

; an inequality contradicting a sum-of-squares non-negativity is refuted with no decomposition
(must "x^2 + 1 < 0 is refuted (the polynomial is a sum of squares, never negative)"
  (equal? (cadunsat-filter (cons (quote neg) (list 1 0 1))) (quote unsat)))
(must "x^2 + 1 = 0 is refuted (a strictly positive polynomial has no real zero)"
  (equal? (cadunsat-filter (cons (quote zero) (list 1 0 1))) (quote unsat)))
(must "x^4 + x^2 + 1 < 0 is refuted (sum of even powers plus a positive constant)"
  (equal? (cadunsat-filter (cons (quote neg) (list 1 0 1 0 1))) (quote unsat)))

; a conjunction is unsatisfiable as soon as one conjunct is refuted, caught without touching the rest
(must "(x^2 + 1 < 0) and (x > 5) is refuted via the first conjunct alone"
  (equal? (cadunsat-filter (list (quote and) (cons (quote neg) (list 1 0 1)) (cons (quote pos) (list -5 1)))) (quote unsat)))

; the filter is sound: it never refutes a satisfiable problem
(must "x^2 = 0 is NOT refuted (it has the real solution x = 0)"
  (equal? (cadunsat-filter (cons (quote zero) (list 0 0 1))) (quote unknown)))
(must "(x > 0) and (x < 1) is NOT refuted (it is satisfiable)"
  (equal? (cadunsat-filter (list (quote and) (cons (quote pos) (list 0 1)) (cons (quote neg) (list -1 1)))) (quote unknown)))
(must "a plain linear bound x - 3 > 0 is NOT refuted (satisfiable, no certificate applies)"
  (equal? (cadunsat-filter (cons (quote pos) (list -3 1))) (quote unknown)))

(newline)
(display "The filter settles a class of unsatisfiable problems by a certificate independent of the number of") (newline)
(display "variables, the cheap front end to the complete but doubly-exponential deciders.  It is deliberately") (newline)
(display "one-directional: 'unknown defers, 'unsat is always a genuine emptiness (cadunsat-caveat).") (newline)
