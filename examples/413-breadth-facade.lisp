; The BREADTH FACADE: a single discoverable entry point to sangaku's decision and computation procedures
; (docs/CAS.md -- the system spans more than two hundred modules; this facade gathers the headline procedures under
; one import and one naming scheme, and provides a machine-readable catalogue of what the system can decide).
;
; The facade re-exports verified top-level procedures (it adds no new mathematics); each cas- name is a thin alias
; for the procedure documented in its own module, where the algorithm, its certificate, and the honest scope are
; given in full.
(import "cas/cas.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "One import, one naming scheme, for the system's headline decision procedures.") (newline) (newline)

(display "real quantifier elimination through the facade:") (newline)
(must "cas-decide-real: exists x. x^2 - 2 = 0" (cas-decide-real 1 (quote exists) (rqe-eq (list -2 0 1))))
(must "cas-sat: exists x, y. x^2 + y^2 < 1" (cas-sat 2 (rqe-lt (list (list -1 0 1) (list) (list 1)))))
(must "cas-valid: for all x. x^2 >= 0" (cas-valid 1 (rqe-ge (list 0 0 1))))

(display "real-algebra decisions through the facade:") (newline)
(must "cas-nonneg?: (x - 1)^2 is nonnegative" (cas-nonneg? (list 1 -2 1)))
(must "cas-nonneg?: x^2 - 2 is not nonnegative" (if (cas-nonneg? (list -2 0 1)) #f #t))

(display "the capability catalogue names the system's areas:") (newline)
(must "ten domains catalogued" (= (length (cas-capabilities)) 10))
(must "real quantifier elimination is listed first" (equal? (car (cas-domains)) (quote real-quantifier-elimination)))

(newline)
(display "The breadth -- real quantifier elimination, symbolic integration, differential equations, algebraic") (newline)
(display "geometry, real algebra, number theory, coding theory, cryptography, and more -- is now reachable and") (newline)
(display "discoverable from a single facade, with a catalogue answering what the system can decide.") (newline)
