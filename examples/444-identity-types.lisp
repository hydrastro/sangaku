; FLOOR 3 of lizard's foundations: INTENSIONAL IDENTITY TYPES over the dependent type checker (docs/CAS.md,
; docs/LIZARD_FOUNDATIONS.md).  This is the DOORWAY to the homotopy reading of type theory -- the type (Id A x y)
; of proofs that x equals y, with the J eliminator (path induction) giving equalities computational force.  HONEST
; SCOPE: this is intensional Martin-Lof identity types, the floor UNDER Homotopy Type Theory, NOT HoTT.  Univalence
; is NOT added (it is an axiom beyond J), higher inductive types are NOT added, and Type : Type is NOT adopted.
; What is verified here are the four rules (formation, introduction, J-elimination, J-computation) and two theorems
; -- symmetry and transport -- genuinely DERIVED from J, not postulated.
(import "cas/idt.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (V n) (list (quote var) n))

(display "Identity types: formation, refl, the J eliminator, and symmetry + transport derived from J.") (newline) (newline)

; context [A:type, a:A], innermost first: a:(var 0) is A, A:type
(define ctxAa (list (V 0) (quote type)))    ; A = var 1, a = var 0
(must "FORMATION: Id A a a is a type" (idt-equal? (idt-infer ctxAa (idt-Id (V 1) (V 0) (V 0))) (quote type)))
(must "INTRODUCTION: refl A a has type Id A a a"
  (idt-check ctxAa (idt-refl (V 1) (V 0)) (idt-Id (V 1) (V 0) (V 0))))

; the J-computation rule: J A P d a a (refl A a) reduces to (d a) -- the subtle heart
(define A1 (V 1))
(define motive (list (quote lam) A1 (list (quote lam) (idt-shift 1 0 A1) (list (quote lam) (idt-Id (idt-shift 2 0 A1) (V 1) (V 0)) (idt-Id (idt-shift 3 0 A1) (V 2) (V 2))))))
(define base (list (quote lam) A1 (idt-refl (idt-shift 1 0 A1) (V 0))))
(must "J-COMPUTATION: J A P d a a (refl A a) reduces to (d a)"
  (idt-equal? (idt-J A1 motive base (V 0) (V 0) (idt-refl A1 (V 0))) (list (quote app) base (V 0))))

; SYMMETRY derived via J, in context [A:type, x:A, y:A, p:Id A x y]
(define ctx (list (idt-Id (V 2) (V 1) (V 0)) (V 1) (V 0) (quote type)))   ; A=v3, x=v2, y=v1, p=v0
(must "SYMMETRY (derived from J): from p : Id A x y, sym infers Id A y x"
  (idt-equal? (idt-infer ctx (idt-sym (V 3) (V 2) (V 1) (V 0))) (idt-Id (V 3) (V 1) (V 2))))
(must "and sym checks against Id A y x" (idt-check ctx (idt-sym (V 3) (V 2) (V 1) (V 0)) (idt-Id (V 3) (V 1) (V 2))))
(must "SYMMETRY computes: sym of (refl A a) normalizes to (refl A a)"
  (idt-equal? (idt-sym (V 1) (V 0) (V 0) (idt-refl (V 1) (V 0))) (idt-refl (V 1) (V 0))))

; TRANSPORT derived via J, in [A:type, Pf:A->type, x:A, y:A, p:Id A x y, u:Pf x]
(define ctxT (list (list (quote app) (V 3) (V 2)) (idt-Id (V 3) (V 1) (V 0)) (V 2) (V 1) (list (quote pi) (V 0) (quote type)) (quote type)))
; A=v5, Pf=v4, x=v3, y=v2, p=v1, u=v0
(must "TRANSPORT (derived from J): from p : Id A x y and u : Pf x, transport infers Pf y"
  (idt-equal? (idt-infer ctxT (idt-transport (V 5) (V 4) (V 3) (V 2) (V 1) (V 0))) (list (quote app) (V 4) (V 2))))

; transport along refl is the identity (the computation rule propagating through transport)
(define ctxR (list (list (quote app) (V 2) (V 1)) (V 1) (list (quote pi) (V 0) (quote type)) (quote type)))  ; A=v3,Pf=v2,a=v1,u=v0
(must "TRANSPORT along refl is the identity: transport(refl, u) normalizes to u"
  (idt-equal? (idt-transport (V 3) (V 2) (V 1) (V 1) (idt-refl (V 3) (V 1)) (V 0)) (V 0)))

(newline)
(display "The four rules hold, J computes (collapsing to the base case on refl), and symmetry and transport are") (newline)
(display "DERIVED from J -- genuinely proved by constructing J-terms the checker accepts, not postulated.  This is the") (newline)
(display "doorway to the homotopy reading: a path is a construction, J is its observation.  It is intensional identity") (newline)
(display "types -- the floor UNDER HoTT; univalence and higher inductive types are not added (idt-caveat).") (newline)
