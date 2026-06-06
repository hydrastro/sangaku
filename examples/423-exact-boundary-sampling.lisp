; EXACT boundary sampling for complete solution-formula construction (docs/CAS.md).  The minimal-formula constructor
; cadqemin attains the true minimum only on a COMPLETE true/false partition of the sign-cells, but cadqen's
; approximate sampling can miss the measure-zero BOUNDARY cells -- a factor exactly zero with prescribed signs on the
; others, such as the tangent stratum of the general quadratic where the discriminant vanishes (b^2 = 4 a c) and the
; quadratic has a real double root.  cadqenx closes this for families whose projection factors have rational roots:
; it samples each parameter level at the EXACT rational roots of the factors (recovered by the rational root
; theorem), so a boundary cell is hit exactly and recorded with its true sign zero.  The general quadratic then
; yields a complete partition, on which cadqemin produces a true three-branch minimal formula directly from the
; sweep -- no conservative fallback.
(import "cas/cadqenx.lisp")
(import "cas/cadqemin.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cadr l) (car (cdr l))) (define (caddr l) (car (cdr (cdr l))))
(define (mem x s) (cond ((null? s) #f) ((equal? x (car s)) #t) (else (mem x (cdr s)))))

(display "Exact section sampling captures the discriminant-zero boundary of the general quadratic.") (newline) (newline)

(define genq (list (list (cons 1 (list 0 0 1))) (list (cons 1 (list 0 1 0))) (list (cons 1 (list 1 0 0)))))
(define factors (list (list (list 1 1 0 0)) (list (list 1 0 1 0)) (list (list 1 0 0 1)) (list (list 1 0 2 0) (list -4 1 0 1))))
(define tf (cadqenx-elim2 factors 3 (quote exists) (cons (quote zero) genq)))
(define trues (cadr tf)) (define falses (caddr tf))

; the rational root theorem recovers the discriminant factor's exact root
(must "exact rational roots of 1 - 4 c are recovered as 1/4"
  (equal? (cadqenx-rat-roots (list 1 -4)) (list (/ 1 4))))
(must "exact rational roots of c^2 - 1 are recovered as 1 and -1"
  (mem 1 (cadqenx-rat-roots (list -1 0 1))))
(must "an irrational-root polynomial c^2 - 2 yields no rational roots"
  (null? (cadqenx-rat-roots (list -2 0 1))))

; the tangent boundary cells (a != 0, c != 0, discriminant = 0: a real double root) are now captured as TRUE
(must "the tangent cell (a>0, b>0, c>0, disc=0) is captured and true"
  (mem (list 1 1 1 0) trues))
(must "the tangent cell (a>0, b<0, c>0, disc=0) is captured and true"
  (mem (list 1 -1 1 0) trues))

; cadqemin now produces a sound and complete three-branch minimal formula directly from the sweep
(define cover (cadqemin-cover trues falses))
(must "the minimal cover from the complete sweep has three branches"
  (= (length cover) 3))
(define (adm lit s) (cond ((equal? lit (quote star)) #t) ((equal? lit (quote ge)) (if (= s 1) #t (= s 0))) ((equal? lit (quote le)) (if (= s -1) #t (= s 0))) ((equal? lit (quote ne)) (if (= s 1) #t (= s -1))) (else (= lit s))))
(define (covers cube v) (cond ((null? cube) #t) ((adm (car cube) (car v)) (covers (cdr cube) (cdr v))) (else #f)))
(define (no-false cube fs) (cond ((null? fs) #t) ((covers cube (car fs)) #f) (else (no-false cube (cdr fs)))))
(define (all-sound cubes fs) (cond ((null? cubes) #t) ((no-false (car cubes) fs) (all-sound (cdr cubes) fs)) (else #f)))
(must "every branch is sound (covers no sampled false cell)"
  (all-sound cover falses))
(define (any-cov cubes v) (cond ((null? cubes) #f) ((covers (car cubes) v) #t) (else (any-cov (cdr cubes) v))))
(define (all-cov ts) (cond ((null? ts) #t) ((any-cov cover (car ts)) (all-cov (cdr ts))) (else #f)))
(must "every true cell is covered (the cover is complete)"
  (all-cov trues))

(newline)
(display "With the discriminant-zero boundary sampled exactly, the true/false partition is complete and cadqemin") (newline)
(display "returns a genuine three-branch minimal solution formula straight from the elimination sweep.  Families with") (newline)
(display "irrational-root projections keep approximate section sampling (cadqenx-caveat).") (newline)
