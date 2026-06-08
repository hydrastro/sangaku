; -*- lisp -*-
; src/cas/idt.lisp -- FLOOR 3 of lizard's foundations: INTENSIONAL IDENTITY TYPES over the dependent type checker
; (dtt.lisp).  This is the DOORWAY to the homotopy reading of type theory -- the type (Id A x y) of proofs that x
; equals y, where "types are spaces and equalities are paths" begins.  Without identity types there is no homotopy
; content; with them, equalities can be stated and proved INSIDE the system, and the J eliminator (path induction)
; is what gives them computational force.
;
; HONEST SCOPE, stated up front: this is INTENSIONAL Martin-Lof identity types -- the floor UNDER Homotopy Type
; Theory, not HoTT itself.  UNIVALENCE (the axiom that equivalent types are equal) is NOT added; it is an axiom
; beyond J and would have to be postulated, which is not done here.  Higher inductive types are NOT added.  What IS
; here -- and verified -- are the four rules of identity types and two theorems DERIVED from them (symmetry and
; transport), genuinely proved via J rather than postulated.
;
; THE FOUR RULES:
;   FORMATION    : A:Type, x:A, y:A  =>  (id A x y) : Type
;   INTRODUCTION : a:A               =>  (refl A a) : (id A a a)
;   ELIMINATION  (J, path induction): given a motive P : (x:A)(y:A)(p:id A x y)->Type and a base
;                  d : (x:A) -> P x x (refl A x), then for x,y:A and p:id A x y,  (jj A P d x y p) : P x y p
;   COMPUTATION  : (jj A P d x x (refl A x))  reduces to  (d applied to x)   -- the rule that makes J compute
;
; The J-computation rule is the subtle heart: when the equality is reflexivity, J collapses to the base case.  Its
; correctness is the whole game, so the accompanying example verifies it by normalization and derives symmetry and
; transport from it.
;
; This extends dtt.lisp's de Bruijn term language with three new formers and adds their typing and the J reduction.
;
; Public:
;   idt-Id A x y         -> the identity type former (id A x y)
;   idt-refl A a         -> (refl A a)
;   idt-J A P d x y p    -> the J eliminator (jj A P d x y p)
;   idt-normalize term   -> normalization including the J-computation rule
;   idt-infer ctx term   -> type inference extended with Id/refl/J
;   idt-check ctx term ty -> checking
;   idt-sym A x y p       -> a TERM proving (id A y x) from p:(id A x y), built via J (symmetry, derived)
;   idt-transport A P x y p u -> transport u:(P x) along p:(id A x y) to (P y), built via J (derived)

(import "cas/dtt.lisp")

; ---------- new term formers ----------
(define (idt-Id A x y) (list (quote id) A x y))
(define (idt-refl A a) (list (quote refl) A a))
(define (idt-J A P d x y p) (list (quote jj) A P d x y p))
(define (idt-id? t)   (and (pair? t) (equal? (car t) (quote id))))
(define (idt-refl? t) (and (pair? t) (equal? (car t) (quote refl))))
(define (idt-jj? t)   (and (pair? t) (equal? (car t) (quote jj))))
(define (id-A t) (car (cdr t)))
(define (id-x t) (car (cdr (cdr t))))
(define (id-y t) (car (cdr (cdr (cdr t)))))
(define (refl-A t) (car (cdr t)))
(define (refl-a t) (car (cdr (cdr t))))
(define (jj-A t) (list-ref t 1))
(define (jj-P t) (list-ref t 2))
(define (jj-d t) (list-ref t 3))
(define (jj-x t) (list-ref t 4))
(define (jj-y t) (list-ref t 5))
(define (jj-p t) (list-ref t 6))

; ---------- shift extended to the new formers ----------
(define (idt-shift d c t)
  (cond ((idt-id? t)   (list (quote id)   (idt-shift d c (id-A t)) (idt-shift d c (id-x t)) (idt-shift d c (id-y t))))
        ((idt-refl? t) (list (quote refl) (idt-shift d c (refl-A t)) (idt-shift d c (refl-a t))))
        ((idt-jj? t)   (list (quote jj) (idt-shift d c (jj-A t)) (idt-shift d c (jj-P t)) (idt-shift d c (jj-d t)) (idt-shift d c (jj-x t)) (idt-shift d c (jj-y t)) (idt-shift d c (jj-p t))))
        ((dtt-var? t) (if (< (dtt-vn t) c) t (list (quote var) (+ (dtt-vn t) d))))
        ((dtt-lam? t) (list (quote lam) (idt-shift d c (dtt-dom t)) (idt-shift d (+ c 1) (dtt-body t))))
        ((dtt-pi? t)  (list (quote pi)  (idt-shift d c (dtt-dom t)) (idt-shift d (+ c 1) (dtt-body t))))
        ((dtt-app? t) (list (quote app) (idt-shift d c (dtt-fn t)) (idt-shift d c (dtt-arg t))))
        (else t)))

; ---------- substitution extended ----------
(define (idt-subst j s t)
  (cond ((idt-id? t)   (list (quote id)   (idt-subst j s (id-A t)) (idt-subst j s (id-x t)) (idt-subst j s (id-y t))))
        ((idt-refl? t) (list (quote refl) (idt-subst j s (refl-A t)) (idt-subst j s (refl-a t))))
        ((idt-jj? t)   (list (quote jj) (idt-subst j s (jj-A t)) (idt-subst j s (jj-P t)) (idt-subst j s (jj-d t)) (idt-subst j s (jj-x t)) (idt-subst j s (jj-y t)) (idt-subst j s (jj-p t))))
        ((dtt-var? t) (cond ((= (dtt-vn t) j) s) ((> (dtt-vn t) j) (list (quote var) (- (dtt-vn t) 1))) (else t)))
        ((dtt-lam? t) (list (quote lam) (idt-subst j s (dtt-dom t)) (idt-subst (+ j 1) (idt-shift 1 0 s) (dtt-body t))))
        ((dtt-pi? t)  (list (quote pi)  (idt-subst j s (dtt-dom t)) (idt-subst (+ j 1) (idt-shift 1 0 s) (dtt-body t))))
        ((dtt-app? t) (list (quote app) (idt-subst j s (dtt-fn t)) (idt-subst j s (dtt-arg t))))
        (else t)))

; ---------- normalization with the J-computation rule ----------
(define (idt-normalize t) (idt-nf t 0))
(define (idt-nf t guard)
  (cond ((> guard 100000) t)
        ((idt-id? t)   (list (quote id)   (idt-nf (id-A t) (+ guard 1)) (idt-nf (id-x t) (+ guard 1)) (idt-nf (id-y t) (+ guard 1))))
        ((idt-refl? t) (list (quote refl) (idt-nf (refl-A t) (+ guard 1)) (idt-nf (refl-a t) (+ guard 1))))
        ((idt-jj? t)   (idt-nf-jj t guard))
        ((dtt-var? t) t)
        ((dtt-type? t) t)
        ((dtt-lam? t) (list (quote lam) (idt-nf (dtt-dom t) (+ guard 1)) (idt-nf (dtt-body t) (+ guard 1))))
        ((dtt-pi? t)  (list (quote pi)  (idt-nf (dtt-dom t) (+ guard 1)) (idt-nf (dtt-body t) (+ guard 1))))
        ((dtt-app? t) (idt-nf-app (idt-nf (dtt-fn t) (+ guard 1)) (idt-nf (dtt-arg t) (+ guard 1)) guard))
        (else t)))
(define (idt-nf-app f a guard)
  (cond ((dtt-lam? f) (idt-nf (idt-subst 0 a (dtt-body f)) (+ guard 1)))
        (else (list (quote app) f a))))
; J-computation: normalize all parts; if p is (refl A x) then J reduces to (app d x); else stuck
(define (idt-nf-jj t guard)
  (let ((nA (idt-nf (jj-A t) (+ guard 1))) (nP (idt-nf (jj-P t) (+ guard 1))) (nd (idt-nf (jj-d t) (+ guard 1)))
        (nx (idt-nf (jj-x t) (+ guard 1))) (ny (idt-nf (jj-y t) (+ guard 1))) (np (idt-nf (jj-p t) (+ guard 1))))
    (cond ((idt-refl? np) (idt-nf (list (quote app) nd (refl-a np)) (+ guard 1)))   ; J A P d x x (refl A x) -> d x
          (else (list (quote jj) nA nP nd nx ny np)))))

; ---------- conversion ----------
(define (idt-equal? s t) (idt-struct-eq? (idt-normalize s) (idt-normalize t)))
(define (idt-struct-eq? s t)
  (cond ((and (idt-id? s) (idt-id? t)) (and (idt-struct-eq? (id-A s) (id-A t)) (idt-struct-eq? (id-x s) (id-x t)) (idt-struct-eq? (id-y s) (id-y t))))
        ((and (idt-refl? s) (idt-refl? t)) (and (idt-struct-eq? (refl-A s) (refl-A t)) (idt-struct-eq? (refl-a s) (refl-a t))))
        ((and (idt-jj? s) (idt-jj? t)) (and (idt-struct-eq? (jj-A s) (jj-A t)) (idt-struct-eq? (jj-P s) (jj-P t)) (idt-struct-eq? (jj-d s) (jj-d t)) (idt-struct-eq? (jj-x s) (jj-x t)) (idt-struct-eq? (jj-y s) (jj-y t)) (idt-struct-eq? (jj-p s) (jj-p t))))
        ((and (dtt-var? s) (dtt-var? t)) (= (dtt-vn s) (dtt-vn t)))
        ((and (dtt-type? s) (dtt-type? t)) #t)
        ((and (dtt-lam? s) (dtt-lam? t)) (and (idt-struct-eq? (dtt-dom s) (dtt-dom t)) (idt-struct-eq? (dtt-body s) (dtt-body t))))
        ((and (dtt-pi? s) (dtt-pi? t)) (and (idt-struct-eq? (dtt-dom s) (dtt-dom t)) (idt-struct-eq? (dtt-body s) (dtt-body t))))
        ((and (dtt-app? s) (dtt-app? t)) (and (idt-struct-eq? (dtt-fn s) (dtt-fn t)) (idt-struct-eq? (dtt-arg s) (dtt-arg t))))
        (else #f)))

; ---------- type inference extended ----------
(define (idt-infer ctx t)
  (cond ((idt-id? t)   (idt-infer-id ctx t))
        ((idt-refl? t) (idt-infer-refl ctx t))
        ((idt-jj? t)   (idt-infer-jj ctx t))
        ((dtt-var? t) (let ((ty (dtt-ctx-lookup ctx (dtt-vn t)))) (cond ((equal? ty (quote out-of-scope)) (quote ill-typed)) (else (idt-shift (+ (dtt-vn t) 1) 0 ty)))))
        ((dtt-type? t) (quote type))
        ((dtt-pi? t) (idt-infer-pi ctx t))
        ((dtt-lam? t) (idt-infer-lam ctx t))
        ((dtt-app? t) (idt-infer-app ctx t))
        (else (quote ill-typed))))
; Id A x y : type   provided A:type, x:A, y:A
(define (idt-infer-id ctx t)
  (cond ((not (idt-is-type? ctx (id-A t))) (quote ill-typed))
        ((not (idt-check ctx (id-x t) (id-A t))) (quote ill-typed))
        ((not (idt-check ctx (id-y t) (id-A t))) (quote ill-typed))
        (else (quote type))))
; refl A a : (id A a a)   provided a:A
(define (idt-infer-refl ctx t)
  (cond ((not (idt-is-type? ctx (refl-A t))) (quote ill-typed))
        ((not (idt-check ctx (refl-a t) (refl-A t))) (quote ill-typed))
        (else (list (quote id) (refl-A t) (refl-a t) (refl-a t)))))
; J: motive P : (x:A)(y:A)(id A x y)->type ; base d : (x:A) -> P x x (refl A x) ; result P x y p
; We check P and d have the right (dependent) types, then return (P x y p) as the result type.
(define (idt-infer-jj ctx t)
  (let ((A (jj-A t)) (P (jj-P t)) (d (jj-d t)) (x (jj-x t)) (y (jj-y t)) (p (jj-p t)))
    (cond ((not (idt-is-type? ctx A)) (quote ill-typed))
          ((not (idt-check ctx x A)) (quote ill-typed))
          ((not (idt-check ctx y A)) (quote ill-typed))
          ((not (idt-check ctx p (list (quote id) A x y))) (quote ill-typed))
          ((not (idt-check-motive ctx A P)) (quote ill-typed))
          ((not (idt-check-base ctx A P d)) (quote ill-typed))
          (else (idt-apply-motive P x y p)))))
; the result type is P applied to x, y, p (P is a triple-argument function term)
(define (idt-apply-motive P x y p) (idt-normalize (list (quote app) (list (quote app) (list (quote app) P x) y) p)))
; motive P must have type (pi A (pi A' (pi (id A var1 var0) type)))  -- three nested Pis ending in type
(define (idt-check-motive ctx A P)
  (let ((expected (list (quote pi) A (list (quote pi) (idt-shift 1 0 A) (list (quote pi) (list (quote id) (idt-shift 2 0 A) (list (quote var) 1) (list (quote var) 0)) (quote type))))))
    (idt-check ctx P expected)))
; base d must have type (pi A (P var0 var0 (refl A var0)))
(define (idt-check-base ctx A P d)
  (let ((expected (list (quote pi) A (idt-apply-motive-open (idt-shift 1 0 P) (list (quote var) 0) (list (quote var) 0) (list (quote refl) (idt-shift 1 0 A) (list (quote var) 0))))))
    (idt-check ctx d expected)))
(define (idt-apply-motive-open P x y p) (list (quote app) (list (quote app) (list (quote app) P x) y) p))
; Pi/lam/app reuse dtt's logic but must route through idt-infer for the new formers; reimplement minimally
(define (idt-infer-pi ctx t)
  (cond ((not (idt-is-type? ctx (dtt-dom t))) (quote ill-typed))
        ((not (idt-is-type? (cons (dtt-dom t) ctx) (dtt-body t))) (quote ill-typed))
        (else (quote type))))
(define (idt-infer-lam ctx t)
  (cond ((not (idt-is-type? ctx (dtt-dom t))) (quote ill-typed))
        (else (let ((bt (idt-infer (cons (dtt-dom t) ctx) (dtt-body t))))
                (cond ((equal? bt (quote ill-typed)) (quote ill-typed)) (else (list (quote pi) (dtt-dom t) bt)))))))
(define (idt-infer-app ctx t)
  (let ((ft (idt-normalize (idt-infer ctx (dtt-fn t)))))
    (cond ((equal? ft (quote ill-typed)) (quote ill-typed))
          ((not (dtt-pi? ft)) (quote ill-typed))
          ((not (idt-check ctx (dtt-arg t) (dtt-dom ft))) (quote ill-typed))
          (else (idt-subst 0 (dtt-arg t) (dtt-body ft))))))
(define (idt-check ctx t expected)
  (let ((inferred (idt-infer ctx t))) (cond ((equal? inferred (quote ill-typed)) #f) (else (idt-equal? inferred expected)))))
(define (idt-is-type? ctx t) (cond ((dtt-type? t) #t) (else (equal? (idt-normalize (idt-infer ctx t)) (quote type)))))

; ---------- DERIVED theorems (built via J, genuinely proved, not postulated) ----------
; SYMMETRY: from p : (id A x y) produce a term of type (id A y x).
;   motive P = \x.\y.\p. (id A y x)   ;  base d = \x. (refl A x) : (id A x x) = P x x (refl)
;   sym = J A P d x y p : P x y p = (id A y x)
(define (idt-sym A x y p)
  (let ((P (list (quote lam) A (list (quote lam) (idt-shift 1 0 A) (list (quote lam) (list (quote id) (idt-shift 2 0 A) (list (quote var) 1) (list (quote var) 0)) (list (quote id) (idt-shift 3 0 A) (list (quote var) 1) (list (quote var) 2))))))
        (d (list (quote lam) A (list (quote refl) (idt-shift 1 0 A) (list (quote var) 0)))))
    (list (quote jj) A P d x y p)))
; TRANSPORT: given Pf : A -> type (a type family), p : (id A x y), u : (Pf x), produce (Pf y).
;   motive P = \x.\y.\_. (Pf x) -> (Pf y)  [a function type]; base d = \x. \u. u : (Pf x)->(Pf x)
;   transport = (J A P d x y p) applied to u
(define (idt-transport A Pf x y p u)
  (let ((P (list (quote lam) A (list (quote lam) (idt-shift 1 0 A) (list (quote lam) (list (quote id) (idt-shift 2 0 A) (list (quote var) 1) (list (quote var) 0)) (list (quote pi) (list (quote app) (idt-shift 3 0 Pf) (list (quote var) 2)) (list (quote app) (idt-shift 4 0 Pf) (list (quote var) 2)))))))
        (d (list (quote lam) A (list (quote lam) (list (quote app) (idt-shift 1 0 Pf) (list (quote var) 0)) (list (quote var) 0)))))
    (list (quote app) (list (quote jj) A P d x y p) u)))

(define (idt-caveat) (quote floor3-intensional-identity-types-J-path-induction-sym-transport-derived-NOT-univalence-NOT-HoTT))
