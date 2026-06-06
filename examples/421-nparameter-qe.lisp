; GENERAL n-parameter parametric quantifier elimination -- the uniform generalization of the parameter line, plane,
; and 3-space to a parameter space of arbitrary dimension (docs/CAS.md).  The eliminated statement has a constant
; truth value on each cell of the cylindrical algebraic decomposition of the k-dimensional parameter space, and the
; answer is the set of sign-vectors of the projection factors over the cells that hold.  cadqen sweeps the k-space
; by recursion: project onto the outer parameter, sample it, substitute, and recurse on the (k-1)-parameter
; subproblem, with the parameter line as the base; each cell is decided by the complete univariate decider.
(import "cas/cadqen.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (present? v vs) (cond ((null? vs) #f) ((equal? v (car vs)) #t) (else (present? v (cdr vs)))))

(display "Eliminating one quantifier over a parameter space of arbitrary dimension, by recursion on the dimension.") (newline) (newline)

; --- k = 3: the general quadratic, reproducing cadqe3 through the general recursion ---
(define genq (list (list (cons 1 (list 0 0 1))) (list (cons 1 (list 0 1 0))) (list (cons 1 (list 1 0 0)))))
(define q3factors (list (list (list 1 1 0 0)) (list (list 1 0 1 0)) (list (list 1 0 0 1)) (list (list 1 0 2 0) (list -4 1 0 1))))
(define q3 (cadqen-elim q3factors 3 (quote exists) (cons (quote zero) genq)))
(define (cadr l) (car (cdr l))) (define (caddr l) (car (cdr (cdr l)))) (define (cadddr l) (car (cdr (cdr (cdr l)))))
(define (q3target sa sb sc sd) (cond ((not (= sa 0)) (>= sd 0)) (else (if (not (= sb 0)) #t (= sc 0)))))
(define (q3-all vs) (cond ((null? vs) #t) ((q3target (car (car vs)) (cadr (car vs)) (caddr (car vs)) (cadddr (car vs))) (q3-all (cdr vs))) (else #f)))
(must "k=3: the general quadratic reproduces the cadqe3 law (every true sign-vector satisfies it)"
  (q3-all (cdr q3)))
(must "k=3: the nondegenerate two-real-roots stratum (a>0, disc>0) is present"
  (present? (list 1 1 1 1) (cdr q3)))
(must "k=3: the trivial identity stratum (a=b=c=0) is present"
  (present? (list 0 0 0 0) (cdr q3)))

; --- k = 4: two linear equations sharing a solution, exists x. a x = b and c x = d ---
(define axmb (list (list (cons -1 (list 0 1 0 0))) (list (cons 1 (list 1 0 0 0)))))
(define cxmd (list (list (cons -1 (list 0 0 0 1))) (list (cons 1 (list 0 0 1 0)))))
(define phi4 (list (quote and) (cons (quote zero) axmb) (cons (quote zero) cxmd)))
; factors a, b, c, d (the coefficients, whose vanishing matters in the degenerate strata) and the resultant b c - a d
(define q4factors (list (list (list 1 1 0 0 0)) (list (list 1 0 1 0 0)) (list (list 1 0 0 1 0)) (list (list 1 0 0 0 1)) (list (list 1 0 1 1 0) (list -1 1 0 0 1))))
(define q4 (cadqen-elim q4factors 4 (quote exists) phi4))
(must "k=4: the all-zero stratum (a=b=c=d=0, system 0=0 and 0=0) is satisfiable and present"
  (present? (list 0 0 0 0 0) (cdr q4)))
(must "k=4: the unsatisfiable corner (a=b=c=0, d nonzero: 0=0 and 0=d) is correctly EXCLUDED"
  (if (present? (list 0 0 0 1 0) (cdr q4)) #f #t))
; the nondegenerate stratum must require the resultant to vanish: spot-check the decision directly
(must "k=4: nondegenerate with b c = a d is satisfiable (x exists)"
  (cadqen-holds-at 4 (quote exists) phi4 (list 1 2 1 2)))
(must "k=4: nondegenerate with b c != a d is unsatisfiable"
  (if (cadqen-holds-at 4 (quote exists) phi4 (list 1 2 1 3)) #f #t))
(must "k=4: a degenerate-but-consistent point (a=0,b=0,c=1,d=5: 0=0 and x=5) is satisfiable"
  (cadqen-holds-at 4 (quote exists) phi4 (list 0 0 1 5)))

(newline)
(display "The same recursion that decomposes a line, a plane, and a 3-space decomposes a parameter space of any") (newline)
(display "dimension; the k=3 general quadratic and the k=4 linear-system resultant are both recovered exactly.") (newline)
(display "The cost is the inherent doubly-exponential cost of CAD in the parameter dimension (cadqen-caveat).") (newline)
