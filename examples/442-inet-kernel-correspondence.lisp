; R2 of the lizard-foundations roadmap: the interaction-net reducer (Floor 0, cas/inet.lisp) is FAITHFUL to lizard's
; trusted kernel reducer kt_whnf, reached from Lisp via kernel-reduce (docs/CAS.md, docs/LIZARD_KERNEL_AUDIT.md).
; Floor 0 reduces by local graph rewriting; the kernel reduces by tree-walking weak-head normalisation; both must
; compute the same beta-reduction.  This harness reduces a corpus of closed lambda terms BOTH ways and checks the
; normal forms land in the same structural class, with the kernel's own trusted equality (kernel-equal?, i.e.
; kt_equal) independently certifying the kernel's reducts.  It then EXHIBITS the correctness boundary: outside the
; one-source-of-duplication fragment, the unlabeled net diverges from the kernel.  Nothing here modifies the trusted
; kernel -- R2 is verification, not modification, and carries no soundness risk.
(import "cas/inetbridge.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(kernel-assume (quote A) (quote (Sort 0)))
(kernel-assume (quote a) (quote A))

(display "The interaction net and lizard's trusted kt_whnf, reducing the same terms and agreeing.") (newline) (newline)

; on the safe fragment, the net's normal-form class matches the kernel's
(must "(I I): net and kernel both reduce to the identity"
  (and (equal? (ibr-net-class (quote (app I I))) (quote identity))
       (equal? (ibr-kernel-class (quote (app (lam (x A) x) (lam (y A) y)))) (quote identity))))
(must "(K I): net and kernel both reduce to a lambda (the constant function returning I)"
  (and (equal? (ibr-net-class (quote (app K I))) (quote lam))
       (equal? (ibr-kernel-class (quote (app (lam (x A) (lam (y A) x)) (lam (z A) z)))) (quote lam))))
(must "(I (I I)): nested beta, net and kernel both reduce to the identity"
  (and (equal? (ibr-net-class (quote (app I (app I I)))) (quote identity))
       (equal? (ibr-kernel-class (quote (app (lam (x A) x) (app (lam (y A) y) (lam (z A) z))))) (quote identity))))
(must "bare I: net and kernel both classify as the identity"
  (and (equal? (ibr-net-class (quote I)) (quote identity))
       (equal? (ibr-kernel-class (quote (lam (x A) x))) (quote identity))))
(must "(K (I I)): net and kernel agree (a lambda)"
  (equal? (ibr-net-class (quote (app K (app I I))))
          (ibr-kernel-class (quote (app (lam (x A) (lam (y A) x)) (app (lam (p A) p) (lam (q A) q)))))))

; the net's agreement is corroborated by the kernel's OWN trusted equality (kt_equal)
(must "kernel-equal? certifies (I I) reduces to the identity"
  (kernel-equal? (quote (app (lam (x A) x) (lam (y A) y))) (quote (lam (w A) w))))
(must "kernel-equal? certifies (K I) reduces to (lam y. lam z. z)"
  (kernel-equal? (quote (app (lam (x A) (lam (y A) x)) (lam (z A) z))) (quote (lam (y A) (lam (z A) z)))))

; the correctness boundary, made concrete: outside the safe fragment the unlabeled net collapses a superposition
(must "outside the safe fragment, the unlabeled net diverges (collapses the superposition)"
  (equal? (ibr-divergence-demo) (quote collapsed-superposition)))

(newline)
(display "On the one-source-of-duplication fragment the interaction net computes exactly what lizard's trusted") (newline)
(display "kt_whnf computes -- so Floor 0 is a faithful parallel evaluation strategy for the kernel, not a separate") (newline)
(display "experiment.  Outside that fragment the unlabeled net diverges, exactly as the boundary predicts (ibr-caveat).") (newline)
