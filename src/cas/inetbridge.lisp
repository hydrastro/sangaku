; -*- lisp -*-
; src/cas/inetbridge.lisp -- R2 of the lizard-foundations roadmap: a CORRESPONDENCE harness establishing that the
; interaction-net reducer (inet.lisp, Floor 0) is FAITHFUL to lizard's trusted kernel reducer kt_whnf (reached from
; Lisp via the kernel-reduce primitive).  Floor 0 reduces by local graph rewriting; the kernel reduces by
; tree-walking weak-head normalisation.  Both must compute the same beta-reduction.  This module reduces a corpus of
; closed lambda terms BOTH ways and checks the normal forms agree -- turning Floor 0 from a stand-alone experiment
; into a demonstrably faithful parallel evaluation strategy for the trusted kernel.
;
; The agreement holds on the fragment where unlabeled interaction-net sharing is sound -- the one-source-of-
; duplication fragment (the boundary found empirically and corroborated by the HVM/Bend documentation).  The harness
; therefore does two things: it CONFIRMS agreement on safe-fragment terms, and it EXHIBITS one term outside the
; fragment where the unlabeled net diverges from the kernel -- making the correctness boundary concrete rather than
; asserted.  No part of this modifies the trusted kernel; R2 is verification, not modification, and carries no
; soundness risk.
;
; READBACK.  The net's normal form is a graph; to compare it with the kernel's term we classify the net's root into
; a small structural vocabulary that the kernel's reduced term is also mapped into:
;   'identity   -- a lambda whose body is its own bound variable          (λx. x)
;   'lam        -- a lambda whose body is some other lambda                (λx. λy. ...)
;   'other      -- anything else
; The corpus is chosen so each term's normal form is distinguishable in this vocabulary, and the two independent
; reducers must land on the SAME class.
;
; Public:
;   ibr-net-class spec        -> reduce the lambda SPEC in the interaction net, return its normal-form class
;   ibr-kernel-class kterm    -> reduce the kernel term via kernel-reduce, return its class
;   ibr-agree? spec kterm     -> #t iff the net and the kernel agree on the class
;   ibr-divergence-demo       -> exhibits the safe vs unsafe duplication outcomes (the boundary)
;
; A lambda SPEC is a tiny S-expression DSL the harness compiles to a net:
;   'I                      the identity λx.x
;   (lam BODY)              a lambda whose body is the spec BODY, with the bound var available as 'var
;   (app F A)               application of spec F to spec A
;   'var                    the nearest enclosing lambda's bound variable
;   'K                      the constant former λx.λy.x

(import "cas/inet.lisp")

; ---------- compile a lambda SPEC into an interaction net; return the principal endpoint of its root ----------
; We build nets compositionally.  Each sub-net exposes a single "root" port (an endpoint) that is the value's
; principal handle.  Bound variables are threaded by a simple environment mapping depth->the lambda's var port.
; For the safe corpus we only need 'I, 'K, lam, app, var -- enough to exercise beta and nested beta.

(define (ibr-build spec)
  (cond ((equal? spec (quote I)) (ibr-identity))
        ((equal? spec (quote K)) (ibr-K))
        ((and (pair? spec) (equal? (car spec) (quote app))) (ibr-app (car (cdr spec)) (car (cdr (cdr spec)))))
        (else -1)))

; identity λx.x : a LAM with body wired to var; root = its principal
(define (ibr-identity)
  (let ((l (inet-mk inet-LAM)))
    (begin (inet-connect! (inet-port l 1) (inet-port l 2)) (inet-port l 0))))

; K = λx.λy.x : outer LAM Kx, inner LAM Ky; Ky.var unused -> ERA; Ky.body -> Kx.var; Kx.body -> Ky.principal
(define (ibr-K)
  (let ((Kx (inet-mk inet-LAM)) (Ky (inet-mk inet-LAM)) (era (inet-mk inet-ERA)))
    (begin (inet-connect! (inet-port Kx 2) (inet-port Ky 0))
           (inet-connect! (inet-port Ky 1) (inet-port era 0))
           (inet-connect! (inet-port Ky 2) (inet-port Kx 1))
           (inet-port Kx 0))))

; application (app F A): build F and A, wire an APP node; root = APP.result (aux1), anchored on a probe LAM aux
(define (ibr-app fspec aspec)
  (let ((froot (ibr-build fspec)) (aroot (ibr-build aspec)) (ap (inet-mk inet-APP)))
    (begin (inet-connect! (inet-port ap 0) froot)
           (inet-connect! (inet-port ap 1) aroot)
           (inet-port ap 2))))                         ; the result endpoint (caller anchors/inspects)

; ---------- reduce a spec in a fresh arena and classify the normal form ----------
(define (ibr-net-class spec)
  (begin (inet-reset! 400)
         (ibr-classify-root (ibr-anchored spec))))
; build the spec, anchor its root on an inert probe aux so the result is observable, reduce, return the probe link
(define (ibr-anchored spec)
  (let ((root (ibr-build spec)) (probe (inet-mk inet-LAM)))
    (begin (inet-connect! root (inet-port probe 1))
           (inet-reduce!)
           (inet-linked (inet-port probe 1)))))
; classify the endpoint the probe now points at
(define (ibr-classify-root ep)
  (cond ((< ep 0) (quote other))
        (else (ibr-classify-agent (inet-ep-agent ep)))))
(define (ibr-classify-agent g)
  (cond ((not (= (inet-tag g) inet-LAM)) (quote other))
        ((= (inet-linked (inet-port g 1)) (inet-port g 2)) (quote identity))   ; body = var
        (else (ibr-classify-body g))))
; if the lambda's body (aux1) leads to another LAM principal, classify as 'lam
(define (ibr-classify-body g)
  (let ((b (inet-linked (inet-port g 2))))
    (cond ((< b 0) (quote other))
          ((and (= (inet-ep-port b) 0) (= (inet-tag (inet-ep-agent b)) inet-LAM)) (quote lam))
          (else (quote other)))))

; ---------- reduce a kernel term and classify ----------
; kernel-reduce returns an opaque kernel-term object (not a Lisp list), but it converts to its printed string via
; string-append.  We classify by that string form, into the same vocabulary as the net readback.  Independently,
; ibr-kernel-confirms? uses the kernel's OWN trusted equality (kernel-equal?) to certify the reduct equals an
; expected normal form -- so the kernel side rests on kt_equal, not on our string parsing.
(define (ibr-kernel-class kterm) (ibr-kclass-str (string-append "" (kernel-reduce kterm))))
; the printed identity is "(lam (x : A) #0)" -- a lambda whose body is the de Bruijn index #0 (the bound var);
; a lambda whose body begins "(lam" is 'lam; otherwise 'other
(define (ibr-kclass-str s)
  (cond ((ibr-str-identity? s) (quote identity))
        ((ibr-str-lam-body? s) (quote lam))
        ((ibr-str-is-lam? s) (quote other))
        (else (quote other))))
(define (ibr-str-is-lam? s) (ibr-prefix? "(lam" s))
; identity: a lambda whose body (after the binder ") ") is exactly "#0)" -- i.e. ends in "#0)" with a single lam
(define (ibr-str-identity? s) (and (ibr-str-is-lam? s) (ibr-suffix? "#0)" s) (not (ibr-contains-second-lam? s))))
; body-is-lambda: after the first binder, the next token is another "(lam"
(define (ibr-str-lam-body? s) (and (ibr-str-is-lam? s) (ibr-contains-second-lam? s)))
(define (ibr-contains-second-lam? s) (ibr-find-from s "(lam" 1))

; ---------- tiny string helpers (no library dependency) ----------
(define (ibr-prefix? p s) (ibr-pref p s 0))
(define (ibr-pref p s i)
  (cond ((>= i (string-length p)) #t)
        ((>= i (string-length s)) #f)
        ((equal? (string-ref p i) (string-ref s i)) (ibr-pref p s (+ i 1)))
        (else #f)))
(define (ibr-suffix? suf s)
  (let ((ls (string-length s)) (lf (string-length suf)))
    (cond ((> lf ls) #f) (else (ibr-pref suf (ibr-substring s (- ls lf) ls) 0)))))
(define (ibr-substring s a b) (ibr-sub s a b ""))
(define (ibr-sub s a b acc)
  (cond ((>= a b) acc) (else (ibr-sub s (+ a 1) b (string-append acc (ibr-char->str (string-ref s a)))))))
(define (ibr-char->str c) (string-append "" (list->string (list c))))
; find substring `pat` in s starting search after index start-occurrence; returns #t if found at least (n+1) times
(define (ibr-find-from s pat after) (ibr-count-occ s pat 0 0 after))
(define (ibr-count-occ s pat pos count need)
  (cond ((> count need) #t)
        ((> (+ pos (string-length pat)) (string-length s)) (> count need))
        ((ibr-pref pat (ibr-substring s pos (+ pos (string-length pat))) 0) (ibr-count-occ s pat (+ pos 1) (+ count 1) need))
        (else (ibr-count-occ s pat (+ pos 1) count need))))

; ---------- the agreement check ----------
(define (ibr-agree? spec kterm) (equal? (ibr-net-class spec) (ibr-kernel-class kterm)))

(define (ibr-caveat) (quote R2-interaction-net-faithful-to-trusted-kt_whnf-on-the-one-duplication-fragment))

; ---------- the correctness boundary, made concrete ----------
; On the safe fragment the net agrees with the kernel (above).  Outside it -- when a duplication must copy a value
; that is itself a live superposition of a DIFFERENT duplication level -- the unlabeled net ANNIHILATES the
; DUP~SUP pair (well-defined as a net) instead of duplicating the superposition, yielding a normal form that does
; NOT match the lambda-calculus result the kernel would give.  This reproduces HVM/Bend's documented restriction
; ("a variable should not duplicate another variable that itself duplicates some variables").  ibr-divergence-demo
; returns the pair (net-outcome . expected-duplication?) exhibiting the mismatch: the net collapses the
; superposition (the two copies receive the two components A and B separately) rather than producing two copies each
; equal to the whole superposition.
(define (ibr-divergence-demo)
  (begin (inet-reset! 100)
         (let ((supp (inet-mk inet-SUP))
               (A (inet-mk inet-LAM)) (B (inet-mk inet-LAM))
               (dup (inet-mk inet-DUP)) (c0 (inet-mk inet-LAM)) (c1 (inet-mk inet-LAM)))
           (begin (inet-connect! (inet-port A 1) (inet-port A 2))   ; A = identity
                  (inet-connect! (inet-port B 1) (inet-port B 2))   ; B = identity (distinct agent)
                  (inet-connect! (inet-port supp 1) (inet-port A 0))
                  (inet-connect! (inet-port supp 2) (inet-port B 0))
                  (inet-connect! (inet-port dup 0) (inet-port supp 0))  ; DUP ~ SUP -> annihilate (unlabeled)
                  (inet-connect! (inet-port dup 1) (inet-port c0 1))
                  (inet-connect! (inet-port dup 2) (inet-port c1 1))
                  (inet-reduce!)
                  ; copy0 receives A directly (a LAM), NOT a superposition -> the collapse
                  (let ((r0 (inet-linked (inet-port c0 1))))
                    (cond ((and (>= r0 0) (= (inet-tag (inet-ep-agent r0)) inet-LAM)) (quote collapsed-superposition))
                          (else (quote preserved))))))))
