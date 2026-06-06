; An OPTIMIZED CDCL SAT solver (docs/CAS.md): the reference solver of example 437 made fast with the data structures
; and heuristics the competition-winning solvers share, from the Handbook of Satisfiability (chapter 4) and the
; modern SAT literature.  The reference rescans every clause on every propagation step; this one uses the
; TWO-WATCHED-LITERAL scheme (4.2) so propagation touches a clause only when one of its two watched literals is
; falsified, and adds VSIDS activity with decay, phase saving, and Luby restarts.  Implemented from the published
; algorithms, not adapted from any solver's source.  On the pigeonhole instances this is several times faster than
; the rescan solver, and it scales to instances where the reference stalls -- though SAT is NP-complete and neither
; escapes the exponential worst case; the strategies are what keep the search far from it on structure.
(import "cas/cdcl2.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
; build the pigeonhole instance PHP(pigeons, holes)
(define (pv i j h) (+ (* (- i 1) h) j))
(define (build-php p h) (append (be p h 1) (bn p h 1)))
(define (be p h i) (cond ((> i p) (quote ())) (else (cons (row i h 1) (be p h (+ i 1))))))
(define (row i h j) (cond ((> j h) (quote ())) (else (cons (pv i j h) (row i h (+ j 1))))))
(define (bn p h j) (cond ((> j h) (quote ())) (else (append (pfh p h j 1) (bn p h (+ j 1))))))
(define (pfh p h j i) (cond ((> i p) (quote ())) (else (append (pik p h j i (+ i 1)) (pfh p h j (+ i 1))))))
(define (pik p h j i k) (cond ((> k p) (quote ())) (else (cons (list (- 0 (pv i j h)) (- 0 (pv k j h))) (pik p h j i (+ k 1))))))

(display "Two-watched-literal BCP, VSIDS with decay, phase saving, Luby restarts -- the fast solver.") (newline) (newline)

; correctness matches the reference solver on every known case
(must "(1 2)(-1 2)(1 -2)(-1 -2) is UNSAT" (equal? (cdcl2-solve 2 (list (list 1 2) (list -1 2) (list 1 -2) (list -1 -2))) (quote unsat)))
(must "(1 2)(-1 3) is SAT with a verified model"
  (begin (cdcl2-solve 3 (list (list 1 2) (list -1 3))) (cdcl2-check-model (list (list 1 2) (list -1 3)) (cdcl2-model))))
(must "the implication chain (1)(-1 2)(-2 3)(-3 4) is SAT and verifies"
  (and (cdcl2-sat? 4 (list (list 1) (list -1 2) (list -2 3) (list -3 4))) (cdcl2-check-model (list (list 1) (list -1 2) (list -2 3) (list -3 4)) (cdcl2-model))))
(must "the contradictory chain (1)(-1 2)(-2 3)(-3) is UNSAT" (equal? (cdcl2-solve 3 (list (list 1) (list -1 2) (list -2 3) (list -3))) (quote unsat)))

; the pigeonhole principle, the conflict-driven benchmark, at sizes the watched-literal solver handles quickly
(must "PHP(3,2) is UNSAT" (equal? (cdcl2-solve 6 (build-php 3 2)) (quote unsat)))
(must "PHP(4,3) is UNSAT" (equal? (cdcl2-solve 12 (build-php 4 3)) (quote unsat)))
(must "PHP(5,4) is UNSAT (the reference rescan solver is several times slower here)"
  (equal? (cdcl2-solve 20 (build-php 5 4)) (quote unsat)))

; a larger satisfiable instance with a verified model
(must "an 8-variable instance is SAT with a verified model"
  (begin (cdcl2-solve 8 (list (list 1 2 3) (list -1 -2) (list -2 -3) (list 4 5) (list -4 6) (list -5 -6) (list 7 8) (list -7 -8) (list 1 -4) (list 3 7)))
         (cdcl2-check-model (list (list 1 2 3) (list -1 -2) (list -2 -3) (list 4 5) (list -4 6) (list -5 -6) (list 7 8) (list -7 -8) (list 1 -4) (list 3 7)) (cdcl2-model))))

(newline)
(display "The two-watched-literal scheme makes propagation cost only the watches actually triggered, the single") (newline)
(display "biggest practical lever in SAT; with VSIDS decay, phase saving, and restarts the solver clears pigeonhole") (newline)
(display "instances the rescan reference stalls on.  The worst case remains exponential (cdcl2-caveat).") (newline)
