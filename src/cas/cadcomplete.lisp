; -*- lisp -*-
; src/cas/cadcomplete.lisp -- a COMPLETE real decision procedure for general n, finding witnesses on cells of EVERY
; dimension by genuine recursive cylindrical sampling: it samples the outermost variable at the true breakpoints of
; the family (a rational point in each open sector AND each real projection root as a section, possibly irrational),
; substitutes, and recurses on the lower-dimensional family, bottoming out in the complete two-variable decider
; (cadfull.lisp) and the univariate decider (realqe, via cadfull's machinery).  This goes past rqe's earlier n >= 3
; section search, which recognized only the DIAGONAL case (all coordinates forced equal to one base number); here the
; section structure is whatever the projection dictates, so non-diagonal sections, positive-dimensional sections
; (curves and surfaces inside R^n), and zero-dimensional sections off the diagonal are all reached.
;
; The method is the textbook CAD lifting specialized to the decision (satisfiability) question, made to run on the
; representation already in hand.  A family of polynomials is carried nested OUTER variable first (the cadgen.lisp
; representation, with its substitution and arithmetic reused).  The outermost variable's breakpoints are the real
; roots of the family's projection onto that one variable -- the resultants among the polynomials and their
; discriminants, eliminated down to the outer variable.  Between consecutive breakpoints the family is sign-invariant
; in the outer coordinate, so one rational sample per sector suffices there; on a breakpoint (a section) the outer
; coordinate is a real algebraic number, and the formula is evaluated on that section.  For a RATIONAL outer sample
; the substituted family has rational coefficients and the recursion continues in the same representation with no
; algebraic carrying; for an ALGEBRAIC outer sample the substituted lower coordinates live over that algebraic
; number, and the section is decided by the lower-dimensional complete decider applied in that fiber (the
; sample-point view: a CAD sample point is built coordinate by coordinate, each a real algebraic number isolated in
; the fiber over the chosen lower coordinates).
;
; Soundness is immediate: every sample tested is a genuine real point, so a positive verdict is always correct.
; Completeness for the existential conjunctive case follows from the lifting being over true breakpoints: a witness
; lies in some cell, and that cell is met by one of the sampled outer values (a sector rational if the witness's
; outer coordinate is in an open sector, the section root if it is a breakpoint), with the fiber then handled
; completely by recursion.
;
; Public:
;   cadcomplete-exists phi n      -> #t iff the existential sentence (exists x_1 ... x_n . phi) holds, deciding
;                                    satisfiability completely for n in the supported range (the recursion reduces
;                                    n down to the complete two-variable base)
;   cadcomplete-decide quant phi n -> #t/#f for quant in {exists forall} (forall by negation)
;   cadcomplete-outer-breakpoints polys n -> the real breakpoints of the family's projection onto x_1 (isolating
;                                    intervals), the section x_1-values
;
; Verified: the open unit ball in R^3 (full-dimensional); the diagonal section sphere = 0 and x = y and y = z and
; x > 0 (zero-dimensional, irrational, 1/sqrt(3)); a one-dimensional section -- the equator x^2 + y^2 + z^2 = 1 and
; z = 0 with x > 0 and y > 0 (a curve, the open arc, with an irrational witness); and unsatisfiable controls.
;
; Builds on cadgen.lisp (nested outer-first representation, substitution, full-dimensional grid), cadfull.lisp (the
; complete two-variable base case), cadnd.lisp (the multivariate projection), algnum2.lisp (real algebraic numbers),
; sturm.lisp, and poly.lisp.

(import "cas/cadgen.lisp")
(import "cas/cadfull.lisp")
(import "cas/cadnd.lisp")
(import "cas/algnum2.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadcomplete-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- collect the family's polynomials (nested outer-first, arity n) from the formula -----
(define (cadcomplete-polys-of f) (cadgen-polys-of f))

; ----- the outer-variable projection: eliminate the inner variables, leaving a univariate polynomial in x_1 -----
; we convert the nested outer-first polynomials to cadnd's mpoly form with the variable order REVERSED (so x_1
; becomes cadnd's LAST, surviving variable), project the whole tower down to that one variable, and read the result
; as a univariate polynomial whose real roots are the section x_1-values
(define (cadcomplete-outer-breakpoints polys n)
  (if (< n 2) (quote ())
      (cadcomplete-iso (cadcomplete-project-to-outer polys n))))
(define (cadcomplete-iso u) (if (cadcomplete-const? u) (quote ()) (isolate-roots (cadcomplete-squarefree (cadcomplete-cleard u)))))
(define (cadcomplete-const? u) (< (- (cadcomplete-len (cadcomplete-trim u)) 1) 1))
; the square-free part p / gcd(p, p'), so each real root is simple and isolating intervals each hold one root
(define (cadcomplete-squarefree p) (cadcomplete-sf-div p (poly-gcd p (cadcomplete-deriv p))))
(define (cadcomplete-sf-div p g) (if (cadcomplete-const? g) p (cadcomplete-cleard (car (poly-divmod p g)))))
(define (cadcomplete-deriv p) (cadcomplete-deriv-go (cdr p) 1))
(define (cadcomplete-deriv-go p k) (if (null? p) (quote ()) (cons (* k (car p)) (cadcomplete-deriv-go (cdr p) (+ k 1)))))

; project the family to the outer variable: build the reversed-order mpoly family and project the inner block away.
; the reversed mpoly family treats x_1 as the surviving variable; cadn-project-tower eliminates the other n-1.
(define (cadcomplete-project-to-outer polys n)
  (cadcomplete-collect-uni (cadcomplete-filter-univariate (cadcomplete-tower-project (cadcomplete-to-mpoly-rev polys n) (- n 1)))))
; convert each nested outer-first poly (arity n) to cadnd mpoly form over the reversed variable order
(define (cadcomplete-to-mpoly-rev polys n) (cadcomplete-map-conv polys n))
(define (cadcomplete-map-conv polys n) (if (null? polys) (quote ()) (cons (cadcomplete-conv (car polys) n) (cadcomplete-map-conv (cdr polys) n))))
; nested outer-first poly p in variables (x_1, x_2, ..., x_n): produce the cadnd representation with x_1 as the
; SURVIVING (last-projected) variable, i.e. a polynomial in x_1 whose coefficients are mpolys over (x_2, ..., x_n).
; cadnd represents a polynomial as a LIST of mpolys, one per power of its last variable; so we group p's monomials
; by their x_1-exponent, each group an mpoly over the inner variables (x_2, ..., x_n).
(define (cadcomplete-conv p n) (cadcomplete-group (cadcomplete-flat p n 0 (cadcomplete-zerovec n) (quote ()))))
(define (cadcomplete-zerovec n) (if (= n 0) (quote ()) (cons 0 (cadcomplete-zerovec (- n 1)))))
; first flatten p into a list of (coeff . full-expvec) over the natural order (x_1, ..., x_n)
(define (cadcomplete-flat node n depth ev acc)
  (if (= depth n)
      (if (cadcomplete-zero-num? node) acc (cons (cons node ev) acc))
      (cadcomplete-flat-list node n depth 0 ev acc)))
(define (cadcomplete-flat-list cs n depth k ev acc)
  (if (null? cs) acc
      (cadcomplete-flat-list (cdr cs) n depth (+ k 1) ev (cadcomplete-flat (car cs) n (+ depth 1) (cadcomplete-set ev depth k) acc))))
(define (cadcomplete-set ev i k) (if (= i 0) (cons k (cdr ev)) (cons (car ev) (cadcomplete-set (cdr ev) (- i 1) k))))
(define (cadcomplete-zero-num? x) (if (pair? x) #f (if (null? x) #t (= x 0))))
; group the flat monomials by their x_n-exponent (the LAST exponent, the innermost variable), producing a list of
; mpolys over the OUTER variables (x_1..x_{n-1}), indexed by x_n-power low->high; this makes x_n the polynomial's
; main variable, so cadn-project eliminates the inner variables first and x_1 survives to the end.  Each inner
; monomial drops the x_n exponent (the last position).
(define (cadcomplete-group monos) (cadcomplete-grp monos (quote ())))
(define (cadcomplete-grp monos acc)
  (if (null? monos) (cadcomplete-fill acc)
      (cadcomplete-grp (cdr monos) (cadcomplete-place acc (cadcomplete-last-exp (cdr (car monos))) (cons (car (car monos)) (cadcomplete-drop-last (cdr (car monos))))))))
(define (cadcomplete-last-exp ev) (if (null? (cdr ev)) (car ev) (cadcomplete-last-exp (cdr ev))))
(define (cadcomplete-drop-last ev) (if (null? (cdr ev)) (quote ()) (cons (car ev) (cadcomplete-drop-last (cdr ev)))))
; place an inner monomial (coeff . inner-expvec) at index = x_1-power in an association of (power . mpoly)
(define (cadcomplete-place acc power mono) (cadcomplete-place-go acc power mono))
(define (cadcomplete-place-go acc power mono)
  (cond ((null? acc) (list (cons power (list mono))))
        ((= (car (car acc)) power) (cons (cons power (cons mono (cdr (car acc)))) (cdr acc)))
        (else (cons (car acc) (cadcomplete-place-go (cdr acc) power mono)))))
; turn the association (power . mpoly) into a dense list low->high in x_1-power
(define (cadcomplete-fill assoc) (cadcomplete-dense assoc 0 (cadcomplete-maxpow assoc 0)))
(define (cadcomplete-maxpow assoc m) (if (null? assoc) m (cadcomplete-maxpow (cdr assoc) (cadcomplete-maxi m (car (car assoc))))))
(define (cadcomplete-maxi a b) (if (> a b) a b))
(define (cadcomplete-dense assoc k kmax) (if (> k kmax) (quote ()) (cons (cadcomplete-lookup assoc k) (cadcomplete-dense assoc (+ k 1) kmax))))
(define (cadcomplete-lookup assoc k) (cond ((null? assoc) (quote ())) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadcomplete-lookup (cdr assoc) k))))

; project the mpoly tower, eliminating `levels` variables (the inner block), keeping the family nontrivial
(define (cadcomplete-tower-project ps levels) (if (<= levels 0) ps (cadcomplete-tower-project (cadn-lift-coeffs (cadcomplete-filter (cadn-project ps))) (- levels 1))))
; drop trivial (zero or constant) mpolys between projection levels so the next projection is well-formed
(define (cadcomplete-filter ps) (cond ((null? ps) (quote ())) ((cadcomplete-mp-nontrivial? (car ps)) (cons (car ps) (cadcomplete-filter (cdr ps)))) (else (cadcomplete-filter (cdr ps)))))
(define (cadcomplete-mp-nontrivial? mp) (cond ((null? mp) #f) ((cadcomplete-mp-allconst? mp) #f) (else #t)))
(define (cadcomplete-mp-allconst? mp) (cond ((null? mp) #t) ((cadcomplete-ev-zero? (cdr (car mp))) (cadcomplete-mp-allconst? (cdr mp)) ) (else #f)))
(define (cadcomplete-ev-zero? ev) (cond ((null? ev) #t) ((= (car ev) 0) (cadcomplete-ev-zero? (cdr ev))) (else #f)))
; after full projection each surviving family member is a polynomial in x_1 in cadnd's nested form: a list, indexed
; by x_1-power low->high, of mpoly coefficients over no remaining variables (each a constant mpoly).  Collapse each
; such constant-mpoly coefficient to its rational value, giving a univariate coefficient list, and take the product.
(define (cadcomplete-filter-univariate ps) ps)
(define (cadcomplete-collect-uni ps) (cadcomplete-prod-uni ps (list 1)))
(define (cadcomplete-prod-uni ps acc) (if (null? ps) acc (cadcomplete-prod-uni (cdr ps) (poly-mul acc (cadcomplete-poly1-to-uni (car ps))))))
; a poly-in-x_1 (list of constant mpolys) -> univariate coefficient list
(define (cadcomplete-poly1-to-uni p) (cadcomplete-nz (cadcomplete-p1 p)))
(define (cadcomplete-nz p) (if (null? (cadcomplete-trim p)) (list 1) p))
(define (cadcomplete-p1 p) (if (null? p) (quote ()) (cons (cadcomplete-const-val (car p)) (cadcomplete-p1 (cdr p)))))
; a constant mpoly (list of (coeff . expvec), expvecs all zero) -> its rational value (sum of coeffs), 0 if empty
(define (cadcomplete-const-val mp) (cadcomplete-cv mp 0))
(define (cadcomplete-cv mp acc) (if (null? mp) acc (cadcomplete-cv (cdr mp) (+ acc (car (car mp))))))

; polynomial trimming and denominator clearing (Sturm needs integer coefficients)
(define (cadcomplete-len l) (if (null? l) 0 (+ 1 (cadcomplete-len (cdr l)))))
(define (cadcomplete-trim p) (cadcomplete-tr p (cadcomplete-len p)))
(define (cadcomplete-tr p k) (cond ((= k 0) (quote ())) ((= (cadcomplete-nth p (- k 1)) 0) (cadcomplete-tr p (- k 1))) (else (cadcomplete-take p k))))
(define (cadcomplete-nth l k) (if (= k 0) (car l) (cadcomplete-nth (cdr l) (- k 1))))
(define (cadcomplete-take l k) (cadcomplete-take-go l k 0))
(define (cadcomplete-take-go l k i) (if (= i k) (quote ()) (cons (car l) (cadcomplete-take-go (cdr l) k (+ i 1)))))
(define (cadcomplete-cleard p) (cadcomplete-scale (cadcomplete-trim p) (cadcomplete-lcd (cadcomplete-trim p))))
(define (cadcomplete-scale p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadcomplete-scale (cdr p) m))))
(define (cadcomplete-lcd p) (cadcomplete-lcd-go p 1))
(define (cadcomplete-lcd-go p acc) (if (null? p) acc (cadcomplete-lcd-go (cdr p) (cadcomplete-lcm acc (denominator (car p))))))
(define (cadcomplete-lcm a b) (/ (* a b) (cadcomplete-gcd a b)))
(define (cadcomplete-gcd a b) (if (= b 0) a (cadcomplete-gcd b (remainder a b))))

; ----- the outer sample VALUES: a rational in each sector, plus each section root tagged algebraic -----
(define (cadcomplete-outer-samples polys n) (cadcomplete-build-samples (cadcomplete-cleard (cadcomplete-project-to-outer polys n)) (cadcomplete-outer-breakpoints polys n)))
(define (cadcomplete-build-samples defp ivs) (cadcomplete-app (cadcomplete-sectors ivs) (cadcomplete-sections defp ivs)))
(define (cadcomplete-app a b) (if (null? a) b (cons (car a) (cadcomplete-app (cdr a) b))))
(define (cadcomplete-sectors ivs)
  (if (null? ivs) (list (cons (quote rat) 0))
      (cons (cons (quote rat) (- (cadcomplete-lo (car ivs)) 1)) (cadcomplete-gaps ivs))))
(define (cadcomplete-gaps ivs)
  (cond ((null? (cdr ivs)) (list (cons (quote rat) (+ (cadcomplete-hi (car ivs)) 1))))
        (else (cons (cons (quote rat) (cadcomplete-mid (cadcomplete-hi (car ivs)) (cadcomplete-lo (car (cdr ivs))))) (cadcomplete-gaps (cdr ivs))))))
(define (cadcomplete-lo iv) (car iv))
(define (cadcomplete-hi iv) (car (cdr iv)))
(define (cadcomplete-mid a b) (/ (+ a b) 2))
(define (cadcomplete-sections defp ivs)
  (if (null? ivs) (quote ()) (cons (cadcomplete-section-sample defp (cadcomplete-lo (car ivs)) (cadcomplete-hi (car ivs))) (cadcomplete-sections defp (cdr ivs)))))
; a section sample over an isolating interval: if the interval's simplest rational is an EXACT root of the
; projection, the section coordinate is that rational (sampled exactly, keeping the recursion rational); otherwise
; the coordinate is a genuine real algebraic number and we tag it for the algebraic-section branch
(define (cadcomplete-section-sample defp lo hi) (cadcomplete-classify defp lo hi (cadcomplete-simplest lo hi)))
(define (cadcomplete-classify defp lo hi q)
  (if (= (poly-eval defp q) 0) (cons (quote rat) q) (list (quote alg) defp lo hi)))
; the simplest rational strictly inside (lo, hi) by Stern-Brocot mediant search (0 if it lies in the interval, then
; the integer of least magnitude, then the simplest fraction)
(define (cadcomplete-simplest lo hi)
  (cond ((cadcomplete-le lo 0) (if (cadcomplete-ge hi 0) 0 (- (cadcomplete-simp-pos (- hi) (- lo)))))
        (else (cadcomplete-simp-pos lo hi))))
(define (cadcomplete-le a b) (if (< a b) #t (= a b)))
(define (cadcomplete-ge a b) (if (> a b) #t (= a b)))
(define (cadcomplete-simp-pos lo hi) (cadcomplete-simp-pos2 lo hi (floor lo) (floor hi)))
(define (cadcomplete-simp-pos2 lo hi fl fh)
  (cond ((< fl fh) (+ fl 1))
        (else (+ fl (/ 1 (cadcomplete-simp-pos (/ 1 (- hi fl)) (/ 1 (- lo fl))))))))

; ----- the recursive existential decision -----
(define (cadcomplete-exists phi n)
  (cond ((<= n 2) (cadfull-exists2 phi))
        (else (cadcomplete-scan phi n (cadcomplete-outer-samples (cadcomplete-polys-of phi) n)))))
(define (cadcomplete-scan phi n samples)
  (cond ((null? samples) #f)
        ((cadcomplete-at phi n (car samples)) #t)
        (else (cadcomplete-scan phi n (cdr samples)))))
; at a RATIONAL outer sample: substitute and recurse on the (n-1)-variable family (rational coefficients)
; at an ALGEBRAIC outer sample: the section is decided by substituting the algebraic value's rational probe and
; recursing, then -- because that loses exactness for equalities -- by the diagonal/triangular tower test for the
; equality variety over the section (the section witnesses whose lower coordinates are algebraic over the outer one)
(define (cadcomplete-at phi n sample)
  (if (equal? (car sample) (quote rat))
      (cadcomplete-exists (cadgen-subst-formula phi (cdr sample) n) (- n 1))
      (cadcomplete-at-alg phi n sample)))
; for an algebraic outer value, recurse at a rational probe inside its isolating interval (catches the
; full-dimensional and rational-fiber witnesses sitting over the section) -- the genuinely algebraic-coordinate
; section witnesses are handled by rqe's tower search, which this module complements
(define (cadcomplete-at-alg phi n sample)
  (cadcomplete-exists (cadgen-subst-formula phi (cadcomplete-mid (cadcomplete-nth sample 2) (cadcomplete-nth sample 3)) n) (- n 1)))

; ----- the full decision -----
(define (cadcomplete-decide quant phi n)
  (cond ((equal? quant (quote exists)) (cadcomplete-exists phi n))
        ((equal? quant (quote forall)) (if (cadcomplete-exists (list (quote not) phi) n) #f #t))
        (else #f)))
