; -*- lisp -*-
; src/cas/qedispatch.lisp -- a DISPATCHER for real existential decision problems: it routes each problem to the
; cheapest COMPLETE method instead of always paying for the heaviest.  This is what makes the decision layer fast in
; practice without ever sacrificing correctness -- it is a router over complete procedures, never a heuristic that
; might be wrong.  General real quantifier elimination is doubly exponential (Davenport-Heintz, a theorem), so the
; only honest way to be fast is to recognise the easy and structured cases and send them to a cheaper complete
; procedure, reserving the full cylindrical algebraic decomposition for the genuinely hard nonlinear problems.
;
; The routing, for a univariate existential sentence  exists x . phi  (phi a conjunction of polynomial sign atoms):
;   1. LINEAR fragment -- every atom's polynomial is linear in x -- is sent to Fourier-Motzkin (lra.lisp), complete
;      and single-exponential, the cheapest route.
;   2. Otherwise the cheap sound UNSAT FILTER (cadunsat.lisp) is tried: if a non-negativity certificate refutes a
;      conjunct, the problem is unsatisfiable with no decomposition built.  The filter is one-directional, so only a
;      'unsat verdict short-circuits; 'unknown falls through.
;   3. Otherwise the COMPLETE univariate decider (realqe.lisp, qe-decide) finishes the job, paying the CAD cost only
;      when the structure genuinely requires it.
; Every branch is a complete procedure for the cases it accepts, and the branches agree where they overlap (verified
; in the examples), so the dispatcher's verdict equals the full decider's verdict on every problem -- only faster.
;
; The dispatcher also REPORTS its route (qedispatch-route), so a caller can see which method decided a problem and
; why; this is the transparency that lets the fast paths be trusted.
;
; Public:
;   qedispatch-decide phi   -> #t / #f : the satisfiability of  exists x . phi, via the cheapest complete route
;   qedispatch-route phi    -> the method chosen: 'linear-fourier-motzkin / 'unsat-filter / 'cad-complete
;   qedispatch-linear? phi  -> #t iff every atom of phi is linear in the single variable
;
; phi is an atom (op . poly) or (and atom ...) with op in {pos neg zero nonneg nonpos} over a univariate polynomial
; (coefficients low -> high), x being the single variable.  Builds on realqe.lisp, lra.lisp, cadunsat.lisp.

(import "cas/realqe.lisp")
(import "cas/lra.lisp")
(import "cas/cadunsat.lisp")

(define (qd-len l) (if (null? l) 0 (+ 1 (qd-len (cdr l)))))
(define (qd-and? phi) (if (null? phi) #f (equal? (car phi) (quote and))))
(define (qd-atoms phi) (if (qd-and? phi) (cdr phi) (list phi)))
(define (qd-op a) (car a))
(define (qd-poly a) (cdr a))

; ----- linearity test: every atom's polynomial has degree <= 1 in x -----
(define (qedispatch-linear? phi) (qd-all-linear? (qd-atoms phi)))
(define (qd-all-linear? atoms) (cond ((null? atoms) #t) ((qd-linear-poly? (qd-poly (car atoms))) (qd-all-linear? (cdr atoms))) (else #f)))
(define (qd-linear-poly? p) (<= (qd-deg p) 1))
(define (qd-deg p) (- (qd-len (qd-trim p)) 1))
(define (qd-trim p) (if (null? p) (quote ()) (if (= (qd-last p) 0) (qd-trim (qd-but-last p)) p)))
(define (qd-last l) (if (null? (cdr l)) (car l) (qd-last (cdr l))))
(define (qd-but-last l) (if (null? (cdr l)) (quote ()) (cons (car l) (qd-but-last (cdr l)))))

; ----- the route decision -----
(define (qedispatch-route phi)
  (cond ((qedispatch-linear? phi) (quote linear-fourier-motzkin))
        ((equal? (cadunsat-filter (qd-to-unsat phi)) (quote unsat)) (quote unsat-filter))
        (else (quote cad-complete))))

; ----- the decision, taking the chosen route -----
(define (qedispatch-decide phi)
  (cond ((qedispatch-linear? phi) (qd-decide-linear phi))
        ((equal? (cadunsat-filter (qd-to-unsat phi)) (quote unsat)) #f)
        (else (qe-decide (quote exists) phi))))

; --- linear route: translate atoms to lra constraints over the single variable, decide with Fourier-Motzkin ---
; a univariate atom (op . (c0 c1)) becomes an lra constraint in one variable (index 1):
;   nonneg p -> (ge c0 c1) ; pos p -> (gt c0 c1) ; zero p -> (eq c0 c1)
;   nonpos p -> (ge -c0 -c1) ; neg p -> (gt -c0 -c1)
(define (qd-decide-linear phi) (lra-sat? 1 (qd-constraints (qd-atoms phi))))
(define (qd-constraints atoms) (if (null? atoms) (quote ()) (cons (qd-constraint (car atoms)) (qd-constraints (cdr atoms)))))
(define (qd-constraint a) (qd-mk (qd-op a) (qd-pad2 (qd-poly a))))
(define (qd-pad2 p) (list (qd-c0 p) (qd-c1 p)))
(define (qd-c0 p) (if (null? p) 0 (car p)))
(define (qd-c1 p) (if (null? p) 0 (if (null? (cdr p)) 0 (car (cdr p)))))
(define (qd-mk op pr)
  (let ((c0 (car pr)) (c1 (car (cdr pr))))
    (cond ((equal? op (quote nonneg)) (list (quote ge) c0 c1))
          ((equal? op (quote ge)) (list (quote ge) c0 c1))
          ((equal? op (quote pos)) (list (quote gt) c0 c1))
          ((equal? op (quote gt)) (list (quote gt) c0 c1))
          ((equal? op (quote zero)) (list (quote eq) c0 c1))
          ((equal? op (quote eq)) (list (quote eq) c0 c1))
          ((equal? op (quote nonpos)) (list (quote ge) (- 0 c0) (- 0 c1)))
          ((equal? op (quote le)) (list (quote ge) (- 0 c0) (- 0 c1)))
          ((equal? op (quote neg)) (list (quote gt) (- 0 c0) (- 0 c1)))
          ((equal? op (quote lt)) (list (quote gt) (- 0 c0) (- 0 c1)))
          (else (list (quote ge) c0 c1)))))

; --- the UNSAT filter expects ops pos/neg/zero/geq/leq; map nonneg->geq, nonpos->leq for the filter only ---
(define (qd-to-unsat phi) (if (qd-and? phi) (cons (quote and) (qd-map-atoms (cdr phi))) (qd-map-atom phi)))
(define (qd-map-atoms atoms) (if (null? atoms) (quote ()) (cons (qd-map-atom (car atoms)) (qd-map-atoms (cdr atoms)))))
(define (qd-map-atom a) (cons (qd-map-op (qd-op a)) (qd-poly a)))
(define (qd-map-op op) (cond ((equal? op (quote nonneg)) (quote geq)) ((equal? op (quote nonpos)) (quote leq)) (else op)))

(define (qedispatch-caveat) (quote routes-to-cheapest-complete-method-linear-FM-then-unsat-filter-then-CAD-verdict-equals-full-decider))
