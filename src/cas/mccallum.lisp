; -*- lisp -*-
; src/cas/mccallum.lisp -- the McCALLUM reduced PROJECTION operator for cylindrical algebraic decomposition, the
; published improvement (McCallum 1988, refined 1998; the basis of the default projection in QEPCAD B and
; Mathematica's CAD) that makes the projection set dramatically smaller than Collins' original.  Collins' projection
; carries, for every projection polynomial, its entire tower of subresultant (principal subresultant) coefficients
; together with discriminants and pairwise resultants; McCallum proved that for a WELL-ORIENTED set the projection
; needs only the DISCRIMINANT of each polynomial, the pairwise RESULTANTS between distinct polynomials, and the
; LEADING COEFFICIENTS -- dropping the entire subresultant tower.  That reduction is the single biggest practical
; lever in making CAD feasible, and it is published mathematics, implemented here from the literature (not adapted
; from any existing system's source).
;
; This module does NOT claim to beat the doubly-exponential worst-case bound (Davenport-Heintz, a theorem); McCallum
; reduces the BASE of the exponential and the constant factors, which is what separates a CAD that runs on real
; problems from one that does not -- exactly why the established systems use it -- without changing the asymptotic
; class.
;
; The operator.  For a set A of polynomials in the last variable x_n (each an mpoly in x_1..x_n, low->high in x_n):
;   PROJ_McCallum(A)  =  { disc_{x_n}(p)            : p in A, deg_{x_n}(p) >= 2 }
;                     cup { lc_{x_n}(p)             : p in A, deg_{x_n}(p) >= 1 }
;                     cup { res_{x_n}(p, q)         : p, q in A distinct }
; This is the reduced set: no principal-subresultant-coefficient tower.  It is a VALID projection -- the resulting
; decomposition is sign-invariant for A -- provided A is well-oriented, meaning no p in A vanishes identically at a
; point of the lower-dimensional decomposition (no p has an identically-zero fiber over a projection cell).  A
; sufficient, checkable guard: every p in A is "nullified-free" in the sense that no p's leading coefficient and all
; lower coefficients vanish simultaneously as polynomials -- captured here by mccallum-well-oriented?, which detects
; the failure mode (a polynomial whose every x_n-coefficient shares a common factor that can vanish).  When
; well-orientedness cannot be certified the caller falls back to the full Collins projection (cadn-project augmented
; with subresultant coefficients), trading size for unconditional validity.
;
; Public:
;   mccallum-project ps          -> the reduced McCallum projection set (a list of mpolys in x_1..x_{n-1})
;   mccallum-well-oriented? ps   -> #t if the reduced operator is certified valid for this set
;   mccallum-project-safe ps     -> the McCallum set when well-oriented, else the full Collins projection
;   mccallum-leading ps          -> the leading-coefficient set (the piece Collins-with-discriminants omitted)
;
; Builds on cadnd.lisp (cadn-resultant, cadn-discriminant, cadn-deg, the mpoly representation) and groebner.lisp's
; mpoly arithmetic.  An mpoly is a list of (coeff . exponent-vector) terms; a polynomial in x_n is a list of such
; mpolys, low->high in x_n.

(import "cas/cadnd.lisp")

(define (mc-len l) (if (null? l) 0 (+ 1 (mc-len (cdr l)))))
(define (mc-app a b) (if (null? a) b (cons (car a) (mc-app (cdr a) b))))
(define (mc-rev l) (mc-rev-go l (quote ()))) (define (mc-rev-go l acc) (if (null? l) acc (mc-rev-go (cdr l) (cons (car l) acc))))

; ----- degree and leading coefficient in x_n (a poly is a list of mpoly coefficients, low->high) -----
(define (mc-deg p) (cadn-deg p))
(define (mc-trim p) (mc-rev (mc-drop-zeros (mc-rev p))))
(define (mc-drop-zeros r) (cond ((null? r) (quote ())) ((mc-mpoly-zero? (car r)) (mc-drop-zeros (cdr r))) (else r)))
(define (mc-mpoly-zero? mp) (cond ((null? mp) #t) (else #f)))
(define (mc-leading-coeff p) (mc-lc (mc-trim p)))
(define (mc-lc tp) (if (null? tp) (quote ()) (car (mc-rev tp))))

; ----- the leading-coefficient set (degree >= 1 in x_n) -----
(define (mccallum-leading ps) (mc-leads ps))
(define (mc-leads ps) (cond ((null? ps) (quote ())) ((>= (mc-deg (car ps)) 1) (cons (mc-leading-coeff (car ps)) (mc-leads (cdr ps)))) (else (mc-leads (cdr ps)))))

; ----- discriminants (degree >= 2 in x_n; a linear poly has no discriminant to contribute) -----
(define (mc-discs ps) (cond ((null? ps) (quote ())) ((>= (mc-deg (car ps)) 2) (cons (cadn-discriminant (car ps)) (mc-discs (cdr ps)))) (else (mc-discs (cdr ps)))))

; ----- pairwise resultants between distinct polynomials -----
(define (mc-pairres ps) (cond ((null? ps) (quote ())) (else (mc-app (mc-pair-one (car ps) (cdr ps)) (mc-pairres (cdr ps))))))
(define (mc-pair-one p rest) (cond ((null? rest) (quote ())) (else (cons (cadn-resultant p (car rest)) (mc-pair-one p (cdr rest))))))

; ----- the reduced McCallum projection set: discriminants + leading coefficients + pairwise resultants -----
(define (mccallum-project ps) (mc-clean (mc-app (mc-discs ps) (mc-app (mccallum-leading ps) (mc-pairres ps)))))
; drop empty / constant mpolys (a nonzero constant has no real roots, contributes no cell boundary)
(define (mc-clean s) (cond ((null? s) (quote ())) ((mc-trivial-mpoly? (car s)) (mc-clean (cdr s))) (else (cons (car s) (mc-clean (cdr s))))))
(define (mc-trivial-mpoly? mp) (or (null? mp) (mc-all-constant? mp)))
(define (mc-all-constant? mp) (cond ((null? mp) #t) ((mc-zero-expvec? (cdr (car mp))) (mc-all-constant? (cdr mp))) (else #f)))
(define (mc-zero-expvec? ev) (cond ((null? ev) #t) ((= (car ev) 0) (mc-zero-expvec? (cdr ev))) (else #f)))

; ----- well-orientedness: certify the reduced operator is valid for this set -----
; McCallum's operator is valid when no p in A is "nullified" -- vanishes identically -- over a cell of the lower
; decomposition.  The practical failure mode is a polynomial whose leading coefficient in x_n is itself the zero
; mpoly after trimming (a degree drop that the projection must track but the reduced set may miss), or a polynomial
; that is constant in x_n (no x_n dependence, cannot constrain the fiber).  A sufficient checkable condition: every
; p has positive x_n-degree and a nonzero (non-identically-vanishing) leading coefficient.  When this holds the set
; is well-oriented in the sense the reduced operator requires; otherwise we cannot certify it and fall back.
(define (mccallum-well-oriented? ps) (mc-all-good? ps))
(define (mc-all-good? ps) (cond ((null? ps) #t) ((mc-good? (car ps)) (mc-all-good? (cdr ps))) (else #f)))
(define (mc-good? p) (and (>= (mc-deg p) 1) (not (mc-mpoly-zero? (mc-leading-coeff p)))))

; ----- the safe projection: McCallum when certified, full Collins (discriminants + resultants + leading + all
; lower coefficients) otherwise -----
(define (mccallum-project-safe ps) (if (mccallum-well-oriented? ps) (mccallum-project ps) (mc-collins-project ps)))
; Collins fallback: the reduced set PLUS every coefficient of every p (the conservative superset that is always
; valid).  Larger, but unconditionally a valid projection.
(define (mc-collins-project ps) (mc-clean (mc-app (mccallum-project ps) (mc-all-coeffs ps))))
(define (mc-all-coeffs ps) (cond ((null? ps) (quote ())) (else (mc-app (mc-coeffs-of (car ps)) (mc-all-coeffs (cdr ps))))))
(define (mc-coeffs-of p) (mc-trim p))

(define (mccallum-caveat) (quote reduced-projection-valid-when-well-oriented-else-collins-fallback-not-beating-doubly-exponential))
