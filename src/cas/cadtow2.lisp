; -*- lisp -*-
; src/cas/cadtow2.lisp -- the irrational-outer-coordinate frontier: decide an existential sentence whose witness is a
; point of an algebraic TOWER, every coordinate a real algebraic number built over the ones below it, including the
; OUTERMOST.  This closes the gap named by cadcomplete's scope note (cadcomplete recurses at a rational probe inside
; an irrational outer coordinate's interval, which finds witnesses sitting over the section but not those whose outer
; coordinate must be exactly that irrational number).  Here the chain of equalities is read as a simple tower
; Q subset Q(a_1) subset Q(a_1, a_2) subset ... -- the construction cadtower.lisp evaluates exactly -- and the extra
; inequalities are tested at the tower point with exact algebraic-number signs, so a witness like x = sqrt(2),
; y = 2^(1/4), z = 2^(1/4) of "x^2 = 2 and y^2 = x and z = y and z > 1" is found, which the rational-probe recursion
; cannot reach.
;
; The bridge from a formula to a tower.  A conjunction's EQUALITY atoms, when they form a simple chain -- one
; equality univariate in the first variable, each later equality introducing the next variable over the one below --
; define a tower: the base polynomial is the univariate one, and each subsequent equality is the fiber polynomial
; f_i(x_{i-1}, x_i) presented as a polynomial in x_i with coefficients polynomial in x_{i-1}.  cadtow2 recognizes
; this shape by flattening each equality to monomials, finding its highest variable, and regrouping it into the
; fiber form; it orders the equalities by highest variable to get the base and the successive fibers.  The
; INEQUALITY atoms become the extra sign conditions, each regrouped as a polynomial in the top variable with
; coefficients in the level below.  The whole is handed to cadtower-exists-chain, which builds the real tower points
; (every base root crossed with every real fiber root, refined as boxes of nested algebraic numbers) and tests the
; conditions exactly.
;
; Soundness: every point cadtower constructs is a genuine real tower point and every sign is exact, so a positive
; verdict is correct.  Scope: simple (iterated-extension) chains are decided directly here via cadtower; genuinely
; COUPLED chains, where a defining polynomial mixes several lower variables at once (z = x*y, z = x + y), are decided
; by the coupled-chain path below, which reads the chain in cadrc.lisp's representation and decides sign and
; vanishing at the chain point by the multivariate resultant.  When the equalities do not form a recognizable
; regular chain at all, cadtow2-exists declines (returns #f) without ever asserting a false witness; it is a sound
; ADDITIONAL source of witnesses, wired into rqe after the cheaper searches.
;
; Public:
;   cadtow2-exists phi n          -> #t iff phi (a conjunction of equalities forming a simple tower plus inequality
;                                    conditions) has a witness on the tower, including when the outer coordinate is
;                                    irrational; #f if no such witness is found or the equalities are not a simple
;                                    chain (sound: never a false positive)
;   cadtow2-chain-of phi n        -> the recognized chain (basef base-intervals higher conds) or () if none
;
; Verified: exists x, y, z . x^2 = 2 and y^2 = x and z = y and z > 1 (true, the tower sqrt(2), 2^(1/4), 2^(1/4));
; the same with z > 2 is false; and a two-level x^2 = 2 and y^2 = x with y > 0 (true, 2^(1/4)).
;
; Builds on cadtower.lisp (the simple-tower point construction and exact sign decision), cadcomplete.lisp / cadgen.lisp
; (the nested polynomial representation and formula tools), sturm.lisp, and poly.lisp.

(import "cas/cadtower.lisp")
(import "cas/cadcomplete.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

; ----- flatten a nested OUTER-first polynomial (arity n) into monomials (coeff . expvec) over (x_1, ..., x_n) -----
(define (cadtow2-flat node n depth ev acc)
  (if (= depth n) (if (cadtow2-zn? node) acc (cons (cons node ev) acc))
      (cadtow2-flat-list node n depth 0 ev acc)))
(define (cadtow2-flat-list cs n depth k ev acc)
  (if (null? cs) acc (cadtow2-flat-list (cdr cs) n depth (+ k 1) ev (cadtow2-flat (car cs) n (+ depth 1) (cadtow2-setexp ev depth k) acc))))
(define (cadtow2-setexp ev i k) (if (= i 0) (cons k (cdr ev)) (cons (car ev) (cadtow2-setexp (cdr ev) (- i 1) k))))
(define (cadtow2-zn? x) (if (pair? x) #f (if (null? x) #t (= x 0))))
(define (cadtow2-zerov n) (if (= n 0) (quote ()) (cons 0 (cadtow2-zerov (- n 1)))))
(define (cadtow2-evnth ev i) (if (= i 0) (car ev) (cadtow2-evnth (cdr ev) (- i 1))))
(define (cadtow2-monos p n) (cadtow2-flat p n 0 (cadtow2-zerov n) (quote ())))

; ----- the highest variable index actually present in a monomial list (0-based; -1 if constant) -----
(define (cadtow2-hivar monos n) (cadtow2-hv monos n -1))
(define (cadtow2-hv monos n best) (if (null? monos) best (cadtow2-hv (cdr monos) n (cadtow2-maxi best (cadtow2-hi-of (cdr (car monos)) n)))))
(define (cadtow2-hi-of ev n) (cadtow2-hio ev 0 -1))
(define (cadtow2-hio ev i best) (cond ((null? ev) best) ((> (car ev) 0) (cadtow2-hio (cdr ev) (+ i 1) i)) (else (cadtow2-hio (cdr ev) (+ i 1) best))))
(define (cadtow2-maxi a b) (if (> a b) a b))
(define (cadtow2-mini a b) (if (< a b) a b))

; ----- the lowest variable index present (to confirm a fiber is simple: spans only hi-1 and hi) -----
(define (cadtow2-lovar monos) (cadtow2-lv monos 1000000))
(define (cadtow2-lv monos best) (if (null? monos) best (cadtow2-lv (cdr monos) (cadtow2-mini best (cadtow2-lo-of (cdr (car monos)))))))
(define (cadtow2-lo-of ev) (cadtow2-loo ev 0 1000000))
(define (cadtow2-loo ev i best) (cond ((null? ev) best) ((> (car ev) 0) (cadtow2-loo (cdr ev) (+ i 1) (cadtow2-mini best i))) (else (cadtow2-loo (cdr ev) (+ i 1) best))))

; ----- regroup monomials into a polynomial in variable `hi`, coefficients polynomial in variable `lo` -----
(define (cadtow2-fiber monos hi lo) (cadtow2-densify (cadtow2-group monos hi lo) 0))
(define (cadtow2-group monos hi lo) (cadtow2-grp monos hi lo (quote ())))
(define (cadtow2-grp monos hi lo acc)
  (if (null? monos) acc
      (cadtow2-grp (cdr monos) hi lo (cadtow2-place acc (cadtow2-evnth (cdr (car monos)) hi) (cadtow2-evnth (cdr (car monos)) lo) (car (car monos))))))
(define (cadtow2-place acc hp lp c)
  (cond ((null? acc) (list (list hp (list lp c))))
        ((= (car (car acc)) hp) (cons (cons hp (cons (list lp c) (cdr (car acc)))) (cdr acc)))
        (else (cons (car acc) (cadtow2-place (cdr acc) hp lp c)))))
(define (cadtow2-densify assoc k) (cadtow2-densify2 assoc k (cadtow2-maxp assoc 0)))
(define (cadtow2-maxp assoc m) (if (null? assoc) m (cadtow2-maxp (cdr assoc) (cadtow2-maxi (car (car assoc)) m))))
(define (cadtow2-densify2 assoc k kmax) (if (> k kmax) (quote ()) (cons (cadtow2-coeffpoly (cadtow2-lookup assoc k)) (cadtow2-densify2 assoc (+ k 1) kmax))))
(define (cadtow2-lookup assoc k) (cond ((null? assoc) (quote ())) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadtow2-lookup (cdr assoc) k))))
(define (cadtow2-coeffpoly terms) (cadtow2-cpoly terms 0 (cadtow2-maxlp terms 0)))
(define (cadtow2-maxlp terms m) (if (null? terms) m (cadtow2-maxlp (cdr terms) (cadtow2-maxi (car (car terms)) m))))
(define (cadtow2-cpoly terms k kmax) (if (> k kmax) (quote ()) (cons (cadtow2-sumc terms k) (cadtow2-cpoly terms (+ k 1) kmax))))
(define (cadtow2-sumc terms k) (cadtow2-sc terms k 0))
(define (cadtow2-sc terms k acc) (cond ((null? terms) acc) ((= (car (car terms)) k) (cadtow2-sc (cdr terms) k (+ acc (car (cdr (car terms)))))) (else (cadtow2-sc (cdr terms) k acc))))

; ----- the univariate base polynomial in x_1 from a monomial list that uses only x_1 -----
(define (cadtow2-uni monos) (cadtow2-uni-d (cadtow2-uni-assoc monos (quote ())) 0))
(define (cadtow2-uni-assoc monos acc) (if (null? monos) acc (cadtow2-uni-assoc (cdr monos) (cadtow2-uni-place acc (cadtow2-evnth (cdr (car monos)) 0) (car (car monos))))))
(define (cadtow2-uni-place acc p c) (cond ((null? acc) (list (cons p c))) ((= (car (car acc)) p) (cons (cons p (+ (cdr (car acc)) c)) (cdr acc))) (else (cons (car acc) (cadtow2-uni-place (cdr acc) p c)))))
(define (cadtow2-uni-d assoc k) (if (> k (cadtow2-maxp assoc 0)) (quote ()) (cons (cadtow2-uni-lk assoc k) (cadtow2-uni-d assoc (+ k 1)))))
(define (cadtow2-uni-lk assoc k) (cond ((null? assoc) 0) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadtow2-uni-lk (cdr assoc) k))))

; ----- separate a conjunction's equality atoms from its inequality atoms -----
(define (cadtow2-conj phi) (cond ((equal? (car phi) (quote and)) (cdr phi)) (else (list phi))))
(define (cadtow2-equalities atoms) (cond ((null? atoms) (quote ())) ((cadtow2-is-zero? (car atoms)) (cons (cdr (car atoms)) (cadtow2-equalities (cdr atoms)))) (else (cadtow2-equalities (cdr atoms)))))
(define (cadtow2-inequalities atoms) (cond ((null? atoms) (quote ())) ((cadtow2-is-zero? (car atoms)) (cadtow2-inequalities (cdr atoms))) (else (cons (car atoms) (cadtow2-inequalities (cdr atoms))))))
(define (cadtow2-is-zero? a) (if (pair? a) (equal? (car a) (quote zero)) #f))

; ----- recognize the simple chain: order equalities by highest variable, one per variable level -----
; returns a list of (hivar . monos) sorted by hivar ascending; #f if it is not one-equality-per-level simple shape
(define (cadtow2-order eqs n) (cadtow2-sort (cadtow2-tag eqs n)))
(define (cadtow2-tag eqs n) (if (null? eqs) (quote ()) (cons (cons (cadtow2-hivar (cadtow2-monos (car eqs) n) n) (cadtow2-monos (car eqs) n)) (cadtow2-tag (cdr eqs) n))))
(define (cadtow2-sort tagged) (cadtow2-sort-go tagged (quote ())))
(define (cadtow2-sort-go tagged acc) (if (null? tagged) acc (cadtow2-sort-go (cdr tagged) (cadtow2-ins (car tagged) acc))))
(define (cadtow2-ins x sorted) (cond ((null? sorted) (list x)) ((< (car x) (car (car sorted))) (cons x sorted)) (else (cons (car sorted) (cadtow2-ins x (cdr sorted))))))

; build the chain (basef base-ivs higher conds) from an ordered simple chain, or () if the shape is not simple.
; `ordered` is the (hivar . monos) list sorted ascending; for a simple tower the hivars are exactly 0,1,...,k.
(define (cadtow2-chain-of phi n)
  (cadtow2-assemble (cadtow2-order (cadtow2-equalities (cadtow2-conj phi)) n) (cadtow2-inequalities (cadtow2-conj phi)) n))
(define (cadtow2-assemble ordered ineqs n)
  (if (cadtow2-simple? ordered 0) (cadtow2-build ordered ineqs n) (quote ())))
; simple if the i-th entry (0-based) has hivar exactly i and (for i>=1) spans only variables i-1 and i
(define (cadtow2-simple? ordered i)
  (cond ((null? ordered) #t)
        ((not (= (car (car ordered)) i)) #f)
        ((and (>= i 1) (< (cadtow2-lovar (cdr (car ordered))) (- i 1))) #f)
        (else (cadtow2-simple? (cdr ordered) (+ i 1)))))
; assemble: base = univariate poly of the level-0 entry; higher fibers each get their REAL ROOT BRACKETS (so each
; starting interval isolates a single fiber root, which cadtower then refines exactly); conds from the inequalities.
; we enumerate every combination of (base root, fiber-1 root, fiber-2 root, ...) as a separate chain and the
; decision succeeds if any combination yields a witness -- this is the lifting over all real branches of the tower.
(define (cadtow2-build ordered ineqs n)
  (cadtow2-make-jobs (cadtow2-uni (cdr (car ordered))) (cadtow2-fibers (cdr ordered)) (cadtow2-conds ineqs (cadtow2-topvar ordered) n)))
; a "job" is one chain (basef base-ivs higher conds); we package the data needed for cadtow2-exists to enumerate
(define (cadtow2-make-jobs basef fibers conds) (list (quote jobs) basef (cadtow2-iso basef) fibers conds))
(define (cadtow2-iso basef) (isolate-roots (cadtow2-cleard basef)))
; the fiber polynomials (poly in x_i with coeffs in x_{i-1}) for levels 1..k, paired with their level index
(define (cadtow2-fibers ordered) (if (null? ordered) (quote ()) (cons (cadtow2-fiber (cdr (car ordered)) (car (car ordered)) (- (car (car ordered)) 1)) (cadtow2-fibers (cdr ordered)))))
; conditions: each inequality atom (op . p), p nested OUTER-first arity n, regrouped as a poly in the TOP variable
; with coefficients in the level below it
(define (cadtow2-topvar ordered) (cadtow2-top ordered 0))
(define (cadtow2-top ordered best) (if (null? ordered) best (cadtow2-top (cdr ordered) (cadtow2-maxi best (car (car ordered))))))
(define (cadtow2-conds ineqs top n) (if (null? ineqs) (quote ()) (cons (cons (car (car ineqs)) (cadtow2-fiber (cadtow2-monos (cdr (car ineqs)) n) top (cadtow2-mini-pos (- top 1)))) (cadtow2-conds (cdr ineqs) top n))))
(define (cadtow2-mini-pos k) (if (< k 0) 0 k))

; denominator clearing for the base polynomial
(define (cadtow2-cleard p) (cadtow2-scale p (cadtow2-lcd p)))
(define (cadtow2-scale p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadtow2-scale (cdr p) m))))
(define (cadtow2-lcd p) (cadtow2-lcd-go p 1))
(define (cadtow2-lcd-go p acc) (if (null? p) acc (cadtow2-lcd-go (cdr p) (cadtow2-lcm acc (denominator (car p))))))
(define (cadtow2-lcm a b) (/ (* a b) (cadtow2-gcd a b)))
(define (cadtow2-gcd a b) (if (= b 0) a (cadtow2-gcd b (remainder a b))))

; ----- the decision: try the simple-tower path, then the general coupled-chain path -----
(define (cadtow2-exists phi n)
  (if (cadtow2-run (cadtow2-chain-of phi n)) #t (cadtow2-coupled-exists phi n)))
(define (cadtow2-run spec)
  (cond ((null? spec) #f)
        ((equal? (car spec) (quote jobs)) (cadtow2-each-base (car (cdr spec)) (car (cdr (cdr spec))) (car (cdr (cdr (cdr spec)))) (car (cdr (cdr (cdr (cdr spec)))))))
        (else #f)))
; for each base root interval, build the fiber brackets over a probe of that interval and try all branches
(define (cadtow2-each-base basef base-ivs fibers conds)
  (cond ((null? base-ivs) #f)
        ((cadtow2-branch basef (car base-ivs) fibers conds) #t)
        (else (cadtow2-each-base basef (cdr base-ivs) fibers conds))))
; one base interval: enumerate the fiber-root brackets level by level (probing each level's interval to isolate the
; next fiber's roots), accumulating (f lo hi) entries, then call cadtower-exists-chain for each full branch
(define (cadtow2-branch basef base-iv fibers conds)
  (cadtow2-lift basef (list base-iv) (cadtow2-probe base-iv) fibers (quote ()) conds))
(define (cadtow2-probe iv) (/ (+ (car iv) (car (cdr iv))) 2))
; lift: `built` is the reversed list of (f lo hi) chosen so far; `lastprobe` a rational approximation of the current
; top coordinate (to substitute into the next fiber).  When fibers are exhausted, test the chain.
(define (cadtow2-lift basef base-ivs lastprobe fibers built conds)
  (if (null? fibers)
      (cadtower-exists-chain basef base-ivs (cadtow2-rev built) conds)
      (cadtow2-try-brackets basef base-ivs lastprobe (car fibers) (cdr fibers) built conds (cadtow2-fiber-brackets (car fibers) lastprobe))))
; try each real-root bracket of the current fiber (evaluated at lastprobe) as the next coordinate
(define (cadtow2-try-brackets basef base-ivs lastprobe fib rest built conds brackets)
  (cond ((null? brackets) #f)
        ((cadtow2-lift basef base-ivs (cadtow2-probe (car brackets)) rest (cons (list fib (car (car brackets)) (car (cdr (car brackets)))) built) conds) #t)
        (else (cadtow2-try-brackets basef base-ivs lastprobe fib rest built conds (cdr brackets)))))
; the real-root brackets of a fiber polynomial (poly in x_i, coeffs polys in x_{i-1}) evaluated at x_{i-1}=probe,
; each refined by a bounded number of bisections so the bracket excludes 0 and isolates its single root tightly
; (a wide bracket straddling 0 defeats the tower's sign-based refinement; refining toward the probe-root keeps the
; true root -- which is near the probe-root -- inside while sharpening the bracket)
(define (cadtow2-fiber-brackets fib probe) (cadtow2-refine-all (cadtow2-eval-fiber-cleared fib probe) (isolate-roots (cadtow2-eval-fiber-cleared fib probe))))
(define (cadtow2-eval-fiber-cleared fib probe) (cadtow2-cleard (cadtow2-eval-fiber fib probe)))
(define (cadtow2-eval-fiber fib probe) (if (null? fib) (quote ()) (cons (poly-eval (car fib) probe) (cadtow2-eval-fiber (cdr fib) probe))))
(define (cadtow2-refine-all p ivs) (if (null? ivs) (quote ()) (cons (cadtow2-refine p (car (car ivs)) (car (cdr (car ivs))) 6) (cadtow2-refine-all p (cdr ivs)))))
; bisect up to k times to tighten (lo,hi) around the single root it isolates
(define (cadtow2-refine p lo hi k)
  (cond ((<= k 0) (list lo hi))
        ((= (poly-eval p lo) 0) (list lo lo))
        ((= (poly-eval p hi) 0) (list hi hi))
        (else (cadtow2-refine-mid p lo hi k (/ (+ lo hi) 2)))))
(define (cadtow2-refine-mid p lo hi k m)
  (cond ((= (poly-eval p m) 0) (list m m))
        ((= (cadtow2-rsgn (poly-eval p lo)) (cadtow2-rsgn (poly-eval p m))) (cadtow2-refine p m hi (- k 1)))
        (else (cadtow2-refine p lo m (- k 1)))))
(define (cadtow2-rsgn v) (cond ((> v 0) 1) ((< v 0) -1) (else 0)))
(define (cadtow2-rev l) (cadtow2-rev-go l (quote ())))
(define (cadtow2-rev-go l acc) (if (null? l) acc (cadtow2-rev-go (cdr l) (cons (car l) acc))))

(define (cadtow2-chain-caveat) (quote simple-tower-only-coupled-chains-via-cadrc))

; ===== the coupled-chain frontier: decide via cadrc when the chain is NOT a simple iterated extension =====
; When the equalities form a general regular chain -- a defining polynomial f_i(x_1, ..., x_i) coupling several lower
; variables at once (z = x*y, z = x + y, ...) rather than only the immediately preceding one -- the simple-tower
; recognizer above declines.  cadrc.lisp decides sign and vanishing at a point of such a chain by the multivariate
; resultant with regrouping between levels.  Here we read the chain off the formula in cadrc's representation (each
; f_i a polynomial in its top variable x_i with mpoly coefficients over the lower variables), build the fiber boxes
; by substituting a rational probe vector of the lower coordinates into each coupled fiber and isolating its roots,
; enumerate the real branches, and test the inequality atoms at the chain point with cadrc-sign.  Soundness is
; unchanged: every constructed point is a genuine real point of the chain and every sign is exact.

(import "cas/cadrc.lisp")

(define (cadtow2-coupled-exists phi n)
  (cadtow2-co-assemble (cadtow2-order (cadtow2-equalities (cadtow2-conj phi)) n) (cadtow2-inequalities (cadtow2-conj phi)) n))
; require one equality per level 0..k (the regular-chain shape); the fibers may be coupled (no simple-span test)
(define (cadtow2-co-assemble ordered ineqs n)
  (if (cadtow2-co-shape? ordered 0) (cadtow2-co-build ordered ineqs n) #f))
(define (cadtow2-co-shape? ordered i)
  (cond ((null? ordered) (> i 1))                       ; need at least a base + one fiber to be worth the coupled path
        ((not (= (car (car ordered)) i)) #f)
        (else (cadtow2-co-shape? (cdr ordered) (+ i 1)))))
; build: base univariate poly; the coupled fibers (cadrc mpoly form) top-down; the conditions as cadrc mpolys in the
; top variable; then enumerate the branches
(define (cadtow2-co-build ordered ineqs n)
  (cadtow2-co-run (cadtow2-uni (cdr (car ordered)))
                  (cadtow2-co-fibers-bottomup (cdr ordered))
                  (cadtow2-co-conds ineqs (cadtow2-topvar ordered))))
; the fibers for levels 1..k, each as (cadrc-poly top-index), bottom-up (level 1 first)
(define (cadtow2-co-fibers-bottomup ordered) (if (null? ordered) (quote ()) (cons (cons (cadtow2-rc-fiber (cdr (car ordered)) (car (car ordered))) (car (car ordered))) (cadtow2-co-fibers-bottomup (cdr ordered)))))
; regroup a monomial list into cadrc form: poly in var `top`, each coefficient an mpoly over vars [0 .. top-1]
(define (cadtow2-rc-fiber monos top) (cadtow2-rc-densify (cadtow2-rc-group monos top) 0))
(define (cadtow2-rc-group monos top) (cadtow2-rc-grp monos top (quote ())))
(define (cadtow2-rc-grp monos top acc)
  (if (null? monos) acc
      (cadtow2-rc-grp (cdr monos) top (cadtow2-rc-place acc (cadtow2-evnth (cdr (car monos)) top) (cons (car (car monos)) (cadtow2-rc-take (cdr (car monos)) top))))))
(define (cadtow2-rc-take ev k) (if (= k 0) (quote ()) (cons (car ev) (cadtow2-rc-take (cdr ev) (- k 1)))))
(define (cadtow2-rc-place acc p mono)
  (cond ((null? acc) (list (cons p (list mono))))
        ((= (car (car acc)) p) (cons (cons p (cons mono (cdr (car acc)))) (cdr acc)))
        (else (cons (car acc) (cadtow2-rc-place (cdr acc) p mono)))))
(define (cadtow2-rc-densify assoc k) (cadtow2-rc-d2 assoc k (cadtow2-rc-maxp assoc 0)))
(define (cadtow2-rc-maxp assoc m) (if (null? assoc) m (cadtow2-rc-maxp (cdr assoc) (cadtow2-maxi (car (car assoc)) m))))
(define (cadtow2-rc-d2 assoc k kmax) (if (> k kmax) (quote ()) (cons (cadtow2-rc-lookup assoc k) (cadtow2-rc-d2 assoc (+ k 1) kmax))))
(define (cadtow2-rc-lookup assoc k) (cond ((null? assoc) (quote ())) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadtow2-rc-lookup (cdr assoc) k))))
; the conditions: each inequality (op . p) as a cadrc mpoly in the top variable with mpoly coeffs over lower vars
(define (cadtow2-co-conds ineqs top) (if (null? ineqs) (quote ()) (cons (cons (car (car ineqs)) (cadtow2-rc-fiber (cadtow2-monos (cdr (car ineqs)) (+ top 1)) top)) (cadtow2-co-conds (cdr ineqs) top))))

; ----- enumerate the chain branches and test the conditions at each point via cadrc -----
(define (cadtow2-co-run basef fibers conds) (cadtow2-co-each-base basef (cadtow2-iso basef) fibers conds))
(define (cadtow2-co-each-base basef base-ivs fibers conds)
  (cond ((null? base-ivs) #f)
        ((cadtow2-co-branch basef (car base-ivs) fibers conds) #t)
        (else (cadtow2-co-each-base basef (cdr base-ivs) fibers conds))))
; one base interval: lift level by level, substituting the probe vector of chosen lower coordinates into each
; coupled fiber to isolate its roots; `probes` is the list (outer-first: x_1 probe, x_2 probe, ...) accumulated;
; `levels` is the reversed list of (f lo hi) for cadrc-point
(define (cadtow2-co-branch basef base-iv fibers conds)
  (cadtow2-co-lift basef base-iv (list (cadtow2-probe base-iv)) fibers (quote ()) conds))
(define (cadtow2-co-lift basef base-iv probes fibers levels conds)
  (if (null? fibers)
      (cadtow2-co-test basef base-iv (cadtow2-rev levels) conds)
      (cadtow2-co-try basef base-iv probes (car fibers) (cdr fibers) levels conds (cadtow2-co-fiber-brackets (car (car fibers)) probes))))
(define (cadtow2-co-try basef base-iv probes fib rest levels conds brackets)
  (cond ((null? brackets) #f)
        ((cadtow2-co-lift basef base-iv (cadtow2-co-append probes (cadtow2-probe (car brackets))) rest (cons (list (car fib) (car (car brackets)) (car (cdr (car brackets)))) levels) conds) #t)
        (else (cadtow2-co-try basef base-iv probes fib rest levels conds (cdr brackets)))))
(define (cadtow2-co-append l x) (if (null? l) (list x) (cons (car l) (cadtow2-co-append (cdr l) x))))
; the real-root brackets of a coupled fiber (cadrc poly in x_i, mpoly coeffs over lower vars) at the probe vector of
; the lower coordinates: substitute the probes into each mpoly coefficient to get a univariate poly in x_i, isolate,
; and refine each bracket to exclude 0 and isolate its single root
(define (cadtow2-co-fiber-brackets fib probes) (cadtow2-refine-all (cadtow2-cleard (cadtow2-co-eval fib probes)) (isolate-roots (cadtow2-cleard (cadtow2-co-eval fib probes)))))
(define (cadtow2-co-eval fib probes) (if (null? fib) (quote ()) (cons (cadtow2-mpoly-eval (car fib) probes) (cadtow2-co-eval (cdr fib) probes))))
(define (cadtow2-mpoly-eval mp pt) (cadtow2-me mp pt 0))
(define (cadtow2-me mp pt acc) (if (null? mp) acc (cadtow2-me (cdr mp) pt (+ acc (* (car (car mp)) (cadtow2-monomial (cdr (car mp)) pt))))))
(define (cadtow2-monomial ev pt) (cadtow2-mono ev pt 1))
(define (cadtow2-mono ev pt acc) (cond ((null? ev) acc) ((null? pt) acc) (else (cadtow2-mono (cdr ev) (cdr pt) (* acc (cadtow2-rpow (car pt) (car ev)))))))
(define (cadtow2-rpow b e) (if (= e 0) 1 (* b (cadtow2-rpow b (- e 1)))))
; test every condition at the chain point with cadrc-sign (the chain is the fibers top-down)
(define (cadtow2-co-test basef base-iv levels conds)
  (cadtow2-co-checkall conds (cadtow2-co-chain levels) basef (car base-iv) (car (cdr base-iv)) levels))
; cadrc wants the chain as the fibers TOP-DOWN (highest variable first); `levels` is bottom-up (level 1 first)
(define (cadtow2-co-chain levels) (cadtow2-rev (cadtow2-co-justf levels)))
(define (cadtow2-co-justf levels) (if (null? levels) (quote ()) (cons (car (car levels)) (cadtow2-co-justf (cdr levels)))))
(define (cadtow2-co-checkall conds chain basef lo hi levels)
  (cond ((null? conds) #t)
        ((cadtow2-co-holds? (car conds) chain basef lo hi levels) (cadtow2-co-checkall (cdr conds) chain basef lo hi levels))
        (else #f)))
(define (cadtow2-co-holds? cond chain basef lo hi levels)
  (cadtow2-co-op (car cond) (cadrc-sign (cdr cond) chain basef lo hi levels)))
(define (cadtow2-co-op op s)
  (cond ((equal? op (quote pos)) (> s 0))
        ((equal? op (quote neg)) (< s 0))
        ((equal? op (quote nonneg)) (>= s 0))
        ((equal? op (quote nonpos)) (<= s 0))
        ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

(define (cadtow2-coupled-caveat) (quote coupled-chains-via-cadrc-multivariate-resultant))
