; The irrational-outer-coordinate frontier: decide an existential sentence whose witness is a point of an algebraic
; TOWER, every coordinate a real algebraic number built over the ones below it -- including the OUTERMOST (docs/CAS.md
; -- closing the gap where the recursive decider could only probe a rational inside an irrational outer coordinate's
; interval, missing witnesses whose outer coordinate must be exactly that irrational number).
;
; A conjunction's equality atoms, when they form a SIMPLE chain (one equality univariate in the first variable, each
; later one introducing the next variable over the one below), define a tower; the module reads that chain off the
; formula, builds the real tower points (every base root crossed with every real fiber root, refined as boxes of
; nested algebraic numbers), and tests the inequality atoms there with exact algebraic-number signs.  So the tower
; sqrt(2), 2^(1/4), 2^(1/4) -- whose outer coordinate sqrt(2) is irrational -- is found.
(import "cas/cadtow2.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Witnesses on an algebraic tower whose outermost coordinate is itself irrational.") (newline) (newline)

; arity 3, nested outer-first in (x, y, z): x^2 - 2, y^2 - x, z - y
(define xm2 (list (list (list -2)) (list) (list (list 1))))                  ; x^2 - 2
(define y2x (list (list (list) (list) (list 1)) (list (list -1))))           ; y^2 - x
(define zmy (list (list (list 0 -1) (list 1))))                              ; z - y

(display "the three-level tower x = sqrt(2), y = 2^(1/4), z = 2^(1/4) -- outer coordinate irrational:") (newline)
(must "exists x, y, z. x^2 = 2 and y^2 = x and z = y and z > 1 (true, z = 2^(1/4) > 1)"
  (cadtow2-exists (list (quote and) (cons (quote zero) xm2) (cons (quote zero) y2x) (cons (quote zero) zmy) (cons (quote pos) (list (list (list -1 1))))) 3))
(must "exists x, y, z. ... and z > 2 (false, 2^(1/4) < 2)"
  (if (cadtow2-exists (list (quote and) (cons (quote zero) xm2) (cons (quote zero) y2x) (cons (quote zero) zmy) (cons (quote pos) (list (list (list -2 1))))) 3) #f #t))

; arity 2: x^2 - 2, y^2 - x, with both branches of the square root
(define xm2_2 (list (list -2) (list) (list 1)))
(define y2x_2 (list (list 0 -1) (list) (list 1)))
(display "the two-level tower with each real branch of the inner root:") (newline)
(must "exists x, y. x^2 = 2 and y^2 = x and y > 0 (true, the positive branch 2^(1/4))"
  (cadtow2-exists (list (quote and) (cons (quote zero) xm2_2) (cons (quote zero) y2x_2) (cons (quote pos) (list (list 0) (list 1)))) 2))
(must "exists x, y. x^2 = 2 and y^2 = x and y < 0 (true, the negative branch -2^(1/4))"
  (cadtow2-exists (list (quote and) (cons (quote zero) xm2_2) (cons (quote zero) y2x_2) (cons (quote pos) (list (list 0) (list -1)))) 2))

(newline)
(display "The equalities are read as a tower, its real points are constructed as nested algebraic numbers, and the") (newline)
(display "inequalities are tested there exactly -- so a witness whose outer coordinate is irrational, out of reach of") (newline)
(display "the rational-probe recursion, is now decided.") (newline)

; ----- the coupled-chain extension: a defining polynomial mixing several lower variables at once -----
; A SIMPLE chain relates only consecutive coordinates (z depends on y).  A COUPLED chain has a defining polynomial
; like z = x*y that mixes two lower variables; the simple recognizer declines it, and the decision falls through to
; cadrc.lisp, which decides sign and vanishing at a point of a general regular chain by the multivariate resultant.
(display "") (newline)
(display "a COUPLED chain -- z = x*y mixes both lower coordinates, decided via the regular-chain resultant:") (newline)
(define zxy (list (list (list 0 1)) (list (list) (list -1))))                ; z - x*y
(must "exists x, y, z. x^2 = 2 and y^2 = x and z = x*y and z > 0 (true, z = 2^(3/4))"
  (cadtow2-exists (list (quote and) (cons (quote zero) xm2) (cons (quote zero) y2x) (cons (quote zero) zxy) (cons (quote pos) (list (list (list 0 1))))) 3))
(must "exists x, y, z. ... and z > 2 (false, 2^(3/4) < 2)"
  (if (cadtow2-exists (list (quote and) (cons (quote zero) xm2) (cons (quote zero) y2x) (cons (quote zero) zxy) (cons (quote pos) (list (list (list -2 1))))) 3) #f #t))
(display "") (newline)
(display "So both shapes of algebraic tower with irrational outer coordinate are decided: the simple iterated") (newline)
(display "extension, and the coupled regular chain whose fibers mix several lower coordinates at once.") (newline)
