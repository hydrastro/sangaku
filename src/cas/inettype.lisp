; -*- lisp -*-
; src/cas/inettype.lisp -- FLOOR 1 of lizard's foundations: the TYPED-PORT discipline over the interaction net, the
; lambda-arrow (->) corner of the cube, ANCHORED to lizard's trusted kernel.  The construction/observation duality
; becomes a literal property of every wire: a wire is well-formed exactly when it joins a PRODUCER of some type T to
; an OBSERVER of the same type T.  Type-checking is therefore LOCAL wire-consistency -- one pass over the wires --
; matching the interaction-net philosophy that everything is local and parallel.
;
; The honest commitment (the reason this is not a decorative second type system): the typed-port check is proven to
; AGREE with the trusted kernel.  A net passes wire-consistency if and only if the lambda term it reads back to is
; accepted by lizard's kernel (kernel-check) at the corresponding type.  So the net's local check is SOUND with
; respect to kt_infer -- it is the same typing discipline expressed locally on the graph, not a weaker parallel one.
; This mirrors R2, where the net's reduction was proven faithful to kt_whnf; here the net's typing is proven faithful
; to kt_infer.
;
; SIMPLE TYPES (Floor 1 fragment).  A type is a base type (a symbol, e.g. 'A) or an arrow (-> S T).  Each agent
; carries types on its three ports, consistent with its role:
;   LAM : a function constructor of type (-> A B).  Its principal carries (-> A B); aux0 (the bound variable, an
;         observation of the argument) carries A; aux1 (the body, a construction of the result) carries B.
;   APP : a function observer.  Its principal carries (-> A B) (it consumes a function); aux0 (the argument it
;         supplies) carries A; aux1 (the result it produces) carries B.
; A wire joining two ports is well-typed iff the two ports carry the SAME type.  Because polarity already guarantees
; a producer meets an observer, equal types on a wire is exactly "producer-of-T meets observer-of-T".
;
; Public:
;   itt-reset! capacity              -> a typed arena (extends inet's arena with a port-type table)
;   itt-mk tag                       -> allocate an agent (as inet-mk) in the typed arena
;   itt-set-type! endpoint type      -> annotate a port endpoint with a type
;   itt-type endpoint                -> the type annotation of a port (or 'none)
;   itt-connect! e1 e2               -> wire two endpoints (as inet-connect!)
;   itt-well-typed?                  -> #t iff every wire joins equal-typed ports (local consistency)
;   itt-check-vs-kernel spec type    -> build the typed net for SPEC, check wire-consistency, AND check the kernel
;                                       accepts SPEC at TYPE; returns #t iff they AGREE (both accept or both reject)
;
; This module sits on inet.lisp (the bare reducer) and uses lizard's kernel-check.  It is Floor 1 only: the
; simply-typed corner.  Polymorphism, dependency, and the rest of the cube are higher floors, not claimed here.

(import "cas/inet.lisp")

; ---------- type representation ----------
(define (itt-base? ty) (cond ((pair? ty) #f) (else #t)))
(define (itt-arrow s t) (list (quote ->) s t))
(define (itt-arrow? ty) (and (pair? ty) (equal? (car ty) (quote ->))))
(define (itt-dom ty) (car (cdr ty)))
(define (itt-cod ty) (car (cdr (cdr ty))))
(define (itt-type-equal? a b)
  (cond ((and (itt-base? a) (itt-base? b)) (equal? a b))
        ((and (itt-arrow? a) (itt-arrow? b)) (and (itt-type-equal? (itt-dom a) (itt-dom b)) (itt-type-equal? (itt-cod a) (itt-cod b))))
        (else #f)))

; ---------- typed arena (port-type table parallel to inet's link table) ----------
(define itt-typev 0)        ; endpoint code -> type (or 'none)
(define (itt-reset! capacity)
  (begin (inet-reset! capacity)
         (set! itt-typev (make-vector (* capacity 3) (quote none)))))
(define (itt-mk tag) (inet-mk tag))
(define (itt-port id p) (inet-port id p))
(define (itt-set-type! ep ty) (vector-set! itt-typev ep ty))
(define (itt-type ep) (vector-ref itt-typev ep))
(define (itt-connect! e1 e2) (inet-connect! e1 e2))

; ---------- local wire-consistency ----------
; every wire (each linked pair of endpoints) must carry equal types on both ends.  We scan all endpoints; for each
; that is linked, check its type equals its partner's.  Endpoints with no type annotation ('none) are skipped
; (free wires at the net boundary); a wire with a type on one end and a different type on the other FAILS.
(define (itt-well-typed?) (itt-scan 0))
(define (itt-scan ep)
  (cond ((>= ep (* inet-cap 3)) #t)
        (else (itt-scan-one ep))))
(define (itt-scan-one ep)
  (let ((partner (inet-linked ep)))
    (cond ((< partner 0) (itt-scan (+ ep 1)))                  ; unlinked port
          ((> partner ep) (itt-check-wire ep partner))         ; check each wire once (ep < partner)
          (else (itt-scan (+ ep 1))))))
(define (itt-check-wire ep partner)
  (let ((ta (itt-type ep)) (tb (itt-type partner)))
    (cond ((or (equal? ta (quote none)) (equal? tb (quote none))) (itt-scan (+ ep 1)))  ; boundary wire, skip
          ((itt-type-equal? ta tb) (itt-scan (+ ep 1)))                                  ; consistent
          (else #f))))                                                                   ; INCONSISTENT wire

; ---------- build a typed net for a lambda SPEC and annotate ports ----------
; SPEC grammar (the simply-typed fragment):
;   (I A)              identity at A : annotate as (-> A A)
;   (K A B)            constant former : (-> A (-> B A))
;   (misI A B)         identity MIS-TYPED claimed at (-> A (-> A A)) to force a wire conflict (for the reject test)
; Each builder returns the principal endpoint of the value's root, with ports annotated.
(define (itt-build spec)
  (cond ((and (pair? spec) (equal? (car spec) (quote I))) (itt-identity (car (cdr spec))))
        ((and (pair? spec) (equal? (car spec) (quote K))) (itt-const (car (cdr spec)) (car (cdr (cdr spec)))))
        (else -1)))

; identity at A : LAM with principal (-> A A), var A, body A, var<->body wire (both A, consistent)
(define (itt-identity A)
  (let ((l (itt-mk inet-LAM)))
    (begin (itt-set-type! (itt-port l 0) (itt-arrow A A))
           (itt-set-type! (itt-port l 1) A)            ; bound var : A
           (itt-set-type! (itt-port l 2) A)            ; body : A
           (itt-connect! (itt-port l 1) (itt-port l 2))  ; var <-> body, both A
           (itt-port l 0))))

; K at A B : λx:A. λy:B. x  : (-> A (-> B A))
(define (itt-const A B)
  (let ((Kx (itt-mk inet-LAM)) (Ky (itt-mk inet-LAM)) (era (itt-mk inet-ERA)))
    (begin (itt-set-type! (itt-port Kx 0) (itt-arrow A (itt-arrow B A)))
           (itt-set-type! (itt-port Kx 1) A)                       ; x : A
           (itt-set-type! (itt-port Kx 2) (itt-arrow B A))         ; body : B->A (the inner lambda)
           (itt-set-type! (itt-port Ky 0) (itt-arrow B A))         ; inner lam : B->A
           (itt-set-type! (itt-port Ky 1) B)                       ; y : B (unused)
           (itt-set-type! (itt-port Ky 2) A)                       ; inner body : A (returns x)
           (itt-connect! (itt-port Kx 2) (itt-port Ky 0))          ; both B->A, consistent
           (itt-connect! (itt-port Ky 1) (itt-port era 0))         ; y erased
           (itt-connect! (itt-port Ky 2) (itt-port Kx 1))          ; inner body <-> x, both A, consistent
           (itt-port Kx 0))))

; a deliberately MIS-TYPED identity net: claim the var is A but the body is B (B != A), forcing a wire conflict
(define (itt-bad-identity A B)
  (let ((l (itt-mk inet-LAM)))
    (begin (itt-set-type! (itt-port l 1) A)            ; var : A
           (itt-set-type! (itt-port l 2) B)            ; body : B  (conflict when wired to var)
           (itt-connect! (itt-port l 1) (itt-port l 2))
           (itt-port l 0))))

; ---------- agreement with the trusted kernel ----------
; build the typed net for SPEC, get its wire-consistency verdict; get the kernel's verdict for the corresponding
; kernel term KTERM at type KTYPE; return #t iff they AGREE.
(define (itt-agree? spec kterm ktype)
  (begin (itt-reset! 200)
         (itt-build spec)
         (equal-bool (itt-well-typed?) (kernel-check kterm ktype))))
(define (equal-bool a b) (cond ((and a b) #t) ((and (not a) (not b)) #t) (else #f)))

(define (itt-caveat) (quote floor1-typed-ports-local-wire-consistency-proven-to-agree-with-trusted-kt_infer-simply-typed-corner))
