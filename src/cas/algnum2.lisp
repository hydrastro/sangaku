; -*- lisp -*-
; src/cas/algnum2.lisp -- REAL ALGEBRAIC NUMBERS by isolating interval, and the exact sign of a rational polynomial
; at one.  This is the primitive that closes the irrational-section gap of the two-variable CAD (cad2d.lisp): it
; lets the decider evaluate sign conditions at a critical x = alpha that is irrational, using only rational
; arithmetic and Sturm, with no floating point and no symbolic field arithmetic.  It is also the device the
; n-variable recursion needs to carry a sample point whose coordinates are algebraic.
;
; A real algebraic number alpha is represented as (list defp lo hi): a defining polynomial defp in Q[x] (a
; coefficient list low->high) that alpha is a root of, together with rational endpoints lo < hi of an isolating
; interval that contains alpha and no other real root of defp.  The interval may be refined arbitrarily by
; bisection -- alpha is the unique root of defp where defp changes sign across (lo, hi), so the subinterval whose
; endpoints bracket that sign change still isolates alpha -- which lets the sign of any other polynomial at alpha be
; read off once the interval is small enough that the polynomial is sign-definite on it.
;
; The exact sign of q in Q[x] at alpha is computed as follows.  First decide whether q(alpha) = 0: this holds iff
; alpha is a common root of q and defp, iff the gcd g = gcd(q, defp) has its (unique, since it divides defp) root in
; the isolating interval -- detected by g changing sign across (lo, hi) or vanishing at an endpoint.  If q(alpha) is
; not zero, refine alpha's interval by bisection until q has the SAME nonzero sign at both endpoints; q is then
; sign-definite on the interval and that common sign is sign(q(alpha)).  Termination is guaranteed because q(alpha)
; != 0 means q is nonzero in a neighbourhood of alpha, which the shrinking interval eventually fits inside.  Every
; operation is exact rational arithmetic.
;
; Public:
;   asec-make defp lo hi          -> a real algebraic number (defp, lo, hi); alpha is the root of defp in (lo, hi)
;   asec-defp a / asec-lo a / asec-hi a -> the defining polynomial and current interval endpoints
;   asec-is-zero-at? q a          -> #t iff q(alpha) = 0 (alpha is a common root of q and the defining polynomial)
;   asec-refine a                 -> the algebraic number with its isolating interval bisected once (same alpha)
;   asec-sign q a                 -> the exact sign of q(alpha): -1, 0, or +1
;   asec-rational? a              -> #t iff alpha is actually a rational (the interval has collapsed to a point, or
;                                    the defining polynomial has a rational root equal to alpha) -- a convenience
;   asec-as-rational a            -> that rational when asec-rational? holds (the collapsed interval point)
;
; Verified: for alpha = sqrt(2) (root of x^2 - 2 in (1, 2)): sign(x - 1) = +1, sign(1 - x) = -1, sign(3 - 2x) = +1,
; sign(2x - 3) = -1, sign(x - 2) = -1, and sign(x^2 - 2) = 0 (the defining polynomial vanishes); for alpha the
; golden ratio (root of x^2 - x - 1 in (1, 2)): sign(x - 1) = +1 and sign(2 - x) = -1 (since 1 < phi < 2).
;
; Builds on poly.lisp.

(import "cas/poly.lisp")

(define (asec-make defp lo hi) (list defp lo hi))
(define (asec-defp a) (car a))
(define (asec-lo a) (car (cdr a)))
(define (asec-hi a) (car (cdr (cdr a))))

(define (asec-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- gcd over Q (monic), for the q(alpha)=0 test -----
(define (asec-gcd a b) (if (asec-zero? b) a (asec-gcd b (asec-rem a b))))
(define (asec-rem a b) (car (cdr (poly-divmod a b))))
(define (asec-zero? p) (asec-allz p))
(define (asec-allz p) (cond ((null? p) #t) ((= (car p) 0) (asec-allz (cdr p))) (else #f)))

; ----- q(alpha) = 0 iff the gcd(q, defp) has alpha (its root) inside the isolating interval -----
(define (asec-is-zero-at? q a)
  (if (asec-zero? q) #t (asec-gcd-root-in? (asec-gcd (asec-defp a) q) (asec-lo a) (asec-hi a))))
(define (asec-gcd-root-in? g lo hi)
  (if (asec-const? g) #f                               ; gcd constant -> no common root
      (cond ((= (asec-sgn (poly-eval g lo)) 0) #t)
            ((= (asec-sgn (poly-eval g hi)) 0) #t)
            (else (< (* (poly-eval g lo) (poly-eval g hi)) 0)))))
(define (asec-const? p) (< (- (asec-tlen (asec-trim p)) 1) 1))
(define (asec-trim p) (asec-tr p (asec-tlen p)))
(define (asec-tlen l) (if (null? l) 0 (+ 1 (asec-tlen (cdr l)))))
(define (asec-tr p k) (cond ((= k 0) (quote ())) ((= (asec-nth p (- k 1)) 0) (asec-tr p (- k 1))) (else (asec-take p k))))
(define (asec-nth l k) (if (= k 0) (car l) (asec-nth (cdr l) (- k 1))))
(define (asec-take l k) (if (= k 0) (quote ()) (cons (car l) (asec-take (cdr l) (- k 1)))))

; ----- refine alpha's interval by one bisection, keeping the subinterval that still isolates alpha -----
(define (asec-refine a) (asec-bisect (asec-defp a) (asec-lo a) (asec-hi a)))
(define (asec-bisect defp lo hi)
  (asec-pick defp lo hi (/ (+ lo hi) 2)))
(define (asec-pick defp lo hi mid)
  (cond ((= (asec-sgn (poly-eval defp mid)) 0) (asec-make defp mid mid))     ; mid is exactly alpha (rational)
        ((< (* (poly-eval defp lo) (poly-eval defp mid)) 0) (asec-make defp lo mid))
        (else (asec-make defp mid hi))))

; ----- the exact sign of q at alpha -----
(define (asec-sign q a)
  (if (asec-is-zero-at? q a) 0 (asec-sign-refine q a 200)))
(define (asec-sign-refine q a fuel)
  (cond ((= fuel 0) (asec-sgn (poly-eval q (/ (+ (asec-lo a) (asec-hi a)) 2))))   ; safety; not reached when q(alpha)!=0
        ((asec-definite? q (asec-lo a) (asec-hi a)) (asec-sgn (poly-eval q (asec-lo a))))
        (else (asec-sign-refine q (asec-refine a) (- fuel 1)))))
(define (asec-definite? q lo hi)
  (if (= (asec-sgn (poly-eval q lo)) 0) #f
      (if (= (asec-sgn (poly-eval q hi)) 0) #f
          (= (asec-sgn (poly-eval q lo)) (asec-sgn (poly-eval q hi))))))

; ----- rationality convenience -----
(define (asec-rational? a) (if (= (asec-lo a) (asec-hi a)) #t (= (asec-sgn (poly-eval (asec-defp a) (/ (+ (asec-lo a) (asec-hi a)) 2))) 0)))
(define (asec-as-rational a) (if (= (asec-lo a) (asec-hi a)) (asec-lo a) (/ (+ (asec-lo a) (asec-hi a)) 2)))
