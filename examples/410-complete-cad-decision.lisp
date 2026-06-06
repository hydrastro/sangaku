; A COMPLETE real decision procedure for the two-variable case: it finds witnesses on cells of EVERY dimension --
; full-dimensional and section alike (docs/CAS.md -- closing the completeness gap of the grid-based decider, which
; sees only full-dimensional witnesses; the section witness (2, sqrt(2)) of "y^2 = x and x = 2" is now found).
;
; The x-axis is sampled at the TRUE CAD breakpoints: a rational in each open sector AND each real root (a section,
; possibly irrational) of the base projection.  Over a rational x the fiber is decided completely in y (its own
; sectors and sections); over an algebraic x the formula is evaluated on the section exactly.  The union of the
; full-dimensional and section searches is complete; every sample is a real point, so the decision is sound.
(import "cas/cadfull.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "A two-variable decider that finds lower-dimensional (section) witnesses, not just open-cell ones.") (newline) (newline)

(define parab (list (list 0 -1) (list) (list 1)))   ; y^2 - x
(define xm2 (list (list -2 1)))                       ; x - 2
(display "the only witness of y^2 = x and x = 2 is the section point (2, sqrt(2)) -- a grid never samples x = 2:") (newline)
(must "exists x, y: y^2 = x and x = 2 (TRUE, found on the section)"
  (cadfull-decide2 (quote exists) (list (quote and) (cons (quote zero) parab) (cons (quote zero) xm2))))

(define circle (list (list -1 0 1) (list) (list 1)))   ; x^2 + y^2 - 1
(define linexy (list (list 0 1) (list -1)))            ; x - y
(display "an irrational section witness (1/sqrt(2), 1/sqrt(2)):") (newline)
(must "exists x, y: x^2 + y^2 = 1 and x = y (TRUE)"
  (cadfull-decide2 (quote exists) (list (quote and) (cons (quote zero) circle) (cons (quote zero) linexy))))

(display "full-dimensional and empty cases agree with the earlier deciders:") (newline)
(must "exists x, y: x^2 + y^2 < 1 (TRUE, open disk)" (cadfull-decide2 (quote exists) (cons (quote neg) circle)))
(must "exists x, y: x^2 + y^2 + 1 < 0 (FALSE)" (if (cadfull-decide2 (quote exists) (cons (quote neg) (list (list 1 0 1) (list) (list 1)))) #f #t))
(must "exists x, y: y^2 = x and x + 1 = 0 (FALSE, no real point)"
  (if (cadfull-decide2 (quote exists) (list (quote and) (cons (quote zero) parab) (cons (quote zero) (list (list 1 1))))) #f #t))

(newline)
(display "The two-variable decision is now complete on every cell dimension: the base axis is cut at the real") (newline)
(display "projection roots, sectors and sections are both sampled, and section witnesses -- including irrational") (newline)
(display "ones the grid could never reach -- are found exactly.") (newline)
