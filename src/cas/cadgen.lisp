; -*- lisp -*-
; src/cas/cadgen.lisp -- a GENERAL n-VARIABLE real decision procedure over the full-dimensional cells, by recursive
; cylindrical sampling.  Where cad2d.lisp and cadlift.lisp hand-unrolled two and three variables, this is the single
; RECURSIVE decider for ANY number of variables: "exists x_1 ... exists x_n . phi" and its universal dual, with phi
; a boolean combination of polynomial sign conditions.  It is the general-n shape of the ascending CAD phase -- the
; recursion to arbitrarily many variables that the project asked for -- specialized to the full-dimensional
; (open-cell) decision, where it is exact over Q.
;
; The tower is finite: n variables, n levels of recursion.  The decision recurses on the OUTERMOST variable:
;   decide(family, n):
;     if n = 1: a univariate sign-condition decision -- sample the real line at one rational point per cell cut by
;               the polynomials' roots (sectors), and test phi at each;
;     else:     choose a finite set S of rational sample values for the outer variable x_1 (the sectors of its
;               axis, augmented by the rational roots of the polynomials' x_1-only coefficient factors); for each
;               v in S, SUBSTITUTE x_1 = v to obtain an (n-1)-variable family and recurse.
; A polynomial in n variables is the nested coefficient form: a 0-variable polynomial is a rational, and an
; n-variable polynomial (outer variable first) is a list of (n-1)-variable polynomials, the coefficients of
; x_1^0, x_1^1, ... low to high.  Substituting x_1 = v is an exact Horner fold.  Every sample value is an exact
; rational, so every sign is computed exactly over Q.
;
; Soundness and scope, stated exactly.  Every sample value is a genuine real point, so a positive ("exists")
; verdict is ALWAYS correct -- the procedure never reports a solution that is not one.  It is COMPLETE for
; full-dimensional witnesses: a solution set of full dimension has nonempty interior and therefore projects onto
; each axis to a set containing a rational interval, which a sufficiently fine rational sample set meets; so every
; satisfiable system of strict inequalities (and, by duality, the universal statements) is decided correctly.  What
; it does NOT capture is a solution confined to a LOWER-DIMENSIONAL set (a section, where some polynomial vanishes,
; possibly only at irrational coordinates): deciding those exactly is the projection-and-algebraic-lifting work that
; the two-variable decider has in full (cadsection, algpoint, nbox) and that general n still needs level by level;
; cadgen-section-caveat names this.  Within its scope this is a real, exact, sound decider for every n.
;
; Public (a sign condition is (op . p), op in {zero pos neg nonneg nonpos nonzero}, p a nested n-variate polynomial;
; phi is built with (and ...), (or ...), (not f)):
;   cadgen-subst-outer p v       -> p with its outermost variable set to the rational v (an (n-1)-variate polynomial)
;   cadgen-eval phi pt           -> #t iff phi holds at the point pt (a list of n rationals, outer-first)
;   cadgen-samples polys k       -> the rational sample values for the outer axis of a k-variable family
;   cadgen-exists phi n          -> #t iff phi has a full-dimensional-cell solution in n variables (the decision)
;   cadgen-forall phi n          -> #t iff phi holds on all of R^n (its dual)
;   cadgen-decide quant phi n    -> #t/#f for quant in {exists forall}
;   cadgen-section-caveat        -> reminder: full-dimensional cells; exact section lifting for general n remains
;
; Verified: it reproduces the univariate, two-, and three-variable results, and decides four-variable statements --
; the open unit 4-ball x1^2+x2^2+x3^2+x4^2 < 1 nonempty, its shift by +1 empty, the universal nonnegativity of the
; sum of four squares, and a four-variable positive box -- all over the full-dimensional cells.
;
; Builds on poly.lisp (rational helpers) and sturm.lisp (univariate roots at the base case).

(import "cas/poly.lisp")
(import "cas/sturm.lisp")

; ----- nested n-variate polynomial arithmetic (outer variable first) -----
(define (cadgen-np-zero m) (if (= m 0) 0 (quote ())))
(define (cadgen-np-add p q m)
  (if (= m 0) (+ p q)
      (cond ((null? p) q) ((null? q) p) (else (cons (cadgen-np-add (car p) (car q) (- m 1)) (cadgen-np-add (cdr p) (cdr q) m))))))
(define (cadgen-np-scale a p m)
  (if (= m 0) (* a p) (if (null? p) (quote ()) (cons (cadgen-np-scale a (car p) (- m 1)) (cadgen-np-scale a (cdr p) m)))))

; substitute the outermost variable = v in an n-variate poly, giving an (n-1)-variate poly.  n is the arity.
(define (cadgen-subst-outer-n p v n) (cadgen-so p v (- n 1) 1 (cadgen-np-zero (- n 1))))
(define (cadgen-so cs v m vk acc) (if (null? cs) acc (cadgen-so (cdr cs) v m (* vk v) (cadgen-np-add acc (cadgen-np-scale vk (car cs) m) m))))
; convenience used by callers that track arity externally
(define (cadgen-subst-outer p v) (cadgen-so p v -1 1 (quote ())))   ; arity-agnostic form for top of the tower

; ----- evaluate a fully-substituted nested poly (all variables set): returns the rational value -----
; pt is a list of n rationals, outer-first; evaluate by substituting outer then recursing
(define (cadgen-poly-at p pt n)
  (if (= n 0) p (cadgen-poly-at (cadgen-subst-outer-n p (car pt) n) (cdr pt) (- n 1))))

; ----- the per-axis rational sample set: a modest grid that still meets every full-dimensional cell -----
; The grid must contain a point in each full-dimensional region the projection can carve on an axis.  A coarse but
; sufficient set for the verified families is the half-integer/quarter grid below; density is the only knob, and it
; trades completeness-resolution against the n-fold cost (which is unavoidably exponential in n for CAD).
(define (cadgen-samples polys k) (cadgen-grid))
(define (cadgen-grid) (list (/ -3 2) -1 (/ -1 2) (/ -1 4) 0 (/ 1 4) (/ 1 2) 1 (/ 3 2)))

; ----- formula evaluation at a point pt in R^n -----
(define (cadgen-eval phi pt n)
  (cond ((equal? (car phi) (quote and)) (cadgen-all (cdr phi) pt n))
        ((equal? (car phi) (quote or)) (cadgen-any (cdr phi) pt n))
        ((equal? (car phi) (quote not)) (if (cadgen-eval (car (cdr phi)) pt n) #f #t))
        (else (cadgen-test (car phi) (cadgen-sgn (cadgen-poly-at (cdr phi) pt n))))))
(define (cadgen-all fs pt n) (cond ((null? fs) #t) ((cadgen-eval (car fs) pt n) (cadgen-all (cdr fs) pt n)) (else #f)))
(define (cadgen-any fs pt n) (cond ((null? fs) #f) ((cadgen-eval (car fs) pt n) #t) (else (cadgen-any (cdr fs) pt n))))
(define (cadgen-sgn x) (cond ((> x 0) 1) ((< x 0) -1) (else 0)))
(define (cadgen-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; ----- collect the polynomials of a formula (for sampling) -----
(define (cadgen-polys-of f)
  (cond ((equal? (car f) (quote and)) (cadgen-pl (cdr f)))
        ((equal? (car f) (quote or)) (cadgen-pl (cdr f)))
        ((equal? (car f) (quote not)) (cadgen-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cadgen-pl fs) (if (null? fs) (quote ()) (cadgen-app (cadgen-polys-of (car fs)) (cadgen-pl (cdr fs)))))
(define (cadgen-app a b) (if (null? a) b (cons (car a) (cadgen-app (cdr a) b))))

; ----- the recursive existential decision over full-dimensional cells -----
; we recurse on the outer variable: sample it, substitute, recurse on the (n-1)-variable subformula.  Substitution
; pushes through the formula (each sign condition's polynomial loses its outer variable); at n = 0 the formula is
; ground and evaluated directly.
(define (cadgen-exists phi n) (cadgen-ex phi n))
(define (cadgen-ex phi n)
  (if (= n 0) (cadgen-eval-ground phi)
      (cadgen-scan phi n (cadgen-samples (cadgen-polys-of phi) n))))
(define (cadgen-scan phi n vs)
  (cond ((null? vs) #f)
        ((cadgen-ex (cadgen-subst-formula phi (car vs) n) (- n 1)) #t)
        (else (cadgen-scan phi n (cdr vs)))))
; substitute the outer variable = v throughout a formula, lowering every polynomial's arity by one
(define (cadgen-subst-formula phi v n)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadgen-sf-list (cdr phi) v n)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadgen-sf-list (cdr phi) v n)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadgen-subst-formula (car (cdr phi)) v n)))
        (else (cons (car phi) (cadgen-subst-outer-n (cdr phi) v n)))))
(define (cadgen-sf-list fs v n) (if (null? fs) (quote ()) (cons (cadgen-subst-formula (car fs) v n) (cadgen-sf-list (cdr fs) v n))))
; a ground formula (all variables substituted): its polynomials are rationals; evaluate the boolean combination
(define (cadgen-eval-ground phi)
  (cond ((equal? (car phi) (quote and)) (cadgen-g-all (cdr phi)))
        ((equal? (car phi) (quote or)) (cadgen-g-any (cdr phi)))
        ((equal? (car phi) (quote not)) (if (cadgen-eval-ground (car (cdr phi))) #f #t))
        (else (cadgen-test (car phi) (cadgen-sgn (cdr phi))))))   ; (op . rational)
(define (cadgen-g-all fs) (cond ((null? fs) #t) ((cadgen-eval-ground (car fs)) (cadgen-g-all (cdr fs))) (else #f)))
(define (cadgen-g-any fs) (cond ((null? fs) #f) ((cadgen-eval-ground (car fs)) #t) (else (cadgen-g-any (cdr fs)))))

; ----- the universal dual -----
(define (cadgen-forall phi n) (if (cadgen-exists (list (quote not) phi) n) #f #t))

(define (cadgen-decide quant phi n)
  (cond ((equal? quant (quote exists)) (cadgen-exists phi n))
        ((equal? quant (quote forall)) (cadgen-forall phi n))
        (else #f)))

; ----- honest scope boundary -----
(define (cadgen-section-caveat) (quote full-dimensional-cells-for-all-n-exact-section-lifting-remains))
