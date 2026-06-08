; FLOOR 1 of lizard's foundations: a SIMPLY-TYPED discipline over the interaction-net substrate, with a type-checker
; (docs/CAS.md, docs/LIZARD_FOUNDATIONS.md).  Floor 0 (inet) gives bare reduction; this floor gives the agents a
; type and a checker that accepts or rejects a net.  It is the lambda-arrow base of the cube of features -- the
; analogue of simply-typed lambda calculus as the base of Barendregt's cube -- and is NOT yet polymorphism,
; dependency, or HoTT; those are higher floors and are not claimed here.  Types live ON THE PORTS, so checking is
; local wire-consistency (a producer-of-T meeting an observer-of-T), making the construction/observation duality a
; literal property of every wire.  This is where the Curry-Howard bridge first appears: a closed well-typed net
; whose free port has type A -> A is a proof of A -> A.
(import "cas/stnet.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define A (quote o))
(define T (stnet-arr A A))

(display "Simply-typed interaction nets: a type-checker, subject reduction, proofs-as-nets.") (newline) (newline)

; the typed identity lambda x.x : o -> o is well-typed, and is a proof of o -> o
(stnet-reset! 50)
(define id (inet-mk inet-LAM))
(inet-connect! (inet-port id 1) (inet-port id 2))
(stnet-set-type! (inet-port id 0) (stnet-arr A A))
(stnet-set-type! (inet-port id 1) A)
(stnet-set-type! (inet-port id 2) A)
(must "the LAM typing rule holds for the identity" (stnet-check-agent id))
(must "the var<->body wire is type- and polarity-consistent" (stnet-check-wire (inet-port id 1)))
(must "the identity net is well-typed at o -> o (a proof of o -> o)" (stnet-check))

; an ill-typed net is rejected: body claims a different base type than the principal's codomain
(stnet-reset! 50)
(define bad (inet-mk inet-LAM))
(inet-connect! (inet-port bad 1) (inet-port bad 2))
(stnet-set-type! (inet-port bad 0) (stnet-arr (quote o) (quote o)))
(stnet-set-type! (inet-port bad 1) (quote o))
(stnet-set-type! (inet-port bad 2) (quote nat))
(must "a net with body:nat under principal (o->o) is rejected" (not (stnet-check)))

; a typed application, and SUBJECT REDUCTION: well-typed before AND after reduction
(stnet-reset! 200)
(define f1 (inet-mk inet-LAM))
(inet-connect! (inet-port f1 1) (inet-port f1 2))
(stnet-set-type! (inet-port f1 0) (stnet-arr T T))
(stnet-set-type! (inet-port f1 1) T)
(stnet-set-type! (inet-port f1 2) T)
(define f2 (inet-mk inet-LAM))
(inet-connect! (inet-port f2 1) (inet-port f2 2))
(stnet-set-type! (inet-port f2 0) T)
(stnet-set-type! (inet-port f2 1) A)
(stnet-set-type! (inet-port f2 2) A)
(define ap (inet-mk inet-APP))
(stnet-set-type! (inet-port ap 0) (stnet-arr T T))
(stnet-set-type! (inet-port ap 1) T)
(stnet-set-type! (inet-port ap 2) T)
(inet-connect! (inet-port ap 0) (inet-port f1 0))
(inet-connect! (inet-port ap 1) (inet-port f2 0))
(must "the typed application is well-typed before reduction" (stnet-check))
(inet-reduce!)
(must "it reduces to normal form" (inet-normal-form?))
(must "it is STILL well-typed after reduction (subject reduction / type preservation)" (stnet-check))

; the polarity discipline: a LAM principal is an observer (-1), an APP principal a producer (+1)
(stnet-reset! 50)
(define lp (inet-mk inet-LAM)) (define apx (inet-mk inet-APP))
(must "a LAM principal is an observer (-1) and an APP principal a producer (+1)"
  (and (= (stnet-port-pol (inet-port lp 0)) -1) (= (stnet-port-pol (inet-port apx 0)) 1)))

(newline)
(display "Types on the ports make checking a single local pass over wires and agents; the beta interaction") (newline)
(display "preserves typing, so a well-typed net stays well-typed under reduction; and a closed well-typed net is a") (newline)
(display "proof of the implication its type names.  This is the simply-typed base of the cube -- one floor, verified;") (newline)
(display "polymorphism, dependency, and the full Curry-Howard correspondence are higher floors (stnet-caveat).") (newline)
