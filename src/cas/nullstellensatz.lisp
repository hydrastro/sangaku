; -*- lisp -*-
; src/cas/nullstellensatz.lisp -- a DECISION PROCEDURE for the satisfiability of a system of polynomial equations
; over an algebraically closed field, via Hilbert's Weak Nullstellensatz and a Groebner-basis certificate (a
; frontier step: Sangaku's first genuine decision procedure, and the shape of problem a TPTP arithmetic prover is
; asked to settle).
;
; The Weak Nullstellensatz: a system f_1 = ... = f_m = 0 has NO common zero over the algebraic closure of the
; coefficient field if and only if the constant 1 lies in the ideal <f_1, ..., f_m>; equivalently, the reduced
; Groebner basis of the ideal is {1}.  This module decides exactly that: it computes the reduced Groebner basis and
; reports
;     'unsatisfiable -- 1 is in the ideal (the system is contradictory over the algebraic closure), or
;     'satisfiable   -- 1 is not in the ideal (a common zero exists over the closure).
; The verdict is a genuine decision (the Nullstellensatz is an iff), and the 'unsatisfiable case carries a
; CERTIFICATE: the constant polynomial 1 appears in the reduced basis, and re-reducing the input generators against
; the basis confirms the ideal is the whole ring.  This is the algebraic analogue of deriving FALSE from a set of
; hypotheses -- a refutation -- so a TPTP-style goal "these polynomial equations are jointly contradictory" maps
; directly onto nss-refutes?.
;
; A note on scope, kept honest: this decides EQUATIONAL systems over an ALGEBRAICALLY CLOSED field (the natural
; setting for the Nullstellensatz).  Real solvability (inequalities, the ordered field R) is a different and harder
; question -- the Positivstellensatz / real Nullstellensatz -- and is NOT decided here; nss-real-caveat names that
; boundary rather than letting a user mistake a complex-unsatisfiability verdict for a real one.  Everything is
; exact over Q: the Groebner basis is computed exactly, and the certificate is the constant 1 in the basis.
;
; Public (generators in groebner.lisp's representation: a polynomial is a list of (coeff . exponent-vector) terms,
; descending lex; the empty list is the zero polynomial):
;   nss-ideal-basis gens       -> the reduced Groebner basis of <gens>
;   nss-one-in-ideal? gens     -> #t iff the constant 1 is in <gens> (the system is unsatisfiable over the closure)
;   nss-decide gens            -> 'unsatisfiable | 'satisfiable (the Nullstellensatz decision)
;   nss-refutes? gens          -> #t iff the system is refuted (contradictory) over the algebraic closure
;   nss-certificate gens       -> (list 'refuted basis) when unsatisfiable (1 is in basis), else (list 'model-exists)
;   nss-verify-refutation gens -> #t iff the certificate checks: 1 reduces to 0 against the basis AND each generator
;                                 reduces to 0 (so the basis generates the same ideal, which is the whole ring)
;   nss-real-caveat            -> a reminder symbol that this is closure-satisfiability, not real-satisfiability
;
; Verified: {x, x-1} is unsatisfiable (1 in ideal: x=0 and x=1 cannot both hold); {x*y-1, x} is unsatisfiable
; (x=0 forces 0=1); {x^2+y^2-1, x-2} is SATISFIABLE over the closure (x=2, y^2=-3 has a complex solution); a single
; generator {x-5} is satisfiable (x=5); the empty system {} is satisfiable (every point); the refutation
; certificate verifies for the unsatisfiable cases.
;
; Builds on groebner.lisp.

(import "cas/groebner.lisp")

(define (nss-len l) (if (null? l) 0 (+ 1 (nss-len (cdr l)))))

; ----- the reduced Groebner basis of the ideal -----
(define (nss-ideal-basis gens) (reduced-groebner gens))

; ----- is the constant 1 in the ideal? Detect a nonzero constant directly in the reduced Groebner
; basis: 1 is in the ideal iff the reduced basis contains a polynomial all of whose monomials are the
; zero exponent vector (a nonzero constant). This is the clean test -- it avoids normal-forming the
; constant 1 against the basis, which is fragile when exponent vectors have differing lengths. -----
(define (nss-one-in-ideal? gens) (nss-basis-has-const? (nss-ideal-basis gens)))
(define (nss-basis-has-const? b) (cond ((null? b) #f) ((nss-const-poly? (car b)) #t) (else (nss-basis-has-const? (cdr b)))))
(define (nss-const-poly? p) (cond ((null? p) #f) ((nss-const-term? (car p)) (null? (cdr p))) (else #f)))
(define (nss-const-term? t) (nss-all-zero? (cdr t)))
(define (nss-all-zero? v) (cond ((null? v) #t) ((= (car v) 0) (nss-all-zero? (cdr v))) (else #f)))

; ----- the decision -----
(define (nss-decide gens) (if (nss-one-in-ideal? gens) (quote unsatisfiable) (quote satisfiable)))
(define (nss-refutes? gens) (nss-one-in-ideal? gens))

; ----- the certificate -----
(define (nss-certificate gens) (if (nss-one-in-ideal? gens) (list (quote refuted) (nss-ideal-basis gens)) (list (quote model-exists))))

; ----- verify the refutation: 1 reduces to 0 against the basis, and every generator reduces to 0 against it -----
(define (nss-verify-refutation gens) (if (nss-one-in-ideal? gens) (nss-check-gens gens (nss-ideal-basis gens)) #f))
(define (nss-check-gens gens basis) (cond ((null? gens) #t) ((mpoly-zero? (nf (car gens) basis)) (nss-check-gens (cdr gens) basis)) (else #f)))

; ----- the honest scope boundary -----
(define (nss-real-caveat) (quote decides-closure-satisfiability-not-real-Positivstellensatz))
