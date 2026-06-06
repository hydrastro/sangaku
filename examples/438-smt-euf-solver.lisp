; A lazy SMT solver, DPLL(T), over EQUALITY with UNINTERPRETED FUNCTIONS (EUF), built on the CDCL SAT core
; (docs/CAS.md).  This is the architecture of every modern SMT solver and the Handbook of Satisfiability's online
; DPLL(T) schema: the Boolean engine treats each theory atom as a propositional variable and finds a satisfying
; assignment; the THEORY SOLVER -- congruence closure over a union-find -- checks whether the asserted equalities and
; disequalities are consistent in EUF; if not, the model is blocked and the search resumes.  Implemented from the
; published algorithms on top of the verified CDCL core, not adapted from any solver's source.
(import "cas/smt.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "DPLL(T): a SAT core deciding the Boolean skeleton, congruence closure deciding the theory.") (newline) (newline)

; interning: a=0, b=1, c=2, d=3, e=4, f(a)=5, f(c)=6, with function symbol id 100
; the application descriptors tell congruence closure that 5 = f(0) and 6 = f(2)
(define apps (list (list 5 100 0) (list 6 100 2)))
(define eqs (list (list 0 1) (list 1 2) (list 5 3) (list 6 4)))   ; a=b, b=c, f(a)=d, f(c)=e
(define cc (smt-cc-build 7 eqs apps))

; congruence closure derives the consequences of the equalities
(must "congruence closure derives a ~ c from a = b, b = c" (smt-cc-same? cc 0 2))
(must "congruence closure derives f(a) ~ f(c) by the congruence rule" (smt-cc-same? cc 5 6))
(must "congruence closure derives d ~ e (because f(a) = d, f(c) = e, f(a) ~ f(c))" (smt-cc-same? cc 3 4))
(must "unrelated terms a and d are NOT merged" (not (smt-cc-same? cc 0 3)))

; EUF consistency: the equalities alone are consistent; adding the forced-false disequality is not
(must "the equality set alone is EUF-consistent" (smt-euf-consistent? 7 eqs (quote ()) apps))
(must "adding d != e is EUF-inconsistent (congruence forces d = e)"
  (not (smt-euf-consistent? 7 eqs (list (list 3 4)) apps)))

; DPLL(T): a transitivity violation is unsatisfiable; the consistent version is satisfiable
(define atoms (list (list 0 1) (list 1 2) (list 0 2)))            ; atom 1: a=b, 2: b=c, 3: a=c
(must "asserting a = b, b = c, a != c is UNSAT (transitivity, caught by the theory)"
  (equal? (smt-solve 3 atoms (quote ()) (list (list 1) (list 2) (list -3))) (quote unsat)))
(must "asserting a = b, b = c, a = c is SAT"
  (equal? (smt-solve 3 atoms (quote ()) (list (list 1) (list 2) (list 3))) (quote sat)))

; a function-congruence conflict through DPLL(T): a=b but f(a)!=f(b)
; atoms 1: a=b (0,1), 2: f(a)=f(b) (5,6); apps: f(a)=(5 100 0), f(b)=(6 100 1)
(must "asserting a = b but f(a) != f(b) is UNSAT (function congruence)"
  (equal? (smt-solve 7 (list (list 0 1) (list 5 6)) (list (list 5 100 0) (list 6 100 1)) (list (list 1) (list -2))) (quote unsat)))

(newline)
(display "The Boolean core finds an assignment to the equality atoms; congruence closure decides whether that") (newline)
(display "assignment is consistent in EUF; a theory conflict blocks the assignment and the search continues.  This is") (newline)
(display "the lazy DPLL(T) loop, deciding quantifier-free EUF on the verified SAT spine (smt-caveat).") (newline)
