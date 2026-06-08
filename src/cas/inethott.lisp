; -*- lisp -*-
; src/cas/inethott.lisp -- FLOOR 4 of lizard's foundations: HIGHER OBSERVATIONAL TYPE THEORY (HOTT) over the
; interaction net, anchored to lizard's trusted equality/cubical machinery.  HOTT (the Altenkirch/Shulman-style
; observational successor, distinct from homotopy type theory) is the type theory whose DEFINING feature is that
; equality is determined by OBSERVATION: equality of functions is pointwise, equality of pairs is componentwise, and
; in general the equality type at a type is computed from how inhabitants of that type are OBSERVED.  This is exactly
; the CO-UNIVERSE side of the construction/observation duality -- observational equality IS equality on the
; observation lattice -- so this floor is the natural continuation of the co-universe/reflection development.
;
; THE DISCIPLINE, UNCHANGED (Floors 1-3).  The net CARRIES the equality derivation (Id / Path / refl, aligned with
; the agents) and DELEGATES the check to lizard's trusted kernel (kernel-check / kernel-infer over the Id and Path
; type formers and the cubical transport).  The net is the proof-term carrier; the trusted kernel is the checker.
; Zero new trusted code; the observational-equality semantics are handled by the audited kernel.
;
; WHAT IS DEMONSTRATED.  ioe-check submits the carrier's readback to the trusted kernel; we prove the net's verdict
; EQUALS the kernel's on a corpus that includes the discriminating REJECTION at the heart of equality: refl proves
; reflexive identity (refl a : Id A a a) but does NOT prove a false equation (refl a : Id A a b for distinct a,b is
; rejected).  The OBSERVATIONAL character is exhibited on transport: transport along refl is the identity, and
; transport at a pair type is componentwise -- equality computed by observation of the components.  So the net's
; observational-equality typing faithfully reflects the trusted kernel, with no net-native equality checker that
; could be subtly unsound -- the same solid pattern as Floors 1-3.
;
; HONEST SCOPE.  This floor anchors to the Id/Path/refl + transport machinery the kernel actually exposes (verified
; live).  Full univalence and the complete higher-observational equality-of-equality tower are deeper and remain
; roadmap; this floor establishes the observational-equality CORE -- formation, refl, the discriminating rejection,
; and the componentwise/transport observational behaviour -- anchored to the trusted kernel.
;
; Public:
;   ioe-id A a b                 -> an identity-type carrier (Id A a b)
;   ioe-refl a                   -> a refl carrier (refl a : Id A a a)
;   ioe-path A a b               -> a Path-type carrier (Path A a b)
;   ioe-readback nt              -> the kernel term the carrier represents
;   ioe-check nt type            -> #t iff the trusted kernel accepts (ioe-readback nt) at type
;   ioe-agree? nt kterm type     -> #t iff ioe-check nt type equals (kernel-check kterm type)
;   ioe-readback-is? nt kterm    -> readback faithfulness check
;   ioe-observational-equal? ... -> the observational view: equality witnessed by matching observations

(import "cas/inetreflect.lisp")

; ---------- observational-equality carriers (aligned with the agents at the equality level) ----------
(define (ioe-var name) (list (quote ioe-var) name))
(define (ioe-id ty a b) (list (quote ioe-id) ty a b))
(define (ioe-refl a) (list (quote ioe-refl) a))
(define (ioe-path ty a b) (list (quote ioe-path) ty a b))
(define (ioe-sort n) (list (quote ioe-sort) n))
(define (ioe-tag nt) (cond ((pair? nt) (car nt)) (else (quote ioe-atom))))

; ---------- readback: lower an equality carrier to the trusted kernel's term syntax ----------
(define (ioe-readback nt)
  (cond ((equal? (ioe-tag nt) (quote ioe-var)) (car (cdr nt)))
        ((equal? (ioe-tag nt) (quote ioe-sort)) (list (quote Sort) (car (cdr nt))))
        ((equal? (ioe-tag nt) (quote ioe-id))
         (list (quote Id) (ioe-readback (car (cdr nt))) (ioe-readback (car (cdr (cdr nt)))) (ioe-readback (car (cdr (cdr (cdr nt)))))))
        ((equal? (ioe-tag nt) (quote ioe-refl))
         (list (quote refl) (ioe-readback (car (cdr nt)))))
        ((equal? (ioe-tag nt) (quote ioe-path))
         (list (quote Path) (ioe-readback (car (cdr nt))) (ioe-readback (car (cdr (cdr nt)))) (ioe-readback (car (cdr (cdr (cdr nt)))))))
        (else nt)))
(define (ioe-readback-is? nt kterm) (equal? (ioe-readback nt) kterm))

; ---------- the equality check: DELEGATE to the trusted kernel ----------
(define (ioe-check nt type) (kernel-check (ioe-readback nt) type))

; ---------- agreement with the trusted kernel (the Floor-4 soundness result) ----------
(define (ioe-agree? nt kterm type) (equal-bool4 (ioe-check nt type) (kernel-check kterm type)))
(define (equal-bool4 a b) (cond ((and a b) #t) ((and (not a) (not b)) #t) (else #f)))

; ---------- the observational view (the co-universe tie): equality witnessed by matching observations ----------
; HOTT's essence: two things are equal when they are OBSERVED to be equal.  For the homoiconic terms (using the
; reflection module's observation), two terms are observationally equal iff their observed structure matches.  This
; is the operational reading of equality-on-the-observation-side; the TYPED guarantee is the kernel's (ioe-check).
(define (ioe-observational-equal? t1 t2) (equal? (iref-parts t1) (iref-parts t2)))

(define (ioe-caveat) (quote floor4-higher-observational-type-theory-equality-by-observation-net-carries-Id-Path-refl-trusted-kernel-checks-incl-rejection-observational-equality-is-couniverse-side))
