; FLOOR 0 of lizard's foundations: a bare INTERACTION-NET reduction engine (docs/CAS.md).  This is the computational
; substrate -- the parallel, local-rewriting analogue of the lambda calculus -- on which the typed layers and the
; Curry-Howard bridge are to be built.  By itself it is ONLY a computational system: no types, no logic yet.  The
; four 3-arrow agents are distinguished by PORT POLARITY (the in/out patterns), and the bet under test is that
; polarity alone -- with NO labels -- suffices to keep duplications from interfering (HVM/Lamping use labels; this
; wagers the four-polarity alphabet replaces them).  Polarity decides which principal-pairs may interact (a wire
; joins a producer + to an observer -, so principals interact only at opposite polarity, giving exactly the four
; pairs {LAM,DUP}x{APP,SUP}); matching decides annihilate vs commute (LAM~APP and DUP~SUP annihilate, LAM~DUP and
; APP~SUP commute), which is precisely the optimal-lambda-reduction rule set -- a correctness oracle.
(import "cas/inet.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (is-identity? g) (and (>= g 0) (= (inet-linked (inet-port g 1)) (inet-port g 2))))
(define (anchored-agent probe-aux-ep) (cond ((>= probe-aux-ep 0) (inet-ep-agent probe-aux-ep)) (else -1)))

(display "An interaction-net reducer: beta-reduction and duplication by local net rewriting.") (newline) (newline)

; polarity restricts the legal interaction table to exactly the producer-observer pairs
(must "LAM~APP is a matching (annihilating) pair" (inet-matching? inet-LAM inet-APP))
(must "DUP~SUP is a matching (annihilating) pair" (inet-matching? inet-DUP inet-SUP))
(must "LAM~DUP is NOT matching (it commutes)" (not (inet-matching? inet-LAM inet-DUP)))
(must "APP~SUP is NOT matching (it commutes)" (not (inet-matching? inet-APP inet-SUP)))

; (lambda x.x)(lambda y.y) beta-reduces to the identity
(inet-reset! 100)
(define id1 (inet-mk inet-LAM)) (inet-connect! (inet-port id1 1) (inet-port id1 2))
(define id2 (inet-mk inet-LAM)) (inet-connect! (inet-port id2 1) (inet-port id2 2))
(define ap (inet-mk inet-APP)) (define probe (inet-mk inet-LAM))
(inet-connect! (inet-port ap 0) (inet-port id1 0))
(inet-connect! (inet-port ap 1) (inet-port id2 0))
(inet-connect! (inet-port ap 2) (inet-port probe 1))
(inet-reduce!)
(must "(lambda x.x)(lambda y.y) reduces to normal form" (inet-normal-form?))
(must "the result is the identity lambda" (is-identity? (anchored-agent (inet-linked (inet-port probe 1)))))

; a duplicator copies a lambda into two identical copies (the LAM~DUP commute, no labels)
(inet-reset! 100)
(define lam (inet-mk inet-LAM)) (inet-connect! (inet-port lam 1) (inet-port lam 2))
(define dup (inet-mk inet-DUP))
(define pa (inet-mk inet-LAM)) (define pb (inet-mk inet-LAM))
(inet-connect! (inet-port dup 0) (inet-port lam 0))
(inet-connect! (inet-port dup 1) (inet-port pa 1))
(inet-connect! (inet-port dup 2) (inet-port pb 1))
(inet-reduce!)
(must "duplicating a lambda reaches normal form" (inet-normal-form?))
(must "the first copy is an identity lambda" (is-identity? (anchored-agent (inet-linked (inet-port pa 1)))))
(must "the second copy is an identity lambda" (is-identity? (anchored-agent (inet-linked (inet-port pb 1)))))

; composition: beta-reduction feeding a duplicator, all in one net
(inet-reset! 200)
(define f1 (inet-mk inet-LAM)) (inet-connect! (inet-port f1 1) (inet-port f1 2))
(define f2 (inet-mk inet-LAM)) (inet-connect! (inet-port f2 1) (inet-port f2 2))
(define ap2 (inet-mk inet-APP))
(inet-connect! (inet-port ap2 0) (inet-port f1 0))
(inet-connect! (inet-port ap2 1) (inet-port f2 0))
(define d2 (inet-mk inet-DUP)) (define qa (inet-mk inet-LAM)) (define qb (inet-mk inet-LAM))
(inet-connect! (inet-port ap2 2) (inet-port d2 0))
(inet-connect! (inet-port d2 1) (inet-port qa 1))
(inet-connect! (inet-port d2 2) (inet-port qb 1))
(inet-reduce!)
(must "beta-then-duplicate composes to normal form" (inet-normal-form?))
(must "both copies of the reduced result are identities"
  (and (is-identity? (anchored-agent (inet-linked (inet-port qa 1)))) (is-identity? (anchored-agent (inet-linked (inet-port qb 1))))))

(newline)
(display "The reducer performs beta-reduction (LAM~APP annihilation) and duplication (LAM~DUP commutation) by local") (newline)
(display "rewriting, with polarity alone deciding legality and no labels -- validated here on the core cases (the") (newline)
(display "elementary-affine fragment).  This is Floor 0, a bare computational engine; types, the cube of features, and") (newline)
(display "the Curry-Howard bridge are later floors and are NOT claimed yet (inet-caveat).") (newline)
