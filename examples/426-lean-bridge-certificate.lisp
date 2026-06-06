; THE BRIDGE from Sangaku's certificates to a proof assistant (docs/CAS.md).  A proof-carrying CAS and a
; type-theoretic proof assistant share one instinct -- make trust mechanical, bottom out in a small checkable kernel
; -- and certlean connects them: it takes a certificate Sangaku produces for polynomial nonnegativity and emits the
; proof obligation Lean 4 (or Coq, same shape) discharges, so "Sangaku decided it" becomes "the kernel type-checked
; it".  For a nonnegative quadratic the bridge emits an EXPLICIT sum-of-squares identity, rendered as an nlinarith
; proof the kernel verifies by polynomial normalization, trusting nothing about Sangaku; for a general nonnegative
; polynomial it emits the sign certificate (the squarefree odd part has no real root, the leading coefficient is
; positive) as a statement the assistant re-checks itself.
(import "cas/certlean.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
; substring search: does `hay` contain `needle`?
(define (cadqe-substr? hay needle) (cadqe-ss hay needle 0 (- (string-length hay) (string-length needle))))
(define (cadqe-ss hay needle i imax) (cond ((> i imax) #f) ((string=? (substring hay i (+ i (string-length needle))) needle) #t) (else (cadqe-ss hay needle (+ i 1) imax))))

(display "Exporting Sangaku nonnegativity certificates as proof-assistant-checkable obligations.") (newline) (newline)

; the explicit sum-of-squares reconstructs the polynomial exactly, so the emitted nlinarith hints genuinely prove it
(define (recon-ok p) (equal? (certlean-reconstruct (certlean-sos-terms p)) (certlean-trim p)))
(define (coeffs-nonneg terms) (cond ((null? terms) #t) ((>= (car (car terms)) 0) (coeffs-nonneg (cdr terms))) (else #f)))

(must "x^2 + x + 1 has an explicit rational SOS that reconstructs it exactly"
  (recon-ok (list 1 1 1)))
(must "its SOS coefficients are all nonnegative (so the certificate is valid)"
  (coeffs-nonneg (certlean-sos-terms (list 1 1 1))))
(must "the non-monic 5 x^2 - 4 x + 1 also gets an exact SOS (the sos non-monic bug is fixed)"
  (recon-ok (list 1 -4 5)))
(must "the perfect square x^2 - 2 x + 1 reconstructs exactly with a zero remainder term"
  (and (recon-ok (list 1 -2 1)) (= (car (car (cdr (certlean-sos-terms (list 1 -2 1))))) 0)))

; the emitted Lean text is a theorem with a closing proof for the explicit-SOS cases
(define lemma1 (certlean-lean-nonneg "sangaku_q1" (list 1 1 1)))
(must "the Lean lemma for x^2+x+1 states the goal and closes with nlinarith over square hints"
  (and (cadqe-substr? lemma1 "theorem sangaku_q1") (cadqe-substr? lemma1 "nlinarith [sq_nonneg")))

; a general (irrational-decomposition) nonnegative polynomial falls back to the sign certificate
(define lemma2 (certlean-lean-nonneg "sangaku_quartic" (list 1 0 -1 0 1)))
(must "the quartic x^4 - x^2 + 1 emits the sign-certificate lemma (deferred to the assistant)"
  (and (cadqe-substr? lemma2 "theorem sangaku_quartic") (cadqe-substr? lemma2 "Sangaku certificate")))

; a polynomial that is not nonnegative yields no certificate
(must "x^2 - 1 (negative on (-1,1)) yields no certificate"
  (cadqe-substr? (certlean-lean-nonneg "sangaku_bad" (list -1 0 1)) "NOT nonnegative"))

; the bridge also exports EXISTENCE certificates -- the completeness-dependent chain.  A sign change brackets a
; real root, and the emitted Lean lemma re-proves existence by the intermediate value theorem.
(must "x^2 - 2 has a sign-change bracket on (1, 2): f(1) < 0 < f(2)"
  (certlean-sign-bracket (list -2 0 1) 1 2))
(define elem (certlean-lean-exists "sangaku_sqrt2_exists" (list -2 0 1) 1 2))
(must "the existence lemma states a root in the interval and proves it via the intermediate value theorem"
  (and (cadqe-substr? elem "∃ x") (cadqe-substr? elem "intermediate_value_Icc")))
(must "a non-bracketing interval is rejected (no false existence certificate)"
  (cadqe-substr? (certlean-lean-exists "bad" (list -2 0 1) 2 3) "not a sign-change bracket"))

(newline)
(display "The quadratic certificates are complete Lean proofs the kernel checks by ring normalization; the general") (newline)
(display "case is rendered faithfully as the sign certificate Sangaku actually holds.  This is one concrete CAS-to-") (newline)
(display "prover bridge grounded in Sangaku's own certificates, not a claim to subsume the proof assistant (certlean-caveat).") (newline)
