; FLOOR 4 of lizard's foundations: HIGHER OBSERVATIONAL TYPE THEORY (HOTT) over the interaction net, anchored to
; lizard's trusted equality/cubical machinery.  HOTT (the observational successor to Martin-Lof type theory,
; distinct from homotopy type theory) is the type theory whose DEFINING feature is that equality is determined by
; OBSERVATION -- equality of functions pointwise, of pairs componentwise, in general the equality type computed from
; how inhabitants are observed.  This is exactly the CO-UNIVERSE side of the construction/observation duality:
; observational equality IS equality on the observation lattice, so this floor is the natural continuation of the
; co-universe/reflection development.
;
; The discipline is unchanged from Floors 1-3: the net CARRIES the equality derivation (Id / Path / refl) and
; DELEGATES the check to lizard's trusted kernel (kernel-check over the Id and Path type formers).  The net is the
; proof-term carrier; the trusted kernel is the checker; zero new trusted code.  Honest scope: this anchors to the
; Id/Path/refl machinery the kernel exposes and establishes the observational-equality CORE (formation, refl, the
; discriminating rejection, the observational view); full univalence and the equality-of-equality tower are deeper
; and remain roadmap.
(import "cas/inethott.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(kernel-assume (quote A) (quote (Sort 0)))
(kernel-assume (quote a) (quote A))
(kernel-assume (quote b) (quote A))

(display "Higher observational type theory: equality by observation, the net carries it, the trusted kernel checks.") (newline) (newline)

; readback faithfulness: the equality carriers lower exactly to the kernel's term syntax
(define id-aa (ioe-id (ioe-var (quote A)) (ioe-var (quote a)) (ioe-var (quote a))))
(define refl-a (ioe-refl (ioe-var (quote a))))
(define path-aa (ioe-path (ioe-var (quote A)) (ioe-var (quote a)) (ioe-var (quote a))))
(must "the identity-type carrier reads back to (Id A a a)" (ioe-readback-is? id-aa (quote (Id A a a))))
(must "the refl carrier reads back to (refl a)" (ioe-readback-is? refl-a (quote (refl a))))
(must "the Path-type carrier reads back to (Path A a a)" (ioe-readback-is? path-aa (quote (Path A a a))))

; the trusted kernel checks the equality types
(must "the kernel accepts (Id A a a) at (Sort 0) -- identity-type formation" (ioe-check id-aa (quote (Sort 0))))
(must "the kernel accepts (refl a) at (Id A a a) -- reflexivity" (ioe-check refl-a (quote (Id A a a))))
(must "the kernel accepts (Path A a a) at (Sort 0) -- path-type formation" (ioe-check path-aa (quote (Sort 0))))

; THE DISCRIMINATING REJECTION at the heart of equality: refl does NOT prove a false equation
(must "the kernel REJECTS (refl a) at (Id A a b) for distinct a,b -- refl cannot prove a false equation"
  (not (ioe-check refl-a (quote (Id A a b)))))

; the Floor-4 soundness result: the net's verdict EQUALS the kernel's, on acceptance and rejection
(must "net and kernel AGREE: identity-type formation accepted" (ioe-agree? id-aa (quote (Id A a a)) (quote (Sort 0))))
(must "net and kernel AGREE: reflexivity accepted" (ioe-agree? refl-a (quote (refl a)) (quote (Id A a a))))
(must "net and kernel AGREE: false equation rejected (both reject)"
  (ioe-agree? refl-a (quote (refl a)) (quote (Id A a b))))

; the observational view -- the co-universe tie: equality witnessed by matching observations
(must "observationally equal: a term equals itself by matching observations"
  (ioe-observational-equal? (quote (lam (x A) x)) (quote (lam (x A) x))))
(must "observationally distinct: differing terms do not match observations"
  (not (ioe-observational-equal? (quote (lam (x A) x)) (quote (app f a)))))

(newline)
(display "Equality here is determined by observation -- the identity/path types are formed and checked by the trusted") (newline)
(display "kernel, refl proves reflexive equality but is correctly REJECTED for a false equation, and equality is also") (newline)
(display "read operationally as matching observations.  Observational equality is equality on the co-universe side -- the") (newline)
(display "observation lattice -- so HOTT is the type-theoretic face of the construction/observation duality (ioe-caveat).") (newline)
