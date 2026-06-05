; -*- lisp -*-
; src/cas/tptp/core.lisp -- the TPTP-ARITHMETIC BRIDGE: a classifier and router that takes an arithmetic goal in a
; normalized form and dispatches it to the Sangaku decision procedure that can settle it, returning a verdict WITH
; the certificate that procedure produces (a side project: connecting Sangaku's deciders to the kind of arithmetic
; problem posed in automated-theorem-proving benchmarks such as TPTP, whose syntax is parsed by the companion
; project github/hydrastro/tptptp).
;
; The honest premise.  Sangaku is NOT a general first-order theorem prover -- it has no saturation/superposition
; engine, and its logic layer is an SLD resolver over Horn clauses, a fragment of FOL.  So it cannot compete in the
; FOF/CNF divisions, and this bridge does not pretend to.  What Sangaku DOES have is exact decision procedures for
; particular arithmetic shapes, and a great many TPTP arithmetic problems (the TFA / arithmetic family) reduce to
; exactly those shapes.  The bridge is therefore a CLASSIFIER + ROUTER, mirroring how real systems hand arithmetic
; subgoals to a specialized backend: it recognizes the shape of a goal and routes it, and for anything outside the
; decidable fragment it returns an explicit 'outside-fragment verdict rather than a guess.
;
; A normalized goal is one of (the parser's AST is expected to be lowered into these forms by tptp/parse glue):
;   (poly-unsat (p_1 ... p_m))         -- claim: the system p_1 = ... = p_m = 0 has NO solution (over C)
;   (poly-identity p q)                -- claim: p = q as polynomials (equivalently p - q is the zero polynomial)
;   (nonneg p)                         -- claim: for all real x, p(x) >= 0   (univariate p: a DECISION)
;   (nonneg-sos p (q_1 ... q_k))       -- claim: p >= 0, witnessed by the SOS decomposition p = sum q_i^2 (any arity)
;   (nonneg-on-set p psatz-cert)       -- claim: p >= 0 on a semialgebraic set, witnessed by a Positivstellensatz
;                                         certificate (sigma_0 . ((sigma_i . g_i) ...)) -- proved on the set, else unknown
;   (real-qe quant phi)                -- a univariate real statement: quant in {exists forall}, phi a boolean
;                                         combination of sign conditions -- DECIDED exactly (theorem or countersat)
;   (ground rel a b)                   -- a variable-free comparison: rel in {= < <= > >=}, a, b rational constants
; Univariate polynomials use the coefficient-list representation (low->high); the multivariate forms use the mpoly
; representation of groebner.lisp.  The classifier tptp-shape reports which form a goal is; tptp-decide routes it.
;
; Verdicts: 'theorem (the claim is proved, with a certificate available), 'countersat (the claim is refuted -- e.g.
; a 'poly-unsat goal whose system actually has a solution, or a 'nonneg goal that changes sign), 'unknown (within
; the fragment but not settled -- e.g. a multivariate 'nonneg without an SOS witness, which Sangaku cannot decide),
; or 'outside-fragment (not an arithmetic shape Sangaku handles).  Soundness is the rule: 'theorem and 'countersat
; are only returned when the underlying decision procedure establishes them; everything uncertain is 'unknown.
;
; Public:
;   tptp-shape goal            -> the goal's form tag ('poly-unsat | 'poly-identity | 'nonneg | 'nonneg-sos |
;                                 'ground | 'unrecognized)
;   tptp-decide goal           -> the verdict ('theorem | 'countersat | 'unknown | 'outside-fragment)
;   tptp-certificate goal      -> a certificate object appropriate to the verdict (the Groebner basis, the SOS
;                                 count, the sign data, or the ground evaluation), or 'none
;   tptp-explain goal          -> (list verdict route certificate): the verdict, which decider handled it, and the
;                                 certificate -- a self-contained, re-checkable record of the bridge's decision
;
; Verified: an unsatisfiable system routes to the Nullstellensatz and returns 'theorem with the refuting basis; a
; satisfiable system returns 'countersat; a true polynomial identity returns 'theorem; a univariate nonnegativity
; is DECIDED ('theorem or 'countersat); a multivariate nonnegativity with a valid SOS returns 'theorem and without
; one returns 'unknown (never a false decision -- the Motzkin boundary); a ground comparison is evaluated; a
; non-arithmetic goal returns 'outside-fragment.
;
; Builds on cas/nullstellensatz.lisp, cas/sos.lisp, cas/sosmv.lisp, cas/poly.lisp.

(import "cas/poly.lisp")
(import "cas/nullstellensatz.lisp")
(import "cas/sos.lisp")
(import "cas/sosmv.lisp")
(import "cas/positivstellensatz.lisp")
(import "cas/realqe.lisp")

; ----- small list helpers -----
(define (tptp-tag g) (car g))
(define (tptp-a1 g) (car (cdr g)))
(define (tptp-a2 g) (car (cdr (cdr g))))
(define (tptp-a3 g) (car (cdr (cdr (cdr g)))))

; ----- the classifier -----
(define (tptp-shape goal)
  (cond ((not (pair? goal)) (quote unrecognized))
        ((equal? (tptp-tag goal) (quote poly-unsat)) (quote poly-unsat))
        ((equal? (tptp-tag goal) (quote poly-identity)) (quote poly-identity))
        ((equal? (tptp-tag goal) (quote nonneg)) (quote nonneg))
        ((equal? (tptp-tag goal) (quote nonneg-sos)) (quote nonneg-sos))
        ((equal? (tptp-tag goal) (quote nonneg-on-set)) (quote nonneg-on-set))
        ((equal? (tptp-tag goal) (quote real-qe)) (quote real-qe))
        ((equal? (tptp-tag goal) (quote ground)) (quote ground))
        (else (quote unrecognized))))

; ----- polynomial identity: p = q iff p - q is the zero polynomial (exact, over Q) -----
(define (tptp-poly-identity? p q) (tptp-zero? (poly-sub p q)))
(define (tptp-len l) (if (null? l) 0 (+ 1 (tptp-len (cdr l)))))
(define (tptp-zero? p) (tptp-allz p))
(define (tptp-allz p) (cond ((null? p) #t) ((= (car p) 0) (tptp-allz (cdr p))) (else #f)))

; ----- ground comparison of two rationals -----
(define (tptp-ground-holds? rel a b)
  (cond ((equal? rel (quote =)) (= a b))
        ((equal? rel (quote <)) (< a b))
        ((equal? rel (quote <=)) (if (< a b) #t (= a b)))
        ((equal? rel (quote >)) (> a b))
        ((equal? rel (quote >=)) (if (> a b) #t (= a b)))
        (else #f)))

; ----- the router -----
(define (tptp-decide goal) (tptp-route goal (tptp-shape goal)))
(define (tptp-route goal shape)
  (cond ((equal? shape (quote poly-unsat))
         (if (nss-refutes? (tptp-a1 goal)) (quote theorem) (quote countersat)))
        ((equal? shape (quote poly-identity))
         (if (tptp-poly-identity? (tptp-a1 goal) (tptp-a2 goal)) (quote theorem) (quote countersat)))
        ((equal? shape (quote nonneg))
         (cond ((sos-nonneg? (tptp-a1 goal)) (quote theorem))
               ((equal? (sos-decide (tptp-a1 goal)) (quote nonpositive)) (quote countersat))
               (else (quote countersat))))           ; univariate is decided: not-nonneg => the claim is false
        ((equal? shape (quote nonneg-sos))
         (if (mvsos-is-certificate? (tptp-a1 goal) (tptp-a2 goal)) (quote theorem) (quote unknown)))
        ((equal? shape (quote nonneg-on-set))
         (if (psatz-valid? (tptp-a1 goal) (tptp-a2 goal)) (quote theorem) (quote unknown)))
        ((equal? shape (quote real-qe))
         (if (qe-decide (tptp-a1 goal) (tptp-a2 goal)) (quote theorem) (quote countersat)))
        ((equal? shape (quote ground))
         (if (tptp-ground-holds? (tptp-a1 goal) (tptp-a2 goal) (tptp-a3 goal)) (quote theorem) (quote countersat)))
        (else (quote outside-fragment))))

; ----- the certificate appropriate to each route -----
(define (tptp-certificate goal) (tptp-cert goal (tptp-shape goal)))
(define (tptp-cert goal shape)
  (cond ((equal? shape (quote poly-unsat)) (nss-certificate (tptp-a1 goal)))
        ((equal? shape (quote poly-identity)) (list (quote identity-residual) (poly-sub (tptp-a1 goal) (tptp-a2 goal))))
        ((equal? shape (quote nonneg)) (sos-certificate (tptp-a1 goal)))
        ((equal? shape (quote nonneg-sos)) (mvsos-certify (tptp-a1 goal) (tptp-a2 goal)))
        ((equal? shape (quote nonneg-on-set)) (psatz-certify (tptp-a1 goal) (tptp-a2 goal)))
        ((equal? shape (quote real-qe)) (list (quote qe-verdict) (tptp-a1 goal) (qe-decide (tptp-a1 goal) (tptp-a2 goal))))
        ((equal? shape (quote ground)) (list (quote ground-eval) (tptp-a1 goal) (tptp-a2 goal) (tptp-a3 goal)))
        (else (quote none))))

; ----- the route label (which decider handled it) -----
(define (tptp-route-name shape)
  (cond ((equal? shape (quote poly-unsat)) (quote nullstellensatz))
        ((equal? shape (quote poly-identity)) (quote polynomial-identity))
        ((equal? shape (quote nonneg)) (quote univariate-sos-decision))
        ((equal? shape (quote nonneg-sos)) (quote multivariate-sos-certificate))
        ((equal? shape (quote nonneg-on-set)) (quote constrained-positivstellensatz))
        ((equal? shape (quote real-qe)) (quote univariate-real-qe))
        ((equal? shape (quote ground)) (quote ground-arithmetic))
        (else (quote none))))

; ----- the full self-contained record -----
(define (tptp-explain goal) (list (tptp-decide goal) (tptp-route-name (tptp-shape goal)) (tptp-certificate goal)))
