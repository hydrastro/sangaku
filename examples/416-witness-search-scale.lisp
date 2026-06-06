; A fast satisfiability-witness search -- a guided depth-first descent that looks for a single real point satisfying
; an existential conjunction, sampling each axis only within the SUPPORT carved by the family's projection and
; committing to the first promising branch (docs/CAS.md).  This is the partial-CAD idea: for the decision problem
; one rarely needs the whole decomposition, only enough to exhibit a witness.  A full-dimensional satisfiable
; instance whose witness sits far from any fixed grid -- which the coarse grid misses, forcing the expensive
; complete decider -- is found here in about n projections instead.
(import "cas/cadwit.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (zc n) (if (= n 0) 0 (list (zc (- n 1)))))
(define (one n) (if (= n 0) 1 (list (one (- n 1)))))
(define (ssqm1 n) (if (= n 1) (list -1 0 1) (list (ssqm1 (- n 1)) (zc (- n 1)) (one (- n 1)))))
(define (sh n c) (if (= n 1) (list (- 100 c) -20 1) (list (sh (- n 1) (- c 100)) (cadgen-np-scale -20 (one (- n 1)) (- n 1)) (one (- n 1)))))

(display "A guided witness search that samples within the projected support and descends to a real point.") (newline) (newline)

(display "the open unit ball in R^3 and R^4 (full-dimensional, witness near the origin):") (newline)
(must "exists x,y,z. x^2+y^2+z^2 < 1 (3-ball) witness found" (cadwit-find (cons (quote neg) (ssqm1 3)) 3))
(must "exists x1..x4. sum xi^2 < 1 (4-ball) witness found" (cadwit-find (cons (quote neg) (ssqm1 4)) 4))

(display "a small ball far from any fixed grid -- center (10,10,10), radius 1/2 -- which a coarse grid misses:") (newline)
(must "exists x,y,z. (x-10)^2+(y-10)^2+(z-10)^2 < 1/4 witness found by support-guided descent"
  (cadwit-find (cons (quote neg) (sh 3 (/ 1 4))) 3))

(newline)
(display "The descent projects to each axis, samples the interior of the support first, substitutes, and recurses,") (newline)
(display "so a full-dimensional witness is reached on a single root-to-leaf path -- the partial-CAD shortcut for the") (newline)
(display "common satisfiable case, leaving the complete deciders for unsatisfiability and irrational-only sections.") (newline)
