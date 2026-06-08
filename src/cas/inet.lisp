; -*- lisp -*-
; src/cas/inet.lisp -- FLOOR 0 of lizard's foundations: a bare INTERACTION-NET reduction engine.  This is the
; computational substrate -- the parallel, local-rewriting analogue of the lambda calculus -- on which the typed
; layers (the cube of features) and the Curry-Howard bridge are meant to be built.  It is, by itself, ONLY a
; computational system: no types, no propositions, no logic yet.  Naming it honestly: this is the evaluator core,
; prototyped in Lisp so the design can be validated before it is ported into lizard's C kernel.
;
; THE ALPHABET.  Nodes are "agents", each with one PRINCIPAL port (where interaction happens) and some auxiliary
; ports.  Floor 0 uses the four 3-arrow agents, distinguished by the POLARITY of their ports (+ = producer/out,
; - = observer/in):
;     LAM  principal -  aux + +     a function constructor          aux = [bound-var, body]
;     APP  principal +  aux - -     a function observer             aux = [argument, continuation]
;     DUP  principal -  aux + -     a duplicator (copying observer)  aux = [copy0, copy1]
;     SUP  principal +  aux - +     a superposition constructor      aux = [val0, val1]
; plus ERA (a 0-ary eraser/null) for garbage, and the wire (a direct connection between two ports).
;
; POLARITY DECIDES LEGALITY.  A wire must join a producer (+) to an observer (-).  Two agents interact only when
; their principal ports are wired together, so a principal-principal interaction is well-formed exactly when the two
; principals have OPPOSITE polarity.  That restricts the interaction table to the four pairs {LAM,DUP} x {APP,SUP} --
; the polarity scheme DERIVES the table rather than stipulating it, which is the point of the four-polarity alphabet.
;
; MATCHING DECIDES ANNIHILATE-VS-COMMUTE (the interaction-combinator pattern):
;   LAM ~ APP  -> ANNIHILATE  = beta reduction: arg binds the variable, body continues.
;   DUP ~ SUP  -> ANNIHILATE  : the two copies receive the two superposed values.
;   LAM ~ DUP  -> COMMUTE     : the duplicator copies the lambda (two LAMs, a SUP feeds the bound var, DUPs push in).
;   APP ~ SUP  -> COMMUTE     : the application distributes over the two superposed components.
; This is exactly the rule set of optimal lambda reduction; it gives a correctness ORACLE -- reduction must match
; ordinary beta-normalisation on the fragment where unlabeled sharing is sound (the elementary-affine fragment).
;
; THE LABEL BET.  Lamping/Gonthier and HVM attach LABELS to DUP/SUP to keep distinct duplications from interfering.
; Here we bet that the four-polarity distinction suffices WITHOUT labels.  This is a strong, falsifiable claim: it is
; known to hold on the elementary-affine fragment and to fail in general (where two different duplications tangle).
; The accompanying example deliberately stresses the boundary so the claim is tested, not assumed.
;
; REPRESENTATION.  A mutable arena (vectors), because reduction is destructive rewriting and lizard handles vectors
; efficiently (functional allocation thrashes it).  An agent is an integer id; arrays hold its tag and the
; endpoints of its three ports.  A port endpoint is encoded as (agent-id * 3 + port-index); ports 0,1,2 are
; principal, aux0, aux1.  Wiring two ports records each as the other's endpoint.
;
; Public:
;   inet-reset! capacity         -> initialise an arena
;   inet-mk tag                  -> allocate an agent with the given tag (inet-LAM/APP/DUP/SUP/ERA), returns id
;   inet-connect! e1 e2          -> wire two port-endpoints together
;   inet-port id p               -> the endpoint code for port p of agent id (p: 0 principal, 1 aux0, 2 aux1)
;   inet-reduce!                 -> reduce to normal form (no more active pairs); returns the number of interactions
;   inet-normal-form?            -> #t iff no active pair remains
;   inet-tag id                  -> the tag of an agent
;   inet-interactions            -> count of interactions performed
;
; This is Floor 0 only.  Types, the cube, and Curry-Howard are later floors and are NOT claimed here.

; ---------- tags ----------
(define inet-ERA 0)
(define inet-LAM 1)
(define inet-APP 2)
(define inet-DUP 3)
(define inet-SUP 4)

; polarity of the principal port: +1 producer, -1 observer
(define (inet-principal-pol tag)
  (cond ((= tag inet-LAM) -1) ((= tag inet-DUP) -1) ((= tag inet-APP) 1) ((= tag inet-SUP) 1) (else 0)))
; is a tag a "constructor" (LAM/SUP) or an "observer" (APP/DUP)?
(define (inet-constructor? tag) (or (= tag inet-LAM) (= tag inet-SUP)))

; ---------- arena ----------
(define inet-cap 0)
(define inet-tagv 0)        ; agent id -> tag
(define inet-alive 0)       ; agent id -> 1 alive / 0 freed
(define inet-link 0)        ; endpoint code -> the endpoint it is wired to (or -1)
(define inet-next 0)        ; next free agent id
(define inet-count 0)       ; interactions performed

(define (inet-reset! capacity)
  (begin (set! inet-cap capacity)
         (set! inet-tagv (make-vector capacity 0))
         (set! inet-alive (make-vector capacity 0))
         (set! inet-link (make-vector (* capacity 3) -1))
         (set! inet-next 0)
         (set! inet-count 0)))
(define (inet-mk tag)
  (let ((id inet-next))
    (begin (vector-set! inet-tagv id tag) (vector-set! inet-alive id 1) (set! inet-next (+ id 1)) id)))
(define (inet-tag id) (vector-ref inet-tagv id))
(define (inet-free! id) (vector-set! inet-alive id 0))
(define (inet-interactions) inet-count)

; ---------- ports & wiring ----------
(define (inet-port id p) (+ (* id 3) p))
(define (inet-ep-agent ep) (quotient ep 3))
(define (inet-ep-port ep) (remainder ep 3))
(define (inet-connect! e1 e2) (begin (vector-set! inet-link e1 e2) (vector-set! inet-link e2 e1)))
(define (inet-linked ep) (vector-ref inet-link ep))

; ---------- finding active pairs ----------
; an active pair: two ALIVE agents whose PRINCIPAL ports (port 0) are wired to each other
(define (inet-find-active) (inet-fa 0))
(define (inet-fa id)
  (cond ((>= id inet-next) -1)
        ((= (vector-ref inet-alive id) 0) (inet-fa (+ id 1)))
        (else (inet-fa-check id))))
(define (inet-fa-check id)
  (let ((pl (inet-linked (inet-port id 0))))
    (cond ((< pl 0) (inet-fa (+ id 1)))                       ; principal not wired
          ((= (inet-ep-port pl) 0)                            ; the other end is also a principal -> active pair
           (let ((other (inet-ep-agent pl)))
             (cond ((and (> other id) (= (vector-ref inet-alive other) 1)) id)  ; report once (id < other)
                   (else (inet-fa (+ id 1))))))
          (else (inet-fa (+ id 1))))))

(define (inet-normal-form?) (< (inet-find-active) 0))

; ---------- the interaction rules ----------
(define (inet-interact! a)
  (let ((b (inet-ep-agent (inet-linked (inet-port a 0)))))
    (let ((ta (inet-tag a)) (tb (inet-tag b)))
      (begin (set! inet-count (+ inet-count 1))
             (cond ((inet-same-kind? ta tb) (inet-annihilate! a b))
                   ((inet-matching? ta tb) (inet-annihilate! a b))
                   (else (inet-commute! a b)))))))
; "same kind" (same tag) annihilates (e.g. LAM-LAM if it ever arises via wiring); "matching" = LAM-APP or DUP-SUP
(define (inet-same-kind? ta tb) (= ta tb))
(define (inet-matching? ta tb)
  (or (and (= ta inet-LAM) (= tb inet-APP)) (and (= ta inet-APP) (= tb inet-LAM))
      (and (= ta inet-DUP) (= tb inet-SUP)) (and (= ta inet-SUP) (= tb inet-DUP))))

; ANNIHILATE matching agents a,b (LAM~APP or DUP~SUP).  The semantics: for each i in {1,2}, the external wire on
; a.aux_i must be spliced to the external wire on b.aux_i.  We gather the two partners, then splice.  The only
; subtlety is internal links (a port wired to another port of the dying pair, e.g. the identity's var<->body); the
; resolver follows such links across the pair with a hard step bound, so it terminates even on self-loops, and a
; fully-internal cycle resolves to a dangling end (discarded).
(define (inet-annihilate! a b)
  (let ((pa1 (inet-resolve (inet-port a 1) a b 0)) (pa2 (inet-resolve (inet-port a 2) a b 0))
        (pb1 (inet-resolve (inet-port b 1) a b 0)) (pb2 (inet-resolve (inet-port b 2) a b 0)))
    (begin (inet-free! a) (inet-free! b)
           (inet-bind pa1 pb1) (inet-bind pa2 pb2))))
; resolve the external endpoint reachable from `port` (a port of a dying agent): follow its link; if that lands on
; a port of a or b, jump to the ANNIHILATION-PARTNER port (same aux index on the other agent) and continue.  Bounded
; by a step counter (the pair has only 4 aux ports, so >8 steps means a closed internal cycle -> dangling).
(define (inet-resolve port a b steps)
  (cond ((> steps 8) -1)
        (else (inet-resolve-link (inet-linked port) a b steps))))
(define (inet-resolve-link ep a b steps)
  (cond ((< ep 0) -1)
        ((inet-in-pair? (inet-ep-agent ep) a b) (inet-resolve (inet-partner-port ep a b) a b (+ steps 1)))
        (else ep)))
(define (inet-in-pair? id a b) (or (= id a) (= id b)))
; the annihilation partner of an internal port: same aux index, the other agent of the pair (aux1<->aux1, aux2<->aux2)
(define (inet-partner-port ep a b)
  (let ((id (inet-ep-agent ep)) (p (inet-ep-port ep)))
    (inet-port (if (= id a) b a) p)))
(define (inet-bind o1 o2)
  (cond ((and (>= o1 0) (>= o2 0)) (inet-connect! o1 o2)) (else (quote ok))))

; COMMUTE: each agent passes through the other, producing two copies of each and 4 new wires.  For X~Y, create
; X0,X1 (copies of X) and Y0,Y1 (copies of Y); the new agents are cross-wired in the standard interaction-net
; commutation square, and the outer neighbours of the originals' aux ports attach to the copies' principals.
(define (inet-commute! a b)
  (let ((ta (inet-tag a)) (tb (inet-tag b)))
    (let ((a0 (inet-mk ta)) (a1 (inet-mk ta)) (b0 (inet-mk tb)) (b1 (inet-mk tb)))
      (begin
        ; outer neighbours of a's aux ports now meet copies of b (b0,b1) at their principals
        (inet-attach (inet-linked (inet-port a 1)) b0)
        (inet-attach (inet-linked (inet-port a 2)) b1)
        ; outer neighbours of b's aux ports now meet copies of a (a0,a1)
        (inet-attach (inet-linked (inet-port b 1)) a0)
        (inet-attach (inet-linked (inet-port b 2)) a1)
        ; the commutation square: each ai aux connects to the bj principals' aux, forming the 4 internal wires
        (inet-connect! (inet-port a0 1) (inet-port b0 1))
        (inet-connect! (inet-port a0 2) (inet-port b1 1))
        (inet-connect! (inet-port a1 1) (inet-port b0 2))
        (inet-connect! (inet-port a1 2) (inet-port b1 2))
        (inet-free! a) (inet-free! b)))))
; attach an outer endpoint (neighbour of a dying agent's aux) to the principal of a new copy
(define (inet-attach outer newagent)
  (cond ((>= outer 0) (inet-connect! outer (inet-port newagent 0)))
        (else (quote ok))))

; ---------- the reduction driver (iterative) ----------
(define (inet-reduce!) (inet-reduce-loop 0))
(define (inet-reduce-loop guard)
  (cond ((> guard 100000) inet-count)                          ; safety bound
        (else (let ((a (inet-find-active)))
                (cond ((< a 0) inet-count)
                      (else (begin (inet-interact! a) (inet-reduce-loop (+ guard 1)))))))))

(define (inet-caveat) (quote floor0-bare-interaction-net-reducer-polarity-no-labels-bet-EAL-fragment-not-yet-typed))
