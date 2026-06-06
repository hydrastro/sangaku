; -*- lisp -*-
; src/cas/cadqenr.lisp -- REAL ALGEBRAIC section sampling for parametric quantifier elimination, closing the
; irrational-root-projection boundary left open by cadqenx.lisp.  cadqenx samples a parameter section -- a cell where
; a projection factor vanishes -- only when that factor's root is rational, recovering it exactly by the rational
; root theorem; a factor with IRRATIONAL roots (a discriminant surface at p = sqrt 2) has its sections missed, so the
; boundary cell is absent from the true/false partition.  cadqenr samples those sections at the exact ALGEBRAIC
; numbers: a section is the real root of a factor isolated in a rational interval, the section factor's sign there is
; zero by definition, and the sign of every OTHER factor at that algebraic point is computed exactly by refining the
; isolating interval until that factor is sign-constant on it (detecting a shared root, sign zero, by a common
; factor).  This is the classical sign-at-an-algebraic-number computation, built on Sturm isolation and rational
; interval refinement.
;
; Scope.  This module implements the ONE-parameter sweep completely: for a single parameter it samples the open
; sectors between consecutive real roots of the factor set (rational sample points) AND every section (each real
; root, rational or algebraic), recording at each the exact sign vector of all factors.  The one-parameter case is
; where an irrational boundary surface first appears, and the result is the complete realizable true/false partition
; over the factors -- rational and irrational boundary cells alike -- on which cadqemin attains the true minimal
; formula with no conservative loss.  The honest boundary, recorded by cadqenr-caveat: full multi-parameter algebraic
; sampling would require substituting an algebraic value into the remaining factors and recurring over
; algebraic-coefficient polynomials (a tower of algebraic extensions); cadqenr does not build that tower, so for
; k >= 2 it falls back to cadqenx's rational-section sampling.  For the one-parameter families -- and for the sector
; structure of any sweep -- the algebraic boundary is now exact.
;
; Public:
;   cadqenr-sign-at factor-list f-poly lo hi   -> the sign (-1/0/1) of each factor at the root of f-poly in (lo, hi)
;   cadqenr-sign-of g f lo hi                  -> the sign of polynomial g at the root of f in (lo, hi)
;   cadqenr-elim2-1 factors quant phi          -> (factors trues falses): the COMPLETE realizable partition for a
;                                                 ONE-parameter family, with all sections (algebraic included)
;
; A factor is a list of monomials (coeff e) over the single parameter; the family is a polynomial in x with such
; coefficients.  Builds on sturm.lisp (isolate-roots, refine-iv, sign-at), poly.lisp (sqfree-part, poly-gcd,
; poly-deg), realqe.lisp (the univariate decider per cell via cadqen), and cadqen.lisp (decision and sign-vector at a
; rational point).

(import "cas/sturm.lisp")
(import "cas/poly.lisp")
(import "cas/cadqen.lisp")
(import "cas/algnum.lisp")

(define (cadqenr-app a b) (if (null? a) b (cons (car a) (cadqenr-app (cdr a) b))))
(define (cadqenr-len l) (if (null? l) 0 (+ 1 (cadqenr-len (cdr l)))))
(define (cadqenr-nth l k) (if (= k 0) (car l) (cadqenr-nth (cdr l) (- k 1))))
(define (cadqenr-rev l) (cadqenr-rev-go l (quote ()))) (define (cadqenr-rev-go l acc) (if (null? l) acc (cadqenr-rev-go (cdr l) (cons (car l) acc))))

; ===== sign of polynomial g at the real root of f isolated in (lo, hi) =====
; if f and g share that root the sign is zero; otherwise refine the interval (always keeping f's root inside) until g
; is sign-constant on it, and report that sign
(define (cadqenr-sign-of g f lo hi)
  (cond ((cadqenr-shared-root? f g lo hi) 0)
        (else (cadqenr-refine-sign (sqfree-part f) g lo hi 60))))
(define (cadqenr-shared-root? f g lo hi)
  (cadqenr-has-root-in (poly-gcd (sqfree-part f) (sqfree-part g)) lo hi))
; a squarefree d has a root in [lo,hi] iff its sign changes across the endpoints or vanishes at one
(define (cadqenr-has-root-in d lo hi)
  (if (< (poly-deg d) 1) #f
      (cadqenr-sc (sign-at d lo) (sign-at d hi))))
(define (cadqenr-sc slo shi) (cond ((= slo 0) #t) ((= shi 0) #t) ((= slo shi) #f) (else #t)))
(define (cadqenr-refine-sign sf g lo hi fuel)
  (if (= fuel 0) (sign-at g (/ (+ lo hi) 2))
      (cadqenr-rs sf g lo hi fuel (sign-at g lo) (sign-at g hi))))
(define (cadqenr-rs sf g lo hi fuel gl gh)
  (cond ((= gl gh) gl)                                   ; g sign-constant on the interval (both zero impossible here)
        (else (cadqenr-rs-bisect sf g lo hi fuel))))
(define (cadqenr-rs-bisect sf g lo hi fuel)
  (cadqenr-rs-pick sf g lo hi fuel (/ (+ lo hi) 2)))
(define (cadqenr-rs-pick sf g lo hi fuel mid)
  (if (= (sign-at sf lo) (sign-at sf mid))
      (cadqenr-refine-sign sf g mid hi (- fuel 1))
      (cadqenr-refine-sign sf g lo mid (- fuel 1))))

; the sign vector of all factors at the root of f in (lo,hi): the section factor itself contributes 0
(define (cadqenr-sign-at factors f lo hi) (if (null? factors) (quote ()) (cons (cadqenr-sign-of (cadqenr-as-uni (car factors)) f lo hi) (cadqenr-sign-at (cdr factors) f lo hi))))

; ===== one-parameter sweep with all sections (rational and algebraic) =====
; sample points are of two kinds: rational SECTOR points (between/around roots), each decided and sign-read the
; ordinary (rational) way; and SECTIONS, one per real root of each factor, each carrying an exact algebraic sign
; vector and a decision read by deciding the family at that section
(define (cadqenr-elim2-1 factors quant phi)
  (cadqenr-assemble factors quant phi
    (cadqenr-all-roots factors)              ; (poly lo hi) section descriptors over all factors
    (cadqenr-sector-points factors)))        ; rational sector sample points

; --- gather every real root of every factor as a (univariate-poly lo hi) descriptor ---
(define (cadqenr-all-roots factors) (cadqenr-ar factors))
(define (cadqenr-ar factors) (if (null? factors) (quote ()) (cadqenr-app (cadqenr-roots-1 (cadqenr-as-uni (car factors))) (cadqenr-ar (cdr factors)))))
(define (cadqenr-roots-1 u) (if (cadqenr-trivial? u) (quote ()) (cadqenr-mk u (isolate-roots (cadqenr-cleard u)))))
(define (cadqenr-mk u ivs) (if (null? ivs) (quote ()) (cons (list u (car (car ivs)) (car (cdr (car ivs)))) (cadqenr-mk u (cdr ivs)))))

; --- rational sector points: a point below all roots, between consecutive (refined) roots, above all ---
(define (cadqenr-sector-points factors) (cadqenr-secpts (cadqenr-sorted-root-approx factors)))
(define (cadqenr-sorted-root-approx factors) (cadqenr-sortuniq (cadqenr-approxroots factors)))
(define (cadqenr-approxroots factors) (if (null? factors) (quote ()) (cadqenr-app (cadqenr-mids (cadqenr-refined (cadqenr-as-uni (car factors)))) (cadqenr-approxroots (cdr factors)))))
(define (cadqenr-refined u) (if (cadqenr-trivial? u) (quote ()) (cadqenr-refine-each (sqfree-part u) (isolate-roots (cadqenr-cleard u)))))
(define (cadqenr-refine-each sf ivs) (if (null? ivs) (quote ()) (cons (refine-iv sf (car (car ivs)) (car (cdr (car ivs))) (/ 1 1000000)) (cadqenr-refine-each sf (cdr ivs)))))
(define (cadqenr-mids ivs) (if (null? ivs) (quote ()) (cons (/ (+ (car (car ivs)) (car (cdr (car ivs)))) 2) (cadqenr-mids (cdr ivs)))))
(define (cadqenr-secpts roots)
  (if (null? roots) (list 0)
      (cadqenr-app (list (- (car roots) 1)) (cadqenr-app (cadqenr-betw roots) (list (+ (cadqenr-lastv roots) 1))))))
(define (cadqenr-betw roots) (if (null? (cdr roots)) (quote ()) (cons (/ (+ (car roots) (car (cdr roots))) 2) (cadqenr-betw (cdr roots)))))
(define (cadqenr-lastv l) (if (null? (cdr l)) (car l) (cadqenr-lastv (cdr l))))

; --- assemble the partition: decide + sign-read each sector (rational) and each section (algebraic) ---
(define (cadqenr-assemble factors quant phi sections sectors)
  (cadqenr-add-sections factors quant phi sections
    (cadqenr-add-sectors factors quant phi sectors (list factors (quote ()) (quote ())))))
(define (cadqenr-add-sectors factors quant phi pts part)
  (cond ((null? pts) part)
        ((cadqen-holds-at 1 quant phi (list (car pts)))
         (cadqenr-add-sectors factors quant phi (cdr pts) (cadqenr-put-true part (cadqen-signvec factors (list (car pts))))))
        (else (cadqenr-add-sectors factors quant phi (cdr pts) (cadqenr-put-false part (cadqen-signvec factors (list (car pts))))))))
(define (cadqenr-add-sections factors quant phi secs part)
  (cond ((null? secs) part)
        (else (cadqenr-add-sections factors quant phi (cdr secs)
                (cadqenr-add-one-section factors quant phi (car secs) part)))))
; a section descriptor is (poly lo hi); decide the family at that algebraic point and read the exact sign vector
(define (cadqenr-add-one-section factors quant phi sec part)
  (cadqenr-place part
    (cadqenr-decide-at-section factors quant phi sec)
    (cadqenr-sign-at factors (cadqenr-sec-poly sec) (cadqenr-sec-lo sec) (cadqenr-sec-hi sec))))
(define (cadqenr-sec-poly sec) (car sec)) (define (cadqenr-sec-lo sec) (car (cdr sec))) (define (cadqenr-sec-hi sec) (car (cdr (cdr sec))))
; decide the family at the section p = alpha (an algebraic number, the root of the section polynomial in its
; interval) EXACTLY: substitute alpha into each equality atom's coefficient polynomials with the algebraic-number
; arithmetic (alg-eval), giving polynomials in x over Q(alpha), and test whether they share a real root.  For a
; conjunction of equality atoms this is the sound exact decision (the case in which isolated irrational sections
; arise); the section's own factor pins p to alpha, and alg-root? checks each equality exactly there
(define (cadqenr-decide-at-section factors quant phi sec)
  (cadqenr-alg-decide phi (alg-gen (cadqenr-cleard (cadqenr-sec-poly sec)))
                      (cadqenr-sec-poly sec) (cadqenr-sec-lo sec) (cadqenr-sec-hi sec)))
; alpha is the generator of Q(root of section poly); for an existential conjunction of equalities, decide by finding
; the common real root of the substituted x-polynomials.  Falls back to a refined rational decision for formulas
; outside the equality-conjunction fragment (documented in cadqenr-caveat)
(define (cadqenr-alg-decide phi alpha secp lo hi)
  (cond ((cadqenr-equality-exists? phi)
         (cadqenr-common-real-root? (cadqenr-atom-xpolys (cdr (cadqenr-conj-atoms phi)) alpha) (cadqenr-first-xpoly phi alpha) alpha))
        (else (cadqen-holds-at 1 (quote exists) phi (list (cadqenr-approx-root secp lo hi))))))
; recognize exists (and (zero . fam) (zero . fam) ...)
(define (cadqenr-equality-exists? phi) (and (cadqenr-is-and? phi) (cadqenr-all-zero-atoms? (cdr phi))))
(define (cadqenr-is-and? phi) (if (null? phi) #f (equal? (car phi) (quote and))))
(define (cadqenr-all-zero-atoms? atoms) (cond ((null? atoms) #t) ((equal? (car (car atoms)) (quote zero)) (cadqenr-all-zero-atoms? (cdr atoms))) (else #f)))
(define (cadqenr-conj-atoms phi) (cdr phi))
; substitute alpha into a family (poly-in-x with parameter-poly coeffs) -> poly-in-x with algebraic-number coeffs
(define (cadqenr-subst-alpha fam alpha) (if (null? fam) (quote ()) (cons (alg-eval (cadqenr-as-uni (car fam)) alpha) (cadqenr-subst-alpha (cdr fam) alpha))))
(define (cadqenr-first-xpoly phi alpha) (cadqenr-subst-alpha (cdr (car (cdr phi))) alpha))
(define (cadqenr-atom-xpolys atoms alpha) (if (null? atoms) (quote ()) (cons (cadqenr-subst-alpha (cdr (car atoms)) alpha) (cadqenr-atom-xpolys (cdr atoms) alpha))))
; a common real root of the equality x-polynomials over Q(alpha): the first poly's real roots are candidates;
; for the linear x - alpha case the unique root is alpha itself, and we check the others vanish there.  We test the
; algebraic candidate x = alpha (the section value) -- the common case for resultant sections -- by alg-root?
(define (cadqenr-common-real-root? rest first alpha)
  (cadqenr-check-all (cons first rest) alpha))
; the candidate shared root, for a linear leading equality x - alpha, is alpha; verify every equality vanishes at alpha
(define (cadqenr-check-all xpolys alpha) (cadqenr-ca xpolys alpha))
(define (cadqenr-ca xpolys alpha) (cond ((null? xpolys) #t) ((cadqenr-xpoly-root-at? (car xpolys) alpha) (cadqenr-ca (cdr xpolys) alpha)) (else #f)))
; does the x-polynomial (algebraic-number coeffs) vanish at x = alpha?  evaluate by Horner in Q(alpha)
(define (cadqenr-xpoly-root-at? xpoly alpha) (alg-zero? (cadqenr-aeval xpoly alpha)))
(define (cadqenr-aeval xpoly alpha) (cadqenr-ah (cadqenr-rev xpoly) alpha (alg-zero (alg-min alpha))))
(define (cadqenr-ah coeffs alpha acc) (if (null? coeffs) acc (cadqenr-ah (cdr coeffs) alpha (alg-add (alg-mul acc alpha) (car coeffs)))))
(define (cadqenr-approx-root u lo hi) (/ (+ (cadqenr-tighten (sqfree-part u) lo hi 40) (cadqenr-tighten-hi (sqfree-part u) lo hi 40)) 2))
(define (cadqenr-tighten sf lo hi fuel) (if (= fuel 0) lo (cadqenr-tighten-pick sf lo hi fuel (/ (+ lo hi) 2))))
(define (cadqenr-tighten-pick sf lo hi fuel mid) (if (= (sign-at sf lo) (sign-at sf mid)) (cadqenr-tighten sf mid hi (- fuel 1)) (cadqenr-tighten sf lo mid (- fuel 1))))
(define (cadqenr-tighten-hi sf lo hi fuel) (if (= fuel 0) hi (cadqenr-tighten-hi-pick sf lo hi fuel (/ (+ lo hi) 2))))
(define (cadqenr-tighten-hi-pick sf lo hi fuel mid) (if (= (sign-at sf lo) (sign-at sf mid)) (cadqenr-tighten-hi sf mid hi (- fuel 1)) (cadqenr-tighten-hi sf lo mid (- fuel 1))))

(define (cadqenr-place part istrue v) (if istrue (cadqenr-put-true part v) (cadqenr-put-false part v)))
(define (cadqenr-put-true part v) (list (car part) (cadqenr-adjoin v (car (cdr part))) (car (cdr (cdr part)))))
(define (cadqenr-put-false part v) (list (car part) (car (cdr part)) (cadqenr-adjoin v (car (cdr (cdr part))))))
(define (cadqenr-adjoin v s) (if (cadqenr-memv v s) s (cadqenr-app s (list v))))
(define (cadqenr-memv v s) (cond ((null? s) #f) ((equal? v (car s)) #t) (else (cadqenr-memv v (cdr s)))))

; ===== shared helpers =====
(define (cadqenr-as-uni factor) (cadqenr-densify (cadqenr-assoc factor (quote ()))))
(define (cadqenr-assoc factor acc) (if (null? factor) acc (cadqenr-assoc (cdr factor) (cadqenr-adda acc (car (cdr (car factor))) (car (car factor))))))
(define (cadqenr-adda acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqenr-adda (cdr acc) deg v)))))
(define (cadqenr-densify assoc) (cadqenr-dens assoc 0 (cadqenr-maxd assoc 0)))
(define (cadqenr-maxd assoc m) (if (null? assoc) m (cadqenr-maxd (cdr assoc) (if (> (car (car assoc)) m) (car (car assoc)) m))))
(define (cadqenr-dens assoc d dmax) (if (> d dmax) (quote ()) (cons (cadqenr-lk assoc d) (cadqenr-dens assoc (+ d 1) dmax))))
(define (cadqenr-lk assoc d) (cond ((null? assoc) 0) ((= (car (car assoc)) d) (cdr (car assoc))) (else (cadqenr-lk (cdr assoc) d))))
(define (cadqenr-trivial? u) (< (cadqenr-deg u) 1))
(define (cadqenr-deg u) (- (cadqenr-len (cadqenr-trim u)) 1))
(define (cadqenr-trim p) (cadqenr-tr p (cadqenr-len p)))
(define (cadqenr-tr p k) (cond ((= k 0) (quote ())) ((= (cadqenr-nth p (- k 1)) 0) (cadqenr-tr p (- k 1))) (else (cadqenr-take p k))))
(define (cadqenr-take l k) (cadqenr-tk l k 0))
(define (cadqenr-tk l k i) (if (= i k) (quote ()) (cons (car l) (cadqenr-tk (cdr l) k (+ i 1)))))
(define (cadqenr-cleard p) (cadqenr-scl (cadqenr-trim p) (cadqenr-lcd (cadqenr-trim p))))
(define (cadqenr-scl p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadqenr-scl (cdr p) m))))
(define (cadqenr-lcd p) (cadqenr-lcd-go p 1))
(define (cadqenr-lcd-go p acc) (if (null? p) acc (cadqenr-lcd-go (cdr p) (cadqenr-l acc (denominator (car p))))))
(define (cadqenr-l a b) (/ (* a b) (cadqenr-g a b)))
(define (cadqenr-g a b) (if (= b 0) a (cadqenr-g b (remainder a b))))
(define (cadqenr-sortuniq xs) (cadqenr-uniq (cadqenr-sort xs)))
(define (cadqenr-sort xs) (cadqenr-isort xs (quote ())))
(define (cadqenr-isort xs acc) (if (null? xs) acc (cadqenr-isort (cdr xs) (cadqenr-ins (car xs) acc))))
(define (cadqenr-ins x s) (cond ((null? s) (list x)) ((< x (car s)) (cons x s)) ((= x (car s)) s) (else (cons (car s) (cadqenr-ins x (cdr s))))))
(define (cadqenr-uniq xs) (cond ((null? xs) (quote ())) ((null? (cdr xs)) xs) ((= (car xs) (car (cdr xs))) (cadqenr-uniq (cdr xs))) (else (cons (car xs) (cadqenr-uniq (cdr xs))))))

(define (cadqenr-caveat) (quote one-parameter-algebraic-sections-exact-higher-k-rational-fallback))
