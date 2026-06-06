; A SOUNDNESS AND COMPLETENESS AUDIT of the unified real-quantifier-elimination decider (docs/CAS.md -- classic QE
; benchmarks together with adversarial controls, checking that no false verdict is ever produced and that known
; witnesses are always found).
;
; Soundness controls are sentences that are FALSE -- they must come back false (an unsatisfiable system, a failing
; universal); completeness benchmarks are classic TRUE sentences -- the ellipse, positivity, and witnesses on cells
; of every dimension including irrational sections.  All decided by the single rqe entry point.
(import "cas/rqe.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))
(define parab (list (list 0 -1) (list) (list 1)))
(define circle (list (list -1 0 1) (list) (list 1)))
(define linexy (list (list 0 1) (list -1)))

(display "soundness controls -- every FALSE sentence is rejected:") (newline)
(must "x^2 + 1 = 0 is unsatisfiable" (if (rqe-decide 1 (quote exists) (rqe-eq (list 1 0 1))) #f #t))
(must "for all x. x > 0 is false" (if (rqe-decide 1 (quote forall) (rqe-gt (list 0 1))) #f #t))
(must "exists x. x^2 < 0 is false" (if (rqe-decide 1 (quote exists) (rqe-lt (list 0 0 1))) #f #t))
(must "x^2 + y^2 + 1 < 0 is unsatisfiable" (if (rqe-decide 2 (quote exists) (rqe-lt (list (list 1 0 1) (list) (list 1)))) #f #t))
(must "y^2 = x and x = -1 is unsatisfiable" (if (rqe-decide 2 (quote exists) (list (quote and) (rqe-eq parab) (rqe-eq (list (list 1 1))))) #f #t))
(must "x^2+y^2+z^2 + 1 < 0 is unsatisfiable" (if (rqe-decide 3 (quote exists) (rqe-lt (list (list (list 1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))) #f #t))

(display "completeness benchmarks -- every TRUE sentence is found:") (newline)
(must "exists x. x^2 - 2 = 0" (rqe-decide 1 (quote exists) (rqe-eq (list -2 0 1))))
(must "for all x. x^2 >= 0" (rqe-decide 1 (quote forall) (rqe-ge (list 0 0 1))))
(must "exists x. x^2 - 2 > 0" (rqe-decide 1 (quote exists) (rqe-gt (list -2 0 1))))
(must "the ellipse x^2 + 4y^2 = 4 is nonempty" (rqe-decide 2 (quote exists) (rqe-eq (list (list -4 0 1) (list) (list 4)))))
(must "for all x, y. x^2 + y^2 + 1 > 0" (rqe-decide 2 (quote forall) (rqe-gt (list (list 1 0 1) (list) (list 1)))))
(must "exists x, y. y^2 = x and x = 2 (section)" (rqe-decide 2 (quote exists) (list (quote and) (rqe-eq parab) (rqe-eq (list (list -2 1))))))
(must "exists x, y. x^2 + y^2 = 1 and x = y (irrational section)" (rqe-decide 2 (quote exists) (list (quote and) (rqe-eq circle) (rqe-eq linexy))))
(must "exists x, y, z. sphere = 0 and x = y and y = z and x > 0 (diagonal section)"
  (rqe-decide 3 (quote exists) (list (quote and)
    (rqe-eq (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))
    (rqe-eq (list (list (list) (list -1)) (cn 1 2)))
    (rqe-eq (list (list (list 0 -1) (list 1))))
    (rqe-gt (list (list) (list (list 1)))))))

(newline)
(display "Fourteen checks -- six false sentences rejected, eight true sentences found, across one to three") (newline)
(display "variables and full-dimensional and section witnesses -- all decided correctly by the single rqe call.") (newline)
