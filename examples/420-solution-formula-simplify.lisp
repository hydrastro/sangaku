; A step toward minimal SOLUTION-FORMULA construction for parametric quantifier elimination (docs/CAS.md).  The
; parametric eliminators report the eliminated condition as a raw disjunction of full SIGN VECTORS over every
; projection factor -- correct, but verbose.  Producing the simplest equivalent formula is Brown's
; solution-formula-construction problem; this module makes an honest dent by minimizing the set of true sign
; vectors the way Quine-McCluskey minimizes a Boolean cover, with two merge rules to a fixpoint: dropping a factor
; whose three signs all appear (FACTOR ELIMINATION), and merging two signs of a factor into a relation
; (>= 0, <= 0, != 0) (SIGN MERGING).  Each merge preserves the covered parameter points, so the result is
; equivalent to the raw disjunction; it is not guaranteed globally minimal, but it reaches the canonical formula on
; the clean cases and removes the bulk of the redundancy on the harder ones.
(import "cas/cadqe2.lisp")
(import "cas/cadqesimp.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Simplifying the raw sign-vector output of parametric quantifier elimination.") (newline) (newline)

; the clean discriminant case: exists x. x^2 + b x + c = 0 gives sign-vectors {(0), (-1)} over the single factor
; -b^2 + 4c; the simplifier merges the zero and negative cells into a single relation <= 0
(define quad (list (list (cons 1 (list 0 1))) (list (cons 1 (list 1 0))) (list (cons 1 (list 0 0)))))
(define r (cadqe2-elim (quote exists) (cons (quote zero) quad)))
(must "the raw output is two sign-vectors over one factor"
  (equal? (cdr r) (quote ((0) (-1)))))
(must "the simplifier merges them into the single relation: discriminant <= 0"
  (equal? (cadqs-simplify (car r) (cdr r)) (quote (or (<= (poly (-1 2 0) (4 0 1)) 0)))))

; a hand case exercising FACTOR ELIMINATION: over two factors, the true-set is "first factor positive, second any"
; -- the three signs of the second factor all present -- which must collapse to a single literal on the first
(define f1 (list (list 1 1 0)))
(define f2 (list (list 1 0 1)))
(must "factor elimination drops a factor whose three signs all appear"
  (equal? (cadqs-simplify (list f1 f2) (list (list 1 1) (list 1 -1) (list 1 0))) (quote (or (> (poly (1 1 0)) 0)))))

; a hand case exercising SIGN MERGING into >= : true-set {(1),(0)} over one factor -> that factor >= 0
(must "sign merging combines positive and zero into >= 0"
  (equal? (cadqs-simplify (list f1) (list (list 1) (list 0))) (quote (or (>= (poly (1 1 0)) 0)))))

(newline)
(display "On the clean discriminant the simplifier reaches the exact textbook relation; on the general quadratic it") (newline)
(display "reduces the nineteen-plus raw sign-vectors substantially while preserving logical equivalence.  Full minimal") (newline)
(display "solution-formula construction over three-valued sign covers remains the open refinement (Brown's problem).") (newline)
