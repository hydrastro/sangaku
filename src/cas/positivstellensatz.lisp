; -*- lisp -*-
; src/cas/positivstellensatz.lisp -- CONSTRAINED positivity certificates: proving p(x) >= 0 on a semialgebraic set
; S = {g_1 >= 0, ..., g_m >= 0} by a weighted sum-of-squares (Positivstellensatz / Putinar) certificate
;     p = sigma_0 + sigma_1 g_1 + ... + sigma_m g_m,   each sigma_j a sum of squares.
; This is the frontier rung directly above unconstrained SOS (sos.lisp): it certifies nonnegativity not on all of R
; but on a constrained region, which is exactly the form a universally-quantified arithmetic goal "for all x in S,
; p(x) >= 0" takes -- and the form a constrained optimization or a guarded TPTP arithmetic lemma needs.
;
; Why it is SOUND.  If p = sigma_0 + sum_i sigma_i g_i with every sigma_j a sum of squares, then at any point of S
; each g_i(x) >= 0 (definition of S) and each sigma_j(x) >= 0 (a sum of squares is nonnegative), so the right-hand
; side is >= 0, hence p(x) >= 0 throughout S.  The certificate is therefore a CHECKABLE PROOF, and the check is
; exact over Q: verify the polynomial identity p = sigma_0 + sum_i sigma_i g_i, and verify each sigma_j is a sum of
; squares (decided here for the univariate sigma_j by sos.lisp's exact nonnegativity decision -- univariate
; nonnegative is equivalent to SOS).
;
; What it is NOT.  As with plain SOS this is a one-directional CERTIFICATE, not a decision: by the Positivstellensatz
; (Schmudgen/Putinar) such a representation EXISTS for every p strictly positive on a compact S, but finding the
; sigma_j is a search (a semidefinite feasibility problem in the general case), and Sangaku verifies a supplied
; certificate rather than searching for one.  Failure to verify a given certificate means "this is not a valid
; certificate", never "p is not nonnegative on S".  The multipliers here are univariate (their SOS-ness is decided
; exactly); the general multivariate Putinar certificate, where sigma_j SOS-ness is itself only certified (Motzkin),
; is the boundary named by psatz-multivariate-caveat.
;
; A certificate is given as (sigma_0 . ((sigma_1 . g_1) ... (sigma_m . g_m))): the constant SOS term paired with a
; list of (multiplier . constraint) pairs.  All polynomials are univariate coefficient lists (low->high).
;
; Public:
;   psatz-rhs cert                  -> the polynomial sigma_0 + sum_i sigma_i g_i represented by a certificate
;   psatz-identity-holds? p cert    -> #t iff p equals that combination exactly (the identity half of the check)
;   psatz-multipliers-sos? cert     -> #t iff sigma_0 and every multiplier sigma_i is a sum of squares (nonnegative)
;   psatz-valid? p cert             -> #t iff BOTH halves hold: a verified proof that p >= 0 on the constraint set
;   psatz-certify p cert            -> (list 'nonneg-on-set 'constraints m) when valid, else
;                                      (list 'invalid-certificate reason) with reason 'identity-fails | 'multiplier-not-sos
;   psatz-on-set? p cert            -> the verdict symbol: 'proved-nonneg-on-set | 'certificate-invalid
;   psatz-multivariate-caveat       -> reminder that multipliers here are univariate-decided; multivariate Putinar
;                                      multipliers are only one-directionally certified (Motzkin)
;
; Verified: x >= 0 on {x-1>=0} via sigma_0=1, sigma_1=1 (identity 1+(x-1)=x); x^2-1 >= 0 on {x-1>=0} via
; sigma_0=(x-1)^2, sigma_1=2 (identity (x-1)^2+2(x-1)=x^2-1); a WRONG multiplier (sigma_0=-2 for x-3) is rejected
; as not-SOS; a broken identity is rejected; the empty constraint list reduces to plain SOS (p = sigma_0).
;
; Builds on poly.lisp and sos.lisp.

(import "cas/poly.lisp")
(import "cas/sos.lisp")

(define (psatz-s0 cert) (car cert))
(define (psatz-pairs cert) (cdr cert))
(define (psatz-mult pair) (car pair))
(define (psatz-constraint pair) (cdr pair))

; ----- the represented polynomial sigma_0 + sum_i sigma_i g_i -----
(define (psatz-rhs cert) (psatz-rhs-go (psatz-pairs cert) (psatz-s0 cert)))
(define (psatz-rhs-go pairs acc)
  (if (null? pairs) acc
      (psatz-rhs-go (cdr pairs) (poly-add acc (poly-mul (psatz-mult (car pairs)) (psatz-constraint (car pairs)))))))

; ----- the identity half: p equals that combination exactly -----
(define (psatz-identity-holds? p cert) (psatz-peq? p (psatz-rhs cert)))
(define (psatz-peq? a b) (equal? (psatz-trim a) (psatz-trim b)))
(define (psatz-len l) (if (null? l) 0 (+ 1 (psatz-len (cdr l)))))
(define (psatz-trim p) (psatz-trim-go p (psatz-len p)))
(define (psatz-trim-go p k) (cond ((= k 0) (quote ())) ((= (psatz-nth p (- k 1)) 0) (psatz-trim-go p (- k 1))) (else (psatz-take p k))))
(define (psatz-nth l k) (if (= k 0) (car l) (psatz-nth (cdr l) (- k 1))))
(define (psatz-take l k) (if (= k 0) (quote ()) (cons (car l) (psatz-take (cdr l) (- k 1)))))

; ----- the SOS half: sigma_0 and every multiplier is a sum of squares (nonnegative, decided exactly) -----
(define (psatz-multipliers-sos? cert) (if (sos-nonneg? (psatz-s0 cert)) (psatz-mults-go (psatz-pairs cert)) #f))
(define (psatz-mults-go pairs) (cond ((null? pairs) #t) ((sos-nonneg? (psatz-mult (car pairs))) (psatz-mults-go (cdr pairs))) (else #f)))

; ----- a valid certificate: both halves hold -----
(define (psatz-valid? p cert) (if (psatz-identity-holds? p cert) (psatz-multipliers-sos? cert) #f))

; ----- the reported certificate -----
(define (psatz-certify p cert)
  (cond ((not (psatz-identity-holds? p cert)) (list (quote invalid-certificate) (quote identity-fails)))
        ((not (psatz-multipliers-sos? cert)) (list (quote invalid-certificate) (quote multiplier-not-sos)))
        (else (list (quote nonneg-on-set) (quote constraints) (psatz-count (psatz-pairs cert))))))
(define (psatz-count l) (if (null? l) 0 (+ 1 (psatz-count (cdr l)))))

; ----- the verdict -----
(define (psatz-on-set? p cert) (if (psatz-valid? p cert) (quote proved-nonneg-on-set) (quote certificate-invalid)))

; ----- honest scope boundary -----
(define (psatz-multivariate-caveat) (quote multipliers-univariate-decided-multivariate-Putinar-only-certified))
