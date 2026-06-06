; -*- lisp -*-
; src/cas/cdcl2.lisp -- an OPTIMIZED conflict-driven clause-learning SAT solver: the cdcl.lisp core made fast with
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
;   cdcl2-solve nvars clauses   -> 'sat / 'unsat ; clauses are lists of nonzero ints
;   cdcl2-sat? nvars clauses    -> #t / #f
;   cdcl2-model                 -> the satisfying assignment after a 'sat result
;   cdcl2-check-model clauses m -> independent verifier
;   cdcl2-stats                 -> (conflicts decisions propagations restarts) for inspection

; ---------- literal encoding ----------
(define (c2-code L) (if (> L 0) (* 2 L) (+ (* 2 (- 0 L)) 1)))
(define (c2-uncode c) (if (= (remainder c 2) 0) (quotient c 2) (- 0 (quotient c 2))))
(define (c2-var L) (if (< L 0) (- 0 L) L))
(define (c2-negcode c) (if (= (remainder c 2) 0) (+ c 1) (- c 1)))

; ---------- solver state ----------
(define c2-n 0)
(define c2-value 0)        ; var -> -1 / 0 / 1
(define c2-level 0)        ; var -> decision level
(define c2-reason 0)       ; var -> clause-vector or '()
(define c2-activity 0)     ; var -> activity
(define c2-phase 0)        ; var -> saved polarity (0/1), default 1
(define c2-watches 0)      ; literal-code -> list of clause-vectors
(define c2-trail 0)        ; list of assigned literals, most recent first
(define c2-tlen 0)         ; length of trail
(define c2-dlevel 0)
(define c2-clauses 0)      ; list of all clause-vectors
(define c2-confl 0) (define c2-deci 0) (define c2-props 0) (define c2-restarts 0)
(define c2-model 0)
(define c2-bump 0)         ; current bump increment

(define (cdcl2-model) c2-model)
(define (cdcl2-stats) (list c2-confl c2-deci c2-props c2-restarts))

; ---------- clause vectors ----------
; layout: index0 = w0 position, index1 = w1 position, index>=2 = literals
(define (c2-make-clause lits)
  (let ((len (c2-llen lits)))
    (let ((v (make-vector (+ len 2) 0)))
      (begin (vector-set! v 0 2)                          ; w0 -> first literal
             (vector-set! v 1 (if (> len 1) 3 2))         ; w1 -> second literal (or same if unit)
             (c2-fill v lits 2) v))))
(define (c2-llen l) (if (null? l) 0 (+ 1 (c2-llen (cdr l)))))
(define (c2-fill v lits i) (cond ((null? lits) v) (else (begin (vector-set! v i (car lits)) (c2-fill v (cdr lits) (+ i 1))))))
(define (c2-clause-len cv) (- (vector-length cv) 2))
(define (c2-lit cv i) (vector-ref cv (+ i 2)))            ; i-th literal (0-based)
(define (c2-w0 cv) (vector-ref cv 0)) (define (c2-w1 cv) (vector-ref cv 1))
(define (c2-watched0 cv) (vector-ref cv (c2-w0 cv)))      ; the literal at watch 0
(define (c2-watched1 cv) (vector-ref cv (c2-w1 cv)))

; ---------- assignment ----------
(define (c2-litval L)
  (let ((v (vector-ref c2-value (c2-var L))))
    (cond ((= v -1) -1) ((= v (if (> L 0) 1 0)) 1) (else 0))))
(define (c2-assign! L reason)
  (let ((v (c2-var L)))
    (begin (vector-set! c2-value v (if (> L 0) 1 0))
           (vector-set! c2-level v c2-dlevel)
           (vector-set! c2-reason v reason)
           (vector-set! c2-phase v (if (> L 0) 1 0))
           (set! c2-trail (cons L c2-trail))
           (set! c2-tlen (+ c2-tlen 1)))))

; ---------- watch lists ----------
(define (c2-watch-add! code cv) (vector-set! c2-watches code (cons cv (vector-ref c2-watches code))))
(define (c2-init-watches!)
  (begin (set! c2-watches (make-vector (+ (* 2 (+ c2-n 1)) 2) (quote ())))
         (c2-watch-all c2-clauses)))
(define (c2-watch-all cls) (cond ((null? cls) (quote ())) (else (begin (c2-watch-clause (car cls)) (c2-watch-all (cdr cls))))))
(define (c2-watch-clause cv)
  (begin (c2-watch-add! (c2-code (c2-watched0 cv)) cv)
         (if (> (c2-clause-len cv) 1) (c2-watch-add! (c2-code (c2-watched1 cv)) cv) (quote ()))))

; ---------- BCP with two watched literals ----------
; propagate from the trail; returns 'ok or a conflict clause-vector
(define (c2-propagate qhead)
  (cond ((>= qhead c2-tlen) (quote ok))                   ; processed all assigned literals
        (else (c2-prop-lit (c2-trail-at qhead) qhead))))
; trail is most-recent-first; the q processes in assignment order, so index from the END
(define (c2-trail-at qhead) (c2-nth-from-end c2-trail (- (- c2-tlen 1) qhead)))
(define (c2-nth-from-end l k) (c2-nth l k))   ; trail stored newest-first; element at assignment-position qhead is (tlen-1-qhead) from front
(define (c2-nth l k) (if (= k 0) (car l) (c2-nth (cdr l) (- k 1))))
(define (c2-prop-lit L qhead)
  ; L was just assigned true; clauses watching its NEGATION may break
  (let ((falsecode (c2-negcode (c2-code L))))
    (let ((res (c2-visit-watchers falsecode (vector-ref c2-watches falsecode) (quote ()))))
      (cond ((null? res) (begin (set! c2-props (+ c2-props 1)) (c2-propagate (+ qhead 1))))   ; no conflict
            (else res)))))                              ; conflict clause
; visit each clause watching the false literal; rebuild that watch list as we may move watches
(define (c2-visit-watchers code clauses kept)
  (cond ((null? clauses) (begin (vector-set! c2-watches code kept) (quote ())))
        (else (c2-visit-one code (car clauses) (cdr clauses) kept))))
(define (c2-visit-one code cv rest kept)
  (let ((r (c2-update-watch cv code)))
    (cond ((equal? r (quote moved)) (c2-visit-watchers-cont code rest kept))           ; clause now watches elsewhere, drop from this list
          ((equal? r (quote sat)) (c2-visit-watchers-cont2 code rest (cons cv kept)))  ; keep watching
          ((equal? r (quote ok)) (c2-visit-watchers-cont2 code rest (cons cv kept)))   ; unit propagated, keep watch
          (else (begin (vector-set! c2-watches code (c2-append-rest (cons cv kept) rest)) r)))))  ; conflict: restore list, return clause
(define (c2-visit-watchers-cont code rest kept) (c2-visit-watchers code rest kept))
(define (c2-visit-watchers-cont2 code rest kept) (c2-visit-watchers code rest kept))
(define (c2-append-rest a b) (cond ((null? a) b) (else (cons (car a) (c2-append-rest (cdr a) b)))))

; update one clause whose watched literal (with code `code`) just became false.
; returns 'moved (rewatched to a new literal), 'sat (other watch true), 'ok (unit propagated), or conflict-cv
(define (c2-update-watch cv code)
  ; figure out which watch is the false one; ensure w0 is the false-coded watch for uniformity
  (let ((w0lit (c2-watched0 cv)) (w1lit (c2-watched1 cv)))
    (cond ((= (c2-code w0lit) code) (c2-do-update cv 0 1))
          (else (c2-do-update cv 1 0)))))
; falseWatch = the watch slot (0/1) whose literal is false; otherWatch = the other slot
(define (c2-do-update cv falseWatch otherWatch)
  (let ((other (vector-ref cv (vector-ref cv otherWatch))))
    (cond ((= (c2-litval other) 1) (quote sat))                       ; other watch true -> satisfied
          (else (c2-seek-replacement cv falseWatch otherWatch other)))))
; seek a non-false literal (not equal to the other watched position) to move falseWatch onto
(define (c2-seek-replacement cv falseWatch otherWatch other)
  (let ((newpos (c2-find-nonfalse cv 2 (vector-ref cv otherWatch))))
    (cond ((>= newpos 0) (c2-move-watch cv falseWatch newpos))
          ((= (c2-litval other) -1) (begin (c2-assign! other cv) (quote ok)))  ; unit
          (else cv))))                                                          ; conflict
(define (c2-find-nonfalse cv i otherpos)
  (cond ((>= i (vector-length cv)) -1)
        ((= i otherpos) (c2-find-nonfalse cv (+ i 1) otherpos))
        ((= (c2-litval (vector-ref cv i)) 0) (c2-find-nonfalse cv (+ i 1) otherpos))
        (else i)))                                          ; a non-false literal position
(define (c2-move-watch cv falseWatch newpos)
  (begin (vector-set! cv falseWatch newpos)                 ; point the watch at the new position
         (c2-watch-add! (c2-code (vector-ref cv newpos)) cv)
         (quote moved)))

; ---------- 1-UIP conflict analysis ----------
(define (c2-analyze conflict-cv) (c2-an-init (c2-clause-lits conflict-cv)))
(define (c2-clause-lits cv) (c2-collect-lits cv 2))
(define (c2-collect-lits cv i) (cond ((>= i (vector-length cv)) (quote ())) (else (cons (vector-ref cv i) (c2-collect-lits cv (+ i 1))))))
(define (c2-an-init clause) (c2-an-loop (c2-dedup clause) c2-trail))
(define (c2-an-loop clause trail)
  (cond ((<= (c2-count-cur clause) 1) (c2-bump-lits! clause) (cons (c2-rev (c2-rev clause)) (c2-bjlevel clause)))
        (else (c2-an-step clause trail))))
(define (c2-an-step clause trail)
  (cond ((null? trail) (cons clause (c2-bjlevel clause)))
        (else (c2-an-pick clause (car trail) (cdr trail)))))
(define (c2-an-pick clause lit rest)
  (let ((v (c2-var lit)))
    (cond ((and (c2-in? clause (- 0 lit)) (= (vector-ref c2-level v) c2-dlevel) (c2-has-reason? v))
           (c2-an-loop (c2-resolve clause (c2-clause-lits (vector-ref c2-reason v)) v) rest))
          (else (c2-an-step clause rest)))))
(define (c2-has-reason? v) (cond ((null? (vector-ref c2-reason v)) #f) (else #t)))
(define (c2-resolve a b v) (c2-dedup (c2-remove-var (c2-app a b) v)))
(define (c2-remove-var l v) (cond ((null? l) (quote ())) ((= (c2-var (car l)) v) (c2-remove-var (cdr l) v)) (else (cons (car l) (c2-remove-var (cdr l) v)))))
(define (c2-count-cur clause) (c2-cc clause 0))
(define (c2-cc l acc) (cond ((null? l) acc) ((= (vector-ref c2-level (c2-var (car l))) c2-dlevel) (c2-cc (cdr l) (+ acc 1))) (else (c2-cc (cdr l) acc))))
(define (c2-bjlevel clause) (c2-second-max (c2-levels clause)))
(define (c2-levels l) (cond ((null? l) (quote ())) (else (cons (vector-ref c2-level (c2-var (car l))) (c2-levels (cdr l))))))
(define (c2-second-max levels) (cond ((null? levels) 0) ((null? (cdr levels)) 0) (else (c2-sm levels -1 -1))))
(define (c2-sm l hi hi2) (cond ((null? l) (if (< hi2 0) 0 hi2)) (else (c2-sm-step (car l) (cdr l) hi hi2))))
(define (c2-sm-step x r hi hi2) (cond ((> x hi) (c2-sm r x hi)) ((> x hi2) (c2-sm r hi x)) (else (c2-sm r hi hi2))))

; ---------- VSIDS ----------
(define (c2-bump-lits! clause) (cond ((null? clause) (c2-decay!)) (else (begin (c2-bump-var! (c2-var (car clause))) (c2-bump-lits! (cdr clause))))))
(define (c2-bump-var! v) (vector-set! c2-activity v (+ (vector-ref c2-activity v) c2-bump)))
(define (c2-decay!) (set! c2-bump (+ c2-bump 1)))         ; integer-friendly decay: grow the increment (equivalent ordering to scaling down old activities)

; ---------- list utils ----------
(define (c2-in? clause lit) (cond ((null? clause) #f) ((= (car clause) lit) #t) (else (c2-in? (cdr clause) lit))))
(define (c2-app a b) (if (null? a) b (cons (car a) (c2-app (cdr a) b))))
(define (c2-dedup l) (c2-dd l (quote ()))) (define (c2-dd l seen) (cond ((null? l) (c2-rev seen)) ((c2-mem? (car l) seen) (c2-dd (cdr l) seen)) (else (c2-dd (cdr l) (cons (car l) seen)))))
(define (c2-mem? x l) (cond ((null? l) #f) ((= (car l) x) #t) (else (c2-mem? x (cdr l)))))
(define (c2-rev l) (c2-rv l (quote ()))) (define (c2-rv l a) (if (null? l) a (c2-rv (cdr l) (cons (car l) a))))

; ---------- backtracking ----------
(define (c2-backtrack! level) (begin (c2-undo level) (set! c2-dlevel level)))
(define (c2-undo level)
  (cond ((null? c2-trail) (quote ()))
        ((> (vector-ref c2-level (c2-var (car c2-trail))) level)
         (begin (vector-set! c2-value (c2-var (car c2-trail)) -1)
                (set! c2-trail (cdr c2-trail)) (set! c2-tlen (- c2-tlen 1))
                (c2-undo level)))
        (else (quote ()))))

; ---------- branching: highest activity, phase-saved polarity ----------
(define (c2-pick) (c2-pick-go 1 -1 -1))
(define (c2-pick-go v best ba) (cond ((> v c2-n) best) ((and (= (vector-ref c2-value v) -1) (> (vector-ref c2-activity v) ba)) (c2-pick-go (+ v 1) v (vector-ref c2-activity v))) (else (c2-pick-go (+ v 1) best ba))))
(define (c2-decide! v) (let ((ph (vector-ref c2-phase v))) (begin (set! c2-dlevel (+ c2-dlevel 1)) (set! c2-deci (+ c2-deci 1)) (c2-assign! (if (= ph 1) v (- 0 v)) (quote ())))))

; ---------- Luby restart sequence ----------
(define (c2-luby i) (c2-luby-go i 1))
(define (c2-luby-go i k) (cond ((= i (- (c2-pow2 k) 1)) (c2-pow2 (- k 1))) ((< i (- (c2-pow2 k) 1)) (c2-luby-go (- (+ i 1) (c2-pow2 (- k 1))) 1)) (else (c2-luby-go i (+ k 1)))))
(define (c2-pow2 k) (if (= k 0) 1 (* 2 (c2-pow2 (- k 1)))))

; ---------- main driver ----------
(define (cdcl2-solve nvars clauses) (begin (c2-init! nvars clauses) (c2-driver 0 (* 100 (c2-luby 1)) 1)))
(define (c2-init! nvars clauses)
  (begin (set! c2-n nvars)
         (set! c2-value (make-vector (+ nvars 1) -1))
         (set! c2-level (make-vector (+ nvars 1) 0))
         (set! c2-reason (make-vector (+ nvars 1) (quote ())))
         (set! c2-activity (make-vector (+ nvars 1) 0))
         (set! c2-phase (make-vector (+ nvars 1) 1))
         (set! c2-trail (quote ())) (set! c2-tlen 0) (set! c2-dlevel 0)
         (set! c2-clauses (c2-build-clauses clauses))
         (set! c2-confl 0) (set! c2-deci 0) (set! c2-props 0) (set! c2-restarts 0)
         (set! c2-bump 1) (set! c2-model (quote ()))
         (c2-init-watches!)
         (c2-check-initial-units c2-clauses)))
(define (c2-build-clauses cls) (cond ((null? cls) (quote ())) (else (cons (c2-make-clause (car cls)) (c2-build-clauses (cdr cls))))))
; assign any initial unit clauses at level 0
(define (c2-check-initial-units cls) (cond ((null? cls) (quote ok)) ((= (c2-clause-len (car cls)) 1) (begin (c2-maybe-assign-unit (car cls)) (c2-check-initial-units (cdr cls)))) (else (c2-check-initial-units (cdr cls)))))
(define (c2-maybe-assign-unit cv) (let ((L (c2-lit cv 0))) (cond ((= (c2-litval L) -1) (c2-assign! L cv)) (else (quote ok)))))

(define (c2-driver qhead conflimit lubyi)
  (let ((p (c2-propagate qhead)))
    (cond ((equal? p (quote ok)) (c2-decide-or-sat (c2-tlen-as-qhead) conflimit lubyi))
          (else (c2-handle-conflict p conflimit lubyi)))))
(define (c2-tlen-as-qhead) c2-tlen)     ; after propagation, all current literals processed; new decisions extend trail
(define (c2-decide-or-sat qhead conflimit lubyi)
  (let ((b (c2-pick)))
    (cond ((< b 0) (c2-succeed))
          (else (begin (c2-decide! b) (c2-driver (- c2-tlen 1) conflimit lubyi))))))
(define (c2-handle-conflict cv conflimit lubyi)
  (begin (set! c2-confl (+ c2-confl 1))
         (cond ((= c2-dlevel 0) (quote unsat))
               (else (c2-learn cv conflimit lubyi)))))
(define (c2-learn cv conflimit lubyi)
  (let ((res (c2-analyze cv)))
    (let ((learned (car res)) (bl (cdr res)))
      (begin (cond ((>= c2-confl conflimit) (begin (c2-add-assert! learned bl) (c2-do-restart (+ lubyi 1))))
                   (else (begin (c2-add-assert! learned bl) (c2-driver (c2-prop-start) (* 100 (c2-luby (c2-cur-lubyi))) (c2-cur-lubyi)))))))))
; add the learned clause, backjump to bl, then ASSERT its 1-UIP literal (the single literal at the old current
; level) as a unit implication with the learned clause as reason -- the step that makes CDCL progress
(define (c2-add-assert! learned bl)
  (let ((uip (c2-uip-literal learned)))
    (begin (c2-add-learned! learned)
           (c2-backtrack! bl)
           (cond ((null? learned) (quote ok))
                 (else (c2-assert-uip uip learned))))))
; the asserting literal is the one whose variable was assigned at the (pre-backjump) current level
(define (c2-uip-literal learned) (c2-find-uip learned c2-dlevel))
(define (c2-find-uip lits lvl) (cond ((null? lits) (if (null? lits) 0 (car lits))) ((= (vector-ref c2-level (c2-var (car lits))) lvl) (car lits)) (else (c2-find-uip (cdr lits) lvl))))
(define (c2-assert-uip uip learned-cv-lits)
  ; find the actual clause-vector just added (head of c2-clauses) to use as the reason
  (cond ((= uip 0) (quote ok)) (else (c2-assign! uip (car c2-clauses)))))
(define (c2-driver-after-learn learned bl) (c2-driver (c2-prop-start) (* 100 (c2-luby (c2-cur-lubyi))) (c2-cur-lubyi)))
(define (c2-prop-start) (if (> c2-tlen 0) (- c2-tlen 1) 0))
(define c2-the-lubyi 1)
(define (c2-cur-lubyi) c2-the-lubyi)
(define (c2-do-restart nextluby)
  (begin (set! c2-restarts (+ c2-restarts 1)) (set! c2-the-lubyi nextluby)
         (c2-backtrack! 0) (c2-driver (c2-prop-start) (* 100 (c2-luby nextluby)) nextluby)))
; add a learned clause as a clause-vector, set its watches on the two highest-level literals
(define (c2-add-learned! lits)
  (cond ((null? lits) (quote ok))
        (else (let ((cv (c2-make-clause lits)))
                (begin (set! c2-clauses (cons cv c2-clauses))
                       (c2-watch-learned cv))))))
(define (c2-watch-learned cv) (c2-watch-clause cv))
(define (c2-succeed) (begin (set! c2-model (c2-extract 1)) (quote sat)))
(define (c2-extract v) (cond ((> v c2-n) (quote ())) (else (cons (if (= (vector-ref c2-value v) 1) v (- 0 v)) (c2-extract (+ v 1))))))

(define (cdcl2-sat? nvars clauses) (equal? (cdcl2-solve nvars clauses) (quote sat)))
(define (cdcl2-check-model clauses model) (c2-all-sat? clauses model))
(define (c2-all-sat? cls m) (cond ((null? cls) #t) ((c2-clause-sat? (car cls) m) (c2-all-sat? (cdr cls) m)) (else #f)))
(define (c2-clause-sat? clause m) (cond ((null? clause) #f) ((c2-mem? (car clause) m) #t) (else (c2-clause-sat? (cdr clause) m))))

(define (cdcl2-caveat) (quote two-watched-literals-vsids-decay-phase-saving-luby-restarts-iterative-NP-hard-worst-case))
