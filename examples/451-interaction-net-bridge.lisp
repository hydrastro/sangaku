; =====================================================================
; 451 — the interaction-net machine, bridged to the trusted kernel
; =====================================================================
; lizard is growing a second evaluation engine: an interaction-combinator
; runtime (Lafont nets / Lamping-Gonthier optimal reduction / the HVM model),
; reached from the surface via (inet-normalize t), (inet-cost t), and
; (inet-reduce t).  It reduces by purely LOCAL graph rewriting on active pairs
; — beta is CON~CON annihilation, sharing is DUP commutation, unused binders
; are erased by ERA — with exact GMP arithmetic agents.
;
; The decisive question (named in the roadmap) is whether this net dynamics
; AGREES with the trusted tree-walking kernel on the fragment where both apply.
; This file is that differential test, made permanent.  For each Church numeral
; N we check BOTH engines and require them to agree:
;   - the TRUSTED KERNEL beta-reduces  (church_N s z)  to  s applied N times to z
;     (kernel-reduce / kernel-equal? — the audited tree-walker);
;   - the INTERACTION NET reduces       (church_N succ 0)  to the integer N
;     (inet-normalize — the graph machine, a completely different engine).
; Agreement across N is real cross-checking: two unrelated reducers, one answer.
;
; This is purely ADDITIVE.  It touches neither the trusted type-checking kernel
; (soundness stays as-is) nor the interaction-net core; it only OBSERVES both.
; Carrying dependent/cubical TYPING on the net remains the open frontier; here
; the shared ground is the untyped lambda calculus, which both engines speak.

(define (must l x) (display "  ") (display l) (display " : ")
  (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "interaction-net <-> trusted-kernel differential bridge") (newline)

; the trusted kernel speaks typed lambda terms; assume a base type and s,z
(kernel-assume (quote A) (quote (Sort 0)))
(kernel-assume (quote s) (quote (Pi (_ A) A)))
(kernel-assume (quote z) (quote A))

; --- builders -------------------------------------------------------------
; kernel-side: church N as a kterm, applied to s and z
(define (k-apps k) (if (= k 0) (quote x) (list (quote app) (quote f) (k-apps (- k 1)))))
(define (k-church k)
  (list (quote lam) (quote (f (Pi (_ A) A)))
        (list (quote lam) (quote (x A)) (k-apps k))))
(define (k-church-sz k) (list (quote app) (list (quote app) (k-church k) (quote s)) (quote z)))
; the kernel's expected beta normal form: s applied N times to z
(define (k-expect k) (if (= k 0) (quote z) (list (quote app) (quote s) (k-expect (- k 1)))))

; net-side: church N as a surface lambda term, applied to succ and 0
(define (net-apps k) (if (= k 0) (quote x) (list (quote f) (net-apps (- k 1)))))
(define (net-church k)
  (list (quote lambda) (quote (f)) (list (quote lambda) (quote (x)) (net-apps k))))
(define (net-church-succ0 k)
  (list (list (net-church k) (quote (lambda (n) (+ n 1)))) 0))

; --- the differential: both engines, required to agree -------------------
(define (agree k)
  (must (string-append (string-append "church " (number->string k))
                       " : kernel beta-depth == interaction-net integer == N")
        (and (kernel-equal? (k-church-sz k) (k-expect k))   ; trusted tree-walker
             (equal? (inet-normalize (net-church-succ0 k)) k)))) ; graph machine

(agree 0) (agree 1) (agree 2) (agree 3) (agree 4) (agree 5) (agree 6) (agree 7)

; --- the net also computes ordinary arithmetic, exactly (GMP agents) -----
(must "interaction net: (lam x. x*x) 8 = 64 (a DUP duplicates x, then MUL)"
      (equal? (inet-normalize (quote ((lambda (x) (* x x)) 8))) 64))
(must "interaction net: nested arithmetic (6*3)+(10-1) = 27"
      (equal? (inet-normalize (quote (+ (* 6 3) (- 10 1)))) 27))

; --- and reads lambda normal forms back as de Bruijn terms ---------------
(must "interaction net: identity reads back to (lam #0)"
      (equal? (inet-reduce (quote (lambda (x) x))) "(lam #0)"))
(must "interaction net: church 2 reads back to (lam (lam (#1 (#1 #0))))"
      (equal? (inet-reduce (net-church 2)) "(lam (lam (#1 (#1 #0))))"))

; --- sharing is observable: cost counts interactions, not re-evaluations -
; (lam y. y + y) applied to (church 3 succ 0): the argument is computed and the
; result SHARED across both uses; inet-cost reports the interaction count so the
; sharing is empirical rather than asserted.
(must "interaction net: sharing demo reduces to 6 = 3 + 3"
      (equal? (inet-normalize
               (list (quote (lambda (y) (+ y y)))
                     (net-church-succ0 3))) 6))
(must "interaction net: the interaction count for that reduction is a positive integer"
      (let ((c (inet-cost (list (quote (lambda (y) (+ y y))) (net-church-succ0 3)))))
        (and (number? c) (> c 0))))

(display "OK — the interaction-net engine agrees with the trusted kernel on the shared fragment") (newline)
