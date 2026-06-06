; A NATIVE certificate format for Sangaku, checked by lizard's own type-theory kernel and nothing else (docs/CAS.md).
; There is no checker-neutral standard for computer-algebra certificates that suits a dependent-type kernel --
; DRAT/LRAT are SAT-specific, Dedukti and OpenTheory are their own ecosystems, and the proof-assistant
; serializations are tied to their kernels -- so Sangaku defines a small principled one, borrowing the DESIGN of LRAT
; (a tiny trusted checker, a self-contained certificate, checking far cheaper than finding) without its
; representation, and deliberately not tied to any external system.  A certificate is a triple (domain claim-type
; proof-term): the proof term must inhabit the claim type in a namespaced kernel signature, and certspec-check
; installs that signature and calls the kernel.  A wrong claim has no valid certificate; soundness is the kernel's.
(import "cas/certspec.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "One certificate format, checked by lizard's own kernel, no external prover.") (newline) (newline)

; the format is a well-formed triple
(must "an order certificate is a well-formed (domain claim proof) triple"
  (certspec-valid-format? (certspec-order-nonneg-cert)))
(must "its domain is the order domain"
  (equal? (certspec-domain (certspec-order-nonneg-cert)) (quote order)))
(must "a truncated triple is rejected by the structural check"
  (not (certspec-valid-format? (list (quote order)))))

; valid certificates are accepted by the kernel
(must "the certificate for x*x >= 0 is accepted by lizard's kernel"
  (certspec-check (certspec-order-nonneg-cert)))
(must "the certificate for x*x + 1 >= 0 (add_nonneg over sq_nonneg and one_nonneg) is accepted"
  (certspec-check (certspec-order-sum-cert)))

; a wrong claim has NO valid certificate -- soundness is the kernel's
(must "a bogus certificate claiming 0 >= x*x via the square axiom is REJECTED"
  (not (certspec-check (certspec-make (quote order)
         (cs-ord-Ge (quote ord_zero) (cs-app2 (quote ord_mul) (quote ord_x) (quote ord_x)))
         (cs-app (quote ord_sq_nonneg) (quote ord_x))))))

; the namespacing lets the domain coexist with others in the single global kernel (the scoping fix)
(must "installing the order domain is idempotent (a Lisp-level install-once flag)"
  (and (certspec-install-order!) (certspec-install-order!)))

(newline)
(display "Every future certificate-producing procedure targets ONE shape -- (domain claim proof) -- and") (newline)
(display "certspec-check decides it in lizard's kernel.  Domains are namespaced so many coexist in one kernel") (newline)
(display "environment as non-interfering sub-signatures, the structural fix for the single global signature") (newline)
(display "(certspec-caveat).  No Lean, no Coq, no foreign checker: the kernel doing the checking is lizard's own.") (newline)
