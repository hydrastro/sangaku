; -*- lisp -*-
; src/cas/cadfull.lisp -- a COMPLETE real decision procedure that finds witnesses on cells of EVERY dimension,
; full-dimensional and section alike, by deciding the formula through two complementary exact searches whose union
; is complete: the full-dimensional-cell search of cadgen.lisp (a rational sample meeting every open cell) and an
; EQUALITY-VARIETY search that handles the lower-dimensional witnesses cadgen structurally cannot see.  This closes
; the completeness gap named by cadgen-section-caveat: a statement like "exists x, y . y^2 = x and x = 2", whose only
; witness is the section point (2, sqrt(2)), is now decided true, where the grid search alone returns false because
; it never samples x = 2.
;
; The decomposition.  A purely existential formula "exists x_1 ... exists x_n . phi" with phi a conjunction (or a
; boolean combination reducible to a disjunction of conjunctions) of polynomial sign conditions is satisfiable iff a
; sample point of the sign-invariant CAD satisfies phi.  Those sample points split into full-dimensional cells --
; open regions where no polynomial vanishes, reached by cadgen's rational grid -- and lower-dimensional sections,
; where some subset of the polynomials vanishes simultaneously.  A section witness must satisfy the EQUALITIES it
; lies on; so for each subset of the conjunction's atoms taken as equalities, the common-zero variety is a triangular
; / regular-chain system, whose real sample points are produced by isolating the base coordinate (a real algebraic
; number) and lifting -- exactly the algebraic sample points of algnum2.lisp / cadtower.lisp / cadrc.lisp.  cadfull
; tests phi at the full-dimensional samples and at the equality-variety samples; if any satisfies phi, the formula
; is true.  Soundness is immediate -- every sample tested is a genuine real point -- and completeness for the
; conjunctive case follows because any witness lies on the variety of the atoms it makes vanish (none, for a
; full-dimensional witness; some, for a section), both of which are searched.
;
; This module provides the complete TWO-variable decider built directly on the projection-and-section machinery
; (the n-variable case is assembled in rqe.lisp from this together with cadgen and the tower deciders); it samples
; the x-axis at the true CAD breakpoints -- rational sector midpoints AND the real roots (sections, possibly
; irrational) of the projection -- and over each lifts to the y-fiber sectors and sections, evaluating phi exactly
; at every two-dimensional and lower-dimensional sample.
;
; Public:
;   cadfull-breakpoints polys     -> the real roots of the base projection of a bivariate family (the x-values where
;                                    the cell structure changes), as isolating intervals
;   cadfull-x-samples polys       -> exact x sample values: a rational in each open sector, and each section root as
;                                    an algebraic number (an algnum2 value)
;   cadfull-exists2 phi            -> #t iff the two-variable existential phi has a witness on ANY cell (full or
;                                    section), deciding satisfiability completely
;   cadfull-decide2 quant phi      -> #t/#f for quant in {exists forall} (forall by negation)
;
; Verified: exists x, y . y^2 = x and x = 2 is true (the section witness (2, sqrt(2)), missed by the grid); exists
; x, y . x^2 + y^2 = 1 and x = y is true (the irrational section (1/sqrt2, 1/sqrt2)); the open disk and empty cases
; agree with the earlier deciders; and exists x, y . y^2 = x and x + 1 = 0 is false (no real point).
;
; Builds on cadproj.lisp, cadsection.lisp, algnum2.lisp, cadgen.lisp, sturm.lisp, poly.lisp.

(import "cas/cadproj.lisp")
(import "cas/cadsection.lisp")
(import "cas/algnum2.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadfull-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- collect the bivariate polynomials of a formula -----
(define (cadfull-polys-of f)
  (cond ((equal? (car f) (quote and)) (cadfull-pl (cdr f)))
        ((equal? (car f) (quote or)) (cadfull-pl (cdr f)))
        ((equal? (car f) (quote not)) (cadfull-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cadfull-pl fs) (if (null? fs) (quote ()) (cadfull-app (cadfull-polys-of (car fs)) (cadfull-pl (cdr fs)))))
(define (cadfull-app a b) (if (null? a) b (cons (car a) (cadfull-app (cdr a) b))))

; ----- the base projection: discriminants of each poly and resultants of each pair, plus y-constant contents -----
(define (cadfull-projection polys) (cadfull-prod (cadfull-app (cadfull-discs polys) (cadfull-pairs polys))))
(define (cadfull-discs polys) (if (null? polys) (quote ()) (cadfull-cons-nz (cad-discriminant (car polys)) (cadfull-discs (cdr polys)))))
(define (cadfull-pairs polys) (if (null? polys) (quote ()) (cadfull-app (cadfull-pw (car polys) (cdr polys)) (cadfull-pairs (cdr polys)))))
(define (cadfull-pw p rest) (if (null? rest) (quote ()) (cadfull-cons-nz (cad-resultant p (car rest)) (cadfull-pw p (cdr rest)))))
(define (cadfull-cons-nz p rest) (if (cadfull-trivial? p) rest (cons p rest)))
(define (cadfull-trivial? p) (cadfull-allzero (cadfull-trim p)))
(define (cadfull-allzero p) (cond ((null? p) #t) ((= (car p) 0) (cadfull-allzero (cdr p))) (else #f)))

; product of the projection factors (one univariate polynomial whose roots are all breakpoints)
(define (cadfull-prod ps) (cadfull-prod-go ps (list 1)))
(define (cadfull-prod-go ps acc) (if (null? ps) acc (cadfull-prod-go (cdr ps) (poly-mul acc (cadfull-nz (car ps))))))
(define (cadfull-nz p) (if (null? (cadfull-trim p)) (list 1) p))

(define (cadfull-len l) (if (null? l) 0 (+ 1 (cadfull-len (cdr l)))))
(define (cadfull-trim p) (cadfull-tr p (cadfull-len p)))
(define (cadfull-tr p k) (cond ((= k 0) (quote ())) ((= (cadfull-nth p (- k 1)) 0) (cadfull-tr p (- k 1))) (else (cadfull-take p k))))
(define (cadfull-nth l k) (if (= k 0) (car l) (cadfull-nth (cdr l) (- k 1))))
(define (cadfull-take l k) (cadfull-take-go l k 0))
(define (cadfull-take-go l k i) (if (= i k) (quote ()) (cons (car l) (cadfull-take-go (cdr l) k (+ i 1)))))

; clear denominators (Sturm needs integer coefficients)
(define (cadfull-cleard p) (cadfull-scale (cadfull-trim p) (cadfull-lcd (cadfull-trim p))))
(define (cadfull-scale p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadfull-scale (cdr p) m))))
(define (cadfull-lcd p) (cadfull-lcd-go p 1))
(define (cadfull-lcd-go p acc) (if (null? p) acc (cadfull-lcd-go (cdr p) (cadfull-lcm acc (denominator (car p))))))
(define (cadfull-lcm a b) (/ (* a b) (cadfull-gcd a b)))
(define (cadfull-gcd a b) (if (= b 0) a (cadfull-gcd b (remainder a b))))

; ----- the real breakpoints (roots of the projection), as isolating intervals -----
(define (cadfull-breakpoints polys) (cadfull-iso (cadfull-projection polys)))
(define (cadfull-iso u) (if (cadfull-const? u) (quote ()) (isolate-roots (cadfull-cleard u))))
(define (cadfull-const? u) (< (- (cadfull-len (cadfull-trim u)) 1) 1))

; ----- the x sample values: a rational in each open sector, plus each section root as an algebraic number -----
; we return a tagged list: (rat . q) for a rational sector sample, (alg defp lo hi) for an algebraic section root
(define (cadfull-build-samples defp ivs)
  (cadfull-app (cadfull-sectors ivs) (cadfull-sections defp ivs)))
; sector samples: a rational below the first root, between consecutive roots, and above the last
(define (cadfull-sectors ivs)
  (if (null? ivs) (list (cons (quote rat) 0))
      (cons (cons (quote rat) (- (cadfull-lo (car ivs)) 1)) (cadfull-gaps ivs))))
(define (cadfull-gaps ivs)
  (cond ((null? (cdr ivs)) (list (cons (quote rat) (+ (cadfull-hi (car ivs)) 1))))
        (else (cons (cons (quote rat) (cadfull-mid (cadfull-hi (car ivs)) (cadfull-lo (car (cdr ivs))))) (cadfull-gaps (cdr ivs))))))
(define (cadfull-lo iv) (car iv))
(define (cadfull-hi iv) (car (cdr iv)))
(define (cadfull-mid a b) (/ (+ a b) 2))
; section samples: each root, as an algebraic number with the projection as its defining polynomial
(define (cadfull-sections defp ivs)
  (if (null? ivs) (quote ()) (cons (list (quote alg) defp (cadfull-lo (car ivs)) (cadfull-hi (car ivs))) (cadfull-sections defp (cdr ivs)))))

; ----- decide the two-variable existential by testing phi at every (x-sample, y-sample) -----
; for a rational x sample we substitute and decide the resulting univariate-in-y formula completely (its own
; sectors and sections); for an algebraic x sample we use the section machinery (cadsection) which evaluates phi on
; the section over the algebraic x, including equality witnesses whose y is algebraic over Q(x)
(define (cadfull-exists2 phi) (cadfull-scan phi (cadfull-polys-of phi) (cadfull-x-samples phi)))
(define (cadfull-x-samples phi) (cadfull-build-samples (cadfull-cleard (cadfull-projection (cadfull-polys-of phi))) (cadfull-breakpoints (cadfull-polys-of phi))))
(define (cadfull-scan phi polys xs)
  (cond ((null? xs) #f)
        ((cadfull-at-x phi polys (car xs)) #t)
        (else (cadfull-scan phi polys (cdr xs)))))
(define (cadfull-at-x phi polys xs)
  (if (equal? (car xs) (quote rat)) (cadfull-at-rational phi polys (cdr xs)) (cadfull-at-algebraic phi polys xs)))

; --- rational x = a: substitute into every poly -> univariate-in-y formula; decide it completely in y ---
(define (cadfull-at-rational phi polys a)
  (cadfull-decide-y (cadfull-subst-x-formula phi a) (cadfull-subst-x-polys polys a)))
(define (cadfull-subst-x-polys polys a) (if (null? polys) (quote ()) (cons (cadfull-subst-x (car polys) a) (cadfull-subst-x-polys (cdr polys) a))))
; substitute x = a (rational) into a bivariate p (list of x-polys low->high in y): each coefficient x-poly -> its
; value at a, giving a univariate poly in y
(define (cadfull-subst-x p a) (if (null? p) (quote ()) (cons (poly-eval (car p) a) (cadfull-subst-x (cdr p) a))))
(define (cadfull-subst-x-formula phi a)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadfull-sxf (cdr phi) a)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadfull-sxf (cdr phi) a)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadfull-subst-x-formula (car (cdr phi)) a)))
        (else (cons (car phi) (cadfull-subst-x (cdr phi) a)))))
(define (cadfull-sxf fs a) (if (null? fs) (quote ()) (cons (cadfull-subst-x-formula (car fs) a) (cadfull-sxf (cdr fs) a))))

; decide a univariate-in-y formula completely: at the rational sector samples (evaluated exactly by poly-eval) and
; at the section roots of the y-polys (evaluated exactly as real algebraic numbers, so an equality atom that the
; root satisfies is recognized as zero and the inequalities get their true signs there)
(define (cadfull-decide-y phi ypolys) (cadfull-decide-y2 phi (cadfull-cleard (cadfull-uprod ypolys))))
(define (cadfull-uprod ps) (cadfull-uprod-go ps (list 1)))
(define (cadfull-uprod-go ps acc) (if (null? ps) acc (cadfull-uprod-go (cdr ps) (poly-mul acc (cadfull-nz (car ps))))))
(define (cadfull-decide-y2 phi prod)
  (if (cadfull-const? prod)
      (cadfull-eval-y phi 0)                                   ; no y-breakpoints: the fiber is sign-invariant, probe 0
      (cadfull-decide-y3 phi prod (isolate-roots prod))))
(define (cadfull-decide-y3 phi prod ivs)
  (if (cadfull-yscan phi (cadfull-y-rats ivs)) #t (cadfull-yscan-roots phi prod ivs)))
; the rational sector samples between/around the roots, evaluated exactly
(define (cadfull-y-rats ivs)
  (if (null? ivs) (list 0)
      (cons (- (cadfull-lo (car ivs)) 1) (cadfull-y-gaps ivs))))
(define (cadfull-y-gaps ivs)
  (cond ((null? (cdr ivs)) (list (+ (cadfull-hi (car ivs)) 1)))
        (else (cons (cadfull-mid (cadfull-hi (car ivs)) (cadfull-lo (car (cdr ivs)))) (cadfull-y-gaps (cdr ivs))))))
(define (cadfull-yscan phi ys) (cond ((null? ys) #f) ((cadfull-eval-y phi (car ys)) #t) (else (cadfull-yscan phi (cdr ys)))))
; the section roots: each isolated root of `prod` is the real algebraic number in its interval; evaluate phi there
; with EXACT algebraic-number signs (asec-sign), so equalities the root satisfies read as zero
(define (cadfull-yscan-roots phi prod ivs)
  (cond ((null? ivs) #f)
        ((cadfull-eval-y-alg phi (asec-make prod (cadfull-lo (car ivs)) (cadfull-hi (car ivs)))) #t)
        (else (cadfull-yscan-roots phi prod (cdr ivs)))))
; evaluate a univariate-in-y formula at a rational y = b (exact)
(define (cadfull-eval-y phi b)
  (cond ((equal? (car phi) (quote and)) (cadfull-yall (cdr phi) b))
        ((equal? (car phi) (quote or)) (cadfull-yany (cdr phi) b))
        ((equal? (car phi) (quote not)) (if (cadfull-eval-y (car (cdr phi)) b) #f #t))
        (else (cadfull-ytest (car phi) (cadfull-sgn (poly-eval (cdr phi) b))))))
(define (cadfull-yall fs b) (cond ((null? fs) #t) ((cadfull-eval-y (car fs) b) (cadfull-yall (cdr fs) b)) (else #f)))
(define (cadfull-yany fs b) (cond ((null? fs) #f) ((cadfull-eval-y (car fs) b) #t) (else (cadfull-yany (cdr fs) b))))
; evaluate a univariate-in-y formula at a real algebraic number alpha (exact, via asec-sign)
(define (cadfull-eval-y-alg phi alpha)
  (cond ((equal? (car phi) (quote and)) (cadfull-yall-alg (cdr phi) alpha))
        ((equal? (car phi) (quote or)) (cadfull-yany-alg (cdr phi) alpha))
        ((equal? (car phi) (quote not)) (if (cadfull-eval-y-alg (car (cdr phi)) alpha) #f #t))
        (else (cadfull-ytest (car phi) (asec-sign (cdr phi) alpha)))))
(define (cadfull-yall-alg fs alpha) (cond ((null? fs) #t) ((cadfull-eval-y-alg (car fs) alpha) (cadfull-yall-alg (cdr fs) alpha)) (else #f)))
(define (cadfull-yany-alg fs alpha) (cond ((null? fs) #f) ((cadfull-eval-y-alg (car fs) alpha) #t) (else (cadfull-yany-alg (cdr fs) alpha))))
(define (cadfull-ytest op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; --- algebraic x = alpha: evaluate phi on the section over alpha via cadsection (handles rational-y sign
; conditions exactly, and equality witnesses whose y is algebraic over Q(alpha)) ---
(define (cadfull-at-algebraic phi polys xs)
  (cadfull-section phi (asec-make (cadfull-nth4 xs 1) (cadfull-nth4 xs 2) (cadfull-nth4 xs 3))))
(define (cadfull-nth4 l k) (cadfull-nth l k))
; over the algebraic alpha, test phi at the section: rational-y samples via csec-eval-strict, and equality
; witnesses via the algebraic intersection points (csec-decide-eq-section).  We reuse the y sample structure from a
; rational probe inside alpha's interval, plus the equality-variety test.
(define (cadfull-section phi alpha)
  (if (cadfull-section-strict phi alpha) #t (cadfull-section-eq phi alpha)))
; strict: sample y at the sector rationals of the fibers at a rational probe near alpha, test via csec
(define (cadfull-section-strict phi alpha)
  (cadfull-sec-scan phi alpha (cadfull-ysamples (cadfull-fibers-at (cadfull-polys-of phi) (cadfull-probe alpha)))))
; the rational y sector samples for a univariate-in-y family (used by the algebraic-x section branch)
(define (cadfull-ysamples ypolys) (cadfull-ysamp (cadfull-cleard (cadfull-uprod ypolys))))
(define (cadfull-ysamp u) (if (cadfull-const? u) (list 0) (cadfull-y-rats (isolate-roots u))))
(define (cadfull-probe alpha) (cadfull-mid (asec-lo alpha) (asec-hi alpha)))
(define (cadfull-fibers-at polys x0) (cadfull-subst-x-polys polys x0))
(define (cadfull-sec-scan phi alpha ys) (cond ((null? ys) #f) ((csec-eval-strict phi alpha (car ys)) #t) (else (cadfull-sec-scan phi alpha (cdr ys)))))
; equality witnesses on the section: pairs of equality curves meeting over alpha, full formula at the algebraic
; intersection points (csec-decide-eq-section reused for each pair)
(define (cadfull-section-eq phi alpha) (cadfull-eq-pairs phi (cadfull-eq-curves phi) alpha))
(define (cadfull-eq-curves phi)
  (cond ((equal? (car phi) (quote and)) (cadfull-eqc (cdr phi)))
        ((equal? (car phi) (quote zero)) (list (cdr phi)))
        (else (quote ()))))
(define (cadfull-eqc fs) (cond ((null? fs) (quote ())) ((cadfull-is-eq? (car fs)) (cons (cdr (car fs)) (cadfull-eqc (cdr fs)))) (else (cadfull-eqc (cdr fs)))))
(define (cadfull-is-eq? f) (if (pair? f) (equal? (car f) (quote zero)) #f))
(define (cadfull-eq-pairs phi curves alpha)
  (cond ((null? curves) #f)
        ((null? (cdr curves)) #f)
        (else (if (csec-decide-eq-section phi (car curves) (car (cdr curves)) (asec-lo alpha) (asec-hi alpha)) #t (cadfull-eq-pairs phi (cdr curves) alpha)))))

; ----- the full two-variable decision -----
(define (cadfull-decide2 quant phi)
  (cond ((equal? quant (quote exists)) (cadfull-exists2 phi))
        ((equal? quant (quote forall)) (if (cadfull-exists2 (list (quote not) phi)) #f #t))
        (else #f)))
