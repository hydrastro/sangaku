; A DECISION PROCEDURE for the satisfiability of a system of polynomial equations over an algebraically closed
; field, via Hilbert's Weak Nullstellensatz and a Groebner-basis certificate (docs/CAS.md -- Sangaku's first
; genuine decision procedure, and the shape of problem an automatic theorem prover is asked to settle: are these
; equations jointly contradictory?).
;
; Weak Nullstellensatz: f_1 = ... = f_m = 0 has NO common zero over the algebraic closure iff the constant 1 lies
; in the ideal <f_1, ..., f_m>, i.e. iff the reduced Groebner basis contains a nonzero constant. So refuting a
; polynomial system -- deriving a contradiction from a set of equational hypotheses -- is decided exactly, with the
; constant in the basis as the certificate. Polynomials are in the Groebner representation: a list of
; (coeff . exponent-vector) terms; e.g. x - 5 over one variable is ((1 1) (-5 0)).
(import "cas/nullstellensatz.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Nullstellensatz decision: are a set of polynomial equations jointly contradictory over the closure?") (newline) (newline)

(display "the hypotheses x = 0 AND x = 1 are contradictory (1 enters the ideal):") (newline)
(define x (list (cons 1 (list 1))))
(define x-1 (list (cons 1 (list 1)) (cons -1 (list 0))))
(display "  decision: ") (display (nss-decide (list x x-1))) (newline)
(must "the system {x, x-1} is unsatisfiable" (equal? (nss-decide (list x x-1)) (quote unsatisfiable)))
(must "equivalently, it is refuted" (nss-refutes? (list x x-1)))
(must "the refutation certificate verifies (1 and each hypothesis reduce to 0 against the basis)" (nss-verify-refutation (list x x-1)))
(must "the certificate is a refutation" (equal? (car (nss-certificate (list x x-1))) (quote refuted)))

(display "the hypotheses x*y = 1 AND x = 0 are contradictory (x = 0 forces 0 = 1):") (newline)
(define xy-1 (list (cons 1 (list 1 1)) (cons -1 (list 0 0))))
(define x2 (list (cons 1 (list 1 0))))
(must "the system {xy-1, x} is unsatisfiable" (equal? (nss-decide (list xy-1 x2)) (quote unsatisfiable)))
(must "and its refutation verifies" (nss-verify-refutation (list xy-1 x2)))

(display "a SATISFIABLE system: x = 5 has the obvious model:") (newline)
(define x-5 (list (cons 1 (list 1)) (cons -5 (list 0))))
(must "the system {x-5} is satisfiable" (equal? (nss-decide (list x-5)) (quote satisfiable)))
(must "it is not refuted" (if (nss-refutes? (list x-5)) #f #t))
(must "the certificate reports a model exists" (equal? (car (nss-certificate (list x-5))) (quote model-exists)))

(display "satisfiability is over the ALGEBRAIC CLOSURE: x^2 + y^2 = 1 AND x = 2 has the complex solution y^2 = -3:") (newline)
(define circ (list (cons 1 (list 2 0)) (cons 1 (list 0 2)) (cons -1 (list 0 0))))
(define x-2 (list (cons 1 (list 1 0)) (cons -2 (list 0 0))))
(must "the system is satisfiable over the closure (not refuted)" (equal? (nss-decide (list circ x-2)) (quote satisfiable)))

(display "the empty system is satisfiable (every point is a model):") (newline)
(must "{} is satisfiable" (equal? (nss-decide (quote ())) (quote satisfiable)))

(display "honest scope: this decides satisfiability over the algebraic CLOSURE, not over the reals:") (newline)
(must "the real-vs-closure boundary is named, not hidden" (equal? (nss-real-caveat) (quote decides-closure-satisfiability-not-real-Positivstellensatz)))

(newline)
(display "Refuting a polynomial system -- the algebraic analogue of deriving FALSE from a set of hypotheses -- is now") (newline)
(display "a decision with a Groebner certificate.  This is the equational, algebraically-closed case; real solvability") (newline)
(display "(inequalities, the Positivstellensatz) and full first-order reasoning remain ahead.") (newline)
