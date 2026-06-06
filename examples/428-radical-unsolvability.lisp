; SOLVABILITY BY RADICALS for prime-degree polynomials -- turning the worked example's ASSERTION that a quintic is
; unsolvable into a checked proof (docs/WORKED_EXAMPLES.md, docs/CAS.md).  The governing theorem is exact: an
; irreducible polynomial over Q of PRIME degree p with exactly two non-real roots has Galois group the full
; symmetric group S_p.  The proof it packages: irreducibility of prime degree forces a transitive action, hence a
; p-cycle; complex conjugation fixes the p - 2 real roots and swaps the two non-real ones, a transposition; a
; p-cycle and a transposition generate S_p; and S_p is not solvable for p >= 5, so by Galois's theorem the
; polynomial is not solvable by radicals.  Every ingredient -- prime degree, irreducibility, a real-root count of
; exactly p - 2 -- is finite and checkable, so Sangaku can EXHIBIT a radical-unsolvable polynomial, not just assert
; one.
(import "cas/galois.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Proving radical-unsolvability of quintics, down to a finite checkable witness.") (newline) (newline)

; the prime-degree machinery
(must "5 is prime (the degree)" (galois-prime? 5))
(must "x^5 - 4 x + 2 is irreducible over Q (Eisenstein at 2)" (galois-eisenstein? (list 2 -4 0 0 0 1) 2))
(must "x^5 - 6 x + 3 is irreducible over Q (Eisenstein at 3)" (galois-eisenstein? (list 3 -6 0 0 0 1) 3))

; the root structure: exactly two non-real roots
(must "x^5 - 4 x + 2 has exactly three real roots (so two non-real)"
  (and (= (galois-real-root-count (list 2 -4 0 0 0 1)) 3) (= (galois-nonreal-count (list 2 -4 0 0 0 1)) 2)))

; the proof: Galois group S_5, hence not solvable by radicals
(must "x^5 - 4 x + 2 is proved to have Galois group S5" (galois-Sp-by-radicals? (list 2 -4 0 0 0 1)))
(must "x^5 - 4 x + 2 is therefore NOT solvable by radicals (proved, not asserted)"
  (equal? (galois-solvable-by-radicals? (list 2 -4 0 0 0 1)) (quote no)))
(must "x^5 - 6 x + 3 is likewise proved unsolvable by radicals"
  (equal? (galois-solvable-by-radicals? (list 3 -6 0 0 0 1)) (quote no)))

; reducible / composite-degree polynomials are correctly not proved unsolvable
(must "x^2 - 1 = (x-1)(x+1) is recognized as reducible" (not (galois-irreducible? (list -1 0 1))))

; honest non-overclaim: x^5 - x - 1 is itself S5 and unsolvable, but it has FOUR non-real roots, so this particular
; criterion does not apply -- the module returns 'unknown rather than a false claim
(must "x^5 - x - 1 has four non-real roots, so the two-non-real criterion does not apply"
  (= (galois-nonreal-count (list -1 -1 0 0 0 1)) 4))
(must "x^5 - x - 1 is therefore left 'unknown by this criterion (not falsely claimed)"
  (equal? (galois-solvable-by-radicals? (list -1 -1 0 0 0 1)) (quote unknown)))

(newline)
(display "For x^5 - 4 x + 2 and x^5 - 6 x + 3 the unsolvability is PROVED: a prime degree, an Eisenstein") (newline)
(display "irreducibility certificate, and a Sturm real-root count of exactly p - 2 together force the Galois group") (newline)
(display "to be the non-solvable S_5.  The criterion does not reach every unsolvable polynomial (x^5 - x - 1 needs a") (newline)
(display "different witness), and the module says 'unknown rather than overclaim -- the companion to galquartic,") (newline)
(display "where every group is solvable (galois-caveat).") (newline)
