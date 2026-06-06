; -*- lisp -*-
; src/cas/cadunsat.lisp -- a sound, cheap UNSATISFIABILITY FILTER for existential problems, a partial answer to
; completeness AT SCALE.  The cost of a complete cylindrical algebraic decomposition is doubly exponential in the
; number of variables (Davenport and Heintz, a theorem -- not a deficiency of any implementation), so for large
; problems the only way to stay fast is to settle the easy instances without building the decomposition.  cadwit.lisp
; does this for the satisfiable side, exhibiting a witness by a single descent; cadunsat does it for a class of the
; UNSATISFIABLE side, refuting a problem by a Positivstellensatz-style certificate that needs no decomposition and is
; independent of the number of variables.
;
; The refutation.  An existential conjunction is unsatisfiable as soon as one of its atoms is unsatisfiable in
; isolation, and a polynomial inequality atom can be refuted by a non-negativity certificate: if g is certifiably
; non-negative everywhere (a sum of squares, detected by the sos module), then
;   g < 0     is unsatisfiable (g is never negative),
;   -g > 0    is unsatisfiable (-g is never positive), and
;   g <= 0 together with g having no real zero (g strictly positive) is unsatisfiable.
; Symmetrically a certifiably non-positive g refutes g > 0.  When any conjunct is refuted this way the whole
; existential conjunction is unsatisfiable, established in time independent of the dimension -- no projection, no
; lifting, no cells.
;
; This is a FILTER, not a decision procedure: it returns 'unsat when it finds such a certificate and 'unknown
; otherwise (the problem may still be unsatisfiable for a reason no single-atom non-negativity certificate captures,
; or it may be satisfiable).  Its value is as a cheap front end: run cadunsat first, and only on 'unknown fall
; through to cadwit (for a witness) and then the complete deciders.  Soundness is one-directional and total -- a
; 'unsat verdict always corresponds to a genuinely empty solution set, because a non-negativity certificate is a
; theorem about all real points -- so the filter never turns a satisfiable problem away.
;
; Public:
;   cadunsat-filter phi   -> 'unsat (a non-negativity certificate refutes a conjunct) or 'unknown
;   cadunsat-atom? atom   -> #t if this single inequality atom is refutable by a non-negativity certificate
;
; An atom is (op . poly) with op one of pos / neg / zero / geq / leq over a univariate polynomial (low -> high);
; phi is an existential matrix, here an atom or an (and atom ...).  Builds on sos.lisp (the non-negativity and
; positivity certificates) and poly.lisp.

(import "cas/sos.lisp")
(import "cas/poly.lisp")

(define (cadunsat-op atom) (car atom))
(define (cadunsat-poly atom) (cdr atom))
(define (cadunsat-neg-poly p) (cadunsat-np p))
(define (cadunsat-np p) (if (null? p) (quote ()) (cons (- (car p)) (cadunsat-np (cdr p)))))

; is this single atom refutable -- unsatisfiable on its own -- by a non-negativity certificate?
(define (cadunsat-atom? atom) (cadunsat-classify (cadunsat-op atom) (cadunsat-poly atom)))
(define (cadunsat-classify op p)
  (cond ((equal? op (quote neg)) (sos-nonneg? p))          ; g < 0 but g >= 0 everywhere
        ((equal? op (quote pos)) (sos-nonneg? (cadunsat-neg-poly p)))  ; g > 0 but g <= 0 everywhere (-g >= 0)
        ((equal? op (quote leq)) (sos-positive? p))         ; g <= 0 but g > 0 everywhere
        ((equal? op (quote geq)) (sos-positive? (cadunsat-neg-poly p)))  ; g >= 0 but g < 0 everywhere (-g > 0)
        ((equal? op (quote zero)) (cadunsat-no-zero? p))    ; g = 0 but g has no real zero (g>0 or g<0 everywhere)
        (else #f)))
(define (cadunsat-no-zero? p) (cond ((sos-positive? p) #t) ((sos-positive? (cadunsat-neg-poly p)) #t) (else #f)))

; filter an existential matrix: 'unsat if any conjunct is refutable, else 'unknown
(define (cadunsat-filter phi)
  (cond ((cadunsat-is-and? phi) (if (cadunsat-any-refuted? (cdr phi)) (quote unsat) (quote unknown)))
        ((cadunsat-is-atom? phi) (if (cadunsat-atom? phi) (quote unsat) (quote unknown)))
        (else (quote unknown))))
(define (cadunsat-is-and? phi) (if (null? phi) #f (equal? (car phi) (quote and))))
(define (cadunsat-is-atom? phi) (if (null? phi) #f (cadunsat-known-op? (car phi))))
(define (cadunsat-known-op? op) (cond ((equal? op (quote pos)) #t) ((equal? op (quote neg)) #t) ((equal? op (quote zero)) #t) ((equal? op (quote geq)) #t) ((equal? op (quote leq)) #t) (else #f)))
(define (cadunsat-any-refuted? atoms) (cond ((null? atoms) #f) ((cadunsat-conjunct-refuted? (car atoms)) #t) (else (cadunsat-any-refuted? (cdr atoms)))))
(define (cadunsat-conjunct-refuted? a) (if (cadunsat-is-atom? a) (cadunsat-atom? a) #f))

(define (cadunsat-caveat) (quote sound-one-directional-sos-refutation-filter-dimension-independent))
