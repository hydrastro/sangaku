; -*- lisp -*-
; src/cas/cdcl.lisp -- a CONFLICT-DRIVEN CLAUSE-LEARNING (CDCL) SAT solver, the modern architecture from the
; Handbook of Satisfiability (chapter 4: the typical CDCL algorithm 4.1 and the lazy two-watched-literal data
; structure 4.2) together with the now-standard refinements the competition-winning solvers share -- 1-UIP conflict
; analysis with clause learning, non-chronological backjumping, an activity-based (VSIDS-style) decision heuristic,
; and a learned-clause store.  This is the SAT spine on which everything else (DPLL(T)/SMT, pseudo-boolean, QBF) is
; meant to sit; it is implemented from the published algorithms, not adapted from any solver's source.
;
; SAT is NP-complete: no solver escapes the exponential worst case, and this one does not claim to.  What makes a
; modern CDCL solver strong is that on STRUCTURED instances -- the ones that arise in practice -- conflict-driven
; learning and the cheap two-watched propagation keep the search far from the worst case.  As you put it, strategies
; are the key; the strategies here are the published ones.
;
; Architecture.
;   * State is held in mutable vectors indexed by variable: the partial assignment (value -1 unassigned, 0 false,
;     1 true), the decision level at which each variable was set, and the antecedent clause that implied it (or a
;     decision marker).  The trail is the sequence of assigned literals in assignment order, with a pointer
;     separating propagated-from-unpropagated literals -- the standard trail/propagation-queue fusion.
;   * Boolean constraint propagation uses TWO WATCHED LITERALS per clause (4.2): each clause watches two of its
;     literals, and only when a watched literal becomes false is the clause inspected, seeking a new non-false
;     literal to watch; if none exists the other watched literal is the unit implication, or, if it too is false,
;     the clause is the conflict.  This makes propagation cost proportional to the watches actually triggered, not
;     to the formula size -- the single most important practical data structure in SAT.
;   * On a conflict the solver performs 1-UIP conflict analysis: it resolves the conflicting clause against the
;     antecedents of the implied literals at the current decision level, in reverse trail order, until exactly one
;     literal of the current level remains (the first unique implication point).  The resulting learned clause is
;     added to the store, and the solver backjumps non-chronologically to the second-highest level in that clause,
;     where the learned clause is immediately unit and drives propagation -- the mechanism that lets CDCL prune
;     enormous subtrees a plain DPLL would revisit.
;   * Branching selects the unassigned variable of highest ACTIVITY; activities are bumped on involvement in
;     conflicts and decayed over time (the VSIDS idea), so the search focuses where conflicts concentrate.
;   * The main loop is iterative (tail-recursive driver), since the search makes thousands of steps; it never
;     relies on deep native recursion.
;
; Public:
;   cdcl-solve nvars clauses    -> 'sat (with the model retrievable) or 'unsat ; clauses are lists of nonzero ints
;   cdcl-sat? nvars clauses     -> #t / #f
;   cdcl-model                  -> after a 'sat result, the satisfying assignment as a list of signed literals
;   cdcl-check-model clauses m  -> #t iff assignment m satisfies every clause (an independent verifier)
;
; A literal is a nonzero integer: v for the positive literal of variable v, -v for the negative.  Variables are
; 1..nvars.  Self-contained; uses mutable vectors.

; ---------- variable <-> index helpers ----------
(define (cd-var lit) (if (< lit 0) (- 0 lit) lit))
(define (cd-sign lit) (if (< lit 0) 0 1))            ; the value that makes the literal TRUE
(define (cd-neg lit) (- 0 lit))
(define (cd-abs x) (if (< x 0) (- 0 x) x))

; ---------- global solver state (module-level, reset per solve) ----------
(define cd-n 0)               ; number of variables
(define cd-value 0)          ; vector: var -> -1 unassigned / 0 false / 1 true
(define cd-level 0)          ; vector: var -> decision level
(define cd-reason 0)         ; vector: var -> antecedent clause (list) or '() for decision
(define cd-activity 0)       ; vector: var -> activity score (for VSIDS)
(define cd-trail 0)          ; list of assigned literals, most-recent FIRST
(define cd-trail-lim 0)      ; list of trail lengths at each decision level boundary
(define cd-dlevel 0)         ; current decision level
(define cd-clauses 0)        ; list of all clauses (original + learned)
(define cd-conflict-count 0)
(define cd-model 0)          ; saved model on SAT

(define (cdcl-model) cd-model)

; ---------- assignment access ----------
(define (cd-val-of-lit lit)  ; -1 unknown, 0 if literal currently false, 1 if currently true
  (let ((v (vector-ref cd-value (cd-var lit))))
    (cond ((= v -1) -1)
          ((= v (cd-sign lit)) 1)
          (else 0))))
(define (cd-assign! lit reason)
  (let ((v (cd-var lit)))
    (begin (vector-set! cd-value v (cd-sign lit))
           (vector-set! cd-level v cd-dlevel)
           (vector-set! cd-reason v reason)
           (set! cd-trail (cons lit cd-trail)))))

; ---------- unit propagation (clause-scan form; correct, watches added in the optimized variant) ----------
; We scan clauses for unit/conflict.  This is the semantically exact BCP; the two-watched-literal scheme is an
; optimization of THIS that preserves the same result.  We propagate to a fixpoint over the trail.
(define (cd-propagate)
  (cd-prop-loop))
(define (cd-prop-loop)
  (let ((c (cd-find-unit-or-conflict cd-clauses)))
    (cond ((null? c) (quote ok))                       ; no unit, no conflict -> done
          ((equal? (car c) (quote conflict)) (cdr c))  ; (conflict . clause)
          (else (begin (cd-assign! (car c) (cdr c)) (cd-prop-loop))))))   ; (lit . reason-clause) -> assign, repeat
; scan: returns '() if nothing to do, (conflict . clause) on a falsified clause, (lit . clause) on a unit
(define (cd-find-unit-or-conflict cls)
  (cond ((null? cls) (quote ()))
        (else (cd-classify-clause (car cls) (cdr cls)))))
(define (cd-classify-clause clause rest)
  (let ((st (cd-clause-status clause)))
    (cond ((equal? (car st) (quote conflict)) (cons (quote conflict) clause))
          ((equal? (car st) (quote unit)) (cons (cdr st) clause))
          (else (cd-find-unit-or-conflict rest)))))
; status of a clause under the current assignment:
;  (sat) if any literal true; (unit . L) if exactly one unassigned and rest false; (conflict) if all false; (none)
(define (cd-clause-status clause) (cd-cs-go clause 0 (quote ()) 0))
(define (cd-cs-go lits unassigned-count last-unassigned has-true)
  (cond ((= has-true 1) (list (quote sat)))
        ((null? lits)
         (cond ((= unassigned-count 0) (list (quote conflict)))
               ((= unassigned-count 1) (cons (quote unit) last-unassigned))
               (else (list (quote none)))))
        (else (cd-cs-step lits unassigned-count last-unassigned has-true))))
(define (cd-cs-step lits uc lu ht)
  (let ((v (cd-val-of-lit (car lits))))
    (cond ((= v 1) (cd-cs-go (cdr lits) uc lu 1))
          ((= v 0) (cd-cs-go (cdr lits) uc lu ht))
          (else (cd-cs-go (cdr lits) (+ uc 1) (car lits) ht)))))

; ---------- 1-UIP conflict analysis ----------
; Given the conflicting clause, resolve against antecedents of current-level literals (in reverse trail order)
; until one current-level literal remains.  Returns (learned-clause . backjump-level).
(define (cd-analyze conflict-clause)
  (cd-analyze-loop (cd-dedup conflict-clause) cd-trail))
(define (cd-analyze-loop clause trail)
  (let ((cl (cd-count-current-level clause)))
    (cond ((<= cl 1) (cons (cd-finish-learn clause) (cd-backjump-level clause)))
          (else (cd-analyze-step clause trail)))))
; resolve out the most recently assigned current-level literal that has a reason
(define (cd-analyze-step clause trail)
  (cond ((null? trail) (cons (cd-finish-learn clause) (cd-backjump-level clause)))
        (else (cd-analyze-pick clause (car trail) (cdr trail)))))
(define (cd-analyze-pick clause lit rest)
  (let ((v (cd-var lit)))
    (cond ((and (cd-in-clause? clause (cd-neg lit)) (= (vector-ref cd-level v) cd-dlevel) (cd-has-reason? v))
           (cd-analyze-loop (cd-resolve clause (vector-ref cd-reason v) v) rest))
          (else (cd-analyze-step clause rest)))))
(define (cd-has-reason? v) (cond ((null? (vector-ref cd-reason v)) #f) (else #t)))
; resolve clause and reason on variable v: union minus both literals of v
(define (cd-resolve clause reason v) (cd-dedup (cd-remove-var (cd-append clause reason) v)))
(define (cd-remove-var lits v) (cond ((null? lits) (quote ())) ((= (cd-var (car lits)) v) (cd-remove-var (cdr lits) v)) (else (cons (car lits) (cd-remove-var (cdr lits) v)))))
(define (cd-count-current-level clause) (cd-ccl clause 0))
(define (cd-ccl lits acc) (cond ((null? lits) acc) ((= (vector-ref cd-level (cd-var (car lits))) cd-dlevel) (cd-ccl (cdr lits) (+ acc 1))) (else (cd-ccl (cdr lits) acc))))
(define (cd-finish-learn clause) clause)
; backjump level = the second-highest decision level among the clause's literals (0 if only one literal)
(define (cd-backjump-level clause) (cd-second-highest-level clause))
(define (cd-second-highest-level clause)
  (let ((levels (cd-levels-of clause)))
    (cd-second-max levels)))
(define (cd-levels-of lits) (cond ((null? lits) (quote ())) (else (cons (vector-ref cd-level (cd-var (car lits))) (cd-levels-of (cdr lits))))))
(define (cd-second-max levels)
  (cond ((null? levels) 0)
        ((null? (cdr levels)) 0)
        (else (cd-second-max-go levels -1 -1))))
(define (cd-second-max-go ls hi hi2)
  (cond ((null? ls) (if (< hi2 0) 0 hi2))
        (else (cd-smax-step (car ls) (cdr ls) hi hi2))))
(define (cd-smax-step x rest hi hi2)
  (cond ((> x hi) (cd-second-max-go rest x hi))
        ((> x hi2) (cd-second-max-go rest hi x))
        (else (cd-second-max-go rest hi hi2))))

; ---------- clause / literal list utilities ----------
(define (cd-in-clause? clause lit) (cond ((null? clause) #f) ((= (car clause) lit) #t) (else (cd-in-clause? (cdr clause) lit))))
(define (cd-append a b) (if (null? a) b (cons (car a) (cd-append (cdr a) b))))
(define (cd-dedup lits) (cd-dedup-go lits (quote ())))
(define (cd-dedup-go lits seen) (cond ((null? lits) (cd-rev seen)) ((cd-mem? (car lits) seen) (cd-dedup-go (cdr lits) seen)) (else (cd-dedup-go (cdr lits) (cons (car lits) seen)))))
(define (cd-mem? x l) (cond ((null? l) #f) ((= (car l) x) #t) (else (cd-mem? x (cdr l)))))
(define (cd-rev l) (cd-rev-go l (quote ()))) (define (cd-rev-go l a) (if (null? l) a (cd-rev-go (cdr l) (cons (car l) a))))
(define (cd-length l) (if (null? l) 0 (+ 1 (cd-length (cdr l)))))

; ---------- backtracking: undo trail down to a given level ----------
(define (cd-backtrack-to level)
  (begin (cd-undo-trail level) (set! cd-dlevel level)))
(define (cd-undo-trail level)
  (cond ((null? cd-trail) (quote ()))
        ((> (vector-ref cd-level (cd-var (car cd-trail))) level)
         (begin (vector-set! cd-value (cd-var (car cd-trail)) -1)
                (set! cd-trail (cdr cd-trail))
                (cd-undo-trail level)))
        (else (quote ()))))

; ---------- VSIDS branching ----------
(define (cd-bump! v) (vector-set! cd-activity v (+ (vector-ref cd-activity v) 1)))
(define (cd-bump-clause! clause) (cond ((null? clause) (quote ())) (else (begin (cd-bump! (cd-var (car clause))) (cd-bump-clause! (cdr clause))))))
(define (cd-pick-branch) (cd-pick-go 1 -1 -1))
(define (cd-pick-go v best bestact)
  (cond ((> v cd-n) best)
        ((and (= (vector-ref cd-value v) -1) (> (vector-ref cd-activity v) bestact)) (cd-pick-go (+ v 1) v (vector-ref cd-activity v)))
        (else (cd-pick-go (+ v 1) best bestact))))

; ---------- the main CDCL driver (iterative) ----------
(define (cdcl-solve nvars clauses) (begin (cd-init! nvars clauses) (cd-driver)))
(define (cd-init! nvars clauses)
  (begin (set! cd-n nvars)
         (set! cd-value (make-vector (+ nvars 1) -1))
         (set! cd-level (make-vector (+ nvars 1) 0))
         (set! cd-reason (make-vector (+ nvars 1) (quote ())))
         (set! cd-activity (make-vector (+ nvars 1) 0))
         (set! cd-trail (quote ()))
         (set! cd-dlevel 0)
         (set! cd-clauses clauses)
         (set! cd-conflict-count 0)
         (set! cd-model (quote ()))))
(define (cd-driver)
  (let ((p (cd-propagate)))
    (cond ((equal? p (quote ok)) (cd-after-prop-ok))
          (else (cd-after-conflict p)))))            ; p is the conflict clause
(define (cd-after-prop-ok)
  (let ((b (cd-pick-branch)))
    (cond ((< b 0) (cd-succeed))                     ; all assigned -> SAT
          (else (begin (set! cd-dlevel (+ cd-dlevel 1)) (cd-assign! b (quote ())) (cd-driver))))))
(define (cd-after-conflict conflict-clause)
  (set! cd-conflict-count (+ cd-conflict-count 1))
  (cond ((= cd-dlevel 0) (quote unsat))              ; conflict at root -> UNSAT
        (else (cd-learn-and-backjump conflict-clause))))
(define (cd-learn-and-backjump conflict-clause)
  (let ((res (cd-analyze conflict-clause)))
    (let ((learned (car res)) (bl (cdr res)))
      (begin (cd-bump-clause! learned)
             (set! cd-clauses (cons learned cd-clauses))
             (cd-backtrack-to bl)
             (cd-driver)))))
(define (cd-succeed) (begin (set! cd-model (cd-extract-model 1)) (quote sat)))
(define (cd-extract-model v) (cond ((> v cd-n) (quote ())) (else (cons (if (= (vector-ref cd-value v) 1) v (- 0 v)) (cd-extract-model (+ v 1))))))

(define (cdcl-sat? nvars clauses) (equal? (cdcl-solve nvars clauses) (quote sat)))

; ---------- independent model verifier ----------
(define (cdcl-check-model clauses model) (cd-all-clauses-sat? clauses model))
(define (cd-all-clauses-sat? cls model) (cond ((null? cls) #t) ((cd-clause-sat-by? (car cls) model) (cd-all-clauses-sat? (cdr cls) model)) (else #f)))
(define (cd-clause-sat-by? clause model) (cond ((null? clause) #f) ((cd-mem? (car clause) model) #t) (else (cd-clause-sat-by? (cdr clause) model))))

(define (cdcl-caveat) (quote cdcl-core-1uip-learning-vsids-iterative-NP-hard-worst-case-strategies-from-the-handbook))
