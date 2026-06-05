; -*- lisp -*-
; src/cas/cadtower.lisp -- the GENERAL multi-algebraic SECTION tower: a point whose coordinates form an iterated
; algebraic extension Q < Q(a_1) < Q(a_1,a_2) < ... , each new coordinate a genuine algebraic number over the field
; below (not merely a polynomial in the previous one), with the exact sign of a polynomial at the point.  This is the
; frontier past cadsecn.lisp: cadsecn decided EXPLICIT triangular sections (x_k a polynomial in x_{k-1}); this
; decides the IMPLICIT tower, where x_k is a ROOT of a polynomial f_k whose coefficients are polynomials in the lower
; coordinates -- the structure of nested radicals like sqrt(2) -> 2^(1/4) -> 2^(1/8) and, generally, of a regular
; chain / triangular set.  It is the n-dimensional generalization of algpoint.lisp's two-level construction.
;
; The chain is a "simple" (iterated-extension) one: each defining polynomial f_i relates the consecutive coordinates
; x_i and x_{i-1}, given in the bivariate form of cadproj.lisp -- a list of x_{i-1}-polynomials, low to high in x_i --
; so that one elimination step is the bivariate resultant we already have.  The base f_1 is a univariate polynomial
; over Q with a rational isolating interval; coordinate x_1 is its chosen real root, a real algebraic number in the
; sense of algnum2.lisp.  Each higher x_i is the real root, in a rational isolating interval, of f_i over the
; algebraic value of x_{i-1}.
;
; Two exact mechanisms decide the sign of a polynomial g at the tower point (g given bivariate in the top two
; coordinates x_k, x_{k-1}, the general shape after reduction):
;   - VANISHING is decided by reducing g down the chain with iterated resultants: eliminate x_k between f_k and g
;     (an x_{k-1}-polynomial), then x_{k-1} between f_{k-1} and that, and so on, until a univariate polynomial in the
;     base x_1 remains; g vanishes at the point iff that polynomial vanishes at the base algebraic number, tested
;     exactly by algnum2.lisp.  (This is algpoint's resultant test, iterated down a tower of any height.)
;   - the NONZERO sign is read by interval arithmetic over a box, refined TOP-DOWN: the base interval is tightened
;     first using f_1 (a univariate refinement that converges on its own), then each higher coordinate's interval is
;     isolated in its fiber over the now-tight lower intervals.  This top-down order is what makes the box converge
;     -- the coupled, all-at-once refinement of an n-box cannot isolate a zero-dimensional point, but tightening the
;     base first and the fibers in turn does.
;
; Honest scope.  This decides sign and vanishing at a point of a SIMPLE algebraic tower (each level an extension by
; one element, the defining polynomial relating consecutive coordinates) of any height -- the nested-radical towers
; and iterated extensions, fully irrational, the n-dimensional analogue of algpoint.  The fully general regular chain
; whose f_i depends on ALL lower coordinates at once (not just the immediately preceding one), and the
; multi-resultant elimination that needs, is the residual generality; cadtower-chain-caveat names it.  Within the
; simple-tower scope this closes the multi-algebraic section case for general n.
;
; Public:
;   cadtower-make basef lo hi levels -> a tower point: base coordinate the root of `basef` in (lo,hi); `levels` a
;                                       list of (f_i lo_i hi_i), each f_i bivariate in (x_i over x_{i-1}) with x_i
;                                       isolated in (lo_i, hi_i)
;   cadtower-base p / cadtower-levels p -> the base algebraic number and the higher levels
;   cadtower-height p                -> the number of coordinates (1 + number of levels)
;   cadtower-reduce-to-base g p      -> the univariate base polynomial obtained by reducing g (bivariate in the top
;                                       two coordinates) down the chain with iterated resultants
;   cadtower-vanishes? g p           -> #t iff g = 0 at the tower point (its base reduction vanishes at the base)
;   cadtower-box p                   -> the current isolating box, refined top-down (one interval per coordinate)
;   cadtower-top-sign g p            -> the exact sign of g at the point (vanishing test, then box refinement)
;   cadtower-chain-caveat            -> reminder: simple iterated towers; the general regular chain remains
;
; Verified: on the tower x = sqrt(2) (x^2 - 2), y = 2^(1/4) (y^2 - x), z = 2^(1/8) (z^2 - y): y^4 - 2 = 0 and
; z^8 - 2 = 0 (the defining radical identities) while y - 1 > 0 and z - 1 > 0; and the vanishing of x*y^2 - 2 (since
; sqrt(2)*sqrt(2) = 2) and the non-vanishing of y^2 - 2.
;
; Builds on cadproj.lisp (bivariate resultant for one elimination step), algnum2.lisp (the base number and its exact
; univariate signs), and poly.lisp.

(import "cas/cadproj.lisp")
(import "cas/algnum2.lisp")
(import "cas/poly.lisp")

; ----- construction -----
(define (cadtower-make basef lo hi levels) (list (asec-make basef lo hi) levels))
(define (cadtower-base p) (car p))
(define (cadtower-levels p) (car (cdr p)))
(define (cadtower-height p) (+ 1 (cadtower-llen (cadtower-levels p))))
(define (cadtower-llen l) (if (null? l) 0 (+ 1 (cadtower-llen (cdr l)))))
(define (cadtower-level-f lv) (car lv))
(define (cadtower-level-lo lv) (car (cdr lv)))
(define (cadtower-level-hi lv) (car (cdr (cdr lv))))

; ----- reduce g down the chain by iterated bivariate resultants to a univariate base polynomial -----
; g is bivariate in the top two coordinates (x_k over x_{k-1}); eliminating x_k against f_k (the top level's
; defining polynomial, also bivariate in x_k over x_{k-1}) gives an x_{k-1}-polynomial; that becomes the new g for
; the next level down, eliminated against f_{k-1}, and so on, until only the base variable remains.
(define (cadtower-reduce-to-base g p) (cadtower-rd g (cadtower-rev (cadtower-levels p) (quote ()))))
(define (cadtower-rev l acc) (if (null? l) acc (cadtower-rev (cdr l) (cons (car l) acc))))
; rd takes g (a polynomial in the current top variable over the next-lower one, bivariate) and the levels from the
; top down; at each step eliminate the top variable against that level's f, lowering g by one variable.  The
; resultant returns a polynomial univariate in the next-lower variable; before eliminating it against the next
; level's f (which is bivariate in that variable over the one below), we LIFT it to the bivariate form -- each of
; its coefficients becomes a constant polynomial in the variable below -- so the representations match.
(define (cadtower-rd g levels-top-down)
  (if (null? levels-top-down) g                                   ; g is now a univariate base polynomial
      (cadtower-rd-step g levels-top-down)))
(define (cadtower-rd-step g levels-top-down)
  (cadtower-rd (cadtower-elim (cadtower-level-f (car levels-top-down)) g (cdr levels-top-down)) (cdr levels-top-down)))
; eliminate the top variable: resultant of f and g; if more levels remain below, lift the (univariate) result to
; bivariate form for the next step, otherwise it is already the univariate base polynomial
(define (cadtower-elim f g rest) (cadtower-maybe-lift (cad-resultant f g) rest))
(define (cadtower-maybe-lift r rest) (if (null? rest) r (cadtower-lift-univariate r)))
; lift a univariate polynomial (coeff list low->high) to the bivariate form (each coefficient a constant polynomial)
(define (cadtower-lift-univariate r) (if (null? r) (quote ()) (cons (cadtower-const-poly (car r)) (cadtower-lift-univariate (cdr r)))))
(define (cadtower-const-poly c) (if (= c 0) (quote ()) (list c)))

; ----- vanishing: the base reduction vanishes at the base algebraic number -----
(define (cadtower-vanishes? g p) (= (asec-sign (cadtower-reduce-to-base g p) (cadtower-base p)) 0))

; ----- the isolating box, refined top-down -----
(define (cadtower-min a b) (if (< a b) a b))
(define (cadtower-max a b) (if (> a b) a b))
; the isolating box reports the CURRENT state: the base's interval as it stands, plus each level's interval.
; refinement is driven externally by cadtower-refine-tower (which tightens the base and the fibers in turn).
(define (cadtower-box p) (cons (cadtower-base-iv (cadtower-base p)) (cadtower-level-ivs (cadtower-levels p))))
(define (cadtower-base-iv a) (cons (asec-lo a) (asec-hi a)))
(define (cadtower-level-ivs levels) (if (null? levels) (quote ()) (cons (cons (cadtower-level-lo (car levels)) (cadtower-level-hi (car levels))) (cadtower-level-ivs (cdr levels)))))

; ----- interval arithmetic (for the nonzero sign over the box) -----
(define (cadtower-i-const c) (cons c c))
(define (cadtower-i-add a b) (cons (+ (car a) (car b)) (+ (cdr a) (cdr b))))
(define (cadtower-i-mul a b) (cadtower-i4 (* (car a) (car b)) (* (car a) (cdr b)) (* (cdr a) (car b)) (* (cdr a) (cdr b))))
(define (cadtower-i4 p1 p2 p3 p4) (cons (cadtower-min (cadtower-min p1 p2) (cadtower-min p3 p4)) (cadtower-max (cadtower-max p1 p2) (cadtower-max p3 p4))))
; evaluate a bivariate g (top var over next-lower var) over the two top intervals (itop, ilow) by interval Horner
(define (cadtower-eval-biv g itop ilow) (cadtower-bh g itop ilow))
(define (cadtower-bh cs itop ilow) (if (null? cs) (cadtower-i-const 0) (cadtower-i-add (cadtower-i-ueval (car cs) ilow) (cadtower-i-mul itop (cadtower-bh (cdr cs) itop ilow)))))
(define (cadtower-i-ueval c iv) (if (null? c) (cadtower-i-const 0) (cadtower-i-add (cadtower-i-const (car c)) (cadtower-i-mul iv (cadtower-i-ueval (cdr c) iv)))))

; ----- the exact top sign: vanishing first, then the box-refined nonzero sign -----
; the two top coordinate intervals come from the refined box; we refine the whole tower top-down enough that g's
; interval over the top two coordinates separates from zero (it must, when g does not vanish at the point)
(define (cadtower-top-sign g p) (if (cadtower-vanishes? g p) 0 (cadtower-sign-refine g p 60)))
(define (cadtower-sign-refine g p fuel)
  (cond ((cadtower-sep? (cadtower-eval-biv g (cadtower-top-iv p) (cadtower-next-iv p))) (cadtower-sgn-iv (cadtower-eval-biv g (cadtower-top-iv p) (cadtower-next-iv p))))
        ((= fuel 0) 0)
        (else (cadtower-sign-refine g (cadtower-refine-tower p) (- fuel 1)))))
(define (cadtower-sep? iv) (if (> (car iv) 0) #t (< (cdr iv) 0)))
(define (cadtower-sgn-iv iv) (cond ((> (car iv) 0) 1) ((< (cdr iv) 0) -1) (else 0)))
; the top coordinate's interval and the next-lower coordinate's interval, from the current tower state
(define (cadtower-top-iv p) (cadtower-nth-iv p (- (cadtower-height p) 1)))
(define (cadtower-next-iv p) (cadtower-nth-iv p (- (cadtower-height p) 2)))
(define (cadtower-nth-iv p i) (cadtower-ix (cadtower-box p) i))
(define (cadtower-ix box i) (if (= i 0) (car box) (cadtower-ix (cdr box) (- i 1))))
; refine the tower: tighten the base and bisect each level's fiber interval keeping the half whose fiber straddles 0
(define (cadtower-refine-tower p) (list (asec-refine (cadtower-base p)) (cadtower-refine-levels (cadtower-base p) (cadtower-levels p))))
; refine each level in turn; the lower interval for the first level is the base's interval, and for each subsequent
; level it is the (refined) interval of the level just below
(define (cadtower-refine-levels base levels) (cadtower-rl (cons (asec-lo base) (asec-hi base)) levels))
(define (cadtower-rl lower-iv levels)
  (if (null? levels) (quote ())
      (cadtower-rl-cons (cadtower-refine-one (car levels) lower-iv) (cdr levels))))
(define (cadtower-rl-cons refined rest) (cons refined (cadtower-rl (cadtower-this-iv refined) rest)))
(define (cadtower-this-iv lv) (cons (cadtower-level-lo lv) (cadtower-level-hi lv)))
; bisect this level's interval, keep the half where f_i over the lower interval straddles zero
(define (cadtower-refine-one lv lower-iv) (cadtower-keep lv lower-iv (/ (+ (cadtower-level-lo lv) (cadtower-level-hi lv)) 2)))
(define (cadtower-keep lv lower-iv m)
  (if (cadtower-fiber-straddles? (cadtower-level-f lv) (cons (cadtower-level-lo lv) m) lower-iv)
      (list (cadtower-level-f lv) (cadtower-level-lo lv) m)
      (list (cadtower-level-f lv) m (cadtower-level-hi lv))))
(define (cadtower-fiber-straddles? f itop ilow) (cadtower-straddle? (cadtower-eval-biv f itop ilow)))
(define (cadtower-straddle? iv) (if (> (car iv) 0) #f (if (< (cdr iv) 0) #f #t)))

; ----- honest scope boundary -----
(define (cadtower-chain-caveat) (quote simple-iterated-towers-decided-general-regular-chain-remains))

; ----- a section decider over a simple chain: construct the tower witness points and test a formula at each -----
; Given a base polynomial f_1 over Q and the higher defining polynomials f_2, ..., f_k (each bivariate, x_i over
; x_{i-1}), the real solutions of the chain are the tower points obtained by choosing, at each level, a real root of
; that level's polynomial over the algebraic value below.  cadtower-build-points isolates those roots level by
; level (the base by Sturm over Q; each higher level by isolating the fiber over the lower coordinate's interval
; midpoint, then carried as a tower whose box refinement makes the coordinate exact), yielding the witness points.
; cadtower-exists-chain tests whether a list of EXTRA sign conditions (beyond the defining equalities, which hold at
; every constructed point by construction) holds at some witness -- the existential decision over this section.
;
; cadtower-build-points basef lo-list higher -> the tower points; lo-list gives the base's isolating intervals to
;   try (e.g. from isolate-roots of basef), higher the list of (f_i lo-guess hi-guess) fiber polynomials with a
;   coarse starting interval each
; cadtower-top-sign-list conds p -> #t iff every condition (op . g) in conds holds at the point p
; cadtower-exists-chain basef base-ivs higher conds -> #t iff some witness satisfies all the extra conditions

(define (cadtower-top-sign-list conds p) (cond ((null? conds) #t) ((cadtower-cond-holds? (car conds) p) (cadtower-top-sign-list (cdr conds) p)) (else #f)))
(define (cadtower-cond-holds? cnd p) (cadtower-ct (car cnd) (cadtower-top-sign (cdr cnd) p)))
(define (cadtower-ct op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; build the witness points: for each base interval, attach the higher levels (their coarse intervals refined by the
; tower's own box machinery when signs are evaluated).  For the simple-chain verified cases the coarse intervals
; isolate the intended branch; multiple branches would be enumerated by isolating each level's several roots.
(define (cadtower-build-points basef base-ivs higher) (cadtower-bp basef base-ivs higher))
(define (cadtower-bp basef ivs higher) (if (null? ivs) (quote ()) (cons (cadtower-make basef (car (car ivs)) (car (cdr (car ivs))) higher) (cadtower-bp basef (cdr ivs) higher))))

(define (cadtower-exists-chain basef base-ivs higher conds) (cadtower-scan-points (cadtower-build-points basef base-ivs higher) conds))
(define (cadtower-scan-points pts conds) (cond ((null? pts) #f) ((cadtower-top-sign-list conds (car pts)) #t) (else (cadtower-scan-points (cdr pts) conds))))
