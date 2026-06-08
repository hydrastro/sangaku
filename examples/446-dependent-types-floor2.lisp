; FLOOR 2 of lizard's foundations: DEPENDENT types over the interaction net -- the first axis of the cube (types
; depending on terms), built SOLID by anchoring entirely to lizard's trusted kernel (docs/LIZARD_KERNEL_AUDIT.md).
; This is where a well-typed net becomes a genuine dependent-type proof.
;
; The honest design.  Floor 1 (simple types) worked because typing was local: a wire carries a fixed type and
; "producer-of-T meets observer-of-T" is checkable one wire at a time.  Dependent types break that locality -- in
; (Pi (x : A) B) the codomain B may mention x, so a port's type depends on the value at another port -- and a naive
; local check would be UNSOUND.  Rather than fake a locality that isn't there, Floor 2 makes the net CARRY the
; dependent derivation and DELEGATES the dependent check to the trusted, audited kernel (kt_infer via kernel-check).
; The net is the proof-term carrier; the kernel is the checker.  Zero new trusted code; the value-dependency is
; handled by machinery already proven sound.  This extends the Floor-1 agreement result to the dependent fragment.
(import "cas/inetdep.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
; a type family F : Nat -> Type and mk : Pi(n:Nat). F n  -- genuinely dependent (result type mentions the argument)
(kernel-assume (quote Nat) (quote (Sort 0)))
(kernel-assume (quote F) (quote (Pi (n Nat) (Sort 0))))
(kernel-assume (quote mk) (quote (Pi (n Nat) (app F n))))

(display "Dependent types: the net carries the derivation, the trusted kernel checks it, and they agree.") (newline) (newline)

; the net-term carrier reads back faithfully to the kernel's term syntax
(define poly-id (itd-lam (quote A) (itd-sort 0) (itd-lam (quote x) (itd-var (quote A)) (itd-var (quote x)))))
(must "the polymorphic identity carrier reads back to (lam (A (Sort 0)) (lam (x A) x))"
  (itd-readback-is? poly-id (quote (lam (A (Sort 0)) (lam (x A) x)))))
(define ty-polyid (itd-pi (quote A) (itd-sort 0) (itd-pi (quote x) (itd-var (quote A)) (itd-var (quote A)))))
(must "the dependent TYPE carrier reads back to (Pi (A (Sort 0)) (Pi (x A) A))"
  (itd-readback-is? ty-polyid (quote (Pi (A (Sort 0)) (Pi (x A) A)))))

; the trusted kernel checks the carrier at the dependent type (delegation)
(must "the kernel accepts the polymorphic identity at (Pi A:U0. Pi x:A. A)"
  (itd-check poly-id (itd-readback ty-polyid)))

; genuine value-dependency: (mk zero) has type (F zero) but NOT (F (succ zero))
(define app-mk-zero (itd-app (itd-const (quote mk)) (itd-const (quote zero))))
(must "(mk zero) reads back to (app mk zero)" (itd-readback-is? app-mk-zero (quote (app mk zero))))
(must "the kernel accepts (mk zero) at type (F zero)" (itd-check app-mk-zero (quote (app F zero))))
(must "the kernel REJECTS (mk zero) at type (F (succ zero)) -- the dependency must match the value"
  (not (itd-check app-mk-zero (quote (app F (succ zero))))))

; the Floor-2 soundness result: the net's verdict EQUALS the kernel's verdict, on acceptance and rejection
(must "net and kernel AGREE: polymorphic identity accepted"
  (itd-agree? poly-id (quote (lam (A (Sort 0)) (lam (x A) x))) (itd-readback ty-polyid)))
(must "net and kernel AGREE: (mk zero) accepted at (F zero)"
  (itd-agree? app-mk-zero (quote (app mk zero)) (quote (app F zero))))
(must "net and kernel AGREE: (mk zero) rejected at (F (succ zero)) (both reject)"
  (itd-agree? app-mk-zero (quote (app mk zero)) (quote (app F (succ zero)))))

(newline)
(display "The net carries the dependent derivation faithfully (readback is exact) and the trusted kernel performs the") (newline)
(display "dependent check; their verdicts agree on both acceptance and the discriminating rejection a naive net-native") (newline)
(display "checker would most likely get wrong.  Dependency is handled by the audited kernel, not by a new unsound local") (newline)
(display "check -- the solid way to add the cube's first axis (itd-caveat).") (newline)
