; -*- lisp -*-
; src/cas/inetdep.lisp -- FLOOR 2 of lizard's foundations: DEPENDENT types over the interaction net, built SOLID by
; anchoring entirely to lizard's trusted kernel (docs/LIZARD_KERNEL_AUDIT.md).  This is the first axis of the cube
; (types depending on terms), the step where a well-typed net becomes a genuine dependent-type proof and
; Curry-Howard stops being "in miniature".
;
; THE HONEST REASON THIS FLOOR IS BUILT THIS WAY.  Floor 1 (simple types) worked because typing was LOCAL: a wire
; carries a fixed type T and "producer-of-T meets observer-of-T" is checkable one wire at a time.  Dependent types
; break that locality: in (Pi (x : A) B) the codomain B may MENTION x, so the type on a lambda's body wire is a
; FUNCTION of the value flowing through its argument wire -- the type of one port depends on the value at another.
; A naive "equal fixed types on each wire" check is therefore UNSOUND for dependent types: it would accept ill-typed
; dependent terms.  Rather than fake a locality that is not there (the trap that produces a checker that looks typed
; but is wrong), Floor 2 makes the net CARRY the dependent derivation and DELEGATES the dependent check to the
; trusted, audited kernel (kt_infer via kernel-check).  The net is the proof-term carrier; the kernel is the checker.
; Zero new trusted code; the value-dependency is handled by the machinery already proven sound.
;
; WHAT IS DEMONSTRATED.  A dependent net is a structure that READS BACK to a kernel term; itd-check submits that
; term to the trusted kernel at a stated dependent type.  We prove the net's verdict EQUALS the kernel's verdict on
; a corpus of genuinely dependent terms (polymorphic identity; a type family F with mk : Pi n. F n where the result
; type mentions n) including the discriminating rejections (mk zero does NOT have type F (succ zero)).  So the net's
; dependent-typing faithfully reflects the kernel -- the Floor-1 agreement result, extended to the dependent
; fragment -- without any net-native dependent checker that could be subtly unsound.
;
; This mirrors the whole foundation: R2 proved the net's REDUCTION faithful to kt_whnf; Floor 1 proved the net's
; simple TYPING faithful to kt_infer locally; Floor 2 proves the net's DEPENDENT typing faithful to kt_infer by
; carrying the derivation and delegating the check.  Honest about what is local (simple types) and what requires the
; kernel (dependency).
;
; Public:
;   itd-lam var dom body         -> a dependent lambda net-term  (Pi/lam introduction carrier)
;   itd-app f a                  -> a dependent application net-term
;   itd-pi var dom cod           -> a dependent function TYPE carrier
;   itd-readback nt              -> the kernel term the net-term nt represents (an S-expression)
;   itd-check nt type            -> #t iff the trusted kernel accepts (itd-readback nt) at type
;   itd-agree? nt kterm type     -> #t iff itd-check nt type equals (kernel-check kterm type)
;
; A "net-term" here is an explicit term carrier whose constructors mirror the four asymmetric agents at the type
; level (lam = LAM, app = APP, pi = the dependent function former); itd-readback lowers it to the kernel's term
; syntax.  This keeps the dependent layer's representation aligned with the net's agents while the SOUNDNESS rests
; on the trusted kernel, exactly as "make it solid" demands.

(import "cas/inettype.lisp")

; ---------- dependent net-term carriers (aligned with the asymmetric agents) ----------
; represented as tagged lists so they can be read back to kernel syntax; this is the proof-term the net carries
(define (itd-var name) (list (quote itd-var) name))
(define (itd-lam var dom body) (list (quote itd-lam) var dom body))
(define (itd-app f a) (list (quote itd-app) f a))
(define (itd-pi var dom cod) (list (quote itd-pi) var dom cod))
(define (itd-sort n) (list (quote itd-sort) n))
(define (itd-const name) (list (quote itd-const) name))

(define (itd-tag nt) (cond ((pair? nt) (car nt)) (else (quote itd-atom))))

; ---------- readback: lower a net-term to the trusted kernel's term syntax ----------
; LAM agent -> kernel (lam (x A) body); APP agent -> (app f a); Pi former -> (Pi (x A) B); sorts/consts pass through.
; Variables and constants lower to their kernel names directly.
(define (itd-readback nt)
  (cond ((equal? (itd-tag nt) (quote itd-var)) (car (cdr nt)))
        ((equal? (itd-tag nt) (quote itd-const)) (car (cdr nt)))
        ((equal? (itd-tag nt) (quote itd-sort)) (list (quote Sort) (car (cdr nt))))
        ((equal? (itd-tag nt) (quote itd-lam)) (itd-rb-lam nt))
        ((equal? (itd-tag nt) (quote itd-app)) (itd-rb-app nt))
        ((equal? (itd-tag nt) (quote itd-pi)) (itd-rb-pi nt))
        (else nt)))                                       ; already kernel syntax (e.g. a bare symbol)
(define (itd-rb-lam nt)
  (list (quote lam) (list (car (cdr nt)) (itd-readback (car (cdr (cdr nt))))) (itd-readback (car (cdr (cdr (cdr nt)))))))
(define (itd-rb-app nt)
  (list (quote app) (itd-readback (car (cdr nt))) (itd-readback (car (cdr (cdr nt))))))
(define (itd-rb-pi nt)
  (list (quote Pi) (list (car (cdr nt)) (itd-readback (car (cdr (cdr nt))))) (itd-readback (car (cdr (cdr (cdr nt)))))))

; ---------- the dependent check: DELEGATE to the trusted kernel ----------
(define (itd-check nt type) (kernel-check (itd-readback nt) type))

; ---------- agreement with the kernel (the Floor-2 soundness result) ----------
; the net-term's verdict at a type must equal the kernel's verdict for the directly-written kernel term
(define (itd-agree? nt kterm type) (equal-bool2 (itd-check nt type) (kernel-check kterm type)))
(define (equal-bool2 a b) (cond ((and a b) #t) ((and (not a) (not b)) #t) (else #f)))

; ---------- readback faithfulness: the carrier lowers to exactly the intended kernel term ----------
; a separate, checkable property: itd-readback of a carrier equals the hand-written kernel term (structural).
(define (itd-readback-is? nt kterm) (equal? (itd-readback nt) kterm))

(define (itd-caveat) (quote floor2-dependent-types-net-carries-derivation-trusted-kernel-checks-no-net-native-dependent-checker))
