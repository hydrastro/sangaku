; The CDCL solver completed with the last two algorithmic techniques the competition-winning solvers rely on, both
; PURE ALGORITHM (independent of low-level engineering): LBD-based learned-clause deletion and conflict-clause
; minimization (docs/CAS.md).  These are the published ideas -- Audemard & Simon's Literal Block Distance (Glucose,
; 2009) and Sorensson & Biere's self-subsuming minimization (2009) -- implemented from the literature.  An honest
; note on ambition: this does NOT make Sangaku competitive with the winning C solvers; on a tree-walking Lisp
; interpreter the propagation hot loop is some three orders of magnitude slower than optimized C, a substrate gap no
; algorithm closes.  What these techniques do is make the solver ALGORITHMICALLY complete and reference-quality --
; as good as it can be on its substrate, slow only because of the interpreter, not because of missing technique.
(import "cas/cdcl3.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (pv i j h) (+ (* (- i 1) h) j))
(define (build-php p h) (append (be p h 1) (bn p h 1)))
(define (be p h i) (cond ((> i p) (quote ())) (else (cons (row i h 1) (be p h (+ i 1))))))
(define (row i h j) (cond ((> j h) (quote ())) (else (cons (pv i j h) (row i h (+ j 1))))))
(define (bn p h j) (cond ((> j h) (quote ())) (else (append (pfh p h j 1) (bn p h (+ j 1))))))
(define (pfh p h j i) (cond ((> i p) (quote ())) (else (append (pik p h j i (+ i 1)) (pfh p h j (+ i 1))))))
(define (pik p h j i k) (cond ((> k p) (quote ())) (else (cons (list (- 0 (pv i j h)) (- 0 (pv k j h))) (pik p h j i (+ k 1))))))

(display "LBD clause deletion and conflict minimization: the solver, algorithmically complete.") (newline) (newline)

; the LBD of a clause is the number of distinct decision levels among its literals
(c3-init! 5 (list (list 1 2 3 4 5)))
(vector-set! c3-level 1 0) (vector-set! c3-level 2 2) (vector-set! c3-level 3 2) (vector-set! c3-level 4 5)
(must "LBD of literals at decision levels {0, 2, 2, 5} is 3" (= (c3-lbd (list 1 2 3 4)) 3))
(must "LBD of a glue-like clause at levels {2, 2} is 1" (= (c3-lbd (list 2 3)) 1))

; correctness is preserved with minimization and LBD deletion active
(must "(1 2)(-1 2)(1 -2)(-1 -2) is UNSAT" (equal? (cdcl3-solve 2 (list (list 1 2) (list -1 2) (list 1 -2) (list -1 -2))) (quote unsat)))
(must "a satisfiable instance returns a verified model"
  (begin (cdcl3-solve 3 (list (list 1 2) (list -1 3))) (cdcl3-check-model (list (list 1 2) (list -1 3)) (cdcl3-model))))
(must "the implication chain (1)(-1 2)(-2 3)(-3 4) is SAT and verifies"
  (and (cdcl3-sat? 4 (list (list 1) (list -1 2) (list -2 3) (list -3 4))) (cdcl3-check-model (list (list 1) (list -1 2) (list -2 3) (list -3 4)) (cdcl3-model))))
(must "the contradictory chain (1)(-1 2)(-2 3)(-3) is UNSAT" (equal? (cdcl3-solve 3 (list (list 1) (list -1 2) (list -2 3) (list -3))) (quote unsat)))

; pigeonhole, including a size that triggers restart-time database reduction, still correct
(must "PHP(3,2) is UNSAT" (equal? (cdcl3-solve 6 (build-php 3 2)) (quote unsat)))
(must "PHP(4,3) is UNSAT" (equal? (cdcl3-solve 12 (build-php 4 3)) (quote unsat)))
(must "PHP(5,4) is UNSAT" (equal? (cdcl3-solve 20 (build-php 5 4)) (quote unsat)))
(must "PHP(6,5) is UNSAT (large enough to trigger LBD-based clause deletion, still sound)"
  (equal? (cdcl3-solve 30 (build-php 6 5)) (quote unsat)))

(newline)
(display "LBD keeps the high-quality glue clauses and discards the rest at restart boundaries, and minimization") (newline)
(display "shrinks each learned clause via self-subsumption -- the published learned-clause-management techniques, both") (newline)
(display "pure algorithm.  The solver is now algorithmically complete; the remaining gap to the winning solvers is the") (newline)
(display "interpreter substrate, not the technique (cdcl3-caveat).") (newline)
