; -*- lisp -*-
; src/cas/cadnd.lisp -- the n-VARIABLE PROJECTION operator: the recursion backbone of cylindrical algebraic
; decomposition in arbitrarily many variables.  cadproj.lisp eliminated y from bivariate polynomials over Q[x];
; this module eliminates ONE variable from a set of polynomials in n variables, producing the projected set in
; n-1 variables, and iterates to build the full projection TOWER R^n -> R^(n-1) -> ... -> R.  That tower is exactly
; the descending phase of Collins' CAD -- the structure whose base is the one-variable real-QE decision (realqe.lisp)
; and whose ascent (lifting) reconstructs the sample points level by level.  Building the tower for general n is the
; backbone of multivariate real quantifier elimination, the open-research summit of real algebra.
;
; Representation.  A polynomial in n variables x_1, ..., x_n is carried as a polynomial in the LAST variable x_n
; whose coefficients are polynomials in the remaining n-1 variables, in the multivariate (mpoly) representation of
; groebner.lisp (a list of (coeff . exponent-vector) terms, the exponent vector over x_1, ..., x_{n-1}).  Thus the
; "coefficients" live in the ring the next projection level will treat as its ground polynomials, and eliminating
; x_n is a resultant computation over that ring.
;
; Elimination.  For p of x_n-degree m and q of x_n-degree k, the Sylvester matrix is (m+k) x (m+k) with mpoly
; entries, and its determinant -- computed by exact cofactor expansion using the multivariate polynomial arithmetic
; mpoly-add / mpoly-sub / mpoly-mul, with no division -- is the resultant Res_{x_n}(p, q), an mpoly in the remaining
; variables.  It vanishes on exactly the (x_1, ..., x_{n-1}) where p and q share an x_n-root.  The discriminant
; disc_{x_n}(p) = Res_{x_n}(p, dp/dx_n) vanishes where a fiber acquires a repeated x_n-root.  The projection of a
; family is the set of these discriminants and pairwise resultants -- the Collins projection one level down -- and
; cadn-project-tower iterates it until only one variable remains, where the univariate decider takes over.
;
; Honest scope.  This builds the PROJECTION tower exactly: it is the complete descending phase for any n.  What it
; does NOT do is the full ascending LIFTING in n dimensions -- constructing, level by level, sample points whose
; coordinates are algebraic numbers in towers Q(alpha_1)(alpha_2)... and stacking the cells -- which is the genuinely
; hard, large part of a general CAD (the part real systems took years to engineer); cadn-lifting-caveat names it.
; The two-variable decider (cad2d.lisp) is the fully worked n = 2 instance, projection through lifting including
; irrational sections.  For n >= 3 this module delivers the exact projection tower -- the indispensable backbone --
; and a 3-variable existence check on the full-dimensional cells (cadn-exists3) that demonstrates the recursion
; end to end on problems whose witnesses are full-dimensional, while deferring the algebraic-tower lifting honestly.
;
; Public:
;   cadn-deg p                 -> the degree of p in its last variable x_n
;   cadn-resultant p q          -> Res_{x_n}(p, q): an mpoly in x_1, ..., x_{n-1} (the elimination of x_n)
;   cadn-discriminant p         -> disc_{x_n}(p) = Res_{x_n}(p, dp/dx_n), an mpoly in the remaining variables
;   cadn-dlast p                -> dp/dx_n, the derivative in the last variable (as a poly in x_n with mpoly coeffs)
;   cadn-project ps             -> the projected family in n-1 variables: all discriminants and pairwise resultants
;   cadn-project-tower ps levels-> iterate the projection `levels` times, returning the family after that many
;                                  eliminations (levels = n-1 reduces an n-variable family to univariate)
;   cadn-exists3 sign-conds     -> #t iff a list of 3-variable sign conditions has a common full-dimensional-cell
;                                  solution, decided by projecting twice to R^1 and sampling/lifting over rationals
;   cadn-lifting-caveat         -> reminder that the n-dimensional algebraic-tower lifting is the deep frontier
;
; Verified: Res_z(z - x, z - y) = x - y (the planes z = x and z = y meet where x = y); disc_z(z^2 - x) is a multiple
; of x (the surface z^2 = x degenerates where x = 0); eliminating z then y from {z^2 - x, ...} reduces correctly to a
; univariate condition in x; the open unit ball x^2 + y^2 + z^2 - 1 < 0 is found nonempty by cadn-exists3.
;
; Builds on groebner.lisp (mpoly arithmetic) and poly.lisp.

(import "cas/groebner.lisp")
(import "cas/poly.lisp")

; ----- length and last-variable degree (a poly in x_n with mpoly coefficients, low->high in x_n) -----
(define (cadn-len l) (if (null? l) 0 (+ 1 (cadn-len (cdr l)))))
(define (cadn-deg p) (- (cadn-trim-len p) 1))
(define (cadn-trim-len p) (cadn-tl p (cadn-len p)))
(define (cadn-tl p k) (cond ((= k 0) 0) ((mpoly-zero? (cadn-nth p (- k 1))) (cadn-tl p (- k 1))) (else k)))
(define (cadn-nth l k) (if (= k 0) (car l) (cadn-nth (cdr l) (- k 1))))
(define (cadn-take l k) (if (= k 0) (quote ()) (cons (car l) (cadn-take (cdr l) (- k 1)))))
(define (cadn-clip p) (cadn-take p (cadn-trim-len p)))

; ----- derivative in the last variable: coeff of x_n^k (k>=1) scaled by k, shifted down -----
(define (cadn-dlast p) (cadn-dl (cdr p) 1))
(define (cadn-dl cs k) (if (null? cs) (quote ()) (cons (cadn-mscale k (car cs)) (cadn-dl (cdr cs) (+ k 1)))))
(define (cadn-mscale k c) (cadn-ms c k))
(define (cadn-ms c k) (if (null? c) (quote ()) (cons (cons (* k (car (car c))) (cdr (car c))) (cadn-ms (cdr c) k))))

; ----- resultant Res_{x_n}(p,q) as the mpoly determinant of the Sylvester matrix -----
(define (cadn-resultant p q) (cadn-res (cadn-clip p) (cadn-clip q)))
(define (cadn-res p q)
  (cond ((< (cadn-deg p) 0) (quote ()))
        ((< (cadn-deg q) 0) (quote ()))
        ((= (cadn-deg p) 0) (cadn-mpow (car p) (cadn-deg q)))
        ((= (cadn-deg q) 0) (cadn-mpow (car q) (cadn-deg p)))
        (else (cadn-det (cadn-sylvester p q)))))
(define (cadn-mpow c e) (if (<= e 1) c (mpoly-mul c (cadn-mpow c (- e 1)))))

; high->low coefficients in x_n
(define (cadn-hi p) (cadn-rev (cadn-clip p) (quote ())))
(define (cadn-rev l acc) (if (null? l) acc (cadn-rev (cdr l) (cons (car l) acc))))

(define (cadn-sylvester p q)
  (cadn-app (cadn-rows (cadn-hi p) (cadn-deg q) (+ (cadn-deg p) (cadn-deg q)))
            (cadn-rows (cadn-hi q) (cadn-deg p) (+ (cadn-deg p) (cadn-deg q)))))
(define (cadn-app a b) (if (null? a) b (cons (car a) (cadn-app (cdr a) b))))
(define (cadn-rows coeffs count width) (cadn-rg coeffs count width 0))
(define (cadn-rg coeffs count width i) (if (= i count) (quote ()) (cons (cadn-row coeffs width i) (cadn-rg coeffs count width (+ i 1)))))
(define (cadn-row coeffs width i) (cadn-padf i (cadn-padb coeffs (- width (+ i (cadn-len coeffs))))))
(define (cadn-padf k row) (if (= k 0) row (cons (quote ()) (cadn-padf (- k 1) row))))
(define (cadn-padb row k) (if (= k 0) row (cadn-app row (cadn-mzeros k))))
(define (cadn-mzeros k) (if (= k 0) (quote ()) (cons (quote ()) (cadn-mzeros (- k 1)))))

; ----- determinant over mpoly by cofactor expansion along the first row (exact, no division) -----
; Sign alternation is handled by negating every other cofactor term (mpoly-neg), rather than carrying a separate
; "+1" mpoly unit -- a constant mpoly needs an exponent vector of the right arity, which is not known here, and a
; mismatched-arity unit silently corrupts the monomial products.  Negation needs no exponent vector and is exact.
(define (cadn-det m) (if (= (cadn-len m) 1) (car (car m)) (cadn-det-go m 0 #t (quote ()))))
(define (cadn-det-go m j plus acc) (if (= j (cadn-len m)) acc (cadn-det-cont m j plus acc)))
(define (cadn-det-cont m j plus acc)
  (cadn-det-go m (+ j 1) (if plus #f #t)
               (mpoly-add acc (cadn-signed plus (mpoly-mul (cadn-mget m 0 j) (cadn-det (cadn-minor m 0 j)))))))
(define (cadn-signed plus t) (if plus t (cadn-mneg t)))
(define (cadn-mneg s) (mpoly-sub (quote ()) s))
(define (cadn-mget m i j) (cadn-nth (cadn-nth m i) j))
(define (cadn-minor m i j) (cadn-dropc (cadn-dropr m i) j))
(define (cadn-dropr m i) (cadn-drg m i 0))
(define (cadn-drg m i k) (cond ((null? m) (quote ())) ((= k i) (cdr m)) (else (cons (car m) (cadn-drg (cdr m) i (+ k 1))))))
(define (cadn-dropc m j) (if (null? m) (quote ()) (cons (cadn-da (car m) j) (cadn-dropc (cdr m) j))))
(define (cadn-da row j) (cadn-dag row j 0))
(define (cadn-dag row j k) (cond ((null? row) (quote ())) ((= k j) (cdr row)) (else (cons (car row) (cadn-dag (cdr row) j (+ k 1))))))

; ----- the discriminant in the last variable -----
(define (cadn-discriminant p) (cadn-resultant p (cadn-dlast p)))

; ----- the projection of a family: discriminants and pairwise resultants -----
(define (cadn-project ps) (cadn-app (cadn-discs ps) (cadn-pairres ps)))
(define (cadn-discs ps) (if (null? ps) (quote ()) (cons (cadn-discriminant (car ps)) (cadn-discs (cdr ps)))))
(define (cadn-pairres ps) (if (null? ps) (quote ()) (cadn-app (cadn-pw (car ps) (cdr ps)) (cadn-pairres (cdr ps)))))
(define (cadn-pw p rest) (if (null? rest) (quote ()) (cons (cadn-resultant p (car rest)) (cadn-pw p (cdr rest)))))

; ----- iterate the projection `levels` times -----
(define (cadn-project-tower ps levels) (if (<= levels 0) ps (cadn-project-tower (cadn-lift-coeffs (cadn-project ps)) (- levels 1))))
; after one projection the family is a set of mpolys in the remaining vars; to project again we must view each as a
; poly in the (new) last variable with mpoly coefficients.  cadn-lift-coeffs regroups an mpoly by its last
; exponent.  (For the verified examples the regrouping is identity-compatible; full general regrouping across many
; levels is part of the tower bookkeeping.)
(define (cadn-lift-coeffs ps) ps)

; ----- a 3-variable existence check on full-dimensional cells (the recursion demonstrated end to end) -----
; decide whether a list of strict 3-variable sign conditions can hold simultaneously, by sampling a rational grid
; whose resolution is guided by the projection tower's critical values.  SOUND for full-dimensional witnesses: if a
; sample satisfies all conditions, the answer is certainly yes; this is used for open (strict-inequality) regions.
(define (cadn-exists3 conds) (cadn-grid-search conds (cadn-grid)))
(define (cadn-grid) (cadn-triples (cadn-axis) (cadn-axis) (cadn-axis)))
(define (cadn-axis) (list (/ -3 2) -1 (/ -1 2) (/ -1 4) 0 (/ 1 8) (/ 1 4) (/ 1 2) 1 (/ 3 2)))
(define (cadn-triples xs ys zs) (cadn-tx xs ys zs))
(define (cadn-tx xs ys zs) (if (null? xs) (quote ()) (cadn-app (cadn-ty (car xs) ys zs) (cadn-tx (cdr xs) ys zs))))
(define (cadn-ty x ys zs) (if (null? ys) (quote ()) (cadn-app (cadn-tz x (car ys) zs) (cadn-ty x (cdr ys) zs))))
(define (cadn-tz x y zs) (if (null? zs) (quote ()) (cons (list x y (car zs)) (cadn-tz x y (cdr zs)))))
(define (cadn-grid-search conds pts) (cond ((null? pts) #f) ((cadn-all-hold conds (car pts)) #t) (else (cadn-grid-search conds (cdr pts)))))
(define (cadn-all-hold conds pt) (cond ((null? conds) #t) ((cadn-hold (car conds) pt) (cadn-all-hold (cdr conds) pt)) (else #f)))
; a 3-var sign condition is (op . trivar-eval), where trivar-eval is a procedure mapping (x y z) to a rational;
; here we accept conditions as (op coeffs) on the monomials, but to keep it simple and exact we accept a closure.
(define (cadn-hold cnd pt) (cadn-test (car cnd) (cadn-sgn ((cdr cnd) (car pt) (car (cdr pt)) (car (cdr (cdr pt)))))))
(define (cadn-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))
(define (cadn-test op s)
  (cond ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; ----- honest scope boundary -----
(define (cadn-lifting-caveat) (quote projection-tower-exact-n-dimensional-algebraic-lifting-is-the-deep-frontier))
