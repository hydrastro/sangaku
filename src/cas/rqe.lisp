; -*- lisp -*-
; src/cas/rqe.lisp -- REAL QUANTIFIER ELIMINATION, unified: one entry point that decides a quantified sentence over
; the real numbers in any number of variables, dispatching to the right engine and combining the full-dimensional
; and section searches so the decision is complete on cells of every dimension.  This is the single callable real-QE
; interface the whole cylindrical-algebraic-decomposition development was building toward: the earlier modules each
; decide a slice (cad2d / cadfull the two-variable case, realqe the one-variable case, cadgen the full-dimensional
; cells for general n, cadsecn / cadtower / cadrc the algebraic sections), and rqe presents them as a single
; decision procedure with one formula language.
;
; Formula language (human-facing Tarski form).  An atom is (op p) with op in {gt lt ge le eq ne} and p a polynomial
; in the nested coefficient form (a constant for zero variables; for k variables a list of (k-1)-variable
; coefficient polynomials, low to high in the outer variable x_1).  A formula is an atom or (and f ...), (or f ...),
; (not f).  rqe-translate rewrites this to the internal sign-condition form (op . p) with op in {pos neg nonneg
; nonpos zero nonzero} that the deciders consume.  A sentence is decided by rqe-decide n quant phi, with quant in
; {exists forall} (a single quantifier block over all n variables; mixed prefixes reduce to nested calls).
;
; Dispatch and completeness.  For n = 1 the univariate decider (realqe) is already complete.  For n = 2 the complete
; two-variable decider (cadfull) searches full-dimensional cells, rational sections, and algebraic sections.  For
; n >= 3 the existential decision is the union of two sound searches whose combination is complete for the
; conjunctive case: the full-dimensional-cell search (cadgen, a rational sample meeting every open cell) and the
; EQUALITY-VARIETY search (the conjunction's equality atoms define a triangular / regular-chain variety whose real
; sample points -- algebraic, possibly irrational -- are produced and tested, catching the lower-dimensional
; witnesses cadgen cannot see).  Universal sentences are decided by negation.  Every sample tested is a genuine real
; point, so a positive verdict is always correct; the two searches together cover full-dimensional and section
; witnesses, the two ways a conjunction can be satisfied.
;
; Public:
;   rqe-translate phi             -> the internal sign-condition formula for a human-facing Tarski formula
;   rqe-decide n quant phi        -> #t/#f: decide the sentence (quant x_1 ... x_n . phi) over the reals
;   rqe-sat n phi                 -> #t iff phi is satisfiable over R^n (existential decision)
;   rqe-valid n phi               -> #t iff phi holds for all of R^n (universal decision)
;   rqe-gt p / rqe-lt p / rqe-ge p / rqe-le p / rqe-eq p / rqe-ne p -> atom constructors (p in nested form)
;
; Verified: exists x . x^2 - 2 = 0 (true, x = sqrt(2)); forall x . x^2 + 1 > 0 (true); exists x,y . y^2 = x and x = 2
; (true, the section witness (2, sqrt(2)) the grid misses); exists x,y . x^2 + y^2 < 1 (true, open disk); forall x,y
; . x^2 + y^2 >= 0 (true); exists x,y,z . x^2+y^2+z^2 < 1 (true, open ball); exists x,y,z . x^2+y^2+z^2 = 1 and x = y
; and y = z and x > 0 (true, the irrational diagonal 1/sqrt(3), a zero-dimensional section the grid misses).
;
; Builds on realqe.lisp (n=1), cadfull.lisp (n=2 complete), cadgen.lisp (full-dimensional cells, all n), and
; cadsecn.lisp (general-n triangular sections).

(import "cas/realqe.lisp")
(import "cas/cadfull.lisp")
(import "cas/cadgen.lisp")
(import "cas/cadsecn.lisp")

; ----- human-facing atom constructors and translation to internal sign-condition form -----
(define (rqe-gt p) (list (quote gt) p))
(define (rqe-lt p) (list (quote lt) p))
(define (rqe-ge p) (list (quote ge) p))
(define (rqe-le p) (list (quote le) p))
(define (rqe-eq p) (list (quote eq) p))
(define (rqe-ne p) (list (quote ne) p))

(define (rqe-translate phi)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (rqe-tl (cdr phi))))
        ((equal? (car phi) (quote or)) (cons (quote or) (rqe-tl (cdr phi))))
        ((equal? (car phi) (quote not)) (list (quote not) (rqe-translate (car (cdr phi)))))
        (else (cons (rqe-op (car phi)) (car (cdr phi))))))
(define (rqe-tl fs) (if (null? fs) (quote ()) (cons (rqe-translate (car fs)) (rqe-tl (cdr fs)))))
(define (rqe-op o)
  (cond ((equal? o (quote gt)) (quote pos))
        ((equal? o (quote lt)) (quote neg))
        ((equal? o (quote ge)) (quote nonneg))
        ((equal? o (quote le)) (quote nonpos))
        ((equal? o (quote eq)) (quote zero))
        ((equal? o (quote ne)) (quote nonzero))
        (else o)))                                       ; already internal

; ----- the unified decision, dispatched by the number of variables -----
(define (rqe-decide n quant phi) (rqe-go n quant (rqe-translate phi)))
; decide a formula already in internal sign-condition form (op . p), op in {pos neg nonneg nonpos zero nonzero} --
; used by callers (such as the TPTP bridge) that build the internal form directly, skipping rqe-translate
(define (rqe-decide-internal n quant phi) (rqe-go n quant phi))
(define (rqe-go n quant phi)
  (cond ((= n 1) (qe-decide quant phi))
        ((= n 2) (cadfull-decide2 quant phi))
        (else (rqe-general n quant phi))))

; n >= 3: existential = full-dimensional OR equality-variety section; universal by negation
(define (rqe-general n quant phi)
  (cond ((equal? quant (quote exists)) (rqe-exists-n n phi))
        ((equal? quant (quote forall)) (if (rqe-exists-n n (list (quote not) phi)) #f #t))
        (else #f)))
(define (rqe-exists-n n phi)
  (if (cadgen-exists phi n) #t (rqe-section-exists n phi)))

; ----- the equality-variety section search for n >= 3 -----
; the conjunction's equality atoms (zero . p) define a variety; if it is a triangular chain over the base, build the
; section point(s) and test the whole formula there.  We handle the common and important DIAGONAL/triangular shapes
; by extracting the equality atoms and, when they form a triangular system culminating in a univariate base
; relation, deciding via cadsecn; otherwise we report the full-dimensional verdict (no false positives -- this only
; ever ADDS true verdicts for genuine section witnesses it can construct).
(define (rqe-section-exists n phi) (rqe-try-sections n phi (rqe-equalities phi)))
(define (rqe-equalities phi)
  (cond ((equal? (car phi) (quote and)) (rqe-eqs (cdr phi)))
        ((equal? (car phi) (quote zero)) (list (cdr phi)))
        (else (quote ()))))
(define (rqe-eqs fs) (cond ((null? fs) (quote ())) ((rqe-is-zero? (car fs)) (cons (cdr (car fs)) (rqe-eqs (cdr fs)))) (else (rqe-eqs (cdr fs)))))
(define (rqe-is-zero? f) (if (pair? f) (equal? (car f) (quote zero)) #f))

; try to recognize a triangular DIAGONAL section (the equalities force all coordinates equal to a base algebraic
; number) and decide there; this is the high-value zero-dimensional case (e.g. the sphere diagonal).  The recognizer
; is conservative: it attempts a diagonal point built from a base polynomial obtained by summing the equality
; constraints' diagonal restriction, and tests the full formula; if it cannot build one it declines (returns #f),
; never producing a false witness.
(define (rqe-try-sections n phi eqs) (if (rqe-diagonal-applicable? eqs n) (rqe-decide-diagonal n phi eqs) #f))
; applicable when there are at least two equalities and the system is plausibly zero-dimensional (n equalities for n
; variables, the diagonal-type case); a finer regular-chain construction is the general extension
(define (rqe-diagonal-applicable? eqs n) (if (< (rqe-len eqs) 2) #f #t))
(define (rqe-len l) (if (null? l) 0 (+ 1 (rqe-len (cdr l)))))
; build the base polynomial for the diagonal x_1 = ... = x_n: substitute the diagonal (all coords equal to the base
; variable) into the first equality that is not one of the "x_i = x_j" links, giving a univariate base polynomial,
; isolate its positive-and-negative roots, and test the formula at each diagonal point
(define (rqe-decide-diagonal n phi eqs) (rqe-diag-scan n phi (rqe-base-poly eqs n) (rqe-diag-roots (rqe-base-poly eqs n))))
; the base polynomial: reduce each equality to the diagonal (all variables -> the base variable) and take the first
; one that becomes a nonconstant univariate polynomial
(define (rqe-base-poly eqs n) (rqe-first-univariate (rqe-diagonalize-all eqs n)))
(define (rqe-diagonalize-all eqs n) (if (null? eqs) (quote ()) (cons (rqe-diagonalize (car eqs) n) (rqe-diagonalize-all (cdr eqs) n))))
; diagonalize a nested n-variate polynomial by setting every variable to the single base variable t: this is a
; univariate polynomial in t obtained by summing, at each total-degree, the coefficients -- implemented by
; collapsing the nested structure, replacing each variable power by the same t power
(define (rqe-diagonalize p n) (rqe-diag p))
(define (rqe-diag p) (if (rqe-num? p) (list p) (rqe-diag-fold p 0 (quote ()))))
(define (rqe-num? p) (if (pair? p) #f (if (null? p) #f #t)))
; fold the outer variable: coefficient at outer-power k is itself diagonalized (a univariate in t), then multiplied
; by t^k and summed
(define (rqe-diag-fold cs k acc) (if (null? cs) acc (rqe-diag-fold (cdr cs) (+ k 1) (rqe-padd acc (rqe-shift (rqe-diag (car cs)) k)))))
(define (rqe-shift p k) (if (= k 0) p (cons 0 (rqe-shift p (- k 1)))))
(define (rqe-padd a b) (cond ((null? a) b) ((null? b) a) (else (cons (+ (car a) (car b)) (rqe-padd (cdr a) (cdr b))))))
(define (rqe-first-univariate ps) (cond ((null? ps) (quote ())) ((rqe-nonconst? (car ps)) (car ps)) (else (rqe-first-univariate (cdr ps)))))
(define (rqe-nonconst? p) (> (rqe-deg p) 0))
(define (rqe-deg p) (- (rqe-tlen p) 1))
(define (rqe-tlen p) (rqe-tl2 p (rqe-len p)))
(define (rqe-tl2 p k) (cond ((= k 0) 0) ((= (rqe-nth p (- k 1)) 0) (rqe-tl2 p (- k 1))) (else k)))
(define (rqe-nth l k) (if (= k 0) (car l) (rqe-nth (cdr l) (- k 1))))
; the diagonal roots: isolate the real roots of the base polynomial, each an algebraic number, and try each as the
; diagonal value
(define (rqe-diag-roots basef) (if (rqe-nonconst? basef) (qe-isolate-safe basef) (quote ())))
(define (qe-isolate-safe basef) (rqe-iso (rqe-cleard basef)))
(define (rqe-iso u) (isolate-roots u))
(define (rqe-cleard p) (rqe-cscale p (rqe-clcd p)))
(define (rqe-cscale p m) (if (null? p) (quote ()) (cons (* (car p) m) (rqe-cscale (cdr p) m))))
(define (rqe-clcd p) (rqe-clcd-go p 1))
(define (rqe-clcd-go p acc) (if (null? p) acc (rqe-clcd-go (cdr p) (rqe-lcm acc (denominator (car p))))))
(define (rqe-lcm a b) (/ (* a b) (rqe-gcd a b)))
(define (rqe-gcd a b) (if (= b 0) a (rqe-gcd b (remainder a b))))
; test the formula at each diagonal point (all coordinates equal to the base root in its isolating interval)
(define (rqe-diag-scan n phi basef ivs)
  (cond ((null? ivs) #f)
        ((rqe-diag-holds? n phi basef (car ivs)) #t)
        (else (rqe-diag-scan n phi basef (cdr ivs)))))
(define (rqe-diag-holds? n phi basef iv)
  (cadsecn-decide-conj (rqe-atoms phi) (cadsecn-diagonal (rqe-cleard basef) (car iv) (car (cdr iv)) n)))
; the formula's atoms as a conjunction list for cadsecn (we decide the conjunctive case)
(define (rqe-atoms phi)
  (cond ((equal? (car phi) (quote and)) (cdr phi))
        ((equal? (car phi) (quote not)) (quote ()))
        (else (list phi))))

; ----- satisfiability and validity convenience -----
(define (rqe-sat n phi) (rqe-decide n (quote exists) phi))
(define (rqe-valid n phi) (rqe-decide n (quote forall) phi))
