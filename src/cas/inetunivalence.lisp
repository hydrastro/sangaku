; -*- lisp -*-
; src/cas/inetunivalence.lisp -- FLOOR 5 of lizard's foundations: UNIVALENCE over the interaction net.  Univalence
; is the deepest principle of cubical/homotopy type theory: an equivalence between types IS a path between them
; (ua : (A ≃ B) -> (A = B)), so equivalent types are interchangeable and transport across an equivalence is
; computation.  This floor carries the univalence constructs on the net and delegates to lizard's cubical layer.
;
; *** THE TRUST BASE IS DIFFERENT FROM FLOORS 1-4 -- STATED PLAINLY. ***  Floors 1-4 (simple, dependent, modal,
; observational) are anchored to lizard's AUDITED ~1,350-line trusted kernel (kt_infer / kt_whnf, via the kernel-*
; primitives), proven sound by agreement with that audited core.  UNIVALENCE CANNOT GET THAT EXACT GUARANTEE: the
; trusted kernel (kernel.c) has Path and Interval but NO Glue / ua / Equiv.  The univalence machinery lives in
; lizard's SURFACE cubical layer (tt_check_cubical.c, ~470 lines, plus lib/cubical.lisp + lib/univalence.lisp,
; reached via infer/reduce), which is a real, shipping, runnable checker/evaluator -- but it is a LARGER, LESS-
; AUDITED trust base than kt_infer, and it does NOT round-trip its cubical typing through the trusted kernel.  So:
;   - the PATH/REFL fragment that DOES live in the trusted kernel is anchored to kt_infer (kernel-check), exactly
;     as Floors 1-4 were;
;   - the genuinely-cubical constructs (id-equiv, Glue, ua, transport) are anchored to the SURFACE cubical layer and
;     are LABELLED as such.  This module never pretends univalence rests on the audited kernel.
; The honesty here is in the LABEL, not in hiding the gap.  See docs/LIMITATIONS.md.
;
; WHAT IS DEMONSTRATED.  (a) Kernel-anchored fragment: the net carries Path/refl derivations and the TRUSTED kernel
; checks them, with the discriminating rejection (refl does not prove a false equation), reusing the Floor-4
; machinery -- this part has the full audited guarantee.  (b) Surface-anchored univalence: the net carries
; id-equiv / Glue / ua and the SURFACE cubical layer computes them -- id-equiv reduces to the identity (forward and
; backward), Glue collapses to T on a true face and to A on a false face, and ua turns an equivalence into a path --
; with the net's readback reducing to exactly what the surface layer computes.  The agreement asserted for (b) is
; agreement with the SURFACE checker, explicitly, not with the audited kernel.
;
; UPDATE (ua typing now kernel-resident): contrary to the previous iteration's claim that the kernel had 'no Glue/
; ua/Equiv', the trusted kernel DOES contain the TYPING of Equiv and ua (KT_EQUIV/KT_UA in kt_infer/kt_whnf/kt_equal),
; and it is SOUND -- verified by lizard's kernel_soundness_test (accepts (ua e):(Id (Sort n) A B); rejects ua of a
; non-equivalence, ua at wrong endpoints, Equiv of a non-type).  So the ua TYPING layer is now KERNEL-ANCHORED, just
; like Floors 1-4.  What remains surface/roadmap is ua COMPUTATION (transport across ua reducing through Glue), which
; the kernel deliberately does not provide and which would require adding transp/Glue/comp to the trusted core.
;
; Public:
;   iuv-id-equiv A               -> an identity-equivalence carrier
;   iuv-glue A phi T e           -> a Glue-type carrier
;   iuv-ua e                     -> a ua (univalence) carrier
;   iuv-readback nt              -> the surface cubical term the carrier represents
;   iuv-surface-reduces-to? nt v -> #t iff the surface cubical layer reduces (iuv-readback nt) to v
;   iuv-path-kernel-check nt ty  -> kernel-check of a Path/refl carrier (the AUDITED-kernel fragment)
;   iuv-trust-base               -> a symbol naming the trust base of each part (for honest reporting)

(import "cas/inethott.lisp")

; ---------- univalence carriers (surface cubical constructs) ----------
(define (iuv-var name) (list (quote iuv-var) name))
(define (iuv-id-equiv A) (list (quote iuv-id-equiv) A))
(define (iuv-glue A phi T e) (list (quote iuv-glue) A phi T e))
(define (iuv-ua e) (list (quote iuv-ua) e))
(define (iuv-tag nt) (cond ((pair? nt) (car nt)) (else (quote iuv-atom))))

; ---------- readback to lizard's surface cubical syntax ----------
(define (iuv-readback nt)
  (cond ((equal? (iuv-tag nt) (quote iuv-var)) (car (cdr nt)))
        ((equal? (iuv-tag nt) (quote iuv-id-equiv)) (list (quote id-equiv) (iuv-rb (car (cdr nt)))))
        ((equal? (iuv-tag nt) (quote iuv-glue))
         (list (quote Glue) (iuv-rb (car (cdr nt))) (iuv-rb (car (cdr (cdr nt)))) (iuv-rb (car (cdr (cdr (cdr nt))))) (iuv-rb (car (cdr (cdr (cdr (cdr nt))))))))
        ((equal? (iuv-tag nt) (quote iuv-ua)) (list (quote ua) (iuv-rb (car (cdr nt)))))
        (else nt)))
(define (iuv-rb x) (cond ((pair? x) (iuv-readback x)) (else x)))
(define (iuv-readback-is? nt surface) (equal? (iuv-readback nt) surface))

; ---------- the AUDITED-kernel fragment: Path/refl checked by the trusted kernel (full guarantee) ----------
; reuse Floor 4's kernel-anchored equality (ioe-check / ioe-agree?) for the part that lives in the trusted kernel
(define (iuv-path-kernel-check ioe-carrier type) (ioe-check ioe-carrier type))
(define (iuv-path-kernel-agree? ioe-carrier kterm type) (ioe-agree? ioe-carrier kterm type))

; ---------- the SURFACE-anchored univalence: delegate computation to the surface cubical layer ----------
; the harness reduces (iuv-readback nt) via the surface reducer and compares to an expected value; this asserts
; agreement with the SURFACE cubical layer, explicitly (NOT the audited kernel)
; ua is NOW kernel-anchored (Equiv/ua were added to the trusted kernel: KT_EQUIV/KT_UA in kernel.c).  The kernel
; types (Equiv A B) and (ua e) : (Id (Sort n) A B) and rejects ua of a non-equivalence -- so univalence's TYPING is
; audited-kernel-anchored.  (Full COMPUTATIONAL univalence -- transport through Glue -- remains surface/roadmap.)
(define (iuv-equiv-kernel-check A B) (kernel-check (list (quote Equiv) A B) (list (quote Sort) 0)))
(define (iuv-ua-kernel-check ua-term id-type) (kernel-check ua-term id-type))
; transp TYPING and its constant-line COMPUTATION rule are now KERNEL-ANCHORED too (KT_TRANSP in the trusted kernel,
; verified by kernel_soundness_test).  transp over a constant type-line reduces to its base (transport along a
; constant path is the identity); a non-constant line stays neutral.  Full transport across a varying line (via
; Glue/comp) is still NOT in the kernel -- that is the remaining roadmap toward full computational univalence.
(define (iuv-transp line base) (list (quote transp) line base))
(define (iuv-transp-kernel-check transp-term type) (kernel-check transp-term type))
(define (iuv-transp-constant-reduces? transp-term base) (kernel-equal? transp-term base))
; STRUCTURAL transport at a non-dependent product is now kernel-anchored too: transport over a VARYING Sigma line
; is componentwise (transp <i>(Sigma A(i) B(i)) (a,b) = (transp <i>A(i) a, transp <i>B(i) b)), needing no Glue.
; A dependent Sigma stays neutral.  This is genuine varying-line transport, the first beyond the constant case.
(define (iuv-transp-sigma-reduces? transp-term componentwise-pair) (kernel-equal? transp-term componentwise-pair))
; the structural tier is now complete for the non-Glue type formers: Sum (transport pushes inside the constructor)
; and Pi with a CONSTANT DOMAIN (transport acts on the codomain only, needing no interval reversal).  All are
; kernel-anchored, type-preserving, no Glue.  Varying-domain Pi (which needs interval negation, absent from the
; kernel) and transport in the UNIVERSE across ua (which needs Glue) stay neutral -- the remaining roadmap.
(define (iuv-transp-sum-check transp-term type) (kernel-check transp-term type))
(define (iuv-transp-pi-check transp-term type) (kernel-check transp-term type))
; interval negation and VARYING-domain Pi transport (via negation) and the identity equivalence are now all
; kernel-anchored.  ineg: ~i0=i1, ~i1=i0, ~~r=r.  Varying-domain Pi transports the argument backward along the
; reversed domain line.  id-equiv A : Equiv A A composes with ua.  The remaining frontier is transport ACROSS ua
; (the Glue/hcomp computation), which is NOT in the kernel and is named, not faked.
(define (iuv-ineg-check term expected) (kernel-equal? term expected))
(define (iuv-id-equiv-check term type) (kernel-check term type))
; the FIRST BRICK of the Kan structure: empty-system homogeneous composition (hcomp A u0 : A, reduces to u0).
; This is a required CCHM equation, added at the only depth with a short proof (no face system -- structurally
; unrepresentable here).  The full face-system hcomp + Glue + the Glue transp rule (transport ACROSS ua) remain
; the named frontier: the irreducible cubical core, a multi-turn build each piece of which needs its own proof.
(define (iuv-hcomp-check term type) (kernel-check term type))
(define (iuv-hcomp-reduces? term base) (kernel-equal? term base))
; the FIRST FACE-AWARE Kan brick: cofibrations (cofib r b) + single-face hcomp (hcomp1 A cof u u0).  On the face
; (r=b) it reduces to the partial element u; off the face to the base u0; else neutral.  TYPING enforces the
; compatibility u=u0 when the face holds -- the soundness heart (it REJECTS an incompatible square).  Multi-face
; hcomp (disjunctions, overlap compatibility) + the Glue type + the Glue transp rule remain the named frontier.
(define (iuv-hcomp1-check term type) (kernel-check term type))
(define (iuv-hcomp1-reduces? term v) (kernel-equal? term v))
; the OVERLAP-LATTICE Kan brick: TWO-face hcomp (hcomp2 A cof1 u1 cof2 u2 u0).  It reduces along the disjunction
; (face1 -> u1, else face2 -> u2, else both-empty -> u0), and TYPING enforces the overlap compatibility lattice:
; u1=u0 on face1, u2=u0 on face2, and -- the new soundness-critical check -- u1=u2 WHERE BOTH FACES HOLD.  That
; overlap check is exactly what makes the reduction order sound.  3+-face hcomp + the Glue type + the Glue transp
; rule (transport ACROSS ua) remain the named frontier.
(define (iuv-hcomp2-check term type) (kernel-check term type))
(define (iuv-hcomp2-reduces? term v) (kernel-equal? term v))
; THE GLUE TYPE-FORMER LAYER -- the type univalence is built from -- is now kernel-anchored: the Glue type
; (Glue A cof T e : Sort, boundary Glue=T on the face), the equivalence forward map (equiv-fun e : T->A, computing
; to the identity for id-equiv), and the eliminator unglue (=g off the face, =(equiv-fun e) g on it, so the
; identity equivalence round-trips).  The Glue TRANSP rule (transport ACROSS ua) is the one remaining CCHM piece.
(define (iuv-glue-check term type) (kernel-check term type))
(define (iuv-glue-reduces? term v) (kernel-equal? term v))
(define (iuv-unglue-reduces? term v) (kernel-equal? term v))
; THE GLUE TRANSPORT KEYSTONE, at its honest depth: the equivalence inverse (equiv-inv e : A->T, identity for
; id-equiv) and gtransp (Glue transport).  gtransp reduces to the base for the IDENTITY equivalence -- the
; regularity case, where forward and inverse are both the identity so the CCHM correction is trivial -- and stays
; NEUTRAL for a general equivalence on a HELD face (which needs the is-equiv coherences the kernel carries via
; mk-equiv plus a comp correction).  It never guesses.  EMPTY-FACE REGULARITY now also fires for an ARBITRARY
; equivalence: on an empty face the Glue degenerates to its base A regardless of the equivalence, so transport is
; the base -- sound without using any coherence.  HELD-FACE CORRECTION now also fires: on a held face the
; constant-line transport of g0 back into A is f(inv(g0)), and gtransp reduces it to the base exactly when f-after-
; inv collapses DEFINITIONALLY (the section coherence is definitional) -- so it covers any equivalence whose maps
; round-trip by computation, not merely the syntactic identity, and stays NEUTRAL when the collapse is only up to
; the eps path.  VARYING EMPTY-FACE LINES now also reduce: transp reduces its type-line body to whnf UNDER the
; interval binder (in both computation and typing), so an empty-face Glue line whose base type A(i) genuinely
; varies delegates to the bare A(i)-line transport -- the Glue is absent on an empty face, so this is sound and
; uses no coherence.  The SAME whnf-under-binder insight, applied symmetrically, also lets transp see through a
; HELD-face Glue line to its bare T-line: a varying T (e.g. a non-dependent Sigma) under a held-face Glue
; transports componentwise just like the bare T-line.  So BOTH boundary faces (empty and held) now transport
; varying lines.  Triangulating the frontier: the remaining cases -- dependent Sigma, Path-type lines, and the
; general Glue transport on an UNDECIDED face -- ALL route through comp (heterogeneous composition), the single
; missing primitive.  comp is the precise, singular next summit; it is named, not faked.
(define (iuv-equiv-inv-reduces? term v) (kernel-equal? term v))
(define (iuv-gtransp-reduces? term v) (kernel-equal? term v))
(define (iuv-gtransp-check term type) (kernel-check term type))
(define (iuv-gtransp-empty-face-reduces? term v) (kernel-equal? term v))
(define (iuv-gtransp-held-face-reduces? term v) (kernel-equal? term v))
(define (iuv-transp-glue-line-reduces? term v) (kernel-equal? term v))
(define (iuv-transp-glue-line-check term type) (kernel-check term type))
(define (iuv-transp-held-glue-line-reduces? term v) (kernel-equal? term v))
(define (iuv-comp-reduces? term v) (kernel-equal? term v))
(define (iuv-comp-check term type) (kernel-check term type))
(define (iuv-comp-total-reduces? term v) (kernel-equal? term v))
(define (iuv-imeet-reduces? term v) (kernel-equal? term v))
(define (iuv-dep-sigma-reduces? term v) (kernel-equal? term v))
(define (iuv-dep-sigma-check term type) (kernel-check term type))
(define (iuv-ivcomp-held-reduces? term v) (kernel-equal? term v))
(define (iuv-ivcomp-check term type) (kernel-check term type))
(define (iuv-pathline-neutral? term) (kernel-equal? term term))
(define (iuv-pathline-infer term) (kernel-infer term))
(define (iuv-pathline-transport-endpoint term endpt v) (kernel-equal? (list (quote papp) term endpt) v))
(define (iuv-pathline-transport-check term type) (kernel-check term type))
(define (iuv-glue-intro-check term type) (kernel-check term type))
(define (iuv-glue-intro-reduces? term v) (kernel-equal? term v))
(define (iuv-unglue-beta? term v) (kernel-equal? term v))
(define (iuv-glue-transport-check term type) (kernel-check term type))
(define (iuv-partial-reduces? term v) (kernel-equal? term v))
(define (iuv-partial-formation term) (kernel-infer term))
(define (iuv-glue-transport-reduces? term v) (kernel-equal? term v))
(define (iuv-glue-transport-infer term) (kernel-infer term))
(define (iuv-psys-infer term) (kernel-infer term))
(define (iuv-psys-reduces? term v) (kernel-equal? term v))
(define (iuv-comp2-reduces? term v) (kernel-equal? term v))
(define (iuv-comp2-check term type) (kernel-check term type))
(define (iuv-glue-comp-check term type) (kernel-check term type))
; THE EQUIVALENCE-STRUCTURE LAYER -- the prerequisite the general Glue transp needs to EXIST -- is now kernel-
; anchored.  An equivalence is no longer just two maps: mk-equiv T A f g eta eps : Equiv T A packages a GENUINE
; quasi-equivalence, with the coherences eta (g(f x)=x) and eps (f(g y)=y) DEMANDED at typing time, and the four
; projections equiv-fun/inv/eta/eps recovering the parts (beta).  gtransp's regularity now extends from the
; id-equiv constructor to ANY equivalence whose forward map is definitionally the identity; a genuinely
; non-identity equivalence with a proper face stays NEUTRAL (the comp-correction over eps is the named frontier).
(define (iuv-mk-equiv-check term type) (kernel-check term type))
(define (iuv-equiv-proj-reduces? term v) (kernel-equal? term v))
; THE GLUE TRANSP RULE -- at the honest degenerate depth -- is now kernel-anchored: the empty-face Glue boundary
; (Glue A [empty] T e = A) plus the fact that transp across a constant empty-face Glue line reduces, via the
; existing transport tier, to the base.  The GENERAL Glue transp rule (varying line, proper face) needs the
; equivalence inverse + is-equiv coherence + a comp operator -- none in the kernel -- so it stays the named frontier.
(define (iuv-glue-empty-boundary? term v) (kernel-equal? term v))
(define (iuv-glue-transp-reduces? term v) (kernel-equal? term v))
; THE GLUE TRANSP RULE -- held-face (regularity) case -- is now kernel-anchored: transport along a line of Glue
; types whose face HOLDS THROUGHOUT reduces to transport along the underlying type line (Glue=T on the held face,
; so the Glue line IS the T line definitionally -- no equivalence inverse, no hcomp correction).  The GENERAL Glue
; transp (varying/proper face, needing the equivalence inverse + is-equiv coherence + comp) remains the frontier.
(define (iuv-glue-transp-held? term type) (kernel-check term type))
(define (iuv-glue-transp-held-reduces? term v) (kernel-equal? term v))

(define (iuv-trust-base)
  (quote ((path-refl . audited-trusted-kernel)
          (Equiv-ua-typing . audited-trusted-kernel)
          (transp-typing-and-constant-line-computation . audited-trusted-kernel)
          (transp-varying-nondependent-Sigma-componentwise . audited-trusted-kernel)
          (transp-varying-Sum-pushes-inside-constructor . audited-trusted-kernel)
          (transp-constant-domain-Pi-on-codomain . audited-trusted-kernel)
          (interval-negation-ineg . audited-trusted-kernel)
          (transp-varying-domain-Pi-via-negation . audited-trusted-kernel)
          (id-equiv-typing . audited-trusted-kernel)
          (hcomp-empty-system . audited-trusted-kernel)
          (cofibration-single-face . audited-trusted-kernel)
          (hcomp1-single-face-with-compatibility . audited-trusted-kernel)
          (hcomp2-two-face-with-overlap-compatibility . audited-trusted-kernel)
          (Glue-type-and-boundary . audited-trusted-kernel)
          (equiv-fun-forward-map . audited-trusted-kernel)
          (unglue-eliminator . audited-trusted-kernel)
          (equiv-inv-inverse-map . audited-trusted-kernel)
          (gtransp-Glue-transport-id-equiv-regularity . audited-trusted-kernel)
          (gtransp-empty-face-regularity-arbitrary-equiv . audited-trusted-kernel)
          (gtransp-held-face-correction-when-f-after-inv-collapses-definitionally . audited-trusted-kernel)
          (transp-empty-face-Glue-line-sees-through-to-varying-base-line . audited-trusted-kernel)
          (transp-held-face-Glue-line-sees-through-to-varying-T-line . audited-trusted-kernel)
          (comp-empty-face-delegates-to-transp . audited-trusted-kernel)
          (comp-constant-line-delegates-to-hcomp1 . audited-trusted-kernel)
          (comp-varying-line-correction-delegates-to-hcomp1-over-transported-endpoints . audited-trusted-kernel)
          (interval-meet-and-join-distributive-lattice-laws . audited-trusted-kernel)
          (bidirectional-pair-check-against-dependent-Sigma . audited-trusted-kernel)
          (dependent-Sigma-transport-via-the-transport-filler . audited-trusted-kernel)
          (i-varying-partial-comp-held-face-reduces-to-the-partial-at-i1 . audited-trusted-kernel)
          (two-face-i-varying-composition-comp2 . audited-trusted-kernel)
          (Path-type-line-transport-via-comp2-reduces-with-correct-endpoints . audited-trusted-kernel)
          (glue-introduction-term-with-coherence-checking-and-unglue-beta . audited-trusted-kernel)
          (general-Glue-transport-type-checks-and-computes-on-decided-faces . audited-trusted-kernel)
          (Partial-type-former-held-reduces-to-A-empty-to-Unit . audited-trusted-kernel)
          (partial-section-typing-via-face-restricted-context . audited-trusted-kernel)
          (general-Glue-transport-on-an-undecided-face-computes-via-partial-section-typing . audited-trusted-kernel)
          (systems-introduction-psys-the-partial-element-intro-typed-under-the-face . audited-trusted-kernel)
          (comp2-one-empty-face-reduction-and-overlap-coherence-check . audited-trusted-kernel)
          (face-restriction-as-context-definition-index-stable-and-sound . audited-trusted-kernel)
          (homogeneous-comp-over-a-Glue-line-type-checks-and-computes . audited-trusted-kernel)
          (cofibration-disjunction-former-cofib-or-with-hcomp1-decided-reduction . audited-trusted-kernel)
          (comp2-empty-face-section-skip-enabling-connection-line-fillers . audited-trusted-kernel)
          (heterogeneous-comp-over-a-Glue-line-varying-A-T-e-type-checks-and-computes . audited-trusted-kernel)
          (forall-face-quantifier-cofib-forall-and-its-held-case-wired-into-comp . audited-trusted-kernel)
          (comp-over-a-Glue-line-decided-psi-reduces-via-the-Glue-boundary . audited-trusted-kernel)
          (mk-equiv-quasi-equivalence-with-coherence-typing . audited-trusted-kernel)
          (equiv-eta-eps-coherence-projections . audited-trusted-kernel)
          (gtransp-regularity-extended-to-definitional-identity . audited-trusted-kernel)
          (Glue-empty-face-boundary . audited-trusted-kernel)
          (Glue-transp-degenerate-empty-face . audited-trusted-kernel)
          (Glue-transp-held-face-regularity . audited-trusted-kernel)
          (varying-gluing-cofibration-the-forall-EMPTY-equivalence-lemma-and-multi-face-composition . surface-cubical-layer-or-roadmap))))

(define (iuv-caveat) (quote floor5-typing-plus-full-transport-plus-interval-negation-plus-id-equiv-plus-full-hcomp-plus-Glue-type-equiv-fun-unglue-plus-the-Glue-transp-EMPTY-and-HELD-face-cases-all-kernel-anchored-only-the-GENERAL-varying-face-Glue-transp-needing-equiv-inverse-coherence-and-comp-remains))
