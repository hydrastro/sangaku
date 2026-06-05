; -*- lisp -*-
; lib/cas/dynsys.lisp — dynamical-systems primitives over Q, built on the
; multivariate-polynomial layer (groebner.lisp) and the exact linear algebra
; (linalg.lisp).
;
; A vector field is a list of multivariate polynomials F = (f_1 ... f_n) in nv
; variables (the state x_1..x_nv), using the groebner.lisp mpoly representation:
; a polynomial is a list of (coeff . exponent-vector) terms in descending lex
; order. This module adds what a dynamical-systems CAS needs and Sangaku did
; not yet have:
;
;   (mpoly-deriv p i)        partial derivative of p w.r.t. variable i (0-based)
;   (mpoly-eval-point p pt)  evaluate p at a rational point pt = (a_1 ... a_nv)
;   (vf-jacobian F nv)       Jacobian: an n-by-nv matrix of mpolys (d f_i/d x_j)
;   (jacobian-at F nv pt)    that Jacobian evaluated at pt -> rational matrix
;   (equilibrium? F nv pt)   #t iff every f_i(pt) = 0 (exact equilibrium test)
;   (equilibrium-eigenvalues F nv pt)  exact eigenvalues of the linearization
;
; Everything is exact (rational/algebraic). The eigenvalue step reuses
; linalg.lisp's mat-eigenvalues, so each spectrum is the exact set of roots of
; the characteristic polynomial of the Jacobian at the equilibrium.
;
; Self-contained over Q; depends on groebner.lisp and linalg.lisp.

(import "cas/groebner.lisp")
(import "cas/linalg.lisp")

; ---------- monomial / term helpers ----------
; exponent vectors are fixed-length lists over nv variables; nth-exp reads the
; i-th exponent, dec-exp decrements it (for d/dx_i).
(define (ds-nth l i) (if (= i 0) (car l) (ds-nth (cdr l) (- i 1))))
(define (ds-set l i v) (if (= i 0) (cons v (cdr l)) (cons (car l) (ds-set (cdr l) (- i 1) v))))

; partial derivative of a single term (coeff . mono) w.r.t. variable i:
;   d/dx_i [c * prod x_k^{e_k}] = (c*e_i) * x_i^{e_i-1} * prod_{k!=i} x_k^{e_k}
; returns '() (the zero polynomial's empty term list contribution) when e_i = 0.
(define (term-deriv t i)
  (let ((c (car t)) (m (cdr t)))
    (let ((ei (ds-nth m i)))
      (if (= ei 0)
          '()                                   ; derivative of a constant-in-x_i term is 0
          (list (cons (* c ei) (ds-set m i (- ei 1))))))))

; partial derivative of a multivariate polynomial w.r.t. variable i (0-based).
; Sum the per-term derivatives with mpoly-add so the result is normalized
; (descending lex, no zero coeffs, no repeated monomials).
(define (mpoly-deriv-go terms i acc)
  (if (null? terms)
      acc
      (mpoly-deriv-go (cdr terms) i (mpoly-add acc (term-deriv (car terms) i)))))
(define (mpoly-deriv p i) (mpoly-deriv-go p i '()))

; ---------- evaluation at a rational point ----------
; pt is (a_1 ... a_nv). Evaluate a monomial, a term, then a polynomial.
(define (pow-q base e) (if (= e 0) 1 (* base (pow-q base (- e 1)))))
(define (mono-eval m pt)
  (if (null? m) 1 (* (pow-q (car pt) (car m)) (mono-eval (cdr m) (cdr pt)))))
(define (term-eval t pt) (* (car t) (mono-eval (cdr t) pt)))
(define (mpoly-eval-point-go terms pt acc)
  (if (null? terms) acc (mpoly-eval-point-go (cdr terms) pt (+ acc (term-eval (car terms) pt)))))
(define (mpoly-eval-point p pt) (mpoly-eval-point-go p pt 0))

; ---------- the Jacobian of a vector field ----------
; row i is (d f_i/d x_0  d f_i/d x_1  ...  d f_i/d x_{nv-1}), each an mpoly.
(define (iota0 n) (if (= n 0) '() (append (iota0 (- n 1)) (list (- n 1)))))
(define (jac-row f nv) (map (lambda (j) (mpoly-deriv f j)) (iota0 nv)))
(define (vf-jacobian F nv) (map (lambda (f) (jac-row f nv)) F))

; the Jacobian evaluated at a point -> a matrix of rationals (linalg.lisp form:
; a list of rational rows), ready for mat-eigenvalues / mat-charpoly.
(define (jacobian-at F nv pt)
  (map (lambda (f) (map (lambda (j) (mpoly-eval-point (mpoly-deriv f j) pt)) (iota0 nv))) F))

; ---------- equilibrium test + eigenvalues at an equilibrium ----------
(define (all-zero? xs) (cond ((null? xs) #t) ((= (car xs) 0) (all-zero? (cdr xs))) (else #f)))
(define (equilibrium? F nv pt) (all-zero? (map (lambda (f) (mpoly-eval-point f pt)) F)))

; exact eigenvalues of the linearization at pt (reuses linalg.lisp). Returns the
; list of (descriptor multiplicity) eigenvalues; combine with the certificate
; checks in linalg.lisp as desired.
(define (equilibrium-eigenvalues F nv pt) (mat-eigenvalues (jacobian-at F nv pt)))
(define (equilibrium-charpoly F nv pt) (mat-charpoly (jacobian-at F nv pt)))
(define (equilibrium-eigenvalues->string F nv pt) (mat-eigenvalues->string (jacobian-at F nv pt)))

; convenience: the trace and determinant of the linearization (exact), handy
; for the 2-D stability summary (tr, det) plane.
(define (equilibrium-trace F nv pt) (trace (jacobian-at F nv pt)))
(define (equilibrium-det F nv pt) (mat-det (jacobian-at F nv pt)))

; ---------- divergence and gradient ----------
; divergence of the vector field, div F = sum_i d f_i/d x_i, as an mpoly. For a
; flow this is the trace of the Jacobian everywhere; its sign governs phase-
; volume contraction (negative => dissipative). Requires n = nv (square field).
(define (div-go F i acc)
  (if (null? F) acc (div-go (cdr F) (+ i 1) (mpoly-add acc (mpoly-deriv (car F) i)))))
(define (vf-divergence F) (div-go F 0 '()))
; divergence evaluated at a point (a rational): exact volume-contraction rate.
(define (divergence-at F pt) (mpoly-eval-point (vf-divergence F) pt))

; gradient of a single scalar polynomial p in nv vars: (d p/d x_0 ... d p/d x_{nv-1}).
(define (mpoly-gradient p nv) (map (lambda (j) (mpoly-deriv p j)) (iota0 nv)))

; ---------- higher partials (for normal-form / Hessian work) ----------
; second partial d^2 p / (d x_i d x_j).
(define (mpoly-deriv2 p i j) (mpoly-deriv (mpoly-deriv p i) j))
; Hessian of a scalar polynomial: an nv-by-nv matrix of mpolys.
(define (mpoly-hessian p nv)
  (map (lambda (i) (map (lambda (j) (mpoly-deriv2 p i j)) (iota0 nv))) (iota0 nv)))
; Hessian evaluated at a point -> rational matrix.
(define (hessian-at p nv pt)
  (map (lambda (i) (map (lambda (j) (mpoly-eval-point (mpoly-deriv2 p i j) pt)) (iota0 nv))) (iota0 nv)))

