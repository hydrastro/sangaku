; The SUBRESULTANT polynomial remainder sequence and its PRINCIPAL SUBRESULTANT COEFFICIENTS (docs/CAS.md) -- the
; ingredient the FULL Collins CAD projection needs beyond discriminants and resultants.  Collins' original
; projection is complete because it carries, for each polynomial and pair, the entire tower of principal
; subresultant coefficients psc_0, psc_1, psc_2, ... -- not just the resultant (psc_0) and discriminant.  These
; detect where the DEGREE of a common factor changes: psc vanishes exactly when two polynomials share a factor, and
; the least nonzero index gives the gcd degree, the finer cell-boundary information unconditional completeness
; requires.  The reduced McCallum operator drops this tower (valid only for well-oriented sets); the psc tower is
; what restores it.
(import "cas/subresultant.lisp")
(import "cas/resultant.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "The principal subresultant coefficient tower, completing the Collins projection.") (newline) (newline)

; psc_0 (the resultant) matches the independent Sylvester resultant when the polynomials are coprime
(must "subres resultant of (x^2-1, x+2) matches the Sylvester resultant (= 3)"
  (and (= (subres-resultant (list -1 0 1) (list 2 1)) (resultant (list -1 0 1) (list 2 1))) (= (subres-resultant (list -1 0 1) (list 2 1)) 3)))
(must "subres resultant of (x^2-1, 2x) matches (= -4)"
  (= (subres-resultant (list -1 0 1) (list 0 2)) -4))

; the resultant VANISHES exactly when the polynomials share a factor -- the key CAD invariant
(must "Res(x^3 - x, x^2 - 1) = 0 (they share the factors x-1, x+1)"
  (= (subres-resultant (list 0 -1 0 1) (list -1 0 1)) 0))
(must "Res(x^2 - 1, x - 1) = 0 (shared root x = 1)"
  (= (subres-resultant (list -1 0 1) (list -1 1)) 0))
(must "Res(x^2 - 2, x - 1) /= 0 (coprime: sqrt 2 is not 1)"
  (not (= (subres-resultant (list -2 0 1) (list -1 1)) 0)))

; the gcd DEGREE, read from the tower, reveals multiplicity structure of a polynomial with its derivative
(must "gcd-degree(x^2 - 1, derivative) = 0 (squarefree)"
  (= (subres-gcd-degree (list -1 0 1) (list 0 2)) 0))
(must "gcd-degree((x-1)^2, derivative) = 1 (a double root)"
  (= (subres-gcd-degree (list 1 -2 1) (list -2 2)) 1))
(must "gcd-degree((x-1)^3, derivative) = 2 (a triple root)"
  (= (subres-gcd-degree (list -1 3 -3 1) (list 3 -6 3)) 2))

; the psc tower itself is a list beginning with the leading data of the sequence
(must "the psc tower of ((x-1)^3, derivative) is a nonempty list of coefficients"
  (> (length (subres-psc-tower (list -1 3 -3 1) (list 3 -6 3))) 0))

(newline)
(display "The psc tower's vanishing set marks exactly where polynomials acquire a common factor, and its gcd-degree") (newline)
(display "gives the multiplicity structure -- the cell-boundary information that makes the Collins projection complete") (newline)
(display "for any set, where McCallum's reduced operator needs well-orientedness (subres-caveat).") (newline)
