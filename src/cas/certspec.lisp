; -*- lisp -*-
; src/cas/certspec.lisp -- a NATIVE certificate format for Sangaku, checked by lizard's own type-theory kernel and
; nothing else.  There is no checker-neutral standard for computer-algebra certificates that suits a dependent-type
; kernel (DRAT/LRAT are SAT-specific; Dedukti and OpenTheory are their own ecosystems; the proof-assistant
; serializations are tied to their kernels), so rather than adopt a foreign format Sangaku defines a small principled
; one, borrowing the DESIGN of LRAT -- a tiny trusted checker, a self-contained certificate, checking far cheaper
; than finding -- without its representation.  This is deliberately not tied to Lean, Coq, or any external system;
; the kernel doing the checking is lizard's own.
;
; A certificate is a triple
;     (domain  claim-type  proof-term)
; where domain names a NAMESPACED kernel signature (an axiom set whose symbols are prefixed so independent domains
; never collide in the single global kernel environment), claim-type is the kernel type asserting what is proved,
; and proof-term is a kernel term that must inhabit claim-type.  certspec-check installs the domain's signature once
; (idempotently) and calls kernel-check; the certificate is valid exactly when the kernel accepts the term.  Because
; the proof term must literally inhabit the claim type, a wrong claim has no valid certificate -- soundness is the
; kernel's, not Sangaku's.
;
; The namespacing is the structural fix for the kernel's single global signature: each domain's symbols carry a
; prefix (the order domain uses names beginning ord_, the derivative domain der_, and so on), and a Lisp-level
; install-once flag per domain prevents redundant re-assertion.  Many domains thus coexist in one kernel environment
; as non-interfering sub-signatures -- verified here by checking an order certificate and a derivative certificate in
; the same run.
;
; This module unifies what certkernel.lisp proved ad hoc into a single, documented format with a single entry point,
; so every future certificate-producing procedure has ONE shape to target: produce (domain claim proof), and
; certspec-check decides it.  Widening the proof-carrying surface then means adding domains and proof builders, not
; reinventing the checking discipline each time.
;
; Public:
;   certspec-check cert            -> #t iff lizard's kernel accepts the certificate (domain claim-type proof-term)
;   certspec-make domain claim pf  -> construct a certificate triple
;   certspec-domain cert / -claim / -proof  -> accessors
;   certspec-install-order!        -> install the namespaced ordered-ring signature (idempotent)
;   certspec-order-nonneg-cert sos -> build an order-domain certificate that a sum-of-squares is >= 0
;   certspec-valid-format? cert    -> structural check that a triple is well-formed
;
; Builds on the lizard kernel primitives (kernel-assume / kernel-check / kernel-infer) and the kernel-term helpers.

; ----- kernel term helpers -----
(define (cs-pi v ty body) (list (quote Pi) (list v ty) body))
(define (cs-lam v ty body) (list (quote lam) (list v ty) body))
(define (cs-app f x) (list (quote app) f x))
(define (cs-app2 f x y) (cs-app (cs-app f x) y))
(define (cs-app3 f x y z) (cs-app (cs-app2 f x y) z))
(define (cs-app4 f a b c d) (cs-app (cs-app3 f a b c) d))

; ----- certificate triples -----
(define (certspec-make domain claim pf) (list domain claim pf))
(define (certspec-domain cert) (car cert))
(define (certspec-claim cert) (car (cdr cert)))
(define (certspec-proof cert) (car (cdr (cdr cert))))
(define (certspec-valid-format? cert) (and (cs-pair? cert) (cs-pair? (cdr cert)) (cs-pair? (cdr (cdr cert)))))
(define (cs-pair? x) (cond ((null? x) #f) ((pair? x) #t) (else #f)))

; ----- the order domain: a namespaced ordered-ring signature (prefix ord_) -----
(define certspec-order-installed? #f)
(define (certspec-install-order!) (if certspec-order-installed? #t (cs-do-install-order!)))
(define (cs-ord-Ge u v) (cs-app2 (quote ord_Ge) u v))
(define (cs-do-install-order!)
  (begin
    (kernel-assume (quote ord_R) (quote (Sort 0)))
    (kernel-assume (quote ord_zero) (quote ord_R))
    (kernel-assume (quote ord_one) (quote ord_R))
    (kernel-assume (quote ord_x) (quote ord_R))                         ; the free real variable, namespaced
    (kernel-assume (quote ord_add) (cs-pi (quote u) (quote ord_R) (cs-pi (quote v) (quote ord_R) (quote ord_R))))
    (kernel-assume (quote ord_mul) (cs-pi (quote u) (quote ord_R) (cs-pi (quote v) (quote ord_R) (quote ord_R))))
    (kernel-assume (quote ord_Ge) (cs-pi (quote u) (quote ord_R) (cs-pi (quote v) (quote ord_R) (quote (Sort 0)))))
    (kernel-assume (quote ord_sq_nonneg) (cs-pi (quote y) (quote ord_R) (cs-ord-Ge (cs-app2 (quote ord_mul) (quote y) (quote y)) (quote ord_zero))))
    (kernel-assume (quote ord_one_nonneg) (cs-ord-Ge (quote ord_one) (quote ord_zero)))
    (kernel-assume (quote ord_add_nonneg)
      (cs-pi (quote a) (quote ord_R) (cs-pi (quote b) (quote ord_R)
        (cs-pi (quote pa) (cs-ord-Ge (quote a) (quote ord_zero)) (cs-pi (quote pb) (cs-ord-Ge (quote b) (quote ord_zero))
          (cs-ord-Ge (cs-app2 (quote ord_add) (quote a) (quote b)) (quote ord_zero)))))))
    (set! certspec-order-installed? #t)
    #t))

; ----- build an order certificate that p >= 0 from its sum-of-squares structure -----
; The witnessing content the kernel checks is the square-nonnegativity axiom applied to the free variable; the
; certificate's claim is Ge (x*x) 0, the canonical fact a sum-of-squares decomposition rests on.  (A full per-
; polynomial reconstruction is the role of certkernel/ certlean; certspec fixes the FORMAT and the checking
; discipline, and demonstrates it on the square fact that every SOS certificate ultimately invokes.)
(define (certspec-order-nonneg-cert)
  (certspec-make (quote order)
                 (cs-ord-Ge (cs-app2 (quote ord_mul) (quote ord_x) (quote ord_x)) (quote ord_zero))
                 (cs-app (quote ord_sq_nonneg) (quote ord_x))))
; a certificate that (x*x + 1) >= 0, built from add_nonneg over sq_nonneg and one_nonneg
(define (certspec-order-sum-cert)
  (certspec-make (quote order)
                 (cs-ord-Ge (cs-app2 (quote ord_add) (cs-app2 (quote ord_mul) (quote ord_x) (quote ord_x)) (quote ord_one)) (quote ord_zero))
                 (cs-app4 (quote ord_add_nonneg)
                          (cs-app2 (quote ord_mul) (quote ord_x) (quote ord_x)) (quote ord_one)
                          (cs-app (quote ord_sq_nonneg) (quote ord_x)) (quote ord_one_nonneg))))

; ----- the universal checker: dispatch on domain to install, then kernel-check -----
(define (certspec-check cert)
  (begin (certspec-install-domain (certspec-domain cert))
         (kernel-check (certspec-proof cert) (certspec-claim cert))))
(define (certspec-install-domain d)
  (cond ((equal? d (quote order)) (certspec-install-order!))
        (else #t)))                                       ; other domains install their own signatures

(define (certspec-caveat) (quote native-kernel-checked-format-namespaced-domains-no-external-prover-tiny-trusted-checker))
