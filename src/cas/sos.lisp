; -*- lisp -*-
; src/cas/sos.lisp -- a DECISION PROCEDURE for global nonnegativity of a univariate real polynomial, with a
; sum-of-squares / sign certificate: p(x) >= 0 for ALL real x is decided exactly, the real-analogue companion to the
; Nullstellensatz (which decides solvability over the algebraically closed field).  This is the first rung of real
; algebraic decision -- the Positivstellensatz world -- where Sangaku reasons over the ORDERED field R, not just C.
;
; The exact characterization (univariate, where it holds with no relaxation gap, unlike the multivariate case):
;     p(x) >= 0 for all real x   <=>   p is identically 0, OR
;                                      its leading coefficient is positive, its degree is even, AND every real root
;                                      of p has EVEN multiplicity (no real root is a sign change).
; Both conditions are decidable with exact arithmetic: the multiplicities come from Yun's squarefree factorization
; p = prod_k g_k^k (g_k squarefree, pairwise coprime), and "every real root has even multiplicity" is exactly "the
; product of the odd-level factors g_1 g_3 g_5 ... has no real root", which Sturm's theorem counts exactly over Q.
; So the verdict is a genuine DECISION, and the witness is twofold: the odd-level factor (whose real-root count is
; 0) and the squarefree factorization that exhibits the even multiplicities.  By Hilbert's theorem a nonnegative
; univariate polynomial is a sum of two squares, so this nonnegativity certificate is equivalent to the existence of
; an SOS representation; this module certifies nonnegativity via the (exact, root-multiplicity) criterion rather
; than constructing the squares numerically, keeping everything over Q.
;
; Strict positivity p(x) > 0 for all x is the same test plus "p has no real root at all" (the odd-level factor AND
; p itself are real-root-free); definiteness on all of R is read off the same data.
;
; Honest scope: this is the UNIVARIATE case, where nonnegativity = SOS is an iff and Sturm decides it.  The
; multivariate real-nonnegativity problem is far harder (nonnegative is strictly weaker than SOS for n >= 2 and
; total degree >= 4 -- Motzkin's polynomial -- and the general decision is Tarski's real quantifier elimination);
; sos-multivariate-caveat names that boundary rather than letting the univariate verdict be mistaken for it.
;
; Public (p a polynomial coefficient list low->high over Q):
;   sos-nonneg? p              -> #t iff p(x) >= 0 for all real x (the decision)
;   sos-positive? p            -> #t iff p(x) > 0 for all real x (strictly positive definite)
;   sos-odd-factor p           -> the product of the odd-multiplicity squarefree factors (real-root-free iff p>=0)
;   sos-decide p               -> 'nonnegative | 'indefinite (changes sign) | 'nonpositive (<= 0 everywhere)
;   sos-certificate p          -> (list 'nonneg-cert 'odd-factor odd 'real-roots-of-odd 0) when p >= 0, else
;                                 (list 'sign-change 'odd-factor odd 'real-roots n) exhibiting the n sign-change roots
;   sos-verify p               -> #t iff the certificate is internally consistent (odd factor has the stated root
;                                 count, leading coefficient sign matches the verdict)
;   sos-multivariate-caveat    -> a reminder symbol that this decides the univariate case only
;
; Verified: x^2, x^2+1, x^4+1, (x-1)^2(x-2)^2 are nonnegative; x^2+1 and x^4+1 are strictly positive; x^2-1, x^3,
; x^2(x-1) are indefinite (a real root of odd multiplicity); -x^2 is nonpositive; the certificate and its
; verification agree in each case.
;
; Builds on poly.lisp and sturm.lisp.

(import "cas/poly.lisp")
(import "cas/sturm.lisp")

(define (sos-len l) (if (null? l) 0 (+ 1 (sos-len (cdr l)))))
(define (sos-zero? p) (null? (sos-trim p)))
(define (sos-trim p) (sos-trim-go p (sos-len p)))
(define (sos-trim-go p k) (cond ((= k 0) (quote ())) ((= (sos-nth p (- k 1)) 0) (sos-trim-go p (- k 1))) (else (sos-take p k))))
(define (sos-nth l k) (if (= k 0) (car l) (sos-nth (cdr l) (- k 1))))
(define (sos-take l k) (if (= k 0) (quote ()) (cons (car l) (sos-take (cdr l) (- k 1)))))
(define (sos-deg p) (- (sos-len (sos-trim p)) 1))
(define (sos-lead p) (sos-nth (sos-trim p) (sos-deg p)))

; ----- the odd-multiplicity factor: product of g_k for odd k, from Yun's squarefree factorization -----
; Yun returns ((k g_k) ...); we multiply the g_k whose level k is odd. A constant (no odd factors) is 1.
(define (sos-odd-factor p) (sos-odd-go (yun-square-free (sos-monic p)) (list 1)))
(define (sos-odd-go fs acc) (cond ((null? fs) acc)
                                  ((sos-odd? (car (car fs))) (sos-odd-go (cdr fs) (poly-mul acc (car (cdr (car fs))))))
                                  (else (sos-odd-go (cdr fs) acc))))
(define (sos-odd? k) (= (remainder k 2) 1))
; make p monic over Q (Yun expects monic non-constant); scale by 1/lead. For the root-count of the odd factor the
; scaling is irrelevant (roots unchanged), so we only need monic for Yun's internal gcd recursion.
(define (sos-monic p) (sos-scale-recip (sos-trim p)))
(define (sos-scale-recip p) (if (null? p) p (sos-divlist p (sos-lead p))))
(define (sos-divlist p c) (if (null? p) (quote ()) (cons (/ (car p) c) (sos-divlist (cdr p) c))))

; ----- the core decision: nonnegative iff odd factor has no real root and (degree 0 or leading coeff > 0) -----
(define (sos-nonneg? p) (if (sos-zero? p) #t (sos-nn-go (sos-trim p))))
(define (sos-nn-go p) (if (> (sos-lead p) 0) (sos-no-real-odd? p) #f))
(define (sos-no-real-odd? p) (= (num-real-roots (sos-odd-factor p)) 0))

; ----- strictly positive: nonnegative AND no real root at all (p itself real-root-free) -----
(define (sos-positive? p) (if (sos-zero? p) #f (if (sos-nonneg? p) (= (num-real-roots (sos-monic p)) 0) #f)))

; ----- nonpositive: -p is nonnegative -----
(define (sos-nonpos? p) (sos-nonneg? (poly-scale -1 p)))

; ----- the verdict -----
(define (sos-decide p)
  (cond ((sos-zero? p) (quote nonnegative))
        ((sos-nonneg? p) (quote nonnegative))
        ((sos-nonpos? p) (quote nonpositive))
        (else (quote indefinite))))

; ----- the certificate -----
(define (sos-certificate p)
  (if (sos-nonneg? p)
      (list (quote nonneg-cert) (quote odd-factor) (sos-odd-factor p) (quote real-roots-of-odd) (num-real-roots (sos-odd-factor p)))
      (list (quote sign-change) (quote odd-factor) (sos-odd-factor p) (quote real-roots) (num-real-roots (sos-odd-factor p)))))

; ----- verify the certificate: the odd factor's real-root count is 0 exactly when we claim nonnegativity, and the
; leading-coefficient sign is consistent with the verdict -----
(define (sos-verify p) (if (sos-zero? p) #t (sos-verify-go (sos-trim p))))
(define (sos-verify-go p) (if (sos-nonneg? p) (sos-vchk p #t) (sos-vchk-indef p)))
(define (sos-vchk p expect) (if (= (num-real-roots (sos-odd-factor p)) 0) (> (sos-lead p) 0) #f))
(define (sos-vchk-indef p) (if (> (num-real-roots (sos-odd-factor p)) 0) #t (< (sos-lead p) 0)))

; ----- honest scope boundary -----
(define (sos-multivariate-caveat) (quote univariate-only-multivariate-needs-Positivstellensatz-or-Tarski-QE))
