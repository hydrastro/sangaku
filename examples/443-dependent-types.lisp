; FLOOR 2 of lizard's foundations: a DEPENDENT type checker (lambda-P, the Pi-type corner of the cube), the floor
; where the two-lattice structure becomes operational (docs/CAS.md, docs/LIZARD_FOUNDATIONS.md).  Dependency means
; types can mention terms, which forces the CO-UNIVERSE object into existence: you cannot state a dependent type
; without a CONTEXT of what is in scope, and the judgment Gamma |- a : A is exactly the contravariant pairing of a
; universe element (the construction a : A) against the co-universe element (the observation Gamma).  This is
; lambda-P -- Pi-types, a universe, a context growing under binders, a bidirectional checker with conversion -- and
; it is NOT the full Calculus of Constructions, NOT univalence, NOT HoTT, and does NOT adopt Type : Type (Girard's
; paradox); those are higher floors / deliberately avoided.  Terms use de Bruijn indices.
(import "cas/dtt.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (V n) (list (quote var) n))
(define (LAM T b) (list (quote lam) T b))
(define (PI T b) (list (quote pi) T b))
(define (APP f a) (list (quote app) f a))

(display "Dependent types: Pi-types, a context (the co-universe), a bidirectional checker with conversion.") (newline) (newline)

; de Bruijn substitution and normalization are the foundation
(must "beta normalization: (\\x.x) applied to a term returns that term"
  (dtt-equal? (APP (LAM (quote type) (V 0)) (V 3)) (V 3)))
(must "conversion compares up to normalization"
  (dtt-equal? (APP (LAM (quote type) (V 0)) (quote type)) (quote type)))

; the identity on a variable type, in a context [A : Type]
(must "in context [A:Type], (\\x:A. x) infers the type A -> A"
  (dtt-equal? (dtt-infer (list (quote type)) (LAM (V 0) (V 0))) (PI (V 0) (V 1))))

; the polymorphic identity, the milestone of dependency
(define polyId (LAM (quote type) (LAM (V 0) (V 0))))
(define polyIdType (PI (quote type) (PI (V 0) (V 1))))
(must "the polymorphic identity /\\A:Type. \\x:A. x infers (A:Type) -> A -> A"
  (dtt-equal? (dtt-infer (quote ()) polyId) polyIdType))
(must "and it checks against that dependent type" (dtt-check (quote ()) polyId polyIdType))

; DEPENDENCY IN ACTION: applying the polymorphic identity to a type computes the instance by substitution
(define someType (PI (quote type) (quote type)))         ; Type -> Type, a closed type
(must "(pi type type) is a well-formed type" (dtt-is-type? (quote ()) someType))
(must "applying polyId to (Type->Type) yields (Type->Type) -> (Type->Type) by substitution in the Pi codomain"
  (dtt-equal? (dtt-infer (quote ()) (APP polyId someType)) (PI someType someType)))

; the checker REJECTS ill-typed terms -- a checker that rejects is a real checker
(must "applying a non-function (app type type) is ill-typed"
  (equal? (dtt-infer (quote ()) (APP (quote type) (quote type))) (quote ill-typed)))
(must "an out-of-scope variable is ill-typed"
  (equal? (dtt-infer (quote ()) (V 0)) (quote ill-typed)))
(must "the identity \\x:A.x does NOT check as the wrong type (pi A Type)"
  (not (dtt-check (list (quote type)) (LAM (V 0) (V 0)) (PI (V 0) (quote type)))))
(must "applying a function to a wrong-typed argument is ill-typed"
  (equal? (dtt-infer (list (quote type) (quote type)) (APP (LAM (V 1) (V 0)) (V 0))) (quote ill-typed)))

(newline)
(display "The context grows as the checker enters binders -- that growing context is the co-universe lattice, and the") (newline)
(display "judgment Gamma |- a : A is its contravariant pairing with the term.  Pi-types whose codomain mentions the") (newline)
(display "bound variable are checked, applications compute the result type by substitution, and ill-typed terms are") (newline)
(display "rejected.  This is the dependent corner of the cube -- one more floor, verified; the Calculus of Constructions,") (newline)
(display "univalence, and HoTT remain higher floors (dtt-caveat).") (newline)
