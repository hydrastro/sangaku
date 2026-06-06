; REAL QUANTIFIER ELIMINATION, unified: ONE entry point that decides a quantified sentence over the reals in any
; number of variables (docs/CAS.md -- the single callable real-QE interface the whole cylindrical-decomposition
; development was building toward; the earlier modules each decide a slice, and this presents them as one decision
; procedure with one human-facing formula language).
;
; Atoms are written in Tarski form -- (rqe-gt p), (rqe-lt p), (rqe-ge p), (rqe-le p), (rqe-eq p), (rqe-ne p) for
; p > 0, p < 0, p >= 0, p <= 0, p = 0, p /= 0 -- combined with (and ...), (or ...), (not ...); a sentence is decided
; by rqe-decide n quant phi.  Dispatch: one variable to the univariate decider, two to the complete two-variable
; decider (full cells and sections), three or more to the full-dimensional-cell search combined with the
; equality-variety section search, so lower-dimensional witnesses are found too.
(import "cas/rqe.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))

(display "One real-quantifier-elimination call, for any number of variables, in human-facing Tarski syntax.") (newline) (newline)

(display "one variable:") (newline)
(must "exists x. x^2 - 2 = 0 (true, x = sqrt 2)" (rqe-decide 1 (quote exists) (rqe-eq (list -2 0 1))))
(must "for all x. x^2 + 1 > 0 (true)" (rqe-decide 1 (quote forall) (rqe-gt (list 1 0 1))))
(must "for all x. x^2 - 1 >= 0 (false)" (if (rqe-decide 1 (quote forall) (rqe-ge (list -1 0 1))) #f #t))

(display "two variables -- including a section witness a grid misses:") (newline)
(define parab (list (list 0 -1) (list) (list 1)))
(must "exists x, y. y^2 = x and x = 2 (true, the section point (2, sqrt 2))"
  (rqe-decide 2 (quote exists) (list (quote and) (rqe-eq parab) (rqe-eq (list (list -2 1))))))
(define circle (list (list -1 0 1) (list) (list 1)))
(must "exists x, y. x^2 + y^2 < 1 (true, open disk)" (rqe-decide 2 (quote exists) (rqe-lt circle)))
(must "for all x, y. x^2 + y^2 >= 0 (true)" (rqe-decide 2 (quote forall) (rqe-ge (list (list 0 0 1) (list) (list 1)))))

(display "three variables -- a full-dimensional region and a zero-dimensional irrational section:") (newline)
(define ball3 (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))
(must "exists x, y, z. x^2 + y^2 + z^2 < 1 (true, open ball)" (rqe-decide 3 (quote exists) (rqe-lt ball3)))
(define sph (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))
(define xy (list (list (list) (list -1)) (cn 1 2)))
(define yz (list (list (list 0 -1) (list 1))))
(define xc (list (list) (list (list 1))))
(must "exists x, y, z. x^2+y^2+z^2 = 1 and x = y and y = z and x > 0 (true, the diagonal 1/sqrt 3)"
  (rqe-decide 3 (quote exists) (list (quote and) (rqe-eq sph) (rqe-eq xy) (rqe-eq yz) (rqe-gt xc))))
(must "for all x, y, z. x^2 + y^2 + z^2 >= 0 (true)" (rqe-decide 3 (quote forall) (rqe-ge (list (list (list 0 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))))

(newline)
(display "A single real-quantifier-elimination procedure now decides sentences in any number of variables, routing") (newline)
(display "to the complete engine for each and combining full-dimensional with section search -- the unified") (newline)
(display "interface, sound on every cell and complete on cells of every dimension for the cases each engine covers.") (newline)
