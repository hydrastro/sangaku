; 392-dynamical-systems.lisp — exact dynamical-systems analysis over Q.
;
; A vector field is a list of multivariate polynomials (cas/dynsys.lisp, on the
; groebner.lisp mpoly representation). This module adds partial derivatives, the
; Jacobian of a vector field, the divergence (phase-volume contraction), the
; Hessian, and — composing with cas/linalg.lisp — the EXACT eigenvalues of the
; linearization at an equilibrium. The Lorenz origin's spectrum comes out as
; -8/3 and (-11 +/- sqrt 1201)/2, exactly; the divergence is the constant
; -41/3, certifying dissipativity. Nothing is numeric.
(import "cas/dynsys.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise 'dynsys-fail)))

(display "Exact dynamical-systems analysis (vector fields over Q).") (newline) (newline)

; Lorenz: f1=10(y-x), f2=28x-xz-y, f3=xy-(8/3)z  in vars (x y z).
(define LOR (list
  (list (cons 10 (list 0 1 0)) (cons -10 (list 1 0 0)))
  (list (cons 28 (list 1 0 0)) (cons -1 (list 1 0 1)) (cons -1 (list 0 1 0)))
  (list (cons 1 (list 1 1 0)) (cons (/ -8 3) (list 0 0 1)))))

(display "Jacobian of Lorenz at the origin:") (newline)
(display "  ") (display (jacobian-at LOR 3 (list 0 0 0))) (newline)
(must "origin is an equilibrium" (equilibrium? LOR 3 (list 0 0 0)))

(display "Characteristic polynomial at the origin (low->high):") (newline)
(display "  ") (display (poly-norm (equilibrium-charpoly LOR 3 (list 0 0 0)))) (newline)

(display "EXACT eigenvalues at the origin:") (newline)
(display "  ") (display (equilibrium-eigenvalues->string LOR 3 (list 0 0 0))) (newline)
(must "-8/3 is an eigenvalue (z-direction decouples)"
  (= (matrix-det (mat-sub (jacobian-at LOR 3 (list 0 0 0)) (mat-scale (/ -8 3) (identity 3)))) 0))

(display "Divergence (phase-volume contraction rate):") (newline)
(display "  div F = ") (display (mpoly->str (vf-divergence LOR) (list "x" "y" "z")))
(display "  (constant => dissipative)") (newline)
(must "divergence = -41/3 everywhere" (= (divergence-at LOR (list 3 -1 7)) (/ -41 3)))

(newline)
(display "Every quantity above is exact: the Jacobian and divergence are exact") (newline)
(display "rational/polynomial objects, and the eigenvalues are the exact roots of") (newline)
(display "the characteristic polynomial via cas/linalg.lisp -- no floating point.") (newline)
