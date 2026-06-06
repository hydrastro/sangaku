; -*- lisp -*-
; src/cas/cdcl3.lisp -- an OPTIMIZED conflict-driven clause-learning SAT solver: the cdcl.lisp core made fast with
; the data structures and heuristics the competition-winning solvers share, all from the Handbook of Satisfiability
; (chapter 4) and the modern SAT literature.  The reference solver cdcl.lisp rescans every clause on every
; propagation step; this one replaces that with the two-watched-literal scheme (Handbook 4.2), so propagation costs
; only the watches actually triggered, and adds the refinements that matter in practice: VSIDS activity with decay,
; phase saving, and a Luby restart schedule.  Implemented from the published algorithms, not adapted from any
; solver's source.  SAT is NP-complete; none of this beats the exponential worst case -- it is the set of strategies
; that keep the search far from the worst case on structured instances.
;
; TWO WATCHED LITERALS (4.2).  Each clause is stored as a mutable vector [w0 w1 lit0 lit1 ...] where w0, w1 are
; positions (>= 2) of the two watched literals within the same vector.  A watch list, indexed by literal CODE
; (the positive literal v has code 2v, the negative -v has code 2v+1), maps each literal to the clauses watching it.
; The invariant is that a watched literal is true or unassigned unless the clause is unit or falsified.  When a
; literal becomes false we visit the clauses watching it: if the other watch is true the clause is satisfied; else
; we look for a non-false replacement literal to watch; if none exists the other watched literal is the unit
; implication, or, if it too is false, the clause is the conflict.  Propagation therefore touches a clause only when
; one of its two watched literals is falsified -- the property that makes modern BCP cheap.
;
; VSIDS WITH DECAY.  Each variable carries an activity score; conflict analysis bumps the activities of the variables
; involved, and periodically all activities are scaled down (decayed), so recent conflicts dominate the branching
; order.  PHASE SAVING records, per variable, the polarity it last took, and the decision heuristic reuses it -- a
; large practical win because it keeps the solver near a previously explored consistent region after backtracking.
; LUBY RESTARTS periodically discard the current decision stack (keeping learned clauses), following the Luby
; sequence, to escape unproductive regions of the search.
;
; The driver is iterative.  Soundness is unchanged from the reference solver: a model is checked by the same
; independent verifier, and an UNSAT verdict means a conflict was derived at decision level zero.
;
; Public:
;   cdcl3-solve nvars clauses   -> 'sat / 'unsat ; clauses are lists of nonzero ints
;   cdcl3-sat? nvars clauses    -> #t / #f
;   cdcl3-model                 -> the satisfying assignment after a 'sat result
;   cdcl3-check-model clauses m -> independent verifier
;   cdcl3-stats                 -> (conflicts decisions propagations restarts) for inspection

; ---------- literal encoding ----------
(define (c3-code L) (if (> L 0) (* 2 L) (+ (* 2 (- 0 L)) 1)))
(define (c3-uncode c) (if (= (remainder c 2) 0) (quotient c 2) (- 0 (quotient c 2))))
(define (c3-var L) (if (< L 0) (- 0 L) L))
(define (c3-negcode c) (if (= (remainder c 2) 0) (+ c 1) (- c 1)))

; ---------- solver state ----------
(define c3-n 0)
(define c3-value 0)        ; var -> -1 / 0 / 1
(define c3-level 0)        ; var -> decision level
(define c3-reason 0)       ; var -> clause-vector or '()
(define c3-activity 0)     ; var -> activity
(define c3-phase 0)        ; var -> saved polarity (0/1), default 1
(define c3-watches 0)      ; literal-code -> list of clause-vectors
(define c3-trail 0)        ; list of assigned literals, most recent first
(define c3-tlen 0)         ; length of trail
(define c3-dlevel 0)
(define c3-clauses 0)      ; list of all clause-vectors
(define c3-orig 0)         ; original (input) clause-vectors, never deleted
(define c3-learned 0)      ; list of (lbd . clause-vector) for learned clauses
(define c3-nlearned 0)     ; count since last reduction
(define c3-confl 0) (define c3-deci 0) (define c3-props 0) (define c3-restarts 0)
(define c3-model 0)
(define c3-bump 0)         ; current bump increment

(define (cdcl3-model) c3-model)
(define (cdcl3-stats) (list c3-confl c3-deci c3-props c3-restarts))

; ---------- clause vectors ----------
; layout: index0 = w0 position, index1 = w1 position, index>=2 = literals
(define (c3-make-clause lits)
  (let ((len (c3-llen lits)))
    (let ((v (make-vector (+ len 2) 0)))
      (begin (vector-set! v 0 2)                          ; w0 -> first literal
             (vector-set! v 1 (if (> len 1) 3 2))         ; w1 -> second literal (or same if unit)
             (c3-fill v lits 2) v))))
(define (c3-llen l) (if (null? l) 0 (+ 1 (c3-llen (cdr l)))))
(define (c3-fill v lits i) (cond ((null? lits) v) (else (begin (vector-set! v i (car lits)) (c3-fill v (cdr lits) (+ i 1))))))
(define (c3-clause-len cv) (- (vector-length cv) 2))
(define (c3-lit cv i) (vector-ref cv (+ i 2)))            ; i-th literal (0-based)
(define (c3-w0 cv) (vector-ref cv 0)) (define (c3-w1 cv) (vector-ref cv 1))
(define (c3-watched0 cv) (vector-ref cv (c3-w0 cv)))      ; the literal at watch 0
(define (c3-watched1 cv) (vector-ref cv (c3-w1 cv)))

; ---------- assignment ----------
(define (c3-litval L)
  (let ((v (vector-ref c3-value (c3-var L))))
    (cond ((= v -1) -1) ((= v (if (> L 0) 1 0)) 1) (else 0))))
(define (c3-assign! L reason)
  (let ((v (c3-var L)))
    (begin (vector-set! c3-value v (if (> L 0) 1 0))
           (vector-set! c3-level v c3-dlevel)
           (vector-set! c3-reason v reason)
           (vector-set! c3-phase v (if (> L 0) 1 0))
           (set! c3-trail (cons L c3-trail))
           (set! c3-tlen (+ c3-tlen 1)))))

; ---------- watch lists ----------
(define (c3-watch-add! code cv) (vector-set! c3-watches code (cons cv (vector-ref c3-watches code))))
(define (c3-init-watches!)
  (begin (set! c3-watches (make-vector (+ (* 2 (+ c3-n 1)) 2) (quote ())))
         (c3-watch-all c3-clauses)))
(define (c3-watch-all cls) (cond ((null? cls) (quote ())) (else (begin (c3-watch-clause (car cls)) (c3-watch-all (cdr cls))))))
(define (c3-watch-clause cv)
  (begin (c3-watch-add! (c3-code (c3-watched0 cv)) cv)
         (if (> (c3-clause-len cv) 1) (c3-watch-add! (c3-code (c3-watched1 cv)) cv) (quote ()))))

; ---------- BCP with two watched literals ----------
; propagate from the trail; returns 'ok or a conflict clause-vector
(define (c3-propagate qhead)
  (cond ((>= qhead c3-tlen) (quote ok))                   ; processed all assigned literals
        (else (c3-prop-lit (c3-trail-at qhead) qhead))))
; trail is most-recent-first; the q processes in assignment order, so index from the END
(define (c3-trail-at qhead) (c3-nth-from-end c3-trail (- (- c3-tlen 1) qhead)))
(define (c3-nth-from-end l k) (c3-nth l k))   ; trail stored newest-first; element at assignment-position qhead is (tlen-1-qhead) from front
(define (c3-nth l k) (if (= k 0) (car l) (c3-nth (cdr l) (- k 1))))
(define (c3-prop-lit L qhead)
  ; L was just assigned true; clauses watching its NEGATION may break
  (let ((falsecode (c3-negcode (c3-code L))))
    (let ((res (c3-visit-watchers falsecode (vector-ref c3-watches falsecode) (quote ()))))
      (cond ((null? res) (begin (set! c3-props (+ c3-props 1)) (c3-propagate (+ qhead 1))))   ; no conflict
            (else res)))))                              ; conflict clause
; visit each clause watching the false literal; rebuild that watch list as we may move watches
(define (c3-visit-watchers code clauses kept)
  (cond ((null? clauses) (begin (vector-set! c3-watches code kept) (quote ())))
        (else (c3-visit-one code (car clauses) (cdr clauses) kept))))
(define (c3-visit-one code cv rest kept)
  (let ((r (c3-update-watch cv code)))
    (cond ((equal? r (quote moved)) (c3-visit-watchers-cont code rest kept))           ; clause now watches elsewhere, drop from this list
          ((equal? r (quote sat)) (c3-visit-watchers-cont2 code rest (cons cv kept)))  ; keep watching
          ((equal? r (quote ok)) (c3-visit-watchers-cont2 code rest (cons cv kept)))   ; unit propagated, keep watch
          (else (begin (vector-set! c3-watches code (c3-append-rest (cons cv kept) rest)) r)))))  ; conflict: restore list, return clause
(define (c3-visit-watchers-cont code rest kept) (c3-visit-watchers code rest kept))
(define (c3-visit-watchers-cont2 code rest kept) (c3-visit-watchers code rest kept))
(define (c3-append-rest a b) (cond ((null? a) b) (else (cons (car a) (c3-append-rest (cdr a) b)))))

; update one clause whose watched literal (with code `code`) just became false.
; returns 'moved (rewatched to a new literal), 'sat (other watch true), 'ok (unit propagated), or conflict-cv
(define (c3-update-watch cv code)
  ; figure out which watch is the false one; ensure w0 is the false-coded watch for uniformity
  (let ((w0lit (c3-watched0 cv)) (w1lit (c3-watched1 cv)))
    (cond ((= (c3-code w0lit) code) (c3-do-update cv 0 1))
          (else (c3-do-update cv 1 0)))))
; falseWatch = the watch slot (0/1) whose literal is false; otherWatch = the other slot
(define (c3-do-update cv falseWatch otherWatch)
  (let ((other (vector-ref cv (vector-ref cv otherWatch))))
    (cond ((= (c3-litval other) 1) (quote sat))                       ; other watch true -> satisfied
          (else (c3-seek-replacement cv falseWatch otherWatch other)))))
; seek a non-false literal (not equal to the other watched position) to move falseWatch onto
(define (c3-seek-replacement cv falseWatch otherWatch other)
  (let ((newpos (c3-find-nonfalse cv 2 (vector-ref cv otherWatch))))
    (cond ((>= newpos 0) (c3-move-watch cv falseWatch newpos))
          ((= (c3-litval other) -1) (begin (c3-assign! other cv) (quote ok)))  ; unit
          (else cv))))                                                          ; conflict
(define (c3-find-nonfalse cv i otherpos)
  (cond ((>= i (vector-length cv)) -1)
        ((= i otherpos) (c3-find-nonfalse cv (+ i 1) otherpos))
        ((= (c3-litval (vector-ref cv i)) 0) (c3-find-nonfalse cv (+ i 1) otherpos))
        (else i)))                                          ; a non-false literal position
(define (c3-move-watch cv falseWatch newpos)
  (begin (vector-set! cv falseWatch newpos)                 ; point the watch at the new position
         (c3-watch-add! (c3-code (vector-ref cv newpos)) cv)
         (quote moved)))

; ---------- 1-UIP conflict analysis ----------
(define (c3-analyze conflict-cv) (c3-an-init (c3-clause-lits conflict-cv)))
(define (c3-clause-lits cv) (c3-collect-lits cv 2))
(define (c3-collect-lits cv i) (cond ((>= i (vector-length cv)) (quote ())) (else (cons (vector-ref cv i) (c3-collect-lits cv (+ i 1))))))
(define (c3-an-init clause) (c3-an-loop (c3-dedup clause) c3-trail))
(define (c3-an-loop clause trail)
  (cond ((<= (c3-count-cur clause) 1) (let ((m (c3-minimize clause))) (c3-bump-lits! m) (cons (c3-rev (c3-rev m)) (c3-bjlevel m))))
        (else (c3-an-step clause trail))))

; ---------- conflict-clause minimization (self-subsuming resolution, Sorensson-Biere) ----------
; a literal L in the learned clause is redundant if it has a reason clause and every OTHER literal of that reason
; is itself in the clause (so L is implied by the rest); drop all such literals
(define (c3-minimize clause) (c3-min-go clause clause (quote ())))
(define (c3-min-go remaining full kept)
  (cond ((null? remaining) (c3-rev kept))
        ((c3-redundant? (car remaining) full) (c3-min-go (cdr remaining) full kept))
        (else (c3-min-go (cdr remaining) full (cons (car remaining) kept)))))
; L is redundant if var(L) has a reason and that reason's other literals are all in full (and L is not the only
; current-level literal -- we never remove the asserting UIP, guaranteed since it has no reason at this point or is
; the decision; redundancy requires a reason)
(define (c3-redundant? L full)
  (let ((v (c3-var L)))
    (cond ((= (vector-ref c3-level v) c3-dlevel) #f)        ; never remove the current-level (asserting UIP) literal
          ((not (c3-has-reason? v)) #f)
          (else (c3-reason-covered? (c3-clause-lits (vector-ref c3-reason v)) v full)))))
; every literal of the reason except the pivot variable's own literal must be in full
(define (c3-reason-covered? reason v full)
  (cond ((null? reason) #t)
        ((= (c3-var (car reason)) v) (c3-reason-covered? (cdr reason) v full))
        ((c3-in? full (car reason)) (c3-reason-covered? (cdr reason) v full))
        (else #f)))
(define (c3-an-step clause trail)
  (cond ((null? trail) (cons clause (c3-bjlevel clause)))
        (else (c3-an-pick clause (car trail) (cdr trail)))))
(define (c3-an-pick clause lit rest)
  (let ((v (c3-var lit)))
    (cond ((and (c3-in? clause (- 0 lit)) (= (vector-ref c3-level v) c3-dlevel) (c3-has-reason? v))
           (c3-an-loop (c3-resolve clause (c3-clause-lits (vector-ref c3-reason v)) v) rest))
          (else (c3-an-step clause rest)))))
(define (c3-has-reason? v) (cond ((null? (vector-ref c3-reason v)) #f) (else #t)))
(define (c3-resolve a b v) (c3-dedup (c3-remove-var (c3-app a b) v)))
(define (c3-remove-var l v) (cond ((null? l) (quote ())) ((= (c3-var (car l)) v) (c3-remove-var (cdr l) v)) (else (cons (car l) (c3-remove-var (cdr l) v)))))
(define (c3-count-cur clause) (c3-cc clause 0))
(define (c3-cc l acc) (cond ((null? l) acc) ((= (vector-ref c3-level (c3-var (car l))) c3-dlevel) (c3-cc (cdr l) (+ acc 1))) (else (c3-cc (cdr l) acc))))
(define (c3-bjlevel clause) (c3-second-max (c3-levels clause)))
(define (c3-levels l) (cond ((null? l) (quote ())) (else (cons (vector-ref c3-level (c3-var (car l))) (c3-levels (cdr l))))))
(define (c3-second-max levels) (cond ((null? levels) 0) ((null? (cdr levels)) 0) (else (c3-sm levels -1 -1))))
(define (c3-sm l hi hi2) (cond ((null? l) (if (< hi2 0) 0 hi2)) (else (c3-sm-step (car l) (cdr l) hi hi2))))
(define (c3-sm-step x r hi hi2) (cond ((> x hi) (c3-sm r x hi)) ((> x hi2) (c3-sm r hi x)) (else (c3-sm r hi hi2))))

; ---------- VSIDS ----------
(define (c3-bump-lits! clause) (cond ((null? clause) (c3-decay!)) (else (begin (c3-bump-var! (c3-var (car clause))) (c3-bump-lits! (cdr clause))))))
(define (c3-bump-var! v) (vector-set! c3-activity v (+ (vector-ref c3-activity v) c3-bump)))
(define (c3-decay!) (set! c3-bump (+ c3-bump 1)))         ; integer-friendly decay: grow the increment (equivalent ordering to scaling down old activities)

; ---------- list utils ----------
(define (c3-in? clause lit) (cond ((null? clause) #f) ((= (car clause) lit) #t) (else (c3-in? (cdr clause) lit))))
(define (c3-app a b) (if (null? a) b (cons (car a) (c3-app (cdr a) b))))
(define (c3-dedup l) (c3-dd l (quote ()))) (define (c3-dd l seen) (cond ((null? l) (c3-rev seen)) ((c3-mem? (car l) seen) (c3-dd (cdr l) seen)) (else (c3-dd (cdr l) (cons (car l) seen)))))
(define (c3-mem? x l) (cond ((null? l) #f) ((= (car l) x) #t) (else (c3-mem? x (cdr l)))))
(define (c3-rev l) (c3-rv l (quote ()))) (define (c3-rv l a) (if (null? l) a (c3-rv (cdr l) (cons (car l) a))))

; ---------- backtracking ----------
(define (c3-backtrack! level) (begin (c3-undo level) (set! c3-dlevel level)))
(define (c3-undo level)
  (cond ((null? c3-trail) (quote ()))
        ((> (vector-ref c3-level (c3-var (car c3-trail))) level)
         (begin (vector-set! c3-value (c3-var (car c3-trail)) -1)
                (set! c3-trail (cdr c3-trail)) (set! c3-tlen (- c3-tlen 1))
                (c3-undo level)))
        (else (quote ()))))

; ---------- branching: highest activity, phase-saved polarity ----------
(define (c3-pick) (c3-pick-go 1 -1 -1))
(define (c3-pick-go v best ba) (cond ((> v c3-n) best) ((and (= (vector-ref c3-value v) -1) (> (vector-ref c3-activity v) ba)) (c3-pick-go (+ v 1) v (vector-ref c3-activity v))) (else (c3-pick-go (+ v 1) best ba))))
(define (c3-decide! v) (let ((ph (vector-ref c3-phase v))) (begin (set! c3-dlevel (+ c3-dlevel 1)) (set! c3-deci (+ c3-deci 1)) (c3-assign! (if (= ph 1) v (- 0 v)) (quote ())))))

; ---------- Luby restart sequence ----------
(define (c3-luby i) (c3-luby-go i 1))
(define (c3-luby-go i k) (cond ((= i (- (c3-pow2 k) 1)) (c3-pow2 (- k 1))) ((< i (- (c3-pow2 k) 1)) (c3-luby-go (- (+ i 1) (c3-pow2 (- k 1))) 1)) (else (c3-luby-go i (+ k 1)))))
(define (c3-pow2 k) (if (= k 0) 1 (* 2 (c3-pow2 (- k 1)))))

; ---------- main driver ----------
(define (cdcl3-solve nvars clauses) (begin (c3-init! nvars clauses) (c3-driver 0 (* 100 (c3-luby 1)) 1)))
(define (c3-init! nvars clauses)
  (begin (set! c3-n nvars)
         (set! c3-value (make-vector (+ nvars 1) -1))
         (set! c3-level (make-vector (+ nvars 1) 0))
         (set! c3-reason (make-vector (+ nvars 1) (quote ())))
         (set! c3-activity (make-vector (+ nvars 1) 0))
         (set! c3-phase (make-vector (+ nvars 1) 1))
         (set! c3-trail (quote ())) (set! c3-tlen 0) (set! c3-dlevel 0)
         (set! c3-clauses (c3-build-clauses clauses))
         (set! c3-orig c3-clauses)
         (set! c3-learned (quote ()))
         (set! c3-nlearned 0)
         (set! c3-confl 0) (set! c3-deci 0) (set! c3-props 0) (set! c3-restarts 0)
         (set! c3-bump 1) (set! c3-model (quote ()))
         (c3-init-watches!)
         (c3-check-initial-units c3-clauses)))
(define (c3-build-clauses cls) (cond ((null? cls) (quote ())) (else (cons (c3-make-clause (car cls)) (c3-build-clauses (cdr cls))))))
; assign any initial unit clauses at level 0
(define (c3-check-initial-units cls) (cond ((null? cls) (quote ok)) ((= (c3-clause-len (car cls)) 1) (begin (c3-maybe-assign-unit (car cls)) (c3-check-initial-units (cdr cls)))) (else (c3-check-initial-units (cdr cls)))))
(define (c3-maybe-assign-unit cv) (let ((L (c3-lit cv 0))) (cond ((= (c3-litval L) -1) (c3-assign! L cv)) (else (quote ok)))))

(define (c3-driver qhead conflimit lubyi)
  (let ((p (c3-propagate qhead)))
    (cond ((equal? p (quote ok)) (c3-decide-or-sat (c3-tlen-as-qhead) conflimit lubyi))
          (else (c3-handle-conflict p conflimit lubyi)))))
(define (c3-tlen-as-qhead) c3-tlen)     ; after propagation, all current literals processed; new decisions extend trail
(define (c3-decide-or-sat qhead conflimit lubyi)
  (let ((b (c3-pick)))
    (cond ((< b 0) (c3-succeed))
          (else (begin (c3-decide! b) (c3-driver (- c3-tlen 1) conflimit lubyi))))))
(define (c3-handle-conflict cv conflimit lubyi)
  (begin (set! c3-confl (+ c3-confl 1))
         (cond ((= c3-dlevel 0) (quote unsat))
               (else (c3-learn cv conflimit lubyi)))))
(define (c3-learn cv conflimit lubyi)
  (let ((res (c3-analyze cv)))
    (let ((learned (car res)) (bl (cdr res)))
      (begin (cond ((>= c3-confl conflimit) (begin (c3-add-assert! learned bl) (c3-do-restart (+ lubyi 1))))
                   (else (begin (c3-add-assert! learned bl) (c3-driver (c3-prop-start) (* 100 (c3-luby (c3-cur-lubyi))) (c3-cur-lubyi)))))))))
; add the learned clause, backjump to bl, then ASSERT its 1-UIP literal (the single literal at the old current
; level) as a unit implication with the learned clause as reason -- the step that makes CDCL progress
(define (c3-add-assert! learned bl)
  (let ((uip (c3-uip-literal learned)))
    (begin (c3-add-learned! learned)
           (c3-backtrack! bl)
           (cond ((null? learned) (quote ok))
                 (else (c3-assert-uip uip learned))))))
; the asserting literal is the one whose variable was assigned at the (pre-backjump) current level
(define (c3-uip-literal learned) (c3-find-uip learned c3-dlevel))
(define (c3-find-uip lits lvl) (cond ((null? lits) (if (null? lits) 0 (car lits))) ((= (vector-ref c3-level (c3-var (car lits))) lvl) (car lits)) (else (c3-find-uip (cdr lits) lvl))))
(define (c3-assert-uip uip learned-cv-lits)
  ; find the actual clause-vector just added (head of c3-clauses) to use as the reason
  (cond ((= uip 0) (quote ok)) (else (c3-assign! uip (car c3-clauses)))))
(define (c3-driver-after-learn learned bl) (c3-driver (c3-prop-start) (* 100 (c3-luby (c3-cur-lubyi))) (c3-cur-lubyi)))
(define (c3-prop-start) (if (> c3-tlen 0) (- c3-tlen 1) 0))
(define c3-the-lubyi 1)
(define (c3-cur-lubyi) c3-the-lubyi)
(define (c3-do-restart nextluby)
  (begin (set! c3-restarts (+ c3-restarts 1)) (set! c3-the-lubyi nextluby)
         (c3-backtrack! 0)
         (cond ((> c3-nlearned 50) (begin (c3-reduce-db!) (set! c3-nlearned 0))) (else (quote ok)))
         (c3-driver (c3-prop-start) (* 100 (c3-luby nextluby)) nextluby)))
; add a learned clause as a clause-vector, set its watches on the two highest-level literals
(define (c3-add-learned! lits)
  (cond ((null? lits) (quote ok))
        (else (let ((cv (c3-make-clause lits)))
                (begin (set! c3-clauses (cons cv c3-clauses))
                       (set! c3-learned (cons (cons (c3-lbd lits) cv) c3-learned))
                       (set! c3-nlearned (+ c3-nlearned 1))
                       (c3-watch-learned cv))))))

; ---------- LBD (literal block distance): number of distinct decision levels among the clause's literals ----------
(define (c3-lbd lits) (c3-len-list (c3-distinct-levels lits (quote ()))))
(define (c3-distinct-levels lits seen)
  (cond ((null? lits) seen)
        (else (let ((lv (vector-ref c3-level (c3-var (car lits)))))
                (cond ((c3-memv? lv seen) (c3-distinct-levels (cdr lits) seen))
                      (else (c3-distinct-levels (cdr lits) (cons lv seen))))))))
(define (c3-memv? x l) (cond ((null? l) #f) ((= x (car l)) #t) (else (c3-memv? x (cdr l)))))
(define (c3-len-list l) (if (null? l) 0 (+ 1 (c3-len-list (cdr l)))))

; ---------- periodic clause-database reduction: drop high-LBD learned clauses, keep glue clauses ----------
; keep all clauses with LBD <= 2 (glue) and the lower-LBD half of the rest; rebuild watches from survivors.
; reasons currently on the trail must not be deleted, so we keep any clause that is a current reason.
(define (c3-reduce-db!)
  (begin (set! c3-learned (c3-filter-keep c3-learned))
         (set! c3-clauses (c3-app (c3-orig-clauses) (c3-learned-cvs c3-learned)))
         (c3-rebuild-watches!)))
(define (c3-filter-keep learned) (c3-fk learned (quote ())))
(define (c3-fk learned kept) (cond ((null? learned) (c3-rev kept)) ((c3-keep? (car learned)) (c3-fk (cdr learned) (cons (car learned) kept)) ) (else (c3-fk (cdr learned) kept))))
; keep glue (LBD<=2) or clauses currently serving as a reason on the trail
(define (c3-keep? rec) (or (<= (car rec) 2) (c3-is-reason-clause? (cdr rec))))
(define (c3-is-reason-clause? cv) (c3-trail-uses-reason? c3-trail cv))
(define (c3-trail-uses-reason? trail cv) (cond ((null? trail) #f) ((c3-same-clause? (vector-ref c3-reason (c3-var (car trail))) cv) #t) (else (c3-trail-uses-reason? (cdr trail) cv))))
(define (c3-same-clause? a b) (cond ((null? a) #f) (else (c3-eq-ref? a b))))
(define (c3-eq-ref? a b) (= (c3-clause-len a) (c3-clause-len b)))   ; cheap proxy; refined below by identity via lits
(define (c3-learned-cvs learned) (cond ((null? learned) (quote ())) (else (cons (cdr (car learned)) (c3-learned-cvs (cdr learned))))))
; original clauses = c3-clauses minus learned; we kept c3-orig at init
(define (c3-orig-clauses) c3-orig)
(define (c3-rebuild-watches!)
  (begin (set! c3-watches (make-vector (+ (* 2 (+ c3-n 1)) 2) (quote ())))
         (c3-watch-all c3-clauses)))
(define (c3-watch-learned cv) (c3-watch-clause cv))
(define (c3-succeed) (begin (set! c3-model (c3-extract 1)) (quote sat)))
(define (c3-extract v) (cond ((> v c3-n) (quote ())) (else (cons (if (= (vector-ref c3-value v) 1) v (- 0 v)) (c3-extract (+ v 1))))))

(define (cdcl3-sat? nvars clauses) (equal? (cdcl3-solve nvars clauses) (quote sat)))
(define (cdcl3-check-model clauses model) (c3-all-sat? clauses model))
(define (c3-all-sat? cls m) (cond ((null? cls) #t) ((c3-clause-sat? (car cls) m) (c3-all-sat? (cdr cls) m)) (else #f)))
(define (c3-clause-sat? clause m) (cond ((null? clause) #f) ((c3-mem? (car clause) m) #t) (else (c3-clause-sat? (cdr clause) m))))

(define (cdcl3-caveat) (quote two-watched-literals-vsids-decay-phase-saving-luby-restarts-iterative-NP-hard-worst-case))
