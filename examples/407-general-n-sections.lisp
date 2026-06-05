; GENERAL-n SECTION sample points and their exact decision -- the final ridge of the cylindrical-algebraic-
; decomposition climb (docs/CAS.md -- cadgen decides every n over the full-dimensional cells; this reaches the
; witnesses confined to a lower-dimensional SECTION, where polynomials vanish and the solution coordinates are
; algebraic, possibly irrational, numbers in a tower -- completing the section picture for general n the way
; algpoint completed the two-variable case).
;
; The exact route is TRIANGULAR (an n-box's coupled refinement cannot isolate a zero-dimensional point -- bisecting
; one coordinate cannot be validated while the others are wide).  Eliminate variables to pin the base coordinate as
; the root of a univariate polynomial -- a real algebraic number -- then propagate the system's relations to express
; each further coordinate over the ones already fixed.  The sign of any polynomial at the section point is computed
; by substituting the triangular relations to reduce it to a univariate polynomial in the base coordinate and taking
; the exact algebraic-number sign there.  All rational arithmetic; fully irrational witnesses.
(import "cas/cadsecn.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))

(display "Deciding a formula at an irrational SECTION point that full-dimensional sampling can never reach.") (newline) (newline)

(display "the zero-dimensional point x = y = z = 1/sqrt(3), cut out by x^2+y^2+z^2 = 1, x = y, y = z:") (newline)
(define p3 (cadsecn-diagonal (list -1 0 3) 0 1 3))      ; base 3x^2 - 1, its root in (0,1)
(define sph (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))   ; x^2 + y^2 + z^2 - 1
(define xy (list (list (list) (list -1)) (cn 1 2)))                          ; x - y
(define yz (list (list (list 0 -1) (list 1))))                               ; y - z
(define xc (list (list) (list (list 1))))                                     ; x

(must "x > 0 at the point" (cadsecn-holds? (cons (quote pos) xc) p3))
(must "x^2 + y^2 + z^2 - 1 = 0 at the point" (cadsecn-holds? (cons (quote zero) sph) p3))
(must "x - y = 0 at the point" (cadsecn-holds? (cons (quote zero) xy) p3))
(must "x + y + z - 2 < 0 at the point (since sqrt(3) < 2)"
  (cadsecn-holds? (cons (quote neg) (list (list (list -2 1) (list 1)) (cn 1 2))) p3))

(display "the full existential witness -- the whole system holds at this single irrational point:") (newline)
(must "exists x,y,z: x^2+y^2+z^2=1 and x=y and y=z and x>0"
  (cadsecn-decide-conj (list (cons (quote zero) sph) (cons (quote zero) xy) (cons (quote zero) yz) (cons (quote pos) xc)) p3))

(display "the same in four dimensions: x1 = x2 = x3 = x4 = 1/2 on the unit 4-sphere:") (newline)
(define p4 (cadsecn-diagonal (list -1 0 4) 0 1 4))      ; base 4x^2 - 1, root 1/2
(define s3 (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))
(define ball4 (list s3 (cn 0 3) (cn 1 3)))
(must "x1^2 + x2^2 + x3^2 + x4^2 - 1 = 0 at the 4-diagonal" (cadsecn-holds? (cons (quote zero) ball4) p4))
(must "x1 - 1/2 = 0 at the 4-diagonal" (cadsecn-holds? (cons (quote zero) (list (cn (/ -1 2) 3) (cn 1 3))) p4))

(display "the honest scope is named:") (newline)
(must "triangular sections decided; the general multi-algebraic tower remains"
  (equal? (cadsecn-general-caveat) (quote triangular-sections-decided-general-multi-algebraic-tower-remains)))

(newline)
(display "Exact section reasoning now reaches general n: a witness living on a zero-dimensional section -- a single") (newline)
(display "irrational point like the sphere diagonal -- is found and verified exactly, by pinning the base coordinate") (newline)
(display "as an algebraic number and propagating the triangular relations.  This is the section analogue, for any n,") (newline)
(display "of the two-variable decider's algebraic-point machinery; the general non-triangular multi-algebraic tower") (newline)
(display "is the deepest remaining work.") (newline)
