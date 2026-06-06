; TRUE minimal SOLUTION-FORMULA construction for parametric quantifier elimination -- the second phase of
; minimization that mere merging (cadqesimp) skips, and the genuinely hard core of Brown's
; solution-formula-construction problem (docs/CAS.md).  Given the realizable sign-cells on which the eliminated
; statement is true and those on which it is false (every other sign pattern being geometrically unrealizable, hence
; a don't-care), cadqemin computes a MINIMAL cover of the true cells by prime implicants: generalize each true cell
; to a prime (a maximal cube covering no false cell), then select a smallest covering subset (essential primes plus
; greedy).  On the general quadratic this returns the textbook three-branch law.
(import "cas/cadqemin.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Minimal solution formulas by prime-implicant cover with don't-cares.") (newline) (newline)

; the four projection factors of the general quadratic: a, b, c, and the discriminant b^2 - 4 a c
(define factors (list (list (list 1 1 0 0)) (list (list 1 0 1 0)) (list (list 1 0 0 1)) (list (list 1 0 2 0) (list -4 1 0 1))))

; the complete realizable true / false partition of the sign-cells for exists x . a x^2 + b x + c = 0, per the
; general-quadratic law (a != 0 and disc >= 0) or (a = 0 and (b != 0 or c = 0))
(define (law sa sb sc sd) (cond ((not (= sa 0)) (if (= sd 1) #t (= sd 0))) (else (if (not (= sb 0)) #t (= sc 0)))))
(define (all-patterns m) (if (= m 0) (list (quote ())) (pre-each (list 1 0 -1) (all-patterns (- m 1)))))
(define (pre-each sgns rest) (if (null? sgns) (quote ()) (app (pre1 (car sgns) rest) (pre-each (cdr sgns) rest))))
(define (pre1 s rest) (if (null? rest) (quote ()) (cons (cons s (car rest)) (pre1 s (cdr rest)))))
(define (app a b) (if (null? a) b (cons (car a) (app (cdr a) b))))
(define (cadr l) (car (cdr l))) (define (caddr l) (car (cdr (cdr l)))) (define (cadddr l) (car (cdr (cdr (cdr l)))))
(define (split ps ts fs) (cond ((null? ps) (list ts fs)) ((law (car (car ps)) (cadr (car ps)) (caddr (car ps)) (cadddr (car ps))) (split (cdr ps) (cons (car ps) ts) fs)) (else (split (cdr ps) ts (cons (car ps) fs)))))
(define sp (split (all-patterns 4) (quote ()) (quote ())))
(define trues (car sp)) (define falses (cadr sp))

(define cover (cadqemin-cover trues falses))
(must "the minimal cover of the general quadratic has exactly three branches"
  (= (length cover) 3))

; soundness: every cube of the cover must cover no false cell
(define (covers cube v) (cond ((null? cube) #t) ((cadqemin-adm (car cube) (car v)) (covers (cdr cube) (cdr v))) (else #f)))
(define (no-false cube fs) (cond ((null? fs) #t) ((covers cube (car fs)) #f) (else (no-false cube (cdr fs)))))
(define (all-sound cubes fs) (cond ((null? cubes) #t) ((no-false (car cubes) fs) (all-sound (cdr cubes) fs)) (else #f)))
(must "every branch is sound (covers no false cell)"
  (all-sound cover falses))

; completeness: every true cell is covered by some branch
(define (any-covers cubes v) (cond ((null? cubes) #f) ((covers (car cubes) v) #t) (else (any-covers (cdr cubes) v))))
(define (all-covered ts cubes) (cond ((null? ts) #t) ((any-covers cubes (car ts)) (all-covered (cdr ts) cubes)) (else #f)))
(must "every true cell is covered (the cover is complete)"
  (all-covered trues cover))

; the rendered formula is the textbook three-branch law
(must "the rendered formula is the three-branch general-quadratic law"
  (equal? (cadqemin-minimize factors trues falses)
    (quote (or (and (neq (poly (1 1 0 0)) 0) (>= (poly (1 0 2 0) (-4 1 0 1)) 0))
               (and (= (poly (1 1 0 0)) 0) (neq (poly (1 0 1 0)) 0))
               (and (= (poly (1 1 0 0)) 0) (= (poly (1 0 0 1)) 0))))))

(must "the EXACT branch-and-bound minimum cover also has three branches (greedy was optimal here)"
  (= (length (cadqemin-cover-exact trues falses)) 3))
(must "the exact minimizer renders the same three-branch law"
  (equal? (cadqemin-minimize-exact factors trues falses) (cadqemin-minimize factors trues falses)))

(newline)
(display "The cover is exactly (a != 0 and b^2 - 4 a c >= 0) or (a = 0 and b != 0) or (a = 0 and c = 0) -- the") (newline)
(display "canonical three-branch solution formula.  The cover step is essential-prime plus greedy: exact on the") (newline)
(display "standard examples, sound and complete always; exact minimum cover in general is NP-hard (cadqemin-caveat).") (newline)
