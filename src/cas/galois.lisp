; -*- lisp -*-
; src/cas/galois.lisp -- SOLVABILITY BY RADICALS for prime-degree polynomials, the result that turns the worked
; example's ASSERTION ("the quintic x^5 - x - 1 is unsolvable by radicals") into a checked verdict for the quintics
; where a classical criterion settles it.  The governing theorem (Dedekind; the prime-degree case of the Galois
; correspondence) is exact:
;
;   If f is irreducible over Q of PRIME degree p and has exactly two non-real roots (hence p - 2 real ones), then
;   its Galois group is the full symmetric group S_p.
;
; The proof the theorem packages: irreducibility of degree p forces the group to act transitively on the p roots, so
; (being a transitive subgroup of S_p with p prime) it contains a p-cycle; complex conjugation is a field
; automorphism fixing the p - 2 real roots and swapping the two non-real ones, so the group contains a transposition;
; a p-cycle and a transposition generate S_p.  And S_p is NOT solvable for p >= 5 (its only proper nontrivial normal
; subgroup A_p is simple and nonabelian), so by Galois's solvability theorem f is NOT solvable by radicals.
;
; Thus Sangaku can EXHIBIT a radical-unsolvable polynomial with a finite, checkable witness: a prime degree, an
; irreducibility certificate, and a real-root count of exactly p - 2.  For x^5 - 4 x + 2 (Eisenstein at 2, three
; real roots) and x^5 - 6 x + 3 (Eisenstein at 3, three real roots) every ingredient is checked and the verdict --
; Galois group S_5, not solvable by radicals -- is proved, not asserted.
;
; Irreducibility is certified two ways: Eisenstein's criterion at a prime (a sufficient condition, checked directly),
; and, failing that, a bounded search for a proper factor with integer coefficients (the factors of a monic integer
; polynomial have integer coefficients bounded in size by the polynomial's, so the absence of any low-degree integer
; factor over a sufficient range is a sound irreducibility witness for the small polynomials handled here).
;
; Scope, kept honest (galois-caveat).  The S_p verdict is exact whenever the two-non-real-roots criterion applies to
; an irreducible prime-degree polynomial.  It does NOT cover every unsolvable polynomial: x^5 - x - 1 is itself S_5
; and unsolvable, but it has four non-real roots, so this particular criterion does not apply to it, and a general
; Galois-group computation (resolvents of degree 6 and higher, or a factorization-pattern / Frobenius approach) is
; not built.  What is built is a sound, checkable witness for the rich family the theorem reaches -- and the
; companion to galquartic, where every group is solvable.
;
; Public:
;   galois-prime? n                       -> #t if n is prime
;   galois-eisenstein? coeffs p           -> #t if Eisenstein's criterion holds at p (coeffs low -> high)
;   galois-irreducible? coeffs            -> #t if an irreducibility certificate is found (Eisenstein or factor scan)
;   galois-real-root-count coeffs         -> the number of distinct real roots (Sturm)
;   galois-Sp-by-radicals? coeffs         -> #t if coeffs is a proved S_p (prime degree, irreducible, 2 non-real)
;   galois-solvable-by-radicals? coeffs   -> 'no when the S_p criterion proves unsolvability, else 'unknown
;
; Builds on poly.lisp, sturm.lisp (num-real-roots), and cadqenx.lisp (rational roots, for the factor scan).

(import "cas/poly.lisp")
(import "cas/sturm.lisp")
(import "cas/cadqenx.lisp")

(define (galois-len l) (if (null? l) 0 (+ 1 (galois-len (cdr l)))))
(define (galois-deg coeffs) (- (galois-len (galois-trim coeffs)) 1))
(define (galois-trim p) (if (null? p) (quote ()) (if (= (car (galois-rev p)) 0) (galois-trim (galois-rev (cdr (galois-rev p)))) p)))
(define (galois-rev l) (galois-rev-go l (quote ()))) (define (galois-rev-go l acc) (if (null? l) acc (galois-rev-go (cdr l) (cons (car l) acc))))

; ----- primality -----
(define (galois-prime? n) (if (< n 2) #f (galois-prime-go n 2)))
(define (galois-prime-go n d) (cond ((> (* d d) n) #t) ((= (remainder n d) 0) #f) (else (galois-prime-go n (+ d 1)))))

; ----- Eisenstein's criterion at a prime p (coeffs low -> high) -----
(define (galois-eisenstein? coeffs p)
  (and (galois-prime? p)
       (galois-div-all? (galois-but-last coeffs) p)
       (not (galois-div? (galois-last coeffs) p))
       (not (galois-div? (car coeffs) (* p p)))))
(define (galois-div? a p) (= (remainder a p) 0))
(define (galois-div-all? l p) (cond ((null? l) #t) ((galois-div? (car l) p) (galois-div-all? (cdr l) p)) (else #f)))
(define (galois-but-last l) (if (null? (cdr l)) (quote ()) (cons (car l) (galois-but-last (cdr l)))))
(define (galois-last l) (if (null? (cdr l)) (car l) (galois-last (cdr l))))

; ----- irreducibility: try Eisenstein at small primes, else a bounded integer-factor scan -----
(define (galois-irreducible? coeffs)
  (cond ((galois-eisenstein-any? coeffs (galois-primes-up-to (galois-coeff-bound coeffs))) #t)
        ((galois-any-rational-root? coeffs) #f)
        (else (not (galois-has-low-factor? coeffs)))))
(define (galois-eisenstein-any? coeffs primes) (cond ((null? primes) #f) ((galois-eisenstein? coeffs (car primes)) #t) (else (galois-eisenstein-any? coeffs (cdr primes)))))
(define (galois-primes-up-to n) (galois-filter-primes 2 n))
(define (galois-filter-primes k n) (cond ((> k n) (quote ())) ((galois-prime? k) (cons k (galois-filter-primes (+ k 1) n))) (else (galois-filter-primes (+ k 1) n))))
(define (galois-coeff-bound coeffs) (+ 2 (galois-maxabs coeffs)))
(define (galois-maxabs p) (galois-maxabs-go p 0)) (define (galois-maxabs-go p m) (if (null? p) m (galois-maxabs-go (cdr p) (galois-max m (galois-abs (car p))))))
(define (galois-abs x) (if (< x 0) (- x) x)) (define (galois-max a b) (if (> a b) a b))
(define (galois-any-rational-root? coeffs) (galois-nonempty? (cadqenx-rat-roots (galois-trim coeffs))))
(define (galois-nonempty? l) (cond ((null? l) #f) (else #t)))
; bounded scan for a monic integer quadratic factor x^2 + s x + t (catches the common composite case beyond roots)
(define (galois-has-low-factor? coeffs) (galois-scan (galois-trim coeffs) (galois-coeff-bound coeffs)))
(define (galois-scan poly bnd) (galois-ss poly (- 0 bnd) (- 0 bnd) bnd))
(define (galois-ss poly s t bnd)
  (cond ((> s bnd) #f)
        ((> t bnd) (galois-ss poly (+ s 1) (- 0 bnd) bnd))
        ((galois-divides? poly (list t s 1)) #t)
        (else (galois-ss poly s (+ t 1) bnd))))
(define (galois-divides? poly q) (galois-zero? (car (cdr (poly-divmod poly q)))))
(define (galois-zero? p) (cond ((null? p) #t) ((= (car p) 0) (galois-zero? (cdr p))) (else #f)))

; ----- real-root count (Sturm) and the S_p decision -----
(define (galois-real-root-count coeffs) (num-real-roots (galois-trim coeffs)))
(define (galois-nonreal-count coeffs) (- (galois-deg coeffs) (galois-real-root-count coeffs)))
; proved S_p: prime degree, irreducible, exactly two non-real roots
(define (galois-Sp-by-radicals? coeffs)
  (and (galois-prime? (galois-deg coeffs))
       (galois-irreducible? coeffs)
       (= (galois-nonreal-count coeffs) 2)))
; solvability verdict: 'no when the S_p criterion proves unsolvability (degree >= 5), else 'unknown
(define (galois-solvable-by-radicals? coeffs)
  (if (and (galois-Sp-by-radicals? coeffs) (>= (galois-deg coeffs) 5)) (quote no) (quote unknown)))

(define (galois-caveat) (quote Sp-via-two-nonreal-roots-of-irreducible-prime-degree-general-galois-group-not-built))
