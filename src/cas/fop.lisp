; -*- lisp -*-
; src/cas/fop.lisp -- a FIRST-ORDER RESOLUTION theorem prover: full clausal first-order logic with binary
; resolution and factoring, proving theorems by refutation through a given-clause saturation loop.  This is the
; Robinson (1965) resolution calculus -- the foundation that the superposition-based provers (Vampire, E, SPASS)
; generalize with equality reasoning and term orderings.  It is a genuine step beyond the Horn/SLD engine in
; logic.lisp (which handles only definite clauses): here a clause is an arbitrary disjunction of positive AND
; negative literals, and the prover searches for a refutation of the axioms together with the negated goal.
;
; Honest scope.  First-order validity is only SEMI-decidable (Church-Turing): no prover, this one or Vampire, can
; always decide a first-order formula -- a search may run forever on a non-theorem.  fop is therefore a proof
; SEARCH, bounded here by a clause limit so it terminates with 'proved, 'unknown (limit reached), or 'saturated (no
; new clauses derivable -- a genuine countermodel exists).  It is NOT competitive in speed with the mature provers,
; which are decades-tuned C++ with superposition, sophisticated literal selection, indexing, and redundancy
; machinery; fop implements the same KIND of reasoning -- resolution refutation -- in a small, verifiable core, the
; honest miniature of what those systems are, with equality (paramodulation/superposition) and term orderings as the
; natural next layer.
;
; The calculus.
;   * A LITERAL is (sign . atom): sign +1 (positive) or -1 (negated), atom an (lvar/term) structure (pred t...).
;   * A CLAUSE is a list of literals, read as their disjunction; the empty clause () is false (a refutation).
;   * BINARY RESOLUTION: given clauses C and D (renamed apart), a positive literal of one and a negative literal of
;     the other whose atoms UNIFY produce the resolvent (C without the literal) ++ (D without the literal), with the
;     unifier applied -- the core inference.
;   * FACTORING: if two literals of the same clause (same sign) unify, the clause collapses them, a necessary
;     companion to resolution for completeness.
;   * The GIVEN-CLAUSE LOOP (saturation): maintain a set of processed clauses and a set of unprocessed ones; pick an
;     unprocessed "given" clause, resolve/factor it against all processed clauses, add the new clauses, and repeat;
;     deriving the empty clause is a refutation, exhausting the unprocessed set without it is saturation.
;   * Refutation soundness: to prove that goal G follows from axioms A, we run saturation on A together with the
;     clausal negation of G; the empty clause certifies A and not-G are jointly unsatisfiable, i.e. A entails G.
;
; Public:
;   fop-prove axioms neg-goal-clauses  -> 'proved / 'saturated / 'unknown ; clauses in surface form
;   fop-resolve c d                     -> the list of binary resolvents of two clauses
;   fop-factor c                        -> the factors of a clause
;   fop-refute clauses                  -> run saturation on a clause set, seeking the empty clause
;   fop-clause surface                  -> parse a surface clause (list of (+ atom)/(- atom)) into internal form
;
; SURFACE SYNTAX.  A clause is a list of literals; a literal is (+ (pred arg...)) or (- (pred arg...)); variables are
; ?-prefixed symbols (as in logic.lisp).  Builds on logic.lisp (unify / walk / parse-term / lvar).

(import "logic.lisp")

(define (fp-len l) (if (null? l) 0 (+ 1 (fp-len (cdr l)))))
(define (fp-app a b) (if (null? a) b (cons (car a) (fp-app (cdr a) b))))
(define (fp-rev l) (fp-rv l (quote ()))) (define (fp-rv l a) (if (null? l) a (fp-rv (cdr l) (cons (car l) a))))
(define (fp-map f l) (if (null? l) (quote ()) (cons (f (car l)) (fp-map f (cdr l)))))

; ---------- literals & clauses (internal form) ----------
(define (fp-sign lit) (car lit))
(define (fp-atom lit) (cdr lit))
(define (fp-mk sign atom) (cons sign atom))
(define (fp-opp? a b) (and (not (= (fp-sign a) (fp-sign b)))))   ; opposite signs
; parse a surface clause into internal literals (atoms parsed by logic.lisp's parse-term)
(define (fop-clause surface) (fp-map fp-parse-lit surface))
(define (fp-parse-lit slit)
  (let ((s (car slit)) (atom (car (cdr slit))))
    (fp-mk (if (equal? s (quote +)) 1 -1) (parse-term atom))))

; ---------- variable renaming: append a tag to every variable name in a clause ----------
(define fp-rename-counter 0)
(define (fp-rename-clause c) (begin (set! fp-rename-counter (+ fp-rename-counter 1)) (fp-map (lambda (lit) (fp-rename-lit lit fp-rename-counter)) c)))
(define (fp-rename-lit lit tag) (fp-mk (fp-sign lit) (fp-rename-term (fp-atom lit) tag)))
(define (fp-rename-term t tag)
  (cond ((lvar? t) (lvar (fp-tagname (lvar-name t) tag)))
        ((pair? t) (cons (fp-rename-term (car t) tag) (fp-rename-term (cdr t) tag)))
        (else t)))
(define (fp-tagname name tag) (string->symbol (string-append (fp-symstr name) (string-append "_" (fp-numstr tag)))))
(define (fp-symstr s) (cond ((symbol? s) (symbol->string s)) (else s)))
(define (fp-numstr n) (number->string n))

; ---------- apply a substitution throughout a clause ----------
(define (fp-subst-clause c subst) (fp-map (lambda (lit) (fp-subst-lit lit subst)) c))
(define (fp-subst-lit lit subst) (fp-mk (fp-sign lit) (fp-deepwalk (fp-atom lit) subst)))
(define (fp-deepwalk t subst)
  (let ((w (walk t subst)))
    (cond ((pair? w) (cons (fp-deepwalk (car w) subst) (fp-deepwalk (cdr w) subst)))
          (else w))))

; ---------- binary resolution of two clauses ----------
; rename both apart, then for every opposite-sign literal pair with unifiable atoms, emit the resolvent
(define (fop-resolve c d)
  (let ((c2 (fp-rename-clause c)) (d2 (fp-rename-clause d)))
    (fp-res-pairs c2 d2)))
(define (fp-res-pairs c d) (fp-res-outer c d c))
(define (fp-res-outer cfull dfull crem)
  (cond ((null? crem) (quote ()))
        (else (fp-app (fp-res-inner cfull dfull (car crem) dfull) (fp-res-outer cfull dfull (cdr crem))))))
(define (fp-res-inner cfull dfull lit drem)
  (cond ((null? drem) (quote ()))
        (else (fp-res-try cfull dfull lit (car drem) drem))))
(define (fp-res-try cfull dfull lit mlit drem)
  (cond ((fp-opp? lit mlit)
         (let ((s (unify (fp-atom lit) (fp-atom mlit) (subst-empty))))
           (cond ((equal? s (quote fail)) (fp-res-inner cfull dfull lit (cdr drem)))
                 (else (cons (fp-make-resolvent cfull dfull lit mlit s) (fp-res-inner cfull dfull lit (cdr drem)))))))
        (else (fp-res-inner cfull dfull lit (cdr drem)))))
(define (fp-make-resolvent cfull dfull lit mlit subst)
  (fp-dedup-lits (fp-subst-clause (fp-app (fp-remove-lit cfull lit) (fp-remove-lit dfull mlit)) subst)))
(define (fp-remove-lit clause lit) (cond ((null? clause) (quote ())) ((fp-lit-eq? (car clause) lit) (fp-remove-lit (cdr clause) lit)) (else (cons (car clause) (fp-remove-lit (cdr clause) lit)))))
(define (fp-lit-eq? a b) (and (= (fp-sign a) (fp-sign b)) (equal? (fp-atom a) (fp-atom b))))

; ---------- factoring: unify two same-sign literals, collapse ----------
(define (fop-factor c) (fp-factor-outer c c))
(define (fp-factor-outer cfull crem)
  (cond ((null? crem) (quote ()))
        ((null? (cdr crem)) (quote ()))
        (else (fp-app (fp-factor-inner cfull (car crem) (cdr crem)) (fp-factor-outer cfull (cdr crem))))))
(define (fp-factor-inner cfull lit rest)
  (cond ((null? rest) (quote ()))
        ((and (= (fp-sign lit) (fp-sign (car rest))) (not (equal? (unify (fp-atom lit) (fp-atom (car rest)) (subst-empty)) (quote fail))))
         (cons (fp-dedup-lits (fp-subst-clause cfull (unify (fp-atom lit) (fp-atom (car rest)) (subst-empty)))) (fp-factor-inner cfull lit (cdr rest))))
        (else (fp-factor-inner cfull lit (cdr rest)))))

; ---------- clause utilities ----------
(define (fp-dedup-lits c) (fp-dd c (quote ())))
(define (fp-dd c seen) (cond ((null? c) (fp-rev seen)) ((fp-lit-member? (car c) seen) (fp-dd (cdr c) seen)) (else (fp-dd (cdr c) (cons (car c) seen)))))
(define (fp-lit-member? lit l) (cond ((null? l) #f) ((fp-lit-eq? lit (car l)) #t) (else (fp-lit-member? lit (cdr l)))))
(define (fp-empty? c) (null? c))
(define (fp-tautology? c) (fp-taut-go c c))
(define (fp-taut-go full rem) (cond ((null? rem) #f) ((fp-has-complement? (car rem) full) #t) (else (fp-taut-go full (cdr rem)))))
(define (fp-has-complement? lit c) (cond ((null? c) #f) ((and (fp-opp? lit (car c)) (equal? (fp-atom lit) (fp-atom (car c)))) #t) (else (fp-has-complement? lit (cdr c)))))
; clause equality up to literal set (cheap subsumption proxy: identical literal sets)
(define (fp-clause-eq? a b) (and (fp-subset? a b) (fp-subset? b a)))
(define (fp-subset? a b) (cond ((null? a) #t) ((fp-lit-member? (car a) b) (fp-subset? (cdr a) b)) (else #f)))
(define (fp-member-clause? c set) (cond ((null? set) #f) ((fp-clause-eq? c (car set)) #t) (else (fp-member-clause? c (cdr set)))))

; ---------- the given-clause saturation loop ----------
; process: list of clauses already used; unprocessed: queue; bound: max iterations
(define (fop-refute clauses) (fp-saturate (quote ()) (fp-clean-initial clauses) 60))
(define (fp-clean-initial cls) (cond ((null? cls) (quote ())) ((fp-tautology? (car cls)) (fp-clean-initial (cdr cls))) (else (cons (car cls) (fp-clean-initial (cdr cls))))))
(define (fp-saturate processed unprocessed bound)
  (cond ((<= bound 0) (quote unknown))
        ((null? unprocessed) (quote saturated))
        ((fp-empty? (car unprocessed)) (quote proved))
        (else (fp-sat-step processed (car unprocessed) (cdr unprocessed) bound))))
(define (fp-sat-step processed given rest bound)
  ; resolve & factor `given` against all processed clauses (and itself), collect new clauses
  (let ((new (fp-all-new given processed)))
    (let ((fresh (fp-filter-fresh new (cons given processed) rest)))
      (cond ((fp-any-empty? fresh) (quote proved))
            (else (fp-saturate (cons given processed) (fp-app rest fresh) (- bound 1)))))))
(define (fp-all-new given processed) (fp-app (fop-factor given) (fp-all-resolve given (cons given processed))))
(define (fp-all-resolve given clauses) (cond ((null? clauses) (quote ())) (else (fp-app (fop-resolve given (car clauses)) (fp-all-resolve given (cdr clauses))))))
(define (fp-any-empty? cls) (cond ((null? cls) #f) ((fp-empty? (car cls)) #t) (else (fp-any-empty? (cdr cls)))))
; keep only non-tautological clauses not already present
(define (fp-filter-fresh new known queue) (cond ((null? new) (quote ())) ((fp-keep? (car new) known queue) (cons (car new) (fp-filter-fresh (cdr new) known queue))) (else (fp-filter-fresh (cdr new) known queue))))
(define (fp-keep? c known queue) (and (not (fp-tautology? c)) (not (fp-member-clause? c known)) (not (fp-member-clause? c queue))))

; ---------- top-level prover: axioms + negated goal -> refutation ----------
(define (fop-prove axiom-surfaces neg-goal-surfaces)
  (fop-refute (fp-app (fp-map fop-clause axiom-surfaces) (fp-map fop-clause neg-goal-surfaces))))

(define (fop-caveat) (quote first-order-resolution-refutation-saturation-semi-decidable-bounded-search-miniature-of-superposition-provers))
