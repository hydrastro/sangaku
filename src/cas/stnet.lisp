; -*- lisp -*-
; src/cas/stnet.lisp -- FLOOR 1 of lizard's foundations: a SIMPLY-TYPED discipline over the interaction-net
; substrate (inet.lisp), with a type-checker.  Floor 0 gives bare reduction; this floor gives the agents a TYPE and
; a checker that accepts or rejects a net.  It is the lambda-> base of the cube of features -- exactly analogous to
; how simply-typed lambda calculus is the base over which Barendregt's cube is built -- and it is NOT yet
; polymorphism, dependency, or HoTT; those are higher floors and are not claimed here.
;
; This is where the Curry-Howard bridge first appears in miniature: reading the function-type constructor as
; implication, a closed well-typed net whose free port has type A -> A is a PROOF of A -> A, and the identity net is
; exactly that proof.
;
; THE CHOICE (typed ports).  Types live ON THE PORTS, so type-checking is LOCAL wire-consistency: a wire is
; well-typed iff it connects two ports carrying the SAME type at OPPOSITE polarity -- a producer-of-T meeting an
; observer-of-T.  That makes the construction/observation duality a literal property of every wire, native to the
; net rather than an external layer, matching the substrate's locality.  (Representing types as first-class agents
; built from the 1- and 2-arrow elements is a real design for a HIGHER floor, where types stop being atomic and
; become constructed; at the simply-typed base, types on the wires are neater and keep the checker a single pass.)
;
; TYPES.  A simple type is either a base type (a symbol, e.g. o) or a function type (arr A B) meaning A -> B.
;
; AGENT TYPING RULES (ports read by role; polarity from Floor 0: + producer, - observer):
;   LAM  principal - : (arr A B)   aux0 + (var) : A     aux1 + (body) : B    -- introduces A -> B
;   APP  principal + : (arr A B)   aux0 - (arg) : A     aux1 - (cont) : B    -- eliminates A -> B
; The beta interaction LAM~APP wires var<->arg (both A) and body<->cont (both B), so reduction preserves typing
; whenever the function types agree -- subject reduction is built into the rule shapes.
;
; THE CHECKER.  A net is well-typed iff (1) every wire connects equal-type, opposite-polarity ports, and (2) every
; alive agent's three ports satisfy its rule (the arr structure lines up).  One local pass over agents and wires.
;
; Public:
;   stnet-reset! capacity            -> reset the net AND the type store
;   stnet-set-type! endpoint type    -> annotate a port with a type
;   stnet-type endpoint              -> the type annotation of a port (or 'untyped)
;   stnet-port-pol endpoint          -> the polarity (+1/-1) of a port given its agent's tag and port index
;   stnet-check                      -> #t iff the whole net is well-typed
;   stnet-check-wire endpoint        -> #t iff the wire at this endpoint is type/polarity-consistent
;   stnet-check-agent id             -> #t iff agent id satisfies its typing rule
;   (re-exports inet via import so a typed net is built with inet-mk / inet-connect! / inet-port)

(import "cas/inet.lisp")

; ---------- type representation ----------
(define (stnet-arr A B) (list (quote arr) A B))
(define (stnet-arr? T) (and (pair? T) (equal? (car T) (quote arr))))
(define (stnet-dom T) (car (cdr T)))
(define (stnet-cod T) (car (cdr (cdr T))))
(define (stnet-type-eq? S T)
  (cond ((and (stnet-arr? S) (stnet-arr? T)) (and (stnet-type-eq? (stnet-dom S) (stnet-dom T)) (stnet-type-eq? (stnet-cod S) (stnet-cod T))))
        ((or (stnet-arr? S) (stnet-arr? T)) #f)
        (else (equal? S T))))

; ---------- per-port type store (parallel to inet's link array) ----------
(define stnet-typev 0)        ; endpoint code -> type (or 'untyped)
(define stnet-tcap 0)
(define (stnet-reset! capacity)
  (begin (inet-reset! capacity)
         (set! stnet-tcap (* capacity 3))
         (set! stnet-typev (make-vector (* capacity 3) (quote untyped)))))
(define (stnet-set-type! ep type) (vector-set! stnet-typev ep type))
(define (stnet-type ep) (vector-ref stnet-typev ep))

; ---------- port polarity (derived from the agent's tag and the port index) ----------
; LAM principal(0) - , var(1) - (the bound variable: where the argument arrives) , body(2) + (the result)
; APP principal(0) + , arg(1) + (it provides the argument) , cont(2) - (it receives the result)
; DUP principal(0) - , copy0(1) + , copy1(2) +   (it produces two copies of what it observes)
; SUP principal(0) + , val0(1) - , val1(2) -      (it consumes two values into a superposition)
; The beta interaction LAM~APP then wires var(-)<->arg(+) and body(+)<->cont(-), both opposite-polarity.
(define (stnet-port-pol ep)
  (let ((tag (inet-tag (inet-ep-agent ep))) (p (inet-ep-port ep)))
    (cond ((= tag inet-LAM) (cond ((= p 0) -1) ((= p 1) -1) (else 1)))
          ((= tag inet-APP) (cond ((= p 0) 1) ((= p 1) 1) (else -1)))
          ((= tag inet-DUP) (cond ((= p 0) -1) (else 1)))
          ((= tag inet-SUP) (cond ((= p 0) 1) (else -1)))
          (else 0))))

; ---------- wire consistency: same type, opposite polarity ----------
(define (stnet-check-wire ep)
  (let ((other (inet-linked ep)))
    (cond ((< other 0) #t)                                   ; dangling/free wire: not an internal constraint
          (else (and (stnet-type-eq? (stnet-type ep) (stnet-type other))
                     (= (+ (stnet-port-pol ep) (stnet-port-pol other)) 0))))))

; ---------- agent typing rule: the three ports' types line up per the agent's role ----------
(define (stnet-check-agent id)
  (let ((tag (inet-tag id)))
    (cond ((= tag inet-LAM) (stnet-check-lam id))
          ((= tag inet-APP) (stnet-check-app id))
          ((= tag inet-DUP) (stnet-check-dup id))
          ((= tag inet-SUP) (stnet-check-sup id))
          (else #t))))
; LAM principal:(arr A B), var:A, body:B  -- the principal's type is the arrow of var->body
(define (stnet-check-lam id)
  (let ((tp (stnet-type (inet-port id 0))) (tv (stnet-type (inet-port id 1))) (tb (stnet-type (inet-port id 2))))
    (and (stnet-arr? tp) (stnet-type-eq? (stnet-dom tp) tv) (stnet-type-eq? (stnet-cod tp) tb))))
; APP principal:(arr A B), arg:A, cont:B
(define (stnet-check-app id)
  (let ((tp (stnet-type (inet-port id 0))) (ta (stnet-type (inet-port id 1))) (tc (stnet-type (inet-port id 2))))
    (and (stnet-arr? tp) (stnet-type-eq? (stnet-dom tp) ta) (stnet-type-eq? (stnet-cod tp) tc))))
; DUP copies a value of type A into two of type A: principal:A, copy0:A, copy1:A
(define (stnet-check-dup id)
  (let ((tp (stnet-type (inet-port id 0))) (t0 (stnet-type (inet-port id 1))) (t1 (stnet-type (inet-port id 2))))
    (and (stnet-type-eq? tp t0) (stnet-type-eq? tp t1))))
; SUP superposes two values of type A: principal:A, val0:A, val1:A
(define (stnet-check-sup id)
  (let ((tp (stnet-type (inet-port id 0))) (t0 (stnet-type (inet-port id 1))) (t1 (stnet-type (inet-port id 2))))
    (and (stnet-type-eq? tp t0) (stnet-type-eq? tp t1))))

; ---------- whole-net checker: every alive agent satisfies its rule, every wire is consistent ----------
(define (stnet-check) (and (stnet-check-all-agents 0) (stnet-check-all-wires 0)))
(define (stnet-check-all-agents id)
  (cond ((>= id (stnet-next-id)) #t)
        ((= (stnet-alive-id id) 0) (stnet-check-all-agents (+ id 1)))
        ((stnet-check-agent id) (stnet-check-all-agents (+ id 1)))
        (else #f)))
(define (stnet-check-all-wires id)
  (cond ((>= id (stnet-next-id)) #t)
        ((= (stnet-alive-id id) 0) (stnet-check-all-wires (+ id 1)))
        (else (stnet-check-agent-wires id (+ id 1)))))
(define (stnet-check-agent-wires id rest)
  (cond ((and (stnet-check-wire (inet-port id 0)) (stnet-check-wire (inet-port id 1)) (stnet-check-wire (inet-port id 2)))
         (stnet-check-all-wires rest))
        (else #f)))
; accessors into inet internals (inet exposes these as module globals)
(define (stnet-next-id) inet-next)
(define (stnet-alive-id id) (vector-ref inet-alive id))

(define (stnet-caveat) (quote floor1-simply-typed-discipline-typed-ports-local-checker-lambda-arrow-base-of-the-cube))
