; Sangaku certificates checked by LIZARD'S OWN type-theory kernel -- the concrete core of "a CAS where every
; statement shows a proof in lizard's type theory" (docs/CAS.md, docs/DOWN_TO_AXIOMS.md).  Where certlean renders a
; certificate as text for an external assistant, certkernel discharges it INSIDE lizard: it builds a proof term in
; lizard's dependent type theory and the kernel primitive kernel-check accepts it only if it genuinely inhabits the
; stated type.  Two fragments are covered over a shared commutative ring: NONNEGATIVITY p(x) >= 0 from an explicit
; sum-of-squares, proved through the order axioms stated as constructors (sq_nonneg, add_nonneg, ...); and the
; DERIVATIVE judgment Der (\x.f) (\x.f'), re-exported from diff-cert.  The same engine that decides also proves, with
; no foreign prover and no trust in Sangaku -- a wrong claim yields a term that does not type-check.
(import "cas/certkernel.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Discharging Sangaku certificates in lizard's own type-theory kernel.") (newline) (newline)

; NONNEGATIVITY proofs the kernel accepts (the sum-of-squares fragment)
(must "x^2 + x + 1 >= 0 is proved in lizard's kernel" (certkernel-check-nonneg (list 1 1 1)))
(must "x^2 + 1 >= 0 is proved in lizard's kernel" (certkernel-check-nonneg (list 1 0 1)))
(must "(x - 1)^2 >= 0 is proved (a perfect square)" (certkernel-check-nonneg (list 1 -2 1)))
(must "the non-monic 5 x^2 - 4 x + 1 >= 0 is proved" (certkernel-check-nonneg (list 1 -4 5)))

; SOUNDNESS: the kernel refuses to certify what is not nonnegative
(must "x^2 - 1 is NOT certified nonnegative (it is negative on (-1,1))" (not (certkernel-check-nonneg (list -1 0 1))))
(must "the linear x is NOT certified nonnegative" (not (certkernel-check-nonneg (list 0 1))))

; DERIVATIVE judgments the kernel type-checks (re-exported from diff-cert)
(must "d/dx(x * x) is certified by lizard's kernel" (certkernel-check-deriv (cas (list (quote *) (quote x) (quote x)))))
(must "d/dx(x + x) is certified by lizard's kernel" (certkernel-check-deriv (cas (list (quote +) (quote x) (quote x)))))
(must "d/dx(sin x) is certified by lizard's kernel" (certkernel-check-deriv (kapp (quote sin) (quote x))))

; the order-fragment square axiom itself is kernel-checked (the universally-quantified content)
(must "the square-nonnegativity axiom sq_nonneg x : Ge (x*x) 0 is kernel-checked"
  (begin (certkernel-install!) (kernel-check (kapp (quote sq_nonneg) (quote xv)) (Ge (ck-k2 (quote mul) (quote xv) (quote xv)) (quote zeroR)))))

(newline)
(display "For the sum-of-squares fragment and the elementary derivatives, a Sangaku verdict now comes with a proof") (newline)
(display "term lizard's kernel checks -- the same system computing and proving.  This does not yet cover every") (newline)
(display "statement Sangaku can decide (general nonnegativity, the full decision procedures); extending the kernel") (newline)
(display "fragment is the path toward that goal (certkernel-caveat).") (newline)
