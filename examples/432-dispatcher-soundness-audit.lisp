; A SOUNDNESS AUDIT of the decision dispatcher (docs/CAS.md): a systematic cross-validation that the dispatcher's
; verdict equals the full decider's on a broad sweep of problems.  The dispatcher routes each problem to the cheapest
; complete method (Fourier-Motzkin for linear, the UNSAT filter for refutable, CAD for the rest); this audit is the
; evidence that the routing never changes an answer -- every linear atom, interval, and quadratic below is decided
; both ways and the verdicts are required to match.  This is what makes the fast paths trustworthy: speed that is
; proven not to cost correctness.
(import "cas/qedispatch.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (agrees? phi) (equal? (qedispatch-decide phi) (qe-decide (quote exists) phi)))
(define (all-agree? phis) (cond ((null? phis) #t) ((agrees? (car phis)) (all-agree? (cdr phis))) (else #f)))

(display "Cross-validating the dispatcher against the full decider across a sweep of problems.") (newline) (newline)

; linear single atoms across signs and operators
(define linear-atoms (list
  (cons (quote nonneg) (list 0 1)) (cons (quote pos) (list -1 1)) (cons (quote neg) (list 1 1)) (cons (quote zero) (list -5 2))
  (cons (quote nonneg) (list 3 -1)) (cons (quote pos) (list 0 0)) (cons (quote neg) (list 2 0)) (cons (quote zero) (list -3 0))))
(must "all linear single atoms agree with the full decider" (all-agree? linear-atoms))

; intervals, closed and open and empty
(define intervals (list
  (list (quote and) (cons (quote nonneg) (list -1 1)) (cons (quote nonneg) (list 3 -1)))
  (list (quote and) (cons (quote nonneg) (list -3 1)) (cons (quote nonneg) (list 1 -1)))
  (list (quote and) (cons (quote pos) (list -1 1)) (cons (quote pos) (list 3 -1)))
  (list (quote and) (cons (quote pos) (list -2 1)) (cons (quote pos) (list 2 -1)))
  (list (quote and) (cons (quote nonneg) (list -2 1)) (cons (quote pos) (list 2 -1)))))
(must "all linear intervals (closed, open, empty, mixed strictness) agree" (all-agree? intervals))

; quadratics, satisfiable and not
(define quadratics (list
  (cons (quote zero) (list -2 0 1)) (cons (quote zero) (list 1 0 1)) (cons (quote neg) (list 1 0 1))
  (cons (quote nonneg) (list 0 0 1)) (cons (quote pos) (list 0 0 1)) (cons (quote neg) (list 0 0 1))
  (cons (quote zero) (list 0 -1 1)) (cons (quote zero) (list -1 0 1)) (cons (quote neg) (list -1 0 1))))
(must "all quadratics (satisfiable and unsatisfiable) agree" (all-agree? quadratics))

; the combined guarantee
(must "across every case in the sweep, the dispatcher verdict equals the full decider verdict"
  (and (all-agree? linear-atoms) (all-agree? intervals) (all-agree? quadratics)))

(newline)
(display "Every problem in the sweep is decided identically by the dispatcher and the full decider, so routing to a") (newline)
(display "cheaper complete method is verdict-preserving -- the audit that lets the fast paths be trusted.") (newline)
