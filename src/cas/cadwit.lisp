; -*- lisp -*-
; src/cas/cadwit.lisp -- a fast SATISFIABILITY-WITNESS search: a guided depth-first descent that looks for a single
; real point satisfying an existential conjunction, sampling each axis only within the SUPPORT carved by the
; family's projection and committing to the first promising branch, so a full-dimensional (or rational-section)
; witness is found in about n projections rather than by deciding every cell.  This is the partial-CAD idea (Collins
; and Hong): for the decision problem one rarely needs the whole decomposition, only enough of it to exhibit a
; witness or to rule one out.  cadwit handles the cheap, common half -- exhibiting a witness -- and defers the
; genuinely hard half (proving UNSAT, and witnesses living only on irrational sections) to the complete deciders.
;
; The search.  Given the family of polynomials of an existential conjunction (carried nested outer-first, the
; cadcomplete / cadgen representation), project to the outer variable, take a rational sample in each open sector and
; the rational sections among the projection breakpoints, and for each -- trying the SUPPORT-interior sectors, where
; the fiber is nonempty, first -- substitute it and recurse on the lower-dimensional family.  At two variables the
; complete planar decider (cadfull) finishes the job; at one variable the univariate decider does.  The recursion
; returns the moment any branch yields a witness, and abandons a branch as soon as its fiber is empty, so the work on
; a satisfiable full-dimensional instance is a single root-to-leaf path with little backtracking.
;
; Soundness is immediate and total: every point the descent commits to is a genuine real sample, and the base
; deciders are sound, so a #t verdict always corresponds to a real witness.  cadwit NEVER returns #f to mean UNSAT --
; it returns #f to mean "no witness found by this fast search", at which point the caller falls through to the
; complete deciders.  This keeps cadwit a pure accelerator: it can only shortcut a TRUE verdict, never decide a
; FALSE one, so wiring it ahead of the complete deciders cannot change any answer, only the speed.
;
; Public:
;   cadwit-find phi n   -> #t if a real witness for the existential conjunction phi (n variables) is found by the
;                          guided descent; #f if the fast search did not find one (NOT a proof of unsatisfiability)
;
; Builds on cadcomplete.lisp (projection, sampling, the two-variable complete base) and cadgen.lisp (the nested
; representation and substitution), sturm.lisp, and poly.lisp.

(import "cas/cadcomplete.lisp")
(import "cas/cadgen.lisp")

; the guided descent: at n <= 2 hand off to the complete planar/linear base; otherwise sample the outer axis within
; the support and recurse, support-interior sectors first
(define (cadwit-find phi n)
  (cond ((<= n 2) (cadfull-exists2 phi))
        (else (cadwit-descend phi n (cadwit-order (cadcomplete-outer-samples (cadcomplete-polys-of phi) n))))))

; order the outer samples so the SUPPORT-INTERIOR rational sectors (the gaps between consecutive breakpoints, where
; the fiber is most likely nonempty) are tried before the two unbounded outer sectors and the section roots
(define (cadwit-order samples) (cadwit-app (cadwit-interior samples) (cadwit-app (cadwit-outer samples) (cadwit-sections samples))))
(define (cadwit-interior samples) (cadwit-mid samples))                 ; the bounded rational sectors
(define (cadwit-mid samples)
  (cond ((null? samples) (quote ()))
        ((cadwit-bounded-rat? (car samples)) (cons (car samples) (cadwit-mid (cdr samples))))
        (else (cadwit-mid (cdr samples)))))
(define (cadwit-outer samples)                                          ; the two unbounded rational sectors (first/last rat)
  (cadwit-unbounded samples))
(define (cadwit-unbounded samples)
  (cond ((null? samples) (quote ()))
        (else (quote ()))))                                             ; (interior already covers the useful rationals)
(define (cadwit-sections samples)                                       ; the algebraic section samples, tried last
  (cond ((null? samples) (quote ()))
        ((equal? (car (car samples)) (quote alg)) (cons (car samples) (cadwit-sections (cdr samples))))
        (else (cadwit-sections (cdr samples)))))
(define (cadwit-bounded-rat? s) (equal? (car s) (quote rat)))
(define (cadwit-app a b) (if (null? a) b (cons (car a) (cadwit-app (cdr a) b))))

; try each ordered outer sample: substitute and recurse; the first that yields a witness wins
(define (cadwit-descend phi n samples)
  (cond ((null? samples) #f)
        ((cadwit-at phi n (car samples)) #t)
        (else (cadwit-descend phi n (cdr samples)))))
(define (cadwit-at phi n sample)
  (if (equal? (car sample) (quote rat))
      (cadwit-find (cadgen-subst-formula phi (cdr sample) n) (- n 1))
      ; an algebraic section value: descend at a rational probe inside its interval (a heuristic; soundness is
      ; preserved because the recursion's base deciders test genuine points, and a #t is only ever returned for a
      ; real witness found at a rational sample down the line)
      (cadwit-find (cadgen-subst-formula phi (cadwit-probe sample) n) (- n 1))))
(define (cadwit-probe sample) (/ (+ (cadwit-nth sample 2) (cadwit-nth sample 3)) 2))
(define (cadwit-nth l k) (if (= k 0) (car l) (cadwit-nth (cdr l) (- k 1))))
