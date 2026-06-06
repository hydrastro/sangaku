; A CONFLICT-DRIVEN CLAUSE-LEARNING (CDCL) SAT solver (docs/CAS.md), the modern architecture from the Handbook of
; Satisfiability (chapter 4: the typical CDCL algorithm and the lazy data structures) with the refinements the
; competition-winning solvers share -- 1-UIP conflict analysis with clause learning, non-chronological backjumping,
; an activity-based (VSIDS-style) decision heuristic.  SAT is NP-complete and this solver does not escape the
; exponential worst case; what makes a modern CDCL solver strong is that conflict-driven learning keeps the search
; far from that worst case on the STRUCTURED instances that arise in practice.  Implemented from the published
; algorithms, not adapted from any solver's source.  This is the SAT spine the SMT layer (DPLL(T)) will sit on.
(import "cas/cdcl.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Conflict-driven clause learning: deciding satisfiability, learning from every conflict.") (newline) (newline)

; the four-clause core forbidding every assignment to two variables is unsatisfiable
(must "(1 2)(-1 2)(1 -2)(-1 -2) is UNSAT (all four combinations forbidden)"
  (equal? (cdcl-solve 2 (list (list 1 2) (list -1 2) (list 1 -2) (list -1 -2))) (quote unsat)))

; a satisfiable instance returns a model that an independent verifier accepts
(must "(1 2)(-1 3) is SAT"
  (cdcl-sat? 3 (list (list 1 2) (list -1 3))))
(must "the returned model actually satisfies the clauses (independent check)"
  (begin (cdcl-solve 3 (list (list 1 2) (list -1 3))) (cdcl-check-model (list (list 1 2) (list -1 3)) (cdcl-model))))

; a chain of implications is satisfied by propagation, and a contradictory chain is refuted
(must "(1)(-1 2)(-2 3)(-3 4) is SAT and the model verifies"
  (and (cdcl-sat? 4 (list (list 1) (list -1 2) (list -2 3) (list -3 4)))
       (cdcl-check-model (list (list 1) (list -1 2) (list -2 3) (list -3 4)) (cdcl-model))))
(must "(1)(-1 2)(-2 3)(-3) is UNSAT (the chain forces 3, the last clause forbids it)"
  (equal? (cdcl-solve 3 (list (list 1) (list -1 2) (list -2 3) (list -3))) (quote unsat)))

; the pigeonhole principle PHP(3,2): three pigeons cannot occupy two holes one-per-hole -- the classic
; conflict-driven benchmark, refuted by learning
(must "the pigeonhole instance PHP(3,2) is UNSAT"
  (equal? (cdcl-solve 6 (list (list 1 2) (list 3 4) (list 5 6)
                              (list -1 -3) (list -1 -5) (list -3 -5)
                              (list -2 -4) (list -2 -6) (list -4 -6))) (quote unsat)))

; a larger satisfiable instance, model verified
(must "an 8-variable instance is SAT with a verified model"
  (begin (cdcl-solve 8 (list (list 1 2 3) (list -1 -2) (list -2 -3) (list 4 5) (list -4 6) (list -5 -6) (list 7 8) (list -7 -8) (list 1 -4) (list 3 7)))
         (cdcl-check-model (list (list 1 2 3) (list -1 -2) (list -2 -3) (list 4 5) (list -4 6) (list -5 -6) (list 7 8) (list -7 -8) (list 1 -4) (list 3 7)) (cdcl-model))))

(newline)
(display "The solver decides satisfiability by conflict-driven search: it propagates units, branches on the most") (newline)
(display "active variable, and on every conflict learns a 1-UIP clause and backjumps non-chronologically -- the") (newline)
(display "mechanism that prunes the subtrees a plain DPLL would revisit.  The worst case stays exponential (SAT is") (newline)
(display "NP-complete); the strategies are what make it fast on structure (cdcl-caveat).") (newline)
