(import "cas/cas.lisp")
(display (cas-decide-real 1 (quote exists) (rqe-eq (list -2 0 1)))) (display " ") (display (cas-sat 2 (rqe-lt (list (list -1 0 1) (list) (list 1))))) (display " ") (display (cas-valid 1 (rqe-ge (list 0 0 1)))) (newline)
(display (cas-nonneg? (list 1 -2 1))) (display " ") (display (cas-nonneg? (list -2 0 1))) (newline)
(display (length (cas-capabilities))) (display " ") (display (car (cas-domains))) (newline)
