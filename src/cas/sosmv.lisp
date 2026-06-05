; -*- lisp -*-
; src/cas/sosmv.lisp -- MULTIVARIATE sum-of-squares certificates of global nonnegativity: a SOUND, one-directional
; positivity certificate for real polynomials in several variables (the frontier rung above the univariate decision
; in sos.lisp, and a genuine entry into multivariate real algebra / the Positivstellensatz).
;
; The univariate case is special: there, nonnegative <=> sum of squares, an iff that Sturm decides.  In TWO OR MORE
; variables this iff FAILS.  Motzkin's polynomial M(x,y) = x^4 y^2 + x^2 y^4 - 3 x^2 y^2 + 1 is nonnegative on all of
; R^2 (by AM-GM on x^4y^2, x^2y^4, 1) yet is NOT a sum of squares of polynomials.  So multivariate nonnegativity is
; NOT decided by SOS, and this module does not pretend to decide it.  What remains true -- and is the whole point --
; is the SOUND direction:
;     if p = q_1^2 + ... + q_k^2 for real polynomials q_i, then p(x) >= 0 for every real x.
; A sum of squares is manifestly nonnegative, so an SOS decomposition is a CHECKABLE PROOF of global nonnegativity.
; This module verifies such a certificate exactly over Q: it expands sum_i q_i^2 with the multivariate polynomial
; arithmetic of groebner.lisp and checks it equals p term-for-term.  When the check passes, p is PROVABLY
; nonnegative; when a candidate fails, the module reports the nonzero difference -- it says "this is not an SOS
; decomposition of p", NEVER "p is not nonnegative" (the converse is false by Motzkin).  That asymmetry is the
; honest content: a positive certificate proves a theorem; the absence of one proves nothing.
;
; It also provides the building blocks: squaring a polynomial, summing squares, and the Gauss product identity
; (a^2+b^2)(c^2+d^2) = (ac-bd)^2 + (ad+bc)^2 that combines two SOS factors into an SOS, used to certify products of
; sums-of-squares (e.g. that a product of univariate-positive factors is nonnegative).
;
; Public (polynomials in groebner.lisp's mpoly representation: a list of (coeff . exponent-vector) terms; the q_i
; are ordinary mpolys; p is the target mpoly):
;   mvsos-square q                 -> q^2 as an mpoly
;   mvsos-sum-of-squares qs        -> sum_i q_i^2 for a list of mpolys qs
;   mvsos-is-certificate? p qs     -> #t iff p = sum_i q_i^2 exactly (a verified SOS proof that p >= 0)
;   mvsos-residual p qs            -> the mpoly p - sum_i q_i^2 (zero iff qs is an SOS decomposition of p)
;   mvsos-certify p qs             -> (list 'nonnegative-by-SOS k) when verified (k = number of squares), else
;                                     (list 'not-an-SOS-decomposition 'residual r) -- NScrupulously not a claim that
;                                     p fails to be nonnegative
;   mvsos-gauss-product a b c d    -> the pair (ac-bd, ad+bc) of the Gauss identity, so (a^2+b^2)(c^2+d^2) is the SOS
;                                     (ac-bd)^2 + (ad+bc)^2 (all four inputs mpolys)
;   mvsos-motzkin-note             -> a reminder that nonnegative is strictly weaker than SOS for n>=2 (Motzkin),
;                                     so a failed SOS check is not a non-nonnegativity verdict
;
; Verified: (x+y)^2 certifies x^2+2xy+y^2 >= 0; {x, y} certifies x^2+y^2 >= 0; {x^2-y^2 ... } residuals are exhibited
; when a candidate is wrong; the Gauss identity reproduces the product of two two-square sums; the Motzkin
; polynomial is acknowledged as nonnegative-but-not-SOS (no false certificate is produced for it).
;
; Builds on groebner.lisp.

(import "cas/groebner.lisp")

; ----- square and sum-of-squares -----
(define (mvsos-square q) (mpoly-mul q q))
(define (mvsos-sum-of-squares qs) (mvsos-sos-go qs (quote ())))
(define (mvsos-sos-go qs acc) (if (null? qs) acc (mvsos-sos-go (cdr qs) (mpoly-add acc (mvsos-square (car qs))))))

; ----- the residual p - sum q_i^2 (zero iff the q_i are an SOS decomposition of p) -----
(define (mvsos-residual p qs) (mpoly-sub p (mvsos-sum-of-squares qs)))

; ----- the certificate check: is p exactly the sum of the squares? -----
(define (mvsos-is-certificate? p qs) (mpoly-zero? (mvsos-residual p qs)))

; ----- the reported certificate (honest about the one-directional nature) -----
(define (mvsos-certify p qs)
  (if (mvsos-is-certificate? p qs)
      (list (quote nonnegative-by-SOS) (mvsos-count qs))
      (list (quote not-an-SOS-decomposition) (quote residual) (mvsos-residual p qs))))
(define (mvsos-count qs) (if (null? qs) 0 (+ 1 (mvsos-count (cdr qs)))))

; ----- the Gauss product identity (a^2+b^2)(c^2+d^2) = (ac-bd)^2 + (ad+bc)^2 -----
(define (mvsos-gauss-product a b c d)
  (list (mpoly-sub (mpoly-mul a c) (mpoly-mul b d)) (mpoly-add (mpoly-mul a d) (mpoly-mul b c))))

; ----- honest scope reminder -----
(define (mvsos-motzkin-note) (quote nonnegative-is-strictly-weaker-than-SOS-for-multivariate-Motzkin))
