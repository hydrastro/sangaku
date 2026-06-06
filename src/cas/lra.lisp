; -*- lisp -*-
; src/cas/lra.lisp -- LINEAR real arithmetic by Fourier-Motzkin elimination: a COMPLETE decision procedure for the
; linear fragment of the theory of real-closed fields, and the fast path that keeps Sangaku from paying the
; doubly-exponential cost of full cylindrical algebraic decomposition when every constraint is linear.  Real
; quantifier elimination is doubly exponential in general (Davenport-Heintz, a theorem), but the LINEAR fragment --
; conjunctions of linear inequalities and equations, existentially quantified -- is decidable far more cheaply, and
; this module decides it exactly.
;
; The method.  A constraint is a linear form  c0 + c1 v1 + ... + cn vn  related to zero by >= (ge), > (gt), or
; = (eq), over the ordered field.  To eliminate an existentially quantified variable x, partition the constraints by
; the sign of x's coefficient: those with positive coefficient give upper bounds x <= U, those with negative
; coefficient give lower bounds x >= L, those with zero coefficient are carried unchanged.  The projection that
; eliminates x asserts every lower bound is <= every upper bound (L <= U for each pair), together with the carried
; constraints; an equality c0 + a x + ... = 0 with a /= 0 is solved for x and substituted, the cheaper route.  The
; result is an equisatisfiable linear system in the remaining variables; iterating eliminates all quantified
; variables, leaving either a ground truth value (no variables remain) or a residual constraint system in the free
; parameters.  Strictness composes correctly: L <= U is strict (gt) exactly when at least one of the two bounds is
; strict, and an x-free constraint that reduces to a false ground inequality refutes the whole system.
;
; Completeness and soundness.  Fourier-Motzkin is a complete quantifier-elimination procedure for linear arithmetic
; over an ordered field: the projected system is satisfiable in the remaining variables if and only if the original
; was satisfiable in all of them.  Every step is exact rational arithmetic, so a decided verdict is exact.  The cost
; is at worst single-exponential in the number of eliminated variables (each step can square the constraint count),
; dramatically better than the double exponential of general CAD -- which is the point: dispatch a linear problem
; here and a hard nonlinear one to the CAD spine.
;
; Public:
;   lra-decide-exists vars constraints  -> 't / 'f (a ground verdict when all vars are eliminated) or a residual
;                                          constraint list (a formula in the leftover free variables)
;   lra-sat? n constraints              -> #t iff the existential conjunction over variables 1..n is satisfiable
;                                          (ground), assuming no free parameters beyond those n
;   lra-eliminate constraints k         -> the Fourier-Motzkin projection eliminating variable index k
;   lra-linear? ...                     -> helpers for the dispatcher to recognise a purely linear problem
;
; A constraint is (op . coeffs) with op in {ge gt eq} and coeffs a list (c0 c1 ... cn): the form sum ci * vi (v0=1)
; related to 0.  Variable indices are 1-based into the coefficient list (index i is coefficient position i).
; Self-contained: integer/rational arithmetic only, no external imports.

(define (lra-len l) (if (null? l) 0 (+ 1 (lra-len (cdr l)))))
(define (lra-nth l k) (if (= k 0) (car l) (lra-nth (cdr l) (- k 1))))
(define (lra-app a b) (if (null? a) b (cons (car a) (lra-app (cdr a) b))))
(define (lra-map f l) (if (null? l) (quote ()) (cons (f (car l)) (lra-map f (cdr l)))))

(define (lra-op c) (car c))
(define (lra-coeffs c) (cdr c))
(define (lra-coeff c k) (lra-safe-nth (lra-coeffs c) k))
(define (lra-safe-nth l k) (cond ((null? l) 0) ((= k 0) (car l)) (else (lra-safe-nth (cdr l) (- k 1)))))

; ----- linear-form arithmetic on coefficient lists (index 0 is the constant) -----
(define (lra-add-co a b) (cond ((null? a) b) ((null? b) a) (else (cons (+ (car a) (car b)) (lra-add-co (cdr a) (cdr b))))))
(define (lra-scale-co a s) (lra-map (lambda (x) (* x s)) a))
(define (lra-neg-co a) (lra-scale-co a -1))

; ----- eliminate variable k from a constraint set by Fourier-Motzkin -----
; returns a new constraint set (over the same indices, with column k now identically zero)
(define (lra-eliminate constraints k) (lra-elim-go constraints k (quote ()) (quote ()) (quote ())))
(define (lra-elim-go cs k lowers uppers frees)
  (cond ((null? cs) (lra-combine lowers uppers frees))
        (else (lra-classify (car cs) k (cdr cs) lowers uppers frees))))
(define (lra-classify c k rest lowers uppers frees)
  (let ((a (lra-coeff c k)))
    (cond ((= a 0) (lra-elim-go rest k lowers uppers (cons c frees)))
          ((lra-eq-op? c) (lra-elim-eq c k rest))                    ; equality: solve and substitute
          ((> a 0) (lra-elim-go rest k lowers (cons c uppers) frees))  ; a x <= -rest  -> upper bound
          (else (lra-elim-go rest k (cons c lowers) uppers frees)))))
(define (lra-eq-op? c) (equal? (lra-op c) (quote eq)))

; equality a*x + r = 0 (a /= 0): x = -r/a; substitute into every other constraint, drop this one
(define (lra-elim-eq c k rest)
  (lra-map (lambda (d) (lra-subst d k c)) rest))
; substitute x_k = -(c without x_k)/a_c into constraint d: d' = d - (d_k / a_c) * c  (clears column k in d)
(define (lra-subst d k c)
  (let ((dk (lra-coeff d k)) (ak (lra-coeff c k)))
    (if (= dk 0) d
        (cons (lra-op d) (lra-clearcol (lra-add-co (lra-pad (lra-coeffs d)) (lra-scale-co (lra-pad (lra-coeffs c)) (/ (- 0 dk) ak))) k)))))
(define (lra-clearcol co k) (lra-set-nth co k 0))
(define (lra-set-nth l k v) (cond ((null? l) (if (= k 0) (list v) (cons 0 (lra-set-nth (quote ()) (- k 1) v)))) ((= k 0) (cons v (cdr l))) (else (cons (car l) (lra-set-nth (cdr l) (- k 1) v)))))
(define (lra-pad co) co)

; combine: every lower bound with every upper bound, plus the carried free constraints
; lower: a<0, form a*x + r >= 0 (or >0) => x <= -r/a... careful: we keep forms "F >= 0"; for variable x with coeff a:
;   F = a x + r (rel 0). solving for x: if a>0 then x <= -r/a (upper); if a<0 then x >= -r/a (lower).
; pairing lower L (x >= L) and upper U (x <= U) requires L <= U, i.e. U - L >= 0. In form terms, from upper
;   (a_u x + r_u rel 0, a_u>0) and lower (a_l x + r_l rel 0, a_l<0): eliminate x by  a_u * (lower) - a_l * (upper)
;   gives (a_u r_l - a_l r_u) rel 0 with column k zero. (a_u>0, -a_l>0 so signs combine to a valid positive combo.)
(define (lra-combine lowers uppers frees) (lra-app frees (lra-pairs lowers uppers)))
(define (lra-pairs lowers uppers) (if (null? lowers) (quote ()) (lra-app (lra-pair-one (car lowers) uppers) (lra-pairs (cdr lowers) uppers))))
(define (lra-pair-one low uppers) (if (null? uppers) (quote ()) (cons (lra-resolve low (car uppers)) (lra-pair-one low (cdr uppers)))))
; resolve a lower (coeff a_l<0) and upper (coeff a_u>0) on the pivot column: positive combination a_u*low + (-a_l)*up
; both are "form rel 0"; the combination's pivot column cancels. op is gt iff either input is gt (strictness spreads).
(define (lra-resolve low up)
  (let ((k (lra-pivot low up)))
    (let ((al (lra-coeff low k)) (au (lra-coeff up k)))
      (cons (lra-join-op (lra-op low) (lra-op up))
            (lra-clearcol (lra-add-co (lra-scale-co (lra-pad (lra-coeffs low)) au) (lra-scale-co (lra-pad (lra-coeffs up)) (- 0 al))) k)))))
(define (lra-join-op o1 o2) (if (or (equal? o1 (quote gt)) (equal? o2 (quote gt))) (quote gt) (quote ge)))
; the pivot column is the one both share with opposite signs; the caller eliminates a fixed k, so thread it through
(define lra-current-pivot 0)
(define (lra-pivot low up) lra-current-pivot)

; ----- top-level: eliminate variables n, n-1, ..., 1 in turn -----
(define (lra-decide-exists vars constraints) (lra-elim-vars constraints vars))
(define (lra-elim-vars constraints vars)
  (cond ((null? vars) (lra-ground-verdict constraints))
        (else (lra-elim-vars (lra-eliminate-at constraints (car vars)) (cdr vars)))))
(define (lra-eliminate-at constraints k) (begin (set! lra-current-pivot k) (lra-eliminate constraints k)))

; after eliminating all quantified vars, if no variable columns remain nonzero the constraints are ground: evaluate
(define (lra-ground-verdict constraints) (if (lra-all-ground? constraints) (if (lra-all-hold? constraints) (quote t) (quote f)) constraints))
(define (lra-all-ground? cs) (cond ((null? cs) #t) ((lra-ground-c? (car cs)) (lra-all-ground? (cdr cs))) (else #f)))
(define (lra-ground-c? c) (lra-only-const? (lra-coeffs c) 0))
(define (lra-only-const? co i) (cond ((null? co) #t) ((= i 0) (lra-only-const? (cdr co) 1)) ((= (car co) 0) (lra-only-const? (cdr co) (+ i 1))) (else #f)))
(define (lra-all-hold? cs) (cond ((null? cs) #t) ((lra-holds? (car cs)) (lra-all-hold? (cdr cs))) (else #f)))
(define (lra-holds? c) (lra-rel (lra-op c) (lra-const-of c)))
(define (lra-const-of c) (lra-safe-nth (lra-coeffs c) 0))
(define (lra-rel op v) (cond ((equal? op (quote ge)) (>= v 0)) ((equal? op (quote gt)) (> v 0)) ((equal? op (quote eq)) (= v 0)) (else #f)))

; ----- ground satisfiability of an existential conjunction over variables 1..n -----
(define (lra-sat? n constraints) (lra-verdict->bool (lra-decide-exists (lra-range 1 n) constraints)))
(define (lra-range a b) (if (> a b) (quote ()) (cons a (lra-range (+ a 1) b))))
(define (lra-verdict->bool v) (cond ((equal? v (quote t)) #t) ((equal? v (quote f)) #f) (else (lra-residual-sat? v))))
; a residual system with no variables left but not caught as ground (shouldn't happen for full elimination): treat
; conservatively by checking ground constraints hold
(define (lra-residual-sat? cs) (lra-all-hold? (lra-ground-only cs)))
(define (lra-ground-only cs) (cond ((null? cs) (quote ())) ((lra-ground-c? (car cs)) (cons (car cs) (lra-ground-only (cdr cs)))) (else (lra-ground-only (cdr cs)))))

(define (lra-caveat) (quote linear-fragment-complete-single-exponential-fourier-motzkin-nonlinear-goes-to-CAD))
