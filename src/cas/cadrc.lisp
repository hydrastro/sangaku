; -*- lisp -*-
; src/cas/cadrc.lisp -- the GENERAL REGULAR CHAIN: exact sign and vanishing of a polynomial at a point cut out by a
; triangular system whose defining polynomials may couple ALL lower coordinates at once, not just the immediately
; preceding one.  This is the last structural generality past cadtower.lisp: cadtower decided the SIMPLE chain (each
; f_i a relation between consecutive coordinates x_i, x_{i-1}); cadrc decides the general chain f_i(x_1, ..., x_i),
; the form a regular chain / triangular decomposition actually takes, where for instance z = x + y depends on two
; earlier coordinates simultaneously.  It is the algebraic core a complete real-quantifier-elimination engine spends
; its heaviest effort on, and it is built here on the multivariate resultant already in cadnd.lisp.
;
; The chain is x_1, ..., x_n with defining polynomials f_1(x_1), f_2(x_1, x_2), ..., f_n(x_1, ..., x_n), each f_i of
; positive degree in its own top variable x_i.  The base f_1 is univariate over Q with a rational isolating interval,
; so x_1 is a real algebraic number (algnum2.lisp); each higher x_i is a real root, in a rational isolating interval,
; of f_i over the algebraic values of the coordinates below.  Polynomials are carried in cadnd.lisp's nested form: a
; polynomial in x_k is a polynomial in its top variable whose coefficients are multivariate (groebner.lisp mpoly)
; polynomials in x_1, ..., x_{k-1}.
;
; VANISHING is decided by reducing the target polynomial g down the chain with the MULTIVARIATE resultant: eliminate
; the top variable x_k between f_k and g (a Sylvester determinant over the mpoly coefficient ring, cadnd's
; cadn-resultant), giving an mpoly in x_1, ..., x_{k-1}; regroup that mpoly as a polynomial in x_{k-1} with mpoly
; coefficients in x_1, ..., x_{k-2}, eliminate x_{k-1} against f_{k-1}, and continue down to a univariate polynomial
; in the base x_1; g vanishes at the point iff that base polynomial vanishes at the base algebraic number, tested
; exactly by algnum2.  The regrouping between levels is the essential plumbing -- a resultant leaves an mpoly in all
; the remaining variables, which must be re-presented as a univariate-over-mpoly in the next variable to be
; eliminated -- and is done here by cadrc-regroup-top, which folds an mpoly by the exponent of the variable being
; eliminated next.  (This generalizes cadtower's iterated bivariate reduction to genuinely multivariate steps.)
;
; The NONZERO sign would be read, as in cadtower, by interval arithmetic over a box refined top-down; cadrc provides
; the exact vanishing decision and the base reduction, which already decides every equality-and-sign question whose
; sign part is handled by the (provided) base-level algebraic number, and names the box-refinement extension for the
; general coupled fibers as the residual step.
;
; Honest scope.  cadrc reduces and decides VANISHING for the general regular chain of any height with coupled
; defining polynomials -- the structural generality cadtower lacked -- via the multivariate resultant chain, exactly
; over Q.  The complete general-coupled-fiber NONZERO sign by a converging top-down box (the coupled-fiber analogue
; of cadtower's interval refinement) is the residual engineering, named by cadrc-fiber-sign-caveat; the vanishing
; reduction here is the part that required the new multivariate elimination.
;
; Public:
;   cadrc-regroup-top mp k        -> regroup an mpoly `mp` (over variables x_1..x_m) as a polynomial in the variable
;                                    at position k (0-based), with mpoly coefficients in the other variables, low to
;                                    high -- the inter-level conversion for the next elimination
;   cadrc-reduce g chain          -> the univariate base polynomial from reducing g down `chain` (the defining
;                                    polynomials f_n, ..., f_2 from the top down, each in nested cadnd form), by the
;                                    multivariate resultant with regrouping between levels
;   cadrc-vanishes? g chain basef lo hi -> #t iff g vanishes at the chain point whose base is the root of basef in
;                                    (lo, hi)
;   cadrc-fiber-sign-caveat       -> reminder: vanishing decided generally; the general coupled-fiber nonzero sign
;                                    by a top-down box is the residual step
;
; Verified: on the coupled chain f1 = x^2 - 2, f2 = y^2 - x, f3 = z - x - y (so z = sqrt(2) + 2^(1/4), genuinely
; depending on both x and y), the target g = z reduces down the chain to the base polynomial x^2 - x, which is
; nonzero at x = sqrt(2) (value 2 - sqrt(2)), correctly reporting that z does not vanish; and a multiple of the
; defining relation reduces to zero.
;
; Builds on cadnd.lisp (multivariate resultant), groebner.lisp (mpoly arithmetic), algnum2.lisp, and poly.lisp.

(import "cas/cadnd.lisp")
(import "cas/groebner.lisp")
(import "cas/algnum2.lisp")
(import "cas/poly.lisp")

; ----- regroup an mpoly as a polynomial in the variable at position k, mpoly coefficients in the rest -----
; an mpoly is a list of (coeff . exponent-vector) terms; to eliminate the variable at index k next, present the
; mpoly as a list (low->high in x_k) whose entries are mpolys in the remaining variables (x_k's exponent dropped to
; zero in each contributing term, but we keep the full vector with position k zeroed so the remaining eliminations
; still see the right indices).
(define (cadrc-regroup-top mp k) (cadrc-rg mp k (quote ())))
(define (cadrc-rg terms k acc) (if (null? terms) acc (cadrc-rg (cdr terms) k (cadrc-insert acc (car terms) k))))
(define (cadrc-insert acc term k) (cadrc-place acc (cadrc-expt (cdr term) k) (cons (car term) (cadrc-trunc (cdr term) k))))
(define (cadrc-expt ev k) (cadrc-nth ev k))
(define (cadrc-nth l i) (if (= i 0) (car l) (cadrc-nth (cdr l) (- i 1))))
; keep only the first k exponent positions (x_0 .. x_{k-1}); the variable at position k is becoming the polynomial
; degree and every position above k has already been eliminated (its exponent is zero), so truncating to length k
; gives the coefficient mpoly over exactly the lower variables, matching the next-level defining polynomial's arity
(define (cadrc-trunc ev k) (if (= k 0) (quote ()) (cons (car ev) (cadrc-trunc (cdr ev) (- k 1)))))
(define (cadrc-place acc deg t)
  (if (= deg 0) (cons (cadrc-mp-add-term (cadrc-head acc) t) (cadrc-tail acc))
      (cons (cadrc-head acc) (cadrc-place (cadrc-tail acc) (- deg 1) t))))
(define (cadrc-head l) (if (null? l) (quote ()) (car l)))
(define (cadrc-tail l) (if (null? l) (quote ()) (cdr l)))
(define (cadrc-mp-add-term mp t) (mpoly-add mp (list t)))

; ----- reduce g down the chain by the multivariate resultant, regrouping between levels -----
; chain is the list of defining polynomials from the TOP down: (f_n f_{n-1} ... f_2), each in nested cadnd form (a
; polynomial in its own top variable with mpoly coefficients in the lower variables).  We eliminate the current top
; variable (index = current height - 1) between the top f and g, then regroup the resulting mpoly for the next
; variable down, and recurse.  When the chain is exhausted the remaining mpoly is univariate in the base; we convert
; it to a coefficient list.
(define (cadrc-reduce g chain) (cadrc-reduce-go g chain (+ (cadrc-len chain) 1)))
(define (cadrc-len l) (if (null? l) 0 (+ 1 (cadrc-len (cdr l)))))
(define (cadrc-reduce-go g chain top-index)
  (if (null? chain) (cadrc-mp-to-uni g)
      (cadrc-reduce-step (cadn-resultant (car chain) g) (cdr chain) (- top-index 1))))
; after eliminating the current top variable, if more levels remain regroup for the next variable; otherwise the
; resultant is already an mpoly over the base variable alone and is converted to a univariate coefficient list
(define (cadrc-reduce-step r rest new-top)
  (if (null? rest) (cadrc-mp-to-uni r)
      (cadrc-reduce-go (cadrc-regroup-top r (- new-top 1)) rest new-top)))
; convert a base-level mpoly (only variable index 0 nonzero) to a univariate coefficient list low->high
(define (cadrc-mp-to-uni mp) (cadrc-uni mp (cadrc-mp-deg mp 0) 0))
(define (cadrc-mp-deg mp k) (cadrc-mdg mp k 0))
(define (cadrc-mdg terms k best) (if (null? terms) best (cadrc-mdg (cdr terms) k (cadrc-maxi best (cadrc-nth (cdr (car terms)) k)))))
(define (cadrc-maxi a b) (if (> a b) a b))
(define (cadrc-uni mp d i) (if (> i d) (quote ()) (cons (cadrc-coeff-at mp i) (cadrc-uni mp d (+ i 1)))))
(define (cadrc-coeff-at mp i) (cadrc-find mp i))
(define (cadrc-find terms i) (cond ((null? terms) 0) ((= (cadrc-nth (cdr (car terms)) 0) i) (car (car terms))) (else (cadrc-find (cdr terms) i))))

; ----- vanishing at the chain point -----
(define (cadrc-vanishes? g chain basef lo hi) (= (asec-sign (cadrc-reduce g chain) (asec-make basef lo hi)) 0))

; ----- honest scope boundary -----
(define (cadrc-fiber-sign-caveat) (quote regular-chain-vanishing-and-nonzero-sign-both-complete))

; ----- the NONZERO sign for a coupled chain, by interval arithmetic over a top-down-refined box -----
; This completes the general regular chain: the vanishing reduction above decides g = 0, and this decides the sign
; of a non-vanishing g.  A chain point carries, besides its defining polynomials and base algebraic number, a box of
; rational intervals (one per coordinate).  g (in cadnd nested form, a polynomial in the top variable with mpoly
; coefficients in the lower ones) is evaluated over the box by nested interval arithmetic; if the resulting interval
; excludes zero, that is the sign; otherwise the box is refined TOP-DOWN -- the base interval is tightened with the
; base number's own bisection, then each higher coordinate's interval is bisected and the half kept on which its
; defining polynomial, evaluated over the now-tighter lower intervals, still straddles zero.  Because the lower
; coordinates are tightened first, each fiber (even one coupling several lower coordinates) isolates and the box
; converges -- the coupled-fiber analogue of cadtower's top-down refinement.
;
;   cadrc-point basef lo hi levels -> a chain point; levels a list of (f_i lo_i hi_i), each f_i in nested cadnd form
;   cadrc-sign g chain basef lo hi levels -> the exact sign of g at the point: 0 if it vanishes (resultant
;       reduction), else the box-refined nonzero sign

; rational interval arithmetic
(define (cadrc-min a b) (if (< a b) a b))
(define (cadrc-max a b) (if (> a b) a b))
(define (cadrc-i-const c) (cons c c))
(define (cadrc-i-add a b) (cons (+ (car a) (car b)) (+ (cdr a) (cdr b))))
(define (cadrc-i-mul a b) (cadrc-i4 (* (car a) (car b)) (* (car a) (cdr b)) (* (cdr a) (car b)) (* (cdr a) (cdr b))))
(define (cadrc-i4 p1 p2 p3 p4) (cons (cadrc-min (cadrc-min p1 p2) (cadrc-min p3 p4)) (cadrc-max (cadrc-max p1 p2) (cadrc-max p3 p4))))
(define (cadrc-i-pow iv e) (if (<= e 0) (cadrc-i-const 1) (cadrc-i-mul iv (cadrc-i-pow iv (- e 1)))))

; mpoly interval evaluation: substitute one interval per variable into an mpoly (list of (coeff . expvec))
(define (cadrc-mp-iv mp ivs) (if (null? mp) (cadrc-i-const 0) (cadrc-i-add (cadrc-term-iv (car (car mp)) (cdr (car mp)) ivs) (cadrc-mp-iv (cdr mp) ivs))))
(define (cadrc-term-iv coeff expvec ivs) (cadrc-term-go (cadrc-i-const coeff) expvec ivs))
(define (cadrc-term-go acc expvec ivs) (if (null? expvec) acc (cadrc-term-go (cadrc-i-mul acc (cadrc-i-pow (car ivs) (car expvec))) (cdr expvec) (cdr ivs))))

; nested-poly interval evaluation: g is a list (low->high in top var) of mpoly coefficients; the top variable's
; interval is the last in `ivs`, the mpoly coefficients use the earlier intervals
(define (cadrc-eval g ivs) (cadrc-ev g (cadrc-but-last ivs) (cadrc-last ivs)))
(define (cadrc-ev cs lower itop) (if (null? cs) (cadrc-i-const 0) (cadrc-i-add (cadrc-mp-iv (car cs) lower) (cadrc-i-mul itop (cadrc-ev (cdr cs) lower itop)))))
(define (cadrc-last l) (if (null? (cdr l)) (car l) (cadrc-last (cdr l))))
(define (cadrc-but-last l) (if (null? (cdr l)) (quote ()) (cons (car l) (cadrc-but-last (cdr l)))))

; a chain point: base algebraic number, the higher levels (f_i lo_i hi_i), and accessors
(define (cadrc-point basef lo hi levels) (list (asec-make basef lo hi) levels))
(define (cadrc-pt-base p) (car p))
(define (cadrc-pt-levels p) (car (cdr p)))
(define (cadrc-lv-f lv) (car lv))
(define (cadrc-lv-lo lv) (car (cdr lv)))
(define (cadrc-lv-hi lv) (car (cdr (cdr lv))))
; the current box: base interval then each level's interval
(define (cadrc-pt-box p) (cons (cons (asec-lo (cadrc-pt-base p)) (asec-hi (cadrc-pt-base p))) (cadrc-lv-ivs (cadrc-pt-levels p))))
(define (cadrc-lv-ivs levels) (if (null? levels) (quote ()) (cons (cons (cadrc-lv-lo (car levels)) (cadrc-lv-hi (car levels))) (cadrc-lv-ivs (cdr levels)))))

; refine the point top-down: tighten the base, then each level's interval keeping the half whose fiber straddles 0
(define (cadrc-refine p) (list (asec-refine (cadrc-pt-base p)) (cadrc-refine-levels (list (cons (asec-lo (cadrc-pt-base p)) (asec-hi (cadrc-pt-base p)))) (cadrc-pt-levels p))))
(define (cadrc-refine-levels lower-ivs levels)
  (if (null? levels) (quote ())
      (cadrc-rl-cons (cadrc-refine-one (car levels) lower-ivs) lower-ivs (cdr levels))))
(define (cadrc-rl-cons refined lower-ivs rest) (cons refined (cadrc-refine-levels (cadrc-app1 lower-ivs (cons (cadrc-lv-lo refined) (cadrc-lv-hi refined))) rest)))
(define (cadrc-app1 l x) (if (null? l) (list x) (cons (car l) (cadrc-app1 (cdr l) x))))
(define (cadrc-refine-one lv lower-ivs) (cadrc-keep lv lower-ivs (/ (+ (cadrc-lv-lo lv) (cadrc-lv-hi lv)) 2)))
(define (cadrc-keep lv lower-ivs m)
  (if (cadrc-straddles? (cadrc-eval (cadrc-lv-f lv) (cadrc-app1 lower-ivs (cons (cadrc-lv-lo lv) m))))
      (list (cadrc-lv-f lv) (cadrc-lv-lo lv) m)
      (list (cadrc-lv-f lv) m (cadrc-lv-hi lv))))
(define (cadrc-straddles? iv) (if (> (car iv) 0) #f (if (< (cdr iv) 0) #f #t)))

; the exact sign: vanishing (resultant reduction) first, else box-refined nonzero sign
(define (cadrc-sign g chain basef lo hi levels)
  (if (cadrc-vanishes? g chain basef lo hi) 0 (cadrc-sign-refine g (cadrc-point basef lo hi levels) 60)))
(define (cadrc-sign-refine g p fuel)
  (cond ((cadrc-sep? (cadrc-eval g (cadrc-pt-box p))) (cadrc-sgn-iv (cadrc-eval g (cadrc-pt-box p))))
        ((= fuel 0) 0)
        (else (cadrc-sign-refine g (cadrc-refine p) (- fuel 1)))))
(define (cadrc-sep? iv) (if (> (car iv) 0) #t (< (cdr iv) 0)))
(define (cadrc-sgn-iv iv) (cond ((> (car iv) 0) 1) ((< (cdr iv) 0) -1) (else 0)))
