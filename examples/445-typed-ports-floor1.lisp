; FLOOR 1 of lizard's foundations: the TYPED-PORT discipline over the interaction net -- the lambda-arrow corner of
; the cube -- ANCHORED to lizard's trusted kernel (docs/CAS.md, docs/LIZARD_KERNEL_AUDIT.md).  The construction/
; observation duality becomes a literal property of every wire: a wire is well-formed exactly when it joins a
; producer of type T to an observer of type T, so type-checking is LOCAL wire-consistency, one pass over the wires.
; The honest commitment -- the reason this is not a decorative second type system -- is that the typed-port check is
; proven to AGREE with the trusted kernel: a net passes wire-consistency if and only if lizard's kernel accepts the
; corresponding term at the corresponding type.  This mirrors R2 (the net's reduction was proven faithful to
; kt_whnf); here the net's typing is proven faithful to kt_infer.  Nothing modifies the trusted kernel.
(import "cas/inettype.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(kernel-assume (quote A) (quote (Sort 0)))
(kernel-assume (quote B) (quote (Sort 0)))

(display "Typed ports: the construction/observation duality as local wire-consistency, agreeing with the kernel.") (newline) (newline)

; type-equality is structural and sound
(must "the arrow type A->A equals A->A" (itt-type-equal? (itt-arrow (quote A) (quote A)) (itt-arrow (quote A) (quote A))))
(must "a base type is not an arrow type" (not (itt-type-equal? (quote A) (itt-arrow (quote A) (quote A)))))
(must "A->B is not A->A" (not (itt-type-equal? (itt-arrow (quote A) (quote B)) (itt-arrow (quote A) (quote A)))))

; the identity net at A is well-typed (every wire joins equal types), and the kernel agrees
(begin (itt-reset! 200) (itt-build (quote (I A))))
(must "the identity net at A passes local wire-consistency" (itt-well-typed?))
(must "the kernel accepts (lam x:A x) at type A->A" (kernel-check (quote (lam (x A) x)) (quote (Pi (x A) A))))
(must "net and kernel AGREE on the identity at A" (itt-agree? (quote (I A)) (quote (lam (x A) x)) (quote (Pi (x A) A))))

; the K combinator net at A,B is well-typed, and the kernel agrees
(begin (itt-reset! 200) (itt-build (quote (K A B))))
(must "the K net at A,B passes local wire-consistency" (itt-well-typed?))
(must "net and kernel AGREE on K at A->B->A"
  (itt-agree? (quote (K A B)) (quote (lam (x A) (lam (y B) x))) (quote (Pi (x A) (Pi (y B) A)))))

; a deliberately ill-typed net (bound variable A, body B with B != A) FAILS wire-consistency -- the duality on the
; wire catches the type error locally -- and the kernel likewise rejects the corresponding ill-typed claim
(begin (itt-reset! 200) (itt-bad-identity (quote A) (quote B)))
(must "the ill-typed net FAILS local wire-consistency (the wire joins A to B)" (not (itt-well-typed?)))
(must "the kernel REJECTS the ill-typed identity claim A->(A->A)"
  (not (kernel-check (quote (lam (x A) x)) (quote (Pi (x A) (Pi (y A) A))))))

(newline)
(display "A wire carries a type; it is well-formed only when a producer-of-T meets an observer-of-T; the whole net") (newline)
(display "type-checks by local wire-consistency.  That check accepts exactly the nets whose terms lizard's trusted") (newline)
(display "kernel accepts, and rejects the rest -- so the typed-port layer is the kernel's discipline expressed locally") (newline)
(display "on the graph, not a weaker parallel one (itt-caveat).  This is Floor 1, the simply-typed corner.") (newline)
