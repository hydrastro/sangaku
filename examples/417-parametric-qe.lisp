; PARAMETRIC quantifier elimination -- the headline real-QE capability: not merely deciding a closed sentence true
; or false, but eliminating a quantified variable from a formula that still has a FREE parameter, returning an
; equivalent quantifier-free condition on the parameter (docs/CAS.md).  This is what QEPCAD or Mathematica's Resolve
; does when it answers "exists x . x^2 + b < 0" with "b < 0".
;
; The method is the cylindrical algebraic decomposition of the PARAMETER line: with the parameter b outer and the
; quantified variable x inner, the projection of the family onto b cuts the b-line into cells on each of which the
; quantified statement has a constant truth value; deciding that value once per cell with the complete univariate
; decider labels each cell, and the eliminated formula is the union of the true cells.
(import "cas/cadqe.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (same? a b) (equal? a b))

(display "Eliminating a quantifier from a one-parameter family, producing a condition on the parameter b.") (newline) (newline)

; exists x. x^2 + b < 0  ->  b < 0
(define x2pb (list (list 0 1) (list) (list 1)))                 ; x^2 + b  (b outer, x inner)
(must "exists x. x^2 + b < 0  gives  b < 0"
  (same? (cadqe-formula (quote exists) (cons (quote neg) x2pb)) (quote (or (< b 0)))))

; forall x. x^2 - b >= 0  ->  b <= 0   (adjacent true cells b<0 and b=0 merge to b<=0)
(define x2mb (list (list 0 -1) (list) (list 1)))                ; x^2 - b
(must "forall x. x^2 - b >= 0  gives  b <= 0"
  (same? (cadqe-formula (quote forall) (cons (quote nonneg) x2mb)) (quote (or (<= b 0)))))

; exists x. x^2 = b  ->  b >= 0   (the section b = 0 is included: x = 0 solves x^2 = 0)
(must "exists x. x^2 = b  gives  b >= 0  (double-root section included)"
  (same? (cadqe-formula (quote exists) (cons (quote zero) x2mb)) (quote (or (>= b 0)))))

; exists x. x^2 = b and x > 0  ->  b > 0   (b = 0 excluded: x = 0 is not > 0)
(define justx (list (list 0) (list 1)))                         ; x
(must "exists x. x^2 = b and x > 0  gives  b > 0"
  (same? (cadqe-formula (quote exists) (list (quote and) (cons (quote zero) x2mb) (cons (quote pos) justx))) (quote (or (> b 0)))))

; exists x. (x - b)^2 - 1 < 0  ->  true (every b: take x = b)
(define xmb2m1 (list (list -1 0 1) (list 0 -2) (list 1)))       ; (x - b)^2 - 1 = x^2 - 2 b x + b^2 - 1
(must "exists x. (x - b)^2 - 1 < 0  gives  true"
  (same? (cadqe-formula (quote exists) (cons (quote neg) xmb2m1)) (quote true)))

; exists x. x^2 + b^2 + 1 < 0  ->  false (never: the polynomial is always positive)
(define x2pb2p1 (list (list 1 0 1) (list) (list 1)))            ; x^2 + (b^2 + 1)
(must "exists x. x^2 + b^2 + 1 < 0  gives  false"
  (same? (cadqe-formula (quote exists) (cons (quote neg) x2pb2p1)) (quote false)))

(newline)
(display "Each result is an exact quantifier-free condition on b: the projection is exact, and every parameter cell's") (newline)
(display "truth is decided by the complete univariate decider on an exact sample. One quantified variable over one free") (newline)
(display "parameter is the planar scope; more parameters are the general parametric CAD (cadqe-caveat names it).") (newline)
