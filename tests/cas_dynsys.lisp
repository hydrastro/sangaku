(import "cas/dynsys.lisp")
; partial derivatives of f = x^2 + xy and g = y^3
(define f (list (cons 1 (list 2 0)) (cons 1 (list 1 1))))
(define g (list (cons 1 (list 0 3))))
(display (mpoly->str (mpoly-deriv f 0) (list "x" "y"))) (newline)
(display (mpoly->str (mpoly-deriv f 1) (list "x" "y"))) (newline)
(display (mpoly->str (mpoly-deriv g 1) (list "x" "y"))) (newline)
; Lorenz at origin: exact Jacobian, charpoly, eigenvalues
(define LOR (list
  (list (cons 10 (list 0 1 0)) (cons -10 (list 1 0 0)))
  (list (cons 28 (list 1 0 0)) (cons -1 (list 1 0 1)) (cons -1 (list 0 1 0)))
  (list (cons 1 (list 1 1 0)) (cons (/ -8 3) (list 0 0 1)))))
(display (jacobian-at LOR 3 (list 0 0 0))) (newline)
(display (poly-norm (equilibrium-charpoly LOR 3 (list 0 0 0)))) (newline)
(display (equilibrium-eigenvalues->string LOR 3 (list 0 0 0))) (newline)
(display (equilibrium? LOR 3 (list 0 0 0))) (newline)
(define LOR2 (list
  (list (cons 10 (list 0 1 0)) (cons -10 (list 1 0 0)))
  (list (cons 28 (list 1 0 0)) (cons -1 (list 1 0 1)) (cons -1 (list 0 1 0)))
  (list (cons 1 (list 1 1 0)) (cons (/ -8 3) (list 0 0 1)))))
(display (mpoly->str (vf-divergence LOR2) (list "x" "y" "z"))) (newline)
(display (divergence-at LOR2 (list 1 2 3))) (newline)
(define ph (list (cons 1 (list 2 0)) (cons 3 (list 1 1)) (cons 1 (list 0 2))))
(display (hessian-at ph 2 (list 0 0))) (newline)
