; THE CO-UNIVERSE / REFLECTION development: making concrete the insight that the co-universe -- the OBSERVATION side
; of the construction/observation duality -- is the hidden structure behind a language's reflection.  Built on the
; modal floor (Floor 3) because, under Pfenning-Davies' judgmental reconstruction of modal logic, necessity (Box)
; and reflection are the same phenomenon: a NECESSARY (valid, closed) term is exactly one that can be treated AS
; CODE -- quoted and reflected upon.
;
; The construction lattice (terms : types : U0 : ...) says what things ARE; the co-universe / observation lattice
; (variables : bindings : contexts : ...) says how they are OBSERVED.  Reflection is observation turned back on
; construction: viewing a term as inspectable data (head, binder, subterms) is the construction -> observation
; direction; rebuilding a term from its observed parts is the contravariant observation -> construction direction.
; A round-trip that returns the same term witnesses that the two lattices are genuine duals.  This is demonstrated
; on lizard's REAL homoiconic terms, tied to the anchored modal layer; it is a demonstration of the duality, not a
; new trusted typing rule.
(import "cas/inetreflect.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "The co-universe is the observation side; reflection is observation turned back on construction.") (newline) (newline)

; a construction: a term (here a lambda, lizard's homoiconic representation)
(define term (quote (lam (x A) x)))

; OBSERVATION (construction -> co-universe): view the term's structure as data
(must "observe the head constructor of (lam (x A) x) is 'lam" (equal? (iref-observe-head term) (quote lam)))
(must "the term is a compound (observable) structure" (iref-is-compound? term))
(must "observe the binder (part 1) is (x A)" (equal? (iref-observe-part term 1) (quote (x A))))
(must "observe the body (part 2) is x" (equal? (iref-observe-part term 2) (quote x)))

; RECONSTRUCTION (co-universe -> construction): rebuild the term from its observed parts
(must "rebuild from observed parts yields a term" (iref-is-compound? (iref-rebuild (iref-parts term))))

; THE DUALITY WITNESS: construction -> observation -> construction is the identity (nothing lost)
(must "round-trip (observe then rebuild) returns the SAME term -- the lattices are genuine duals"
  (iref-roundtrip? term))
(must "round-trip holds for a dependent type too: (Pi (x A) (app F x))"
  (iref-roundtrip? (quote (Pi (x A) (app F x)))))
(must "round-trip holds for an application: (app f a)"
  (iref-roundtrip? (quote (app f a))))

; THE MODAL TIE: necessity (Box) = closed code = a reflectable (quotable) term
(define boxed (itm-box (itm-sort 0)))           ; the modal carrier for (box (U 0))
(must "a box-introduction carrier represents necessity-as-code" (iref-necessity-is-code? boxed))
(must "viewing the necessity carrier AS CODE gives its surface term (box (U 0))"
  (equal? (iref-as-code boxed) (quote (box (U 0)))))
(must "the code view is itself observable (reflection is recursive): its head is 'box"
  (equal? (iref-observe-head (iref-as-code boxed)) (quote box)))

(newline)
(display "Observing a term's structure (head, binder, subterms) is the co-universe made operational; rebuilding from") (newline)
(display "those parts is the contravariant return; the round-trip loses nothing, witnessing the duality.  And the modal") (newline)
(display "Box -- necessity, anchored to the trusted S4 kernel in Floor 3 -- is exactly closed code, the reflective") (newline)
(display "fragment: a boxed term is a quoted term.  The co-universe is the hidden key behind reflection (iref-caveat).") (newline)
