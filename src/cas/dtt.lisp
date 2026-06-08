; -*- lisp -*-
; src/cas/dtt.lisp -- FLOOR 2 of lizard's foundations: a DEPENDENT type checker (lambda-P, the Pi-type corner of
; the cube of features), the floor where the two-lattice structure becomes operational.  Floors 0-1 (inet, stnet)
; gave bare reduction and a simply-typed discipline on the net substrate; this floor adds DEPENDENCY -- types that
; mention terms -- which forces the co-universe object into existence: you cannot even state a dependent type without
; a CONTEXT of what is in scope.  The judgment Gamma |- a : A is exactly the contravariant pairing of a universe
; element (the construction a : A) against a co-universe element (the observation Gamma).
;
; WHAT THIS IS: lambda-P -- Pi-types, a universe, a context that grows under binders, and a bidirectional checker
; with conversion (type equality up to normalization).  The four agent ROLES of Floors 0-1 get their dependent
; typing rules: lam/app are the LAM/APP agents, pi is the type of a lam, the universe is where types live.
;
; WHAT THIS IS NOT (stated plainly, not claimed): not the full Calculus of Constructions (the polymorphism and
; type-operator axes are not added here), not univalence, not higher inductive types, not HoTT.  Those are higher
; floors.  CONSISTENCY: we do NOT adopt Type : Type (that is Girard's paradox, inconsistent); the universe is
; predicative and a closed term is checked against a type without the universe typing itself.  A full stratified
; universe hierarchy is future work; here Type is a single sort used to classify types, and we never derive
; Type : Type as a usable judgment for encoding paradoxes (the checker treats the universe as a top sort).
;
; REPRESENTATION: de Bruijn INDICES (nameless terms), the standard choice that makes substitution capture-free and
; alpha-equality syntactic.  Terms:
;   (var n)        de Bruijn index n (0 = innermost bound variable)
;   (lam T b)      lambda with domain type T; b is the body, using (var 0) for the bound variable
;   (app f a)      application
;   (pi T b)       dependent function type (x : T) -> b, where b may mention (var 0)
;   type           the universe
;
; Public:
;   dtt-shift d c term         -> lift free variables (index >= c) by d
;   dtt-subst j s term         -> substitute term s for (var j)
;   dtt-normalize term         -> beta normal form
;   dtt-equal? s t             -> conversion: equal up to normalization
;   dtt-infer ctx term         -> the inferred type (ctx = list of types, innermost first), or 'ill-typed
;   dtt-check ctx term type    -> #t iff term checks against type in ctx
;   dtt-type? ctx term         -> #t iff term is a well-formed type in ctx

(define (dtt-var? t) (and (pair? t) (equal? (car t) (quote var))))
(define (dtt-lam? t) (and (pair? t) (equal? (car t) (quote lam))))
(define (dtt-app? t) (and (pair? t) (equal? (car t) (quote app))))
(define (dtt-pi? t)  (and (pair? t) (equal? (car t) (quote pi))))
(define (dtt-type? t) (equal? t (quote type)))
(define (dtt-vn t) (car (cdr t)))
(define (dtt-dom t) (car (cdr t)))
(define (dtt-body t) (car (cdr (cdr t))))
(define (dtt-fn t) (car (cdr t)))
(define (dtt-arg t) (car (cdr (cdr t))))

; ---------- shift: lift free variables (index >= cutoff c) by d ----------
(define (dtt-shift d c t)
  (cond ((dtt-var? t) (if (< (dtt-vn t) c) t (list (quote var) (+ (dtt-vn t) d))))
        ((dtt-lam? t) (list (quote lam) (dtt-shift d c (dtt-dom t)) (dtt-shift d (+ c 1) (dtt-body t))))
        ((dtt-pi? t)  (list (quote pi)  (dtt-shift d c (dtt-dom t)) (dtt-shift d (+ c 1) (dtt-body t))))
        ((dtt-app? t) (list (quote app) (dtt-shift d c (dtt-fn t)) (dtt-shift d c (dtt-arg t))))
        (else t)))

; ---------- substitute term s for (var j) ----------
(define (dtt-subst j s t)
  (cond ((dtt-var? t) (dtt-subst-var j s (dtt-vn t)))
        ((dtt-lam? t) (list (quote lam) (dtt-subst j s (dtt-dom t)) (dtt-subst (+ j 1) (dtt-shift 1 0 s) (dtt-body t))))
        ((dtt-pi? t)  (list (quote pi)  (dtt-subst j s (dtt-dom t)) (dtt-subst (+ j 1) (dtt-shift 1 0 s) (dtt-body t))))
        ((dtt-app? t) (list (quote app) (dtt-subst j s (dtt-fn t)) (dtt-subst j s (dtt-arg t))))
        (else t)))
(define (dtt-subst-var j s n)
  (cond ((= n j) s)
        ((> n j) (list (quote var) (- n 1)))      ; a binder was removed, free vars above shift down
        (else (list (quote var) n))))

; ---------- beta normalization ----------
(define (dtt-normalize t) (dtt-nf t 0))
(define (dtt-nf t guard)
  (cond ((> guard 100000) t)
        ((dtt-var? t) t)
        ((dtt-type? t) t)
        ((dtt-lam? t) (list (quote lam) (dtt-nf (dtt-dom t) (+ guard 1)) (dtt-nf (dtt-body t) (+ guard 1))))
        ((dtt-pi? t)  (list (quote pi)  (dtt-nf (dtt-dom t) (+ guard 1)) (dtt-nf (dtt-body t) (+ guard 1))))
        ((dtt-app? t) (dtt-nf-app (dtt-nf (dtt-fn t) (+ guard 1)) (dtt-nf (dtt-arg t) (+ guard 1)) guard))
        (else t)))
(define (dtt-nf-app f a guard)
  (cond ((dtt-lam? f) (dtt-nf (dtt-subst 0 a (dtt-body f)) (+ guard 1)))   ; beta redex
        (else (list (quote app) f a))))

; ---------- conversion: equal up to normalization (de Bruijn => structural after normalizing) ----------
(define (dtt-equal? s t) (dtt-struct-eq? (dtt-normalize s) (dtt-normalize t)))
(define (dtt-struct-eq? s t)
  (cond ((and (dtt-var? s) (dtt-var? t)) (= (dtt-vn s) (dtt-vn t)))
        ((and (dtt-type? s) (dtt-type? t)) #t)
        ((and (dtt-lam? s) (dtt-lam? t)) (and (dtt-struct-eq? (dtt-dom s) (dtt-dom t)) (dtt-struct-eq? (dtt-body s) (dtt-body t))))
        ((and (dtt-pi? s) (dtt-pi? t)) (and (dtt-struct-eq? (dtt-dom s) (dtt-dom t)) (dtt-struct-eq? (dtt-body s) (dtt-body t))))
        ((and (dtt-app? s) (dtt-app? t)) (and (dtt-struct-eq? (dtt-fn s) (dtt-fn t)) (dtt-struct-eq? (dtt-arg s) (dtt-arg t))))
        (else #f)))

; ---------- context: list of types, innermost (var 0) first ----------
(define (dtt-ctx-lookup ctx n) (cond ((null? ctx) (quote out-of-scope)) ((= n 0) (car ctx)) (else (dtt-ctx-lookup (cdr ctx) (- n 1)))))

; ---------- bidirectional type checking ----------
; infer the type of a term in a context; returns the type term, or 'ill-typed
(define (dtt-infer ctx t)
  (cond ((dtt-var? t) (dtt-infer-var ctx (dtt-vn t)))
        ((dtt-type? t) (quote type))                        ; top sort (see consistency note); not used to encode paradoxes
        ((dtt-pi? t) (dtt-infer-pi ctx t))
        ((dtt-lam? t) (dtt-infer-lam ctx t))
        ((dtt-app? t) (dtt-infer-app ctx t))
        (else (quote ill-typed))))
(define (dtt-infer-var ctx n)
  (let ((ty (dtt-ctx-lookup ctx n)))
    (cond ((equal? ty (quote out-of-scope)) (quote ill-typed))
          (else (dtt-shift (+ n 1) 0 ty)))))                ; shift the looked-up type into the current scope
; Pi: domain must be a type, and body must be a type in the extended context; then Pi : type
(define (dtt-infer-pi ctx t)
  (cond ((not (dtt-is-type? ctx (dtt-dom t))) (quote ill-typed))
        ((not (dtt-is-type? (cons (dtt-dom t) ctx) (dtt-body t))) (quote ill-typed))
        (else (quote type))))
; lam: domain must be a type; infer body type in extended context; result is (pi domain bodytype)
(define (dtt-infer-lam ctx t)
  (cond ((not (dtt-is-type? ctx (dtt-dom t))) (quote ill-typed))
        (else (let ((bt (dtt-infer (cons (dtt-dom t) ctx) (dtt-body t))))
                (cond ((equal? bt (quote ill-typed)) (quote ill-typed))
                      (else (list (quote pi) (dtt-dom t) bt)))))))
; app: f must infer to a Pi; arg must check against the domain; result is the codomain with arg substituted
(define (dtt-infer-app ctx t)
  (let ((ft (dtt-normalize (dtt-infer ctx (dtt-fn t)))))
    (cond ((equal? ft (quote ill-typed)) (quote ill-typed))
          ((not (dtt-pi? ft)) (quote ill-typed))
          ((not (dtt-check ctx (dtt-arg t) (dtt-dom ft))) (quote ill-typed))
          (else (dtt-subst 0 (dtt-arg t) (dtt-body ft))))))
; check: infer and compare up to conversion
(define (dtt-check ctx t expected)
  (let ((inferred (dtt-infer ctx t)))
    (cond ((equal? inferred (quote ill-typed)) #f)
          (else (dtt-equal? inferred expected)))))
; is t a well-formed type in ctx? (its type is the universe, or it IS the universe)
(define (dtt-is-type? ctx t)
  (cond ((dtt-type? t) #t)
        (else (equal? (dtt-normalize (dtt-infer ctx t)) (quote type)))))

(define (dtt-caveat) (quote floor2-dependent-types-lambda-P-pi-universe-context-bidirectional-conversion-NOT-CoC-NOT-HoTT-no-type-in-type))
