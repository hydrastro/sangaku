; CONSTRAINED positivity certificates: proving p(x) >= 0 on a semialgebraic set S = {g_1 >= 0, ..., g_m >= 0} by a
; weighted sum-of-squares (Positivstellensatz / Putinar) certificate p = sigma_0 + sum_i sigma_i g_i with each
; sigma_j a sum of squares (docs/CAS.md -- the frontier rung above unconstrained SOS, and the form a goal "for all
; x in S, p(x) >= 0" takes).
;
; Soundness: on S every g_i >= 0 and every sigma_j >= 0 (a sum of squares), so sigma_0 + sum_i sigma_i g_i >= 0 on
; S, hence p >= 0 on S. The certificate is a checkable proof; the check is exact over Q (verify the polynomial
; identity, and verify each sigma_j is a sum of squares -- decided exactly for univariate sigma_j). A certificate is
; (sigma_0 . ((sigma_1 . g_1) ... )): the constant SOS term and the (multiplier . constraint) pairs.
(import "cas/positivstellensatz.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Constrained positivity: prove p >= 0 on {g_i >= 0} by a weighted-SOS certificate p = sigma_0 + sum sigma_i g_i.") (newline) (newline)

(display "x >= 0 on the set {x - 1 >= 0} (i.e. x >= 1 implies x >= 0), via sigma_0 = 1, sigma_1 = 1:") (newline)
(define g1 (list -1 1))
(define cert1 (cons (list 1) (list (cons (list 1) g1))))
(display "  the identity 1 + 1*(x-1) = x: ") (display (psatz-rhs cert1)) (newline)
(must "the identity holds" (psatz-identity-holds? (list 0 1) cert1))
(must "both multipliers are sums of squares" (psatz-multipliers-sos? cert1))
(must "so the certificate proves x >= 0 on {x-1>=0}" (psatz-valid? (list 0 1) cert1))
(must "the verdict is proved-nonneg-on-set" (equal? (psatz-on-set? (list 0 1) cert1) (quote proved-nonneg-on-set)))

(display "x^2 - 1 >= 0 on {x - 1 >= 0}, via sigma_0 = (x-1)^2, sigma_1 = 2:") (newline)
(define s0 (poly-mul g1 g1))
(define cert2 (cons s0 (list (cons (list 2) g1))))
(must "the identity (x-1)^2 + 2*(x-1) = x^2-1 holds" (psatz-identity-holds? (list -1 0 1) cert2))
(must "sigma_0 = (x-1)^2 and sigma_1 = 2 are both SOS" (psatz-multipliers-sos? cert2))
(must "so the certificate proves x^2-1 >= 0 on {x-1>=0}" (psatz-valid? (list -1 0 1) cert2))

(display "soundness: x - 3 is NOT >= 0 on {x-1>=0} (it is -2 at x=1), and no valid certificate exists:") (newline)
(define bad (cons (list -2) (list (cons (list 1) g1))))
(must "the identity -2 + (x-1) = x-3 does hold" (psatz-identity-holds? (list -3 1) bad))
(must "but sigma_0 = -2 is not a sum of squares, so the certificate is invalid" (if (psatz-valid? (list -3 1) bad) #f #t))
(must "the reason reported is multiplier-not-sos" (equal? (car (cdr (psatz-certify (list -3 1) bad))) (quote multiplier-not-sos)))

(display "a broken identity is rejected as identity-fails (not silently accepted):") (newline)
(define brk (cons (list 1) (list (cons (list 2) g1))))
(must "claiming x = 1 + 2*(x-1) is rejected" (if (psatz-identity-holds? (list 0 1) brk) #f #t))
(must "the reason is identity-fails" (equal? (car (cdr (psatz-certify (list 0 1) brk))) (quote identity-fails)))

(display "with no constraints the certificate reduces to plain SOS (p = sigma_0):") (newline)
(must "x^2 + 1 certified nonnegative with empty constraint set" (psatz-valid? (list 1 0 1) (cons (list 1 0 1) (quote ()))))

(newline)
(display "Constrained nonnegativity on a semialgebraic set is now provable by a checkable weighted-SOS certificate,") (newline)
(display "sound by construction.  Like SOS this CERTIFIES rather than DECIDES (finding the multipliers is a search,") (newline)
(display "a semidefinite feasibility problem in general); Sangaku verifies a supplied certificate exactly.  The general") (newline)
(display "multivariate Putinar search, and the full real decision (Tarski quantifier elimination), remain ahead.") (newline)
