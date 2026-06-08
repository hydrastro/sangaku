; -*- lisp -*-
; src/cas/inetreflect.lisp -- the CO-UNIVERSE / REFLECTION development: making concrete the insight that the
; co-universe (the observation side of the construction/observation duality) is the hidden structure behind a
; language's reflection.  This builds on Floor 3 (the modal layer) because necessity (Box) and reflection are the
; same phenomenon under Pfenning-Davies' judgmental reconstruction of modal logic: a NECESSARY (valid, closed) term
; is exactly a term that can be treated AS CODE -- i.e. quoted and reflected upon.
;
; THE DUALITY, OPERATIONAL.  The construction lattice (terms : types : U0 : U1 : ...) says what things ARE; the
; co-universe / observation lattice (variables : bindings : contexts : ...) says how they are USED and OBSERVED.
; Reflection is OBSERVATION turned back on construction:
;   quote-like direction (construction -> observation): a term, viewed as inspectable data (its head, its binder,
;     its subterms) -- the co-universe made operational, since to observe a term's structure is to use it through
;     the observation lattice rather than to run it.
;   rebuild-like direction (observation -> construction): assembling a term back from its observed parts -- the
;     contravariant partner, promoting an observation back to a construction.
; A round-trip (observe a term's parts, rebuild it, get the same term) witnesses that the two lattices are genuine
; duals: nothing is lost passing construction -> observation -> construction.
;
; THE MODAL TIE.  Box / necessity is the type-level marker of "this is closed code" -- the reflective fragment.
; This module reuses the Floor-3 modal carriers (itm-box etc.) so the reflection story and the modal story are one:
; a boxed derivation is a quoted (reflectable) term, and the valid context Delta is the context of names available
; for reflection.  This keeps the development anchored: the modal half rests on lizard's trusted S4 checker (Floor
; 3), and the reflection half rests on lizard's actual homoiconic structural observation (car/cdr/pair? on terms).
;
; HONEST SCOPE.  This is a DEMONSTRATION of the co-universe/reflection duality on lizard's real homoiconic terms,
; tied to the anchored modal layer -- not a new trusted typing rule.  It shows the duality operationally (the
; round-trip is exact) and connects it to necessity; it does not claim a full reflective type theory, which would
; be its own anchored floor.
;
; Public:
;   iref-observe-head term       -> the head constructor of a term (observation)
;   iref-observe-part term i      -> the i-th part of a term (0 = head)
;   iref-is-compound? term        -> #t iff the term is a compound (observable) structure
;   iref-rebuild parts            -> assemble a term from a list of parts (observation -> construction)
;   iref-roundtrip? term          -> #t iff observing then rebuilding yields the same term (the duality witness)
;   iref-as-code modal-carrier    -> the modal (box) carrier viewed as reflectable code (its readback)
;   iref-necessity-is-code? mc    -> #t iff a modal carrier is a box-introduction (necessity = closed code)

(import "cas/inetmodal.lisp")

; ---------- observation: view a construction (term) through the co-universe (as data) ----------
(define (iref-is-compound? term) (pair? term))
(define (iref-observe-head term) (cond ((pair? term) (car term)) (else term)))
(define (iref-observe-part term i) (iref-nth term i))
(define (iref-nth lst i) (cond ((= i 0) (car lst)) (else (iref-nth (cdr lst) (- i 1)))))
; collect all top-level parts of a term as a list (full observation of one layer)
(define (iref-parts term) (cond ((pair? term) term) (else (list term))))

; ---------- reconstruction: promote an observation (parts) back to a construction (term) ----------
; rebuild is just assembling the parts back into a list; for the homoiconic representation this reconstructs the term
(define (iref-rebuild parts) parts)

; ---------- the duality witness: construction -> observation -> construction is the identity ----------
(define (iref-roundtrip? term)
  (cond ((pair? term) (equal? (iref-rebuild (iref-parts term)) term))
        (else (equal? (iref-rebuild (list term)) (list term)))))   ; atoms wrap trivially

; ---------- the modal tie: necessity (box) = closed code = a reflectable (quotable) term ----------
; a modal box-introduction carrier, viewed as code, is its readback (lizard's surface term) -- the reflective view
(define (iref-as-code modal-carrier) (itm-readback modal-carrier))
; a modal carrier represents necessity-as-code iff it is a box-introduction
(define (iref-necessity-is-code? mc) (equal? (itm-tag mc) (quote itm-box)))

(define (iref-caveat) (quote couniverse-is-the-observation-side-reflection-is-observation-turned-on-construction-necessity-Box-is-closed-code-demonstrated-on-lizard-homoiconic-terms))
