; The GALOIS GROUP of a quartic, by its resolvent cubic and discriminant -- the classical decision that completes the
; solvability story (docs/CAS.md, docs/WORKED_EXAMPLES.md).  The quintic x^5 - x - 1 is unsolvable by radicals because
; its Galois group is the non-solvable S_5; every quartic, by contrast, is solvable, because each of the five possible
; quartic Galois groups -- S_4, A_4, the dihedral D_4, the cyclic C_4, the Klein four-group V_4 -- is solvable.  For a
; quartic the group is computable exactly: depress to x^4 + p x^2 + q x + r, form the resolvent cubic, count its
; rational roots, and test whether the discriminant is a perfect square.  A resolvent that splits completely gives
; V_4; an irreducible resolvent gives A_4 (square discriminant) or S_4 (non-square); one rational root gives the
; C_4 / D_4 pair.
(import "cas/galquartic.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Computing the Galois group of a quartic from its resolvent cubic and discriminant.") (newline) (newline)

; x^4 + 1 (the eighth cyclotomic) has Galois group the Klein four-group V_4: its resolvent splits completely
(must "x^4 + 1 has Galois group V4 (resolvent y(y-2)(y+2) splits completely)"
  (equal? (galq-group 0 0 0 1) (quote V4)))
(must "the resolvent cubic of x^4 + 1 is y^3 - 4 y"
  (equal? (galq-resolvent 0 0 0 1) (list 0 -4 0 1)))

; x^4 + x + 1 is irreducible with Galois group S_4: irreducible resolvent, non-square discriminant 229
(must "x^4 + x + 1 has Galois group S4 (irreducible resolvent, non-square discriminant)"
  (equal? (galq-group 0 0 1 1) (quote S4)))
(must "the discriminant of x^4 + x + 1 is 229 (not a perfect square)"
  (= (galq-discriminant 0 0 1 1) 229))

; x^4 + 8 x + 12 has Galois group A_4: irreducible resolvent, perfect-square discriminant 331776 = 576^2
(must "x^4 + 8 x + 12 has Galois group A4 (irreducible resolvent, square discriminant)"
  (equal? (galq-group 0 0 8 12) (quote A4)))
(must "the discriminant of x^4 + 8 x + 12 is the perfect square 576^2"
  (= (galq-discriminant 0 0 8 12) (* 576 576)))

; x^4 - 2 is irreducible with Galois group D_4; the resolvent has exactly one rational root, so the module reports
; the unresolved C4-or-D4 pair (the tie-break needs irreducibility over a quadratic extension)
(must "x^4 - 2 is reported as the C4-or-D4 pair (one rational resolvent root; truth is D4)"
  (equal? (galq-group 0 0 0 -2) (quote C4-or-D4)))

; reducible quartics are detected, including those with no rational root that split into two rational quadratics
(must "x^4 + 4 = (x^2 - 2x + 2)(x^2 + 2x + 2) is detected as reducible (no rational root, but factors)"
  (equal? (galq-group 0 0 0 4) (quote reducible)))
(must "x^4 - 5 x^2 + 6 = (x^2 - 2)(x^2 - 3) is detected as reducible"
  (equal? (galq-group 0 -5 0 6) (quote reducible)))

; the solvability verdict is unconditional: every quartic is solvable by radicals
(must "every quartic is solvable by radicals (each of the five groups is solvable)"
  (and (galq-solvable? 0 0 1 1) (galq-solvable? 0 0 8 12) (galq-solvable? 0 0 0 -2)))

(newline)
(display "The group is reported exactly where the resolvent and discriminant settle it -- V4, A4, S4 -- and as the") (newline)
(display "C4-or-D4 pair otherwise; the solvability verdict is total, since unlike the quintic every quartic group is") (newline)
(display "solvable (galq-caveat).  This is the degree-four companion to the radical-unsolvable quintic example.") (newline)
