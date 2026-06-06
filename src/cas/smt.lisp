; -*- lisp -*-
; src/cas/smt.lisp -- a lazy SMT solver, DPLL(T), over the theory of EQUALITY with UNINTERPRETED FUNCTIONS (EUF),
; built on the CDCL SAT core (cdcl.lisp).  This is the architecture of every modern SMT solver and the Handbook of
; Satisfiability's online DPLL(T) schema (chapter 26.3, with the lazy theory-consistency checking of 26.5/26.7): the
; Boolean engine treats each theory atom as a propositional variable and finds a propositionally satisfying
; assignment; the THEORY SOLVER then checks whether the asserted equalities and disequalities are consistent in EUF;
; if so the formula is satisfiable, and if not the offending model is blocked and the Boolean search resumes.
; Implemented from the published algorithms, not adapted from any solver's source.
;
; The theory solver is CONGRUENCE CLOSURE over a union-find on INTERNED TERMS.  Every distinct subterm appearing in
; the problem is assigned an integer id once; a mutable parent vector maintains equivalence classes (find by parent-
; following, union by repointing roots), which keeps allocation flat -- the functional assoc-list version thrashed
; the interpreter, so the theory is carried in vectors exactly as the SAT core's trail is.  Asserting a = b unions
; the ids of a and b; the congruence rule -- equal arguments imply equal applications -- is closed to a fixpoint by
; repeatedly merging application terms whose argument ids are pairwise equal; then each asserted DISequality a /= b
; is a conflict iff a and b share a class.  This decides quantifier-free EUF, the core SMT theory.
;
; Soundness is two independent checks: the Boolean assignment from the verified CDCL core, and the exact congruence-
; closure disequality test.  A satisfiable verdict means some propositional model is theory-consistent; unsatisfiable
; means every propositional model is theory-inconsistent.  Richer theories (difference logic, linear arithmetic via
; the existing Fourier-Motzkin module, arrays) plug in behind the same DPLL(T) loop as additional theory solvers.
;
; Public:
;   smt-euf-consistent? terms equalities disequalities  -> #t iff EUF-satisfiable (terms = id-interning list)
;   smt-solve atoms clauses                              -> DPLL(T): 'sat / 'unsat / 'unknown for a CNF over atoms
;   smt-cc-build nterms eqs apps                          -> the closed parent vector (for inspection/testing)
;   smt-cc-same? parent a b                               -> are interned ids a, b in the same class
;
; INTERNING.  The caller works with integer term ids 0..nterms-1.  An APPLICATION is described for the congruence
; closure as (result-id fn-id arg-id ...): result-id is the id of the term f(args), fn-id an id for the function
; symbol, and arg-id... the ids of the arguments.  Equalities/disequalities are pairs (id1 id2).  This keeps the
; theory layer purely numeric and allocation-light.  Builds on cdcl.lisp for the Boolean search.

(import "cas/cdcl.lisp")

(define (sm-len l) (if (null? l) 0 (+ 1 (sm-len (cdr l)))))
(define (sm-app2 a b) (if (null? a) b (cons (car a) (sm-app2 (cdr a) b))))
(define (sm-mem? x l) (cond ((null? l) #f) ((= (car l) x) #t) (else (sm-mem? x (cdr l)))))

; ---------- vector union-find over interned ids ----------
(define (sm-uf-make nterms) (sm-uf-init (make-vector nterms 0) 0 nterms))
(define (sm-uf-init v i n) (cond ((>= i n) v) (else (begin (vector-set! v i i) (sm-uf-init v (+ i 1) n)))))
(define (sm-uf-find parent i) (cond ((= (vector-ref parent i) i) i) (else (sm-uf-find parent (vector-ref parent i)))))
(define (sm-uf-union! parent i j)
  (let ((ri (sm-uf-find parent i)) (rj (sm-uf-find parent j)))
    (cond ((= ri rj) #f) (else (begin (vector-set! parent ri rj) #t)))))
(define (smt-cc-same? parent a b) (= (sm-uf-find parent a) (sm-uf-find parent b)))

; ---------- congruence closure ----------
; parent: union-find vector ; apps: list of (result-id fn-id arg-id...) ; eqs: list of (id id)
; assert all equalities, then close under congruence to a fixpoint
(define (smt-cc-build nterms eqs apps)
  (let ((parent (sm-uf-make nterms)))
    (begin (sm-assert-eqs! parent eqs) (sm-close! parent apps) parent)))
(define (sm-assert-eqs! parent eqs) (cond ((null? eqs) (quote ok)) (else (begin (sm-uf-union! parent (car (car eqs)) (car (cdr (car eqs)))) (sm-assert-eqs! parent (cdr eqs))))))
; close: repeat passes until a pass makes no union
(define (sm-close! parent apps) (cond ((sm-close-pass! parent apps apps) (sm-close! parent apps)) (else (quote ok))))
; one pass: for every ordered pair of apps, if congruent and not same, union their result ids; return #t if any union
(define (sm-close-pass! parent outer apps) (cond ((null? outer) #f) (else (sm-or (sm-close-one! parent (car outer) apps) (sm-close-pass! parent (cdr outer) apps)))))
(define (sm-or a b) (cond (a #t) (b #t) (else #f)))     ; note: both evaluated (no short-circuit needed; effects are unions)
(define (sm-close-one! parent app others) (cond ((null? others) #f) (else (sm-or (sm-try-merge! parent app (car others)) (sm-close-one! parent app (cdr others))))))
(define (sm-try-merge! parent a b)
  (cond ((and (sm-congruent? parent a b) (not (smt-cc-same? parent (car a) (car b)))) (sm-uf-union! parent (car a) (car b)))
        (else #f)))
; a=(res fn arg...), b=(res fn arg...): congruent if same fn and pairwise-equal args (under current classes)
(define (sm-congruent? parent a b)
  (and (= (car (cdr a)) (car (cdr b)))                  ; same function id
       (= (sm-len (cdr (cdr a))) (sm-len (cdr (cdr b)))) ; same arity
       (sm-args-eq? parent (cdr (cdr a)) (cdr (cdr b)))))
(define (sm-args-eq? parent as bs) (cond ((null? as) #t) ((smt-cc-same? parent (car as) (car bs)) (sm-args-eq? parent (cdr as) (cdr bs))) (else #f)))

; ---------- EUF consistency ----------
(define (smt-euf-consistent? nterms eqs diseqs apps)
  (let ((parent (smt-cc-build nterms eqs apps)))
    (sm-check-diseqs parent diseqs)))
(define (sm-check-diseqs parent diseqs) (cond ((null? diseqs) #t) ((smt-cc-same? parent (car (car diseqs)) (car (cdr (car diseqs)))) #f) (else (sm-check-diseqs parent (cdr diseqs)))))

; ---------- DPLL(T): lazy SMT over a CNF whose atoms are equality atoms ----------
; A problem is (nterms atoms apps clauses): nterms interned ids; atoms a list of equality atoms (id id) indexed
; 1..k; apps the application descriptors for congruence; clauses a CNF over +/- atom-indices (positive = equality
; asserted true, negative = the equality asserted false = a disequality).  smt-solve finds a Boolean model with the
; CDCL core, reads off the asserted equalities/disequalities, checks EUF consistency, and on a theory conflict
; blocks that Boolean model and retries.
(define (smt-solve nterms atoms apps clauses) (sm-dpllt nterms atoms apps clauses 0))
(define (sm-dpllt nterms atoms apps clauses rounds)
  (cond ((> rounds 300) (quote unknown))
        (else (sm-dpllt-step nterms atoms apps clauses rounds))))
(define (sm-dpllt-step nterms atoms apps clauses rounds)
  (let ((res (cdcl-solve (sm-len atoms) clauses)))
    (cond ((equal? res (quote unsat)) (quote unsat))
          (else (sm-theory-check nterms atoms apps clauses rounds (cdcl-model))))))
(define (sm-theory-check nterms atoms apps clauses rounds model)
  (let ((eqs (sm-asserted atoms model 1 #t)) (diseqs (sm-asserted atoms model 1 #f)))
    (cond ((smt-euf-consistent? nterms eqs diseqs apps) (quote sat))
          (else (sm-dpllt nterms atoms apps (cons (sm-block model) clauses) (+ rounds 1))))))
; collect equalities (positive literals) or disequalities (negative literals) from a Boolean model
(define (sm-asserted atoms model idx positive)
  (cond ((null? atoms) (quote ()))
        ((sm-mem? idx model) (if positive (cons (car atoms) (sm-asserted (cdr atoms) model (+ idx 1) positive)) (sm-asserted (cdr atoms) model (+ idx 1) positive)))
        (else (if positive (sm-asserted (cdr atoms) model (+ idx 1) positive) (cons (car atoms) (sm-asserted (cdr atoms) model (+ idx 1) positive))))))
(define (sm-block model) (sm-negate model)) (define (sm-negate m) (cond ((null? m) (quote ())) (else (cons (- 0 (car m)) (sm-negate (cdr m))))))

(define (smt-caveat) (quote lazy-dpll-T-over-EUF-congruence-closure-vector-union-find-on-cdcl-core))
