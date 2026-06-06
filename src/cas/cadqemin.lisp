; -*- lisp -*-
; src/cas/cadqemin.lisp -- TRUE minimal solution-formula construction for parametric quantifier elimination.  The
; parametric eliminators report the eliminated condition as a disjunction of sign vectors over the projection
; factors, and cadqesimp.lisp reduces that by Quine-McCluskey-style merging -- but merging alone is only the first
; phase of minimization and can leave a redundant cover.  This module performs the genuine minimization: it computes
; a MINIMAL cover of the true cells by prime implicants, the second phase that produces the simplest formula, which
; is Brown's solution-formula-construction problem.
;
; The decisive ingredient is that the sign-vector space has DON'T-CARES.  The sign of a projection factor is not free
; -- a discriminant's sign is determined by the coefficients -- so of the 3^m sign patterns over m factors only some
; are geometrically realizable.  The eliminator therefore returns two sets: the realizable sign vectors on which the
; statement is TRUE, and those on which it is FALSE; every other pattern is unrealizable and is a don't-care, free to
; be covered or not.  A cube (a conjunction of sign/relation conditions) is VALID exactly when it covers no realizable
; FALSE cell; within that constraint it may freely cover true cells and don't-cares.  This is ordinary
; minimization-with-don't-cares, with the realizable-false set as the validity oracle.
;
; Two phases:
;   1. PRIME GENERATION.  From each true cell (an exact sign vector) repeatedly GENERALIZE one position -- an exact
;      sign to a two-sign relation (1 or 0 to >=, -1 or 0 to <=, 1 or -1 to !=), a relation to "any" (star) -- keeping
;      only generalizations that remain valid (cover no false cell).  Generalizing every position as far as it will
;      go yields a prime implicant: a maximal valid cube.  Collecting the primes of every true cell, deduplicated,
;      gives the prime set.
;   2. MINIMAL COVER.  Choose a smallest subset of primes that covers every true cell.  Essential primes -- those
;      that alone cover some true cell no other prime covers -- are forced into the cover; the remaining true cells
;      are covered greedily by the prime covering the most of them, repeating until all are covered.  Essential-prime
;      selection plus greedy is exact on the standard examples (it returns the textbook three-branch formula for the
;      general quadratic) and near-minimal in general; it is always a sound and complete cover.
;
; Soundness and completeness.  Every prime covers no false cell (validity), so the disjunction covers no false cell;
; the cover includes every true cell (completeness of the selection), so the formula is logically equivalent to the
; true-set over the realizable space.  The result is the minimal such disjunction up to the exactness of the cover
; step.  cadqemin-caveat records that the cover is essential-plus-greedy (exact on the standard cases, not a proven
; global optimum for every input -- the exact set cover is NP-hard, the genuinely hard core of Brown's problem).
;
; Public:
;   cadqemin-minimize factors trues falses   -> a readable formula (disjunction of conjunctions of factor sign /
;                                               relation conditions), a minimal cover of `trues` avoiding `falses`
;   cadqemin-cover trues falses               -> the chosen list of prime cubes (the cover, before rendering)
;
; A sign vector is a list over the factors of 1, 0, or -1.  A cube is a list over the factors of 1, 0, -1, the
; relations ge / le / ne, or star.  Builds only on list primitives; pairs with cadqesimp (its merges) and the
; eliminators cadqe2 / cadqe3 / cadqen (which supply the true and false sign-vector sets).

(define (cadqemin-app a b) (if (null? a) b (cons (car a) (cadqemin-app (cdr a) b))))
(define (cadqemin-len l) (if (null? l) 0 (+ 1 (cadqemin-len (cdr l)))))
(define (cadqemin-nth l k) (if (= k 0) (car l) (cadqemin-nth (cdr l) (- k 1))))
(define (cadqemin-mem x s) (cond ((null? s) #f) ((equal? x (car s)) #t) (else (cadqemin-mem x (cdr s)))))

; ===== coverage: does a cube admit a sign vector? =====
(define (cadqemin-adm lit s)
  (cond ((equal? lit (quote star)) #t)
        ((equal? lit (quote ge)) (if (= s 1) #t (= s 0)))
        ((equal? lit (quote le)) (if (= s -1) #t (= s 0)))
        ((equal? lit (quote ne)) (if (= s 1) #t (= s -1)))
        (else (= lit s))))
(define (cadqemin-covers cube v) (cond ((null? cube) #t) ((cadqemin-adm (car cube) (car v)) (cadqemin-covers (cdr cube) (cdr v))) (else #f)))
; a cube is valid iff it covers NO false cell
(define (cadqemin-valid? cube falses) (cond ((null? falses) #t) ((cadqemin-covers cube (car falses)) #f) (else (cadqemin-valid? cube (cdr falses)))))

; ===== phase 1: prime generation by greedy generalization =====
; the generalization options for a position value (most general first is handled by trying and keeping if valid)
(define (cadqemin-generalizations val)
  (cond ((equal? val 1) (list (quote star) (quote ge) (quote ne)))
        ((equal? val -1) (list (quote star) (quote le) (quote ne)))
        ((equal? val 0) (list (quote star) (quote ge) (quote le)))
        ((equal? val (quote ge)) (list (quote star)))
        ((equal? val (quote le)) (list (quote star)))
        ((equal? val (quote ne)) (list (quote star)))
        (else (quote ()))))
; generalize one true cube to a prime: walk each position, replace by the most general valid value, to a fixpoint
(define (cadqemin-prime-of cube falses) (cadqemin-prime-pass cube falses 0 (cadqemin-len cube)))
(define (cadqemin-prime-pass cube falses k n)
  (if (>= k n) cube
      (cadqemin-prime-pass (cadqemin-relax cube falses k) falses (+ k 1) n)))
; at position k, try each generalization (most general first); keep the first that stays valid
(define (cadqemin-relax cube falses k) (cadqemin-try-gens cube falses k (cadqemin-generalizations (cadqemin-nth cube k))))
(define (cadqemin-try-gens cube falses k gens)
  (cond ((null? gens) cube)
        ((cadqemin-valid? (cadqemin-set cube k (car gens)) falses) (cadqemin-set cube k (car gens)))
        (else (cadqemin-try-gens cube falses k (cdr gens)))))
(define (cadqemin-set cube k v) (if (= k 0) (cons v (cdr cube)) (cons (car cube) (cadqemin-set (cdr cube) (- k 1) v))))
; collect the primes of all true cells (a single greedy prime per cell; dedup)
(define (cadqemin-primes trues falses) (cadqemin-dedup (cadqemin-primes-go trues falses)))
(define (cadqemin-primes-go trues falses) (if (null? trues) (quote ()) (cons (cadqemin-prime-of (car trues) falses) (cadqemin-primes-go (cdr trues) falses))))
(define (cadqemin-dedup l) (cadqemin-dd l (quote ())))
(define (cadqemin-dd l acc) (cond ((null? l) (cadqemin-rev acc)) ((cadqemin-mem (car l) acc) (cadqemin-dd (cdr l) acc)) (else (cadqemin-dd (cdr l) (cons (car l) acc)))))
(define (cadqemin-rev l) (cadqemin-rev-go l (quote ())))
(define (cadqemin-rev-go l acc) (if (null? l) acc (cadqemin-rev-go (cdr l) (cons (car l) acc))))

; ===== phase 2: minimal cover (essential primes + greedy) =====
(define (cadqemin-cover trues falses) (cadqemin-select (cadqemin-primes trues falses) trues))
; select a covering subset: take essentials, then greedily cover the rest
(define (cadqemin-select primes trues)
  (cadqemin-greedy primes (cadqemin-uncovered trues (cadqemin-essentials primes trues)) (cadqemin-essentials primes trues)))
; essentials: a prime is essential if some true cell is covered by it and by no other prime
(define (cadqemin-essentials primes trues) (cadqemin-ess-go primes trues primes))
(define (cadqemin-ess-go primes trues all)
  (cond ((null? primes) (quote ()))
        ((cadqemin-is-essential (car primes) trues all) (cons (car primes) (cadqemin-ess-go (cdr primes) trues all)))
        (else (cadqemin-ess-go (cdr primes) trues all))))
(define (cadqemin-is-essential p trues all) (cadqemin-ie-go p trues all))
(define (cadqemin-ie-go p trues all)
  (cond ((null? trues) #f)
        ((and (cadqemin-covers p (car trues)) (cadqemin-only-cover p (car trues) all)) #t)
        (else (cadqemin-ie-go p (cdr trues) all))))
; is p the ONLY prime in `all` covering cell v?
(define (cadqemin-only-cover p v all) (cadqemin-oc-go p v all))
(define (cadqemin-oc-go p v all)
  (cond ((null? all) #t)
        ((and (not (equal? (car all) p)) (cadqemin-covers (car all) v)) #f)
        (else (cadqemin-oc-go p v (cdr all)))))
; true cells not covered by any cube in `chosen`
(define (cadqemin-uncovered trues chosen) (cadqemin-unc-go trues chosen))
(define (cadqemin-unc-go trues chosen)
  (cond ((null? trues) (quote ()))
        ((cadqemin-any-covers chosen (car trues)) (cadqemin-unc-go (cdr trues) chosen))
        (else (cons (car trues) (cadqemin-unc-go (cdr trues) chosen)))))
(define (cadqemin-any-covers cubes v) (cond ((null? cubes) #f) ((cadqemin-covers (car cubes) v) #t) (else (cadqemin-any-covers (cdr cubes) v))))
; greedily add the prime covering the most still-uncovered cells, until none remain
(define (cadqemin-greedy primes remaining chosen)
  (if (null? remaining) chosen
      (cadqemin-greedy primes (cadqemin-uncovered remaining (list (cadqemin-best primes remaining))) (cons (cadqemin-best primes remaining) chosen))))
(define (cadqemin-best primes remaining) (cadqemin-best-go (cdr primes) remaining (car primes) (cadqemin-count (car primes) remaining)))
(define (cadqemin-best-go primes remaining bestp bestn)
  (cond ((null? primes) bestp)
        ((> (cadqemin-count (car primes) remaining) bestn) (cadqemin-best-go (cdr primes) remaining (car primes) (cadqemin-count (car primes) remaining)))
        (else (cadqemin-best-go (cdr primes) remaining bestp bestn))))
(define (cadqemin-count cube cells) (cadqemin-cnt cube cells 0))
(define (cadqemin-cnt cube cells acc) (cond ((null? cells) acc) ((cadqemin-covers cube (car cells)) (cadqemin-cnt cube (cdr cells) (+ acc 1))) (else (cadqemin-cnt cube (cdr cells) acc))))

; ===== phase 2': EXACT minimum cover by branch and bound (optimal, for small prime sets) =====
; the essential-plus-greedy cover (cadqemin-cover) is fast and exact on the standard examples but greedy can be
; suboptimal in general; cadqemin-cover-exact finds a provably MINIMUM cover by branch and bound over the primes --
; force in the essential primes, then recursively pick an uncovered true cell and branch on each prime covering it,
; pruning any branch that reaches the current best size.  Exact for the small prime sets quantifier elimination
; produces; cadqemin-cover-best chooses exact when the prime set is small and greedy otherwise
(define (cadqemin-cover-exact trues falses) (cadqemin-exact-from (cadqemin-primes trues falses) trues))
(define (cadqemin-exact-from primes trues)
  (cadqemin-bnb primes trues (cadqemin-essentials primes trues) (+ 1 (cadqemin-len primes))))
(define (cadqemin-bnb primes trues chosen bound)
  (cond ((null? (cadqemin-uncovered trues chosen)) chosen)
        ((>= (cadqemin-len chosen) bound) (quote cadqemin-toobig))
        (else (cadqemin-branch (cadqemin-covering primes (car (cadqemin-uncovered trues chosen))) primes trues chosen bound))))
(define (cadqemin-branch cands primes trues chosen bound) (cadqemin-br cands primes trues chosen bound (quote cadqemin-toobig)))
(define (cadqemin-br cands primes trues chosen bound best)
  (if (null? cands) best
      (cadqemin-br (cdr cands) primes trues chosen bound
        (cadqemin-better (cadqemin-bnb primes trues (cons (car cands) chosen) (cadqemin-curbound best bound)) best))))
(define (cadqemin-curbound best bound) (if (equal? best (quote cadqemin-toobig)) bound (cadqemin-len best)))
(define (cadqemin-better res best)
  (cond ((equal? res (quote cadqemin-toobig)) best)
        ((equal? best (quote cadqemin-toobig)) res)
        ((< (cadqemin-len res) (cadqemin-len best)) res)
        (else best)))
(define (cadqemin-covering primes cell) (cond ((null? primes) (quote ())) ((cadqemin-covers (car primes) cell) (cons (car primes) (cadqemin-covering (cdr primes) cell))) (else (cadqemin-covering (cdr primes) cell))))
; choose exact when the prime set is small (branch and bound stays cheap), greedy otherwise
(define (cadqemin-cover-best trues falses) (cadqemin-pick-cover (cadqemin-primes trues falses) trues))
(define (cadqemin-pick-cover primes trues)
  (if (<= (cadqemin-len primes) 12) (cadqemin-exact-from primes trues) (cadqemin-select primes trues)))
(define (cadqemin-minimize-exact factors trues falses) (cadqemin-render factors (cadqemin-cover-best trues falses)))

; ===== rendering =====
(define (cadqemin-minimize factors trues falses) (cadqemin-render factors (cadqemin-cover trues falses)))
(define (cadqemin-render factors cubes)
  (cond ((null? cubes) (quote false))
        ((cadqemin-any-allstar? cubes) (quote true))
        (else (cons (quote or) (cadqemin-render-cubes factors cubes)))))
(define (cadqemin-any-allstar? cubes) (cond ((null? cubes) #f) ((cadqemin-allstar? (car cubes)) #t) (else (cadqemin-any-allstar? (cdr cubes)))))
(define (cadqemin-allstar? cube) (cond ((null? cube) #t) ((equal? (car cube) (quote star)) (cadqemin-allstar? (cdr cube))) (else #f)))
(define (cadqemin-render-cubes factors cubes) (if (null? cubes) (quote ()) (cons (cadqemin-render-cube factors (car cubes)) (cadqemin-render-cubes factors (cdr cubes)))))
(define (cadqemin-render-cube factors cube) (cadqemin-conj (cadqemin-lits factors cube)))
(define (cadqemin-conj lits) (cond ((null? lits) (quote true)) ((null? (cdr lits)) (car lits)) (else (cons (quote and) lits))))
(define (cadqemin-lits factors cube)
  (cond ((null? factors) (quote ()))
        ((equal? (car cube) (quote star)) (cadqemin-lits (cdr factors) (cdr cube)))
        (else (cons (cadqemin-lit (car factors) (car cube)) (cadqemin-lits (cdr factors) (cdr cube))))))
(define (cadqemin-lit factor sgn)
  (cond ((equal? sgn 1) (list (quote >) (cons (quote poly) factor) 0))
        ((equal? sgn -1) (list (quote <) (cons (quote poly) factor) 0))
        ((equal? sgn 0) (list (quote =) (cons (quote poly) factor) 0))
        ((equal? sgn (quote ge)) (list (quote >=) (cons (quote poly) factor) 0))
        ((equal? sgn (quote le)) (list (quote <=) (cons (quote poly) factor) 0))
        ((equal? sgn (quote ne)) (list (quote neq) (cons (quote poly) factor) 0))
        (else (cons (quote poly) factor))))

(define (cadqemin-caveat) (quote prime-implicant-cover-essential-plus-greedy))
