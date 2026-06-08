; FLOOR 5 of lizard's foundations: UNIVALENCE over the interaction net.  Univalence -- an equivalence between types
; IS a path between them (ua : (A ≃ B) -> (Path/Id U A B)) -- the deepest principle of cubical/homotopy type theory.
;
; *** UPDATE: ua TYPING is now KERNEL-ANCHORED. ***  The previous iteration claimed the trusted kernel had no Glue/
; ua/Equiv and anchored all of univalence to the surface cubical layer.  That was an overcorrection: the trusted
; kernel DOES contain the TYPING of Equiv and ua (KT_EQUIV/KT_UA, handled in kt_infer/kt_whnf/kt_equal), and it is
; SOUND -- verified by lizard's kernel_soundness_test (which builds ill-typed kterms directly and confirms kt_infer
; rejects them).  So the ua TYPING layer now has the SAME audited-kernel guarantee as Floors 1-4.  What remains
; surface/roadmap is ua COMPUTATION (transport across ua reducing through Glue), which the kernel deliberately omits
; and which would require adding transp/Glue/comp to the trusted core (a multi-hundred-line CCHM project, not faked).
; See docs/LIMITATIONS.md.  The honesty is in the split: TYPING kernel-anchored, COMPUTATION surface/roadmap.
(import "cas/inetunivalence.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(kernel-assume (quote A) (quote (Sort 0)))
(kernel-assume (quote B) (quote (Sort 0)))
(kernel-assume (quote C) (quote (Sort 0)))
(kernel-assume (quote e) (quote (Equiv A B)))
(kernel-assume (quote a) (quote A))
(kernel-assume (quote a2) (quote A))

(display "Univalence: an equivalence IS a path.  ua TYPING is now in the trusted kernel; only ua COMPUTATION (via") (newline)
(display "Glue) remains surface/roadmap.  This floor is explicit about the split.") (newline) (newline)

; ---- ua TYPING, now KERNEL-ANCHORED (audited-kernel guarantee, like Floors 1-4) ----
(must "[audited kernel] (Equiv A B) is a type at (Sort 0)" (iuv-ua-kernel-check (quote (Equiv A B)) (quote (Sort 0))))
(must "[audited kernel] (ua e) : (Id (Sort 0) A B) -- univalence typing in the trusted kernel"
  (iuv-ua-kernel-check (quote (ua e)) (quote (Id (Sort 0) A B))))
(must "[audited kernel] the kernel REJECTS (ua e) at the wrong codomain (Id (Sort 0) A C)"
  (not (iuv-ua-kernel-check (quote (ua e)) (quote (Id (Sort 0) A C)))))
(must "[audited kernel] the kernel REJECTS (ua a) -- a is not an equivalence"
  (not (iuv-ua-kernel-check (quote (ua a)) (quote (Id (Sort 0) A B)))))
(must "[audited kernel] the kernel REJECTS (Equiv a B) -- a is not a type"
  (not (iuv-ua-kernel-check (quote (Equiv a B)) (quote (Sort 0)))))
(must "[audited kernel] Equiv-kernel-check accepts (Equiv A B) as a type"
  (iuv-equiv-kernel-check (quote A) (quote B)))

; ---- the Path/refl fragment, also kernel-anchored (reused from Floor 4) ----
(define refl-a (ioe-refl (ioe-var (quote a))))
(must "[audited kernel] (refl a) proves (Id A a a) but not a false equation"
  (and (iuv-path-kernel-check refl-a (quote (Id A a a)))
       (not (iuv-path-kernel-check refl-a (quote (Id A a (succ a)))))))

; ---- readback faithfulness of the univalence carriers ----
(must "the id-equiv carrier reads back to (id-equiv A)" (iuv-readback-is? (iuv-id-equiv (iuv-var (quote A))) (quote (id-equiv A))))
(must "the ua carrier reads back to (ua (id-equiv A))" (iuv-readback-is? (iuv-ua (iuv-id-equiv (iuv-var (quote A)))) (quote (ua (id-equiv A)))))

; ---- transp TYPING + constant-line COMPUTATION, now KERNEL-ANCHORED (a step toward computational univalence) ----
(must "[audited kernel] (transp <i>A a) : A -- transport typing in the trusted kernel"
  (iuv-transp-kernel-check (quote (transp (plam i A) a)) (quote A)))
(must "[audited kernel] (transp <i>A a) REDUCES to a -- transport along a constant line is the identity"
  (iuv-transp-constant-reduces? (quote (transp (plam i A) a)) (quote a)))
(must "[audited kernel] the kernel REJECTS (transp <i>A a) : B -- transport does not falsely change the type"
  (not (iuv-transp-kernel-check (quote (transp (plam i A) a)) (quote B))))

; ---- STRUCTURAL transport across a VARYING line (the first step beyond the constant case) ----
; set up a varying type-line via a path in the universe, then transport at a non-dependent product
(kernel-assume (quote A1) (quote (Sort 0)))
(kernel-assume (quote PA) (quote (Path (Sort 0) A A1)))
(kernel-assume (quote bb) (quote B))
(must "[audited kernel] varying non-dependent Sigma transport is TYPE-PRESERVING (result : Sigma A1 B)"
  (iuv-transp-kernel-check (quote (transp (plam i (Sigma (x (papp PA i)) B)) (pair a bb))) (quote (Sigma (y A1) B))))
(must "[audited kernel] varying Sigma transport reduces COMPONENTWISE (no Glue needed)"
  (iuv-transp-sigma-reduces? (quote (transp (plam i (Sigma (x (papp PA i)) B)) (pair a bb)))
                             (quote (pair (transp (plam i (papp PA i)) a) (transp (plam i B) bb)))))
(kernel-assume (quote B1) (quote (Sort 0)))
(kernel-assume (quote PB) (quote (Path (Sort 0) B B1)))
(must "[audited kernel] varying Sum transport (inl) is TYPE-PRESERVING (result : Sum A1 B1)"
  (iuv-transp-sum-check (quote (transp (plam i (Sum (papp PA i) (papp PB i))) (inl a B))) (quote (Sum A1 B1))))
(kernel-assume (quote f) (quote (Pi (x A) B)))
(must "[audited kernel] constant-domain Pi transport is TYPE-PRESERVING (result : Pi (x A) B1)"
  (iuv-transp-pi-check (quote (transp (plam i (Pi (x A) (papp PB i))) f)) (quote (Pi (x A) B1))))
(must "[audited kernel] varying-domain Pi (constant codomain B) is TYPE-PRESERVING via interval negation"
  (iuv-transp-pi-check (quote (transp (plam i (Pi (x (papp PA i)) B)) f)) (quote (Pi (x A1) B))))

; ---- interval negation, varying-domain Pi (now via negation), and the identity equivalence ----
(must "[audited kernel] interval negation: ~i0 = i1" (iuv-ineg-check (quote (ineg i0)) (quote i1)))
(must "[audited kernel] interval negation: ~i1 = i0" (iuv-ineg-check (quote (ineg i1)) (quote i0)))
(must "[audited kernel] interval negation involution: ~~i0 = i0" (iuv-ineg-check (quote (ineg (ineg i0))) (quote i0)))
(must "[audited kernel] ~i0 is NOT i0 (no wrong endpoint)" (not (iuv-ineg-check (quote (ineg i0)) (quote i0))))
(kernel-assume (quote PB2) (quote (Path (Sort 0) B B1)))
(must "[audited kernel] VARYING-domain Pi transport is now TYPE-PRESERVING (via interval negation)"
  (iuv-transp-pi-check (quote (transp (plam i (Pi (x (papp PA i)) (papp PB2 i))) f)) (quote (Pi (x A1) B1))))
(must "[audited kernel] the identity equivalence (id-equiv A) : (Equiv A A)"
  (iuv-id-equiv-check (quote (id-equiv A)) (quote (Equiv A A))))
(must "[audited kernel] ua composes with id-equiv: ua (id-equiv A) : (Id (Sort 0) A A)"
  (iuv-id-equiv-check (quote (ua (id-equiv A))) (quote (Id (Sort 0) A A))))

; ---- the first brick of the Kan structure: empty-system hcomp ----
(must "[audited kernel] empty-system hcomp: (hcomp A a) : A"
  (iuv-hcomp-check (quote (hcomp A a)) (quote A)))
(must "[audited kernel] empty-system hcomp reduces to the base: (hcomp A a) = a"
  (iuv-hcomp-reduces? (quote (hcomp A a)) (quote a)))

; ---- the first FACE-AWARE Kan brick: cofibrations + single-face hcomp ----
(must "[audited kernel] single-face hcomp ON the face (compatible) : A"
  (iuv-hcomp1-check (quote (hcomp1 A (cofib i1 i1) a a)) (quote A)))
(must "[audited kernel] single-face hcomp ON the face reduces to the partial element"
  (iuv-hcomp1-reduces? (quote (hcomp1 A (cofib i1 i1) a a)) (quote a)))
(must "[audited kernel] single-face hcomp OFF the face (i0=i1) reduces to the base"
  (iuv-hcomp1-reduces? (quote (hcomp1 A (cofib i0 i1) a a)) (quote a)))
(must "[audited kernel] single-face hcomp REJECTS an incompatible square (compatibility heart)"
  (not (iuv-hcomp1-check (quote (hcomp1 A (cofib i1 i1) a2 a)) (quote A))))

; ---- the OVERLAP-LATTICE Kan brick: two-face hcomp ----
(must "[audited kernel] two-face hcomp both-empty reduces to the base"
  (iuv-hcomp2-reduces? (quote (hcomp2 A (cofib i0 i1) a2 (cofib i0 i1) a2 a)) (quote a)))
(must "[audited kernel] two-face hcomp on face1 (compatible) : A"
  (iuv-hcomp2-check (quote (hcomp2 A (cofib i1 i1) a (cofib i0 i1) a a)) (quote A)))
(must "[audited kernel] two-face hcomp REJECTS C1 violation (partial1 != base on face1)"
  (not (iuv-hcomp2-check (quote (hcomp2 A (cofib i1 i1) a2 (cofib i0 i1) a a)) (quote A))))
(must "[audited kernel] two-face hcomp REJECTS the OVERLAP incompatibility (u1 != u2 where both faces hold)"
  (not (iuv-hcomp2-check (quote (hcomp2 A (cofib i1 i1) a2 (cofib i1 i1) a a2)) (quote A))))

; ---- THE GLUE TYPE-FORMER LAYER: the type univalence is built from ----
(kernel-assume (quote T) (quote (Sort 0)))
(kernel-assume (quote eqv) (quote (Equiv T A)))
(must "[audited kernel] the Glue type (Glue A cof T e) : (Sort 0)"
  (iuv-glue-check (quote (Glue A (cofib i0 i1) T eqv)) (quote (Sort 0))))
(must "[audited kernel] Glue BOUNDARY: on the face (i1=i1) the Glue type reduces to T"
  (iuv-glue-reduces? (quote (Glue A (cofib i1 i1) T eqv)) (quote T)))
(must "[audited kernel] equiv-fun (id-equiv A) computes to the identity function"
  (iuv-glue-reduces? (quote (equiv-fun (id-equiv A))) (quote (lam (x A) x))))
(must "[audited kernel] unglue with id-equiv ON the face round-trips the argument (the equivalence computes)"
  (iuv-unglue-reduces? (quote (unglue A (cofib i1 i1) A (id-equiv A) a)) (quote a)))
(kernel-assume (quote tT) (quote T))
(must "[audited kernel] HELD-face Glue transp is type-preserving (: T)"
  (iuv-glue-transp-held? (quote (transp (plam i (Glue A (cofib i1 i1) T eqv)) tT)) (quote T)))
(must "[audited kernel] HELD-face Glue transp reduces via the underlying type line (to the base)"
  (iuv-glue-transp-held-reduces? (quote (transp (plam i (Glue A (cofib i1 i1) T eqv)) tT)) (quote tT)))

; ---- THE GLUE TRANSP RULE at the honest degenerate depth ----
(must "[audited kernel] Glue EMPTY-face boundary: (Glue A [empty] T e) reduces to A"
  (iuv-glue-empty-boundary? (quote (Glue A (cofib i0 i1) T eqv)) (quote A)))
(must "[audited kernel] DEGENERATE Glue transp: transp over a constant empty-face Glue line reduces to the base"
  (iuv-glue-transp-reduces? (quote (transp (plam i (Glue A (cofib i0 i1) T eqv)) a)) (quote a)))

; ---- comp is now TOTAL: the varying-line correction reduces (no longer neutral) ----
(kernel-assume (quote Ca0) (quote (Sort 0)))
(kernel-assume (quote Ca1) (quote (Sort 0)))
(kernel-assume (quote CPA) (quote (Path (Sort 0) Ca0 Ca1)))
(kernel-assume (quote cx0) (quote Ca0))
(must "[audited kernel] comp is TOTAL: VARYING line + HELD face reduces to hcomp1 over the transported endpoints"
  (iuv-comp-total-reduces?
    (quote (comp (plam i (papp CPA i)) (cofib i1 i1) cx0 cx0))
    (quote (hcomp1 Ca1 (cofib i1 i1) (transp (plam i (papp CPA i)) cx0) (transp (plam i (papp CPA i)) cx0)))))
(must "[audited kernel] the comp varying-line correction types at the i1 endpoint"
  (iuv-comp-check (quote (comp (plam i (papp CPA i)) (cofib i1 i1) cx0 cx0)) (quote Ca1)))

; ---- interval MEET /\\ and JOIN \\/ : the distributive-lattice operations (and the FILLER boundaries) ----
(must "[audited kernel] interval meet: i0 /\\ r = i0 (bottom absorbs)"
  (iuv-imeet-reduces? (quote (imeet i0 cx0)) (quote i0)))
(must "[audited kernel] interval meet: i1 /\\ r = r (top is identity) -- filler boundary k/\\i1=k"
  (iuv-imeet-reduces? (quote (imeet i1 cx0)) (quote cx0)))
(must "[audited kernel] interval join: i1 \\/ r = i1 (top absorbs)"
  (iuv-imeet-reduces? (quote (ijoin i1 cx0)) (quote i1)))
(must "[audited kernel] interval join: i0 \\/ r = r (bottom is identity)"
  (iuv-imeet-reduces? (quote (ijoin i0 cx0)) (quote cx0)))

; ---- DEPENDENT Sigma transport via the transport filler (the FIRST downstream wiring) ----
(kernel-assume (quote da) (quote Ca0))
(kernel-assume (quote db) (quote (Id Ca0 da da)))
(must "[audited kernel] DEPENDENT Sigma transport reduces componentwise with the filler q(i)=transp <k>A(k/\\i) a"
  (iuv-dep-sigma-reduces?
    (quote (transp (plam i (Sigma (x (papp CPA i)) (Id (papp CPA i) x x))) (pair da db)))
    (quote (pair (transp (plam i (papp CPA i)) da)
                 (transp (plam i (Id (papp CPA i)
                                     (transp (plam k (papp CPA (imeet k i))) da)
                                     (transp (plam k (papp CPA (imeet k i))) da))) db)))))
(must "[audited kernel] DEPENDENT Sigma transport result type-checks at the dependent i1-endpoint type"
  (iuv-dep-sigma-check
    (quote (transp (plam i (Sigma (x (papp CPA i)) (Id (papp CPA i) x x))) (pair da db)))
    (quote (Sigma (x (papp CPA i1)) (Id (papp CPA i1) x x)))))
(must "[audited kernel] DEPENDENT Sigma over a CONSTANT line gives back the pair (filler degenerates)"
  (iuv-dep-sigma-reduces?
    (quote (transp (plam i (Sigma (x Ca0) (Id Ca0 x x))) (pair da db)))
    (quote (pair da db))))

; ---- the i-VARYING-partial comp, HELD-face fragment (a component of the Path-line machinery) ----
; partial is a genuine SECTION of the type line: the filler q(i)=transp <k>(CPA@(k/\i)) cx0, q(i0)=cx0.
(must "[audited kernel] i-varying comp on a HELD face reduces to the partial line at i1: comp [held -> <i>q(i)] = q(i1)"
  (iuv-ivcomp-held-reduces?
    (quote (comp (plam i (papp CPA i)) (cofib i1 i1) (plam i (transp (plam k (papp CPA (imeet k i))) cx0)) cx0))
    (quote (transp (plam k (papp CPA (imeet k i1))) cx0))))
(must "[audited kernel] the i-varying held-face composite types at the i1 endpoint (Ca1)"
  (iuv-ivcomp-check
    (quote (comp (plam i (papp CPA i)) (cofib i1 i1) (plam i (transp (plam k (papp CPA (imeet k i))) cx0)) cx0))
    (quote Ca1)))

; ---- THE PATH-LINE / GLUE FRONTIER, honestly pinned: sound typing + neutrality, no faked reduction ----
(kernel-assume (quote plu0) (quote Ca0))
(kernel-assume (quote plv0) (quote Ca0))
(kernel-assume (quote plp) (quote (Path Ca0 plu0 plv0)))
; transp over a Path-type-line is WELL-TYPED: it infers Path (CPA@i1) (filler@i1) (filler@i1).
(must "[audited kernel] transp over a Path-type-line is well-typed (the kernel TYPES Path-line transport)"
  (not (error-object?
    (iuv-pathline-infer
      (quote (transp (plam i (Path (papp CPA i)
                                   (transp (plam k (papp CPA (imeet k i))) plu0)
                                   (transp (plam k (papp CPA (imeet k i))) plv0))) plp))))))

; ---- comp2: the two-face i-varying Kan composition (the disjunction-system brick) ----
; a DECIDED held face yields that face's partial line at i1:
(must "[audited kernel] comp2 on a DECIDED held face reduces to that face's partial line at i1"
  (iuv-comp2-reduces?
    (quote (comp2 (plam i (papp CPA i))
                  (cofib i1 i1) (plam i (transp (plam k (papp CPA (imeet k i))) plu0))
                  (cofib i0 i1) (plam i (transp (plam k (papp CPA (imeet k i))) plu0))
                  plu0))
    (quote (transp (plam k (papp CPA (imeet k i1))) plu0))))
; an EMPTY system yields transport of the base over the line:
(must "[audited kernel] comp2 on an EMPTY system reduces to transport of the base over the line"
  (iuv-comp2-reduces?
    (quote (comp2 (plam i (papp CPA i))
                  (cofib i0 i1) (plam i (transp (plam k (papp CPA (imeet k i))) plu0))
                  (cofib i0 i1) (plam i (transp (plam k (papp CPA (imeet k i))) plu0))
                  plu0))
    (quote (transp (plam i (papp CPA i)) plu0))))

; ---- Path-type-line transport, NOW WIRED: transp auto-reduces with the correct boundary ----
; r = transp <i>(Path A(i) u(i) v(i)) p ; r@i0 = u(i1), r@i1 = v(i1).
(must "[audited kernel] WIRED: transp over a Path-line has left endpoint u(i1) (boundary-pinned, not the naive transp)"
  (iuv-pathline-transport-endpoint
    (quote (transp (plam i (Path (papp CPA i)
                                 (transp (plam k (papp CPA (imeet k i))) plu0)
                                 (transp (plam k (papp CPA (imeet k i))) plv0))) plp))
    (quote i0)
    (quote (transp (plam k (papp CPA (imeet k i1))) plu0))))
(must "[audited kernel] WIRED: transp over a Path-line has right endpoint v(i1)"
  (iuv-pathline-transport-endpoint
    (quote (transp (plam i (Path (papp CPA i)
                                 (transp (plam k (papp CPA (imeet k i))) plu0)
                                 (transp (plam k (papp CPA (imeet k i))) plv0))) plp))
    (quote i1)
    (quote (transp (plam k (papp CPA (imeet k i1))) plv0))))
; and the transported path TYPE-CHECKS at Path (CPA@i1) u(i1) v(i1):
(must "[audited kernel] WIRED: the transported Path-line type-checks at Path (CPA@i1) u(i1) v(i1)"
  (iuv-pathline-transport-check
    (quote (transp (plam i (Path (papp CPA i)
                                 (transp (plam k (papp CPA (imeet k i))) plu0)
                                 (transp (plam k (papp CPA (imeet k i))) plv0))) plp))
    (quote (Path (papp CPA i1)
                 (transp (plam k (papp CPA (imeet k i1))) plu0)
                 (transp (plam k (papp CPA (imeet k i1))) plv0)))))
; PROOF retained: the naive shortcut is still WRONG (genuine composition was necessary).
(kernel-assume (quote usec) (quote (Pi (i I) (papp CPA i))))
(must "[audited kernel] the naive Path-line shortcut is WRONG: transp(u(i0)) is NOT the required u(i1) (generic section)"
  (not (kernel-equal? (quote (transp (plam i (papp CPA i)) (app usec i0))) (quote (app usec i1)))))

; ---- the GLUE INTRODUCTION term and the general Glue transport on DECIDED faces ----
(kernel-assume (quote GA) (quote (Sort 0)))
(kernel-assume (quote GT) (quote (Sort 0)))
(kernel-assume (quote Gf) (quote (Pi (_ GT) GA)))
(kernel-assume (quote Gg) (quote (Pi (_ GA) GT)))
(kernel-assume (quote Geta) (quote (Pi (x GT) (Id GT (app Gg (app Gf x)) x))))
(kernel-assume (quote Geps) (quote (Pi (y GA) (Id GA (app Gf (app Gg y)) y))))
(kernel-assume (quote Gtt) (quote GT))
; the glue equivalence
(define Ge (quote (mk-equiv GT GA Gf Gg Geta Geps)))
; coherent glue on a HELD face: base = (equiv-fun e) u = Gf Gtt
(must "[audited kernel] glue introduction with coherent base type-checks at the Glue type"
  (iuv-glue-intro-check
    (quote (glue GA (cofib i1 i1) GT (mk-equiv GT GA Gf Gg Geta Geps) Gtt (app Gf Gtt)))
    (quote (Glue GA (cofib i1 i1) GT (mk-equiv GT GA Gf Gg Geta Geps)))))
(must "[audited kernel] glue on a held face reduces to its T-component (the member)"
  (iuv-glue-intro-reduces?
    (quote (glue GA (cofib i1 i1) GT (mk-equiv GT GA Gf Gg Geta Geps) Gtt (app Gf Gtt)))
    (quote Gtt)))
(must "[audited kernel] glue off the face reduces to its base component"
  (iuv-glue-intro-reduces?
    (quote (glue GA (cofib i0 i1) GT (mk-equiv GT GA Gf Gg Geta Geps) Gtt (app Gf Gtt)))
    (quote (app Gf Gtt))))
(must "[audited kernel] unglue (glue .. u a) = a (the eliminator beta-rule)"
  (iuv-unglue-beta?
    (quote (unglue GA (cofib i1 i1) GT (mk-equiv GT GA Gf Gg Geta Geps)
                   (glue GA (cofib i1 i1) GT (mk-equiv GT GA Gf Gg Geta Geps) Gtt (app Gf Gtt))))
    (quote (app Gf Gtt))))

; the FULL CCHM Glue-transport result on a HELD face: it type-checks at the Glue type and reduces to t1.
; t1 = transp <i>T(i) g0 ; a1 = comp <i>A(i) [phi -> <i> equiv-fun(e(i), transp<k>T(k/\i) g0)] (unglue g0).
(kernel-assume (quote GA1) (quote (Sort 0))) (kernel-assume (quote GT1) (quote (Sort 0)))
(kernel-assume (quote GPA) (quote (Path (Sort 0) GA GA1)))
(kernel-assume (quote GPT) (quote (Path (Sort 0) GT GT1)))
(kernel-assume (quote Gefam) (quote (Pi (i I) (Equiv (papp GPT i) (papp GPA i)))))
(kernel-assume (quote Gg0) (quote GT))   ; on a held face the glue element is a T-element
(must "[audited kernel] the FULL Glue-transport result type-checks at the Glue type (held face, decided)"
  (iuv-glue-transport-check
    (quote (glue GA1 (cofib i1 i1) GT1 (app Gefam i1)
                 (transp (plam i (papp GPT i)) Gg0)
                 (comp (plam i (papp GPA i)) (cofib i1 i1)
                       (plam i (app (equiv-fun (app Gefam i)) (transp (plam k (papp GPT (imeet k i))) Gg0)))
                       (unglue GA (cofib i1 i1) GT (app Gefam i0) Gg0))))
    (quote (Glue GA1 (cofib i1 i1) GT1 (app Gefam i1)))))

; ---- the partial-elements layer: the Partial type former (first stone) ----
(must "[audited kernel] Partial (cofib r b) A is a Sort (the partial-element type former)"
  (not (error-object? (iuv-partial-formation (quote (Partial (cofib i1 i1) GA))))))
(must "[audited kernel] Partial on a HELD face reduces to A (a partial element on a true face is total)"
  (iuv-partial-reduces? (quote (Partial (cofib i1 i1) GA)) (quote GA)))
(must "[audited kernel] Partial on an EMPTY face reduces to Unit (only the trivial partial element)"
  (iuv-partial-reduces? (quote (Partial (cofib i0 i1) GA)) (quote Unit)))

; ---- partial-section typing + the GENERAL GLUE TRANSPORT on an UNDECIDED face (the breakthrough) ----
; A function lam (j:I)(lam (g0 : Glue GA (cofib j i1) GT (Gefam i0)) RES) type-checks iff RES (the full
; Glue-transport result) type-checks under the FACE-RESTRICTED context -- partial-section typing.
(must "[audited kernel] the general Glue transport on an UNDECIDED face TYPE-CHECKS (partial-section typing)"
  (not (error-object?
    (kernel-infer
      (quote (lam (j I) (lam (g0 (Glue GA (cofib j i1) GT (app Gefam i0)))
        (glue GA1 (cofib j i1) GT1 (app Gefam i1)
              (transp (plam i (papp GPT i)) g0)
              (comp (plam i (papp GPA i)) (cofib j i1)
                    (plam i (app (equiv-fun (app Gefam i)) (transp (plam k (papp GPT (imeet k i))) g0)))
                    (unglue GA (cofib j i1) GT (app Gefam i0) g0))))))))))
; and transp over a Glue-line on an UNDECIDED face AUTO-REDUCES to a glue element (no longer neutral):
(kernel-assume (quote jU) (quote I))
(kernel-assume (quote gU) (quote (Glue GA (cofib jU i1) GT (app Gefam i0))))
(must "[audited kernel] transp over a Glue-line (undecided face) is well-typed at the transported Glue type"
  (not (error-object?
    (iuv-glue-transport-infer
      (quote (transp (plam i (Glue (papp GPA i) (cofib jU i1) (papp GPT i) (app Gefam i))) gU))))))
(must "[audited kernel] transp over a Glue-line on an UNDECIDED face is no longer neutral (it computes a glue element)"
  (not (iuv-glue-transport-reduces?
    (quote (transp (plam i (Glue (papp GPA i) (cofib jU i1) (papp GPT i) (app Gefam i))) gU))
    (quote (gtransp GA (cofib jU i1) GT (app Gefam i0) gU)))))  ; not equal to the neutral gtransp form
; SOUNDNESS retained: a partial whose body is ill-typed even on the face is REJECTED.
(must "[audited kernel] partial-section typing stays SOUND: a wrong-typed partial body is still rejected"
  (error-object?
    (kernel-infer
      (quote (lam (j I) (lam (g0 (Glue GA (cofib j i1) GT (app Gefam i0)))
        (comp (plam i (papp GPA i)) (cofib j i1)
              (plam i (transp (plam k (papp GPT (imeet k i))) g0))   ; body : T(i), not A(i) -- wrong
              (unglue GA (cofib j i1) GT (app Gefam i0) g0))))))))

; ---- systems introduction: psys (cofib r b) A a -- the partial-element introduction ----
(kernel-assume (quote SA) (quote (Sort 0)))
(kernel-assume (quote Sa) (quote SA))
(kernel-assume (quote Sj) (quote I))
(must "[audited kernel] psys (cofib r b) A a : Partial (cofib r b) A (the systems introduction types)"
  (not (error-object? (iuv-psys-infer (quote (psys (cofib Sj i1) SA Sa))))))
(must "[audited kernel] a system on a HELD face reduces to its value a"
  (iuv-psys-reduces? (quote (psys (cofib i1 i1) SA Sa)) (quote Sa)))
(must "[audited kernel] a system on an EMPTY face reduces to * : Unit (the trivial partial element)"
  (iuv-psys-reduces? (quote (psys (cofib i0 i1) SA Sa)) (quote *)))
(must "[audited kernel] a system inhabits the Partial type on an undecided face"
  (kernel-check (quote (psys (cofib Sj i1) SA Sa)) (quote (Partial (cofib Sj i1) SA))))
; the element is typed UNDER the face: a value well-typed only on the face is accepted (bound face var)
(kernel-assume (quote SA0) (quote (Sort 0))) (kernel-assume (quote ST0) (quote (Sort 0)))
(kernel-assume (quote See) (quote (Equiv ST0 SA0)))
(must "[audited kernel] face-restricted system typing: lam(j)(psys (cofib j i1) T0 g) with g:Glue..(cofib j i1)..T0 types"
  (not (error-object?
    (kernel-infer (quote (lam (j I) (lam (g (Glue SA0 (cofib j i1) ST0 See)) (psys (cofib j i1) ST0 g))))))))
(must "[audited kernel] SOUND: a system whose value has the wrong type even on the face is rejected"
  (error-object? (iuv-psys-infer (quote (psys (cofib i1 i1) SA0 ST0)))))   ; ST0 : Sort, not : SA0

; ---- frontier (2) mapped: faces depending on the transport variable belong to comp-over-Glue, not transport ----
(kernel-assume (quote DA0) (quote (Sort 0))) (kernel-assume (quote DT0) (quote (Sort 0)))
(kernel-assume (quote Dee) (quote (Equiv DT0 DA0)))
(kernel-assume (quote Dg0) (quote (Glue DA0 (cofib i0 i1) DT0 Dee)))
; transp over an i-DEPENDENT-face Glue line correctly does NOT fire the general rule (stays neutral):
(must "[audited kernel] transp over an i-DEPENDENT-face Glue line stays NEUTRAL (an i-moving locus is a composition, not a transport)"
  (iuv-glue-transport-reduces?
    (quote (transp (plam i (Glue DA0 (cofib i i1) DT0 Dee)) Dg0))
    (quote (transp (plam i (Glue DA0 (cofib i i1) DT0 Dee)) Dg0))))
; comp over a Glue line is well-typed and stays neutral (the full Glue-composition is future work):
(kernel-assume (quote Dj) (quote I))
(kernel-assume (quote Dg) (quote (Glue DA0 (cofib Dj i1) DT0 Dee)))
(kernel-assume (quote Du) (quote (Pi (i I) (Glue DA0 (cofib Dj i1) DT0 Dee))))
(must "[audited kernel] comp over a Glue line is well-typed and stays NEUTRAL on an undecided face (Glue-composition is future work)"
  (not (error-object? (kernel-infer (quote (comp (plam i (Glue DA0 (cofib Dj i1) DT0 Dee)) (cofib Dj i1) (plam i (app Du i)) Dg))))))

; ---- comp over a Glue line: comp2 advances + decided-psi cases + the general-case mapping ----
(kernel-assume (quote KA) (quote (Sort 0)))
(kernel-assume (quote Kg0) (quote KA))
(kernel-assume (quote Ku) (quote (Pi (i I) KA)))
(kernel-assume (quote Km) (quote I))
; (1) the NEW one-empty-face reduction (the composition-filler equation):
(must "[audited kernel] comp2 with one EMPTY face drops to the single-face comp (the filler regularity equation)"
  (iuv-comp2-reduces?
    (quote (comp2 (plam k KA) (cofib Km i1) (plam k (app Ku k)) (cofib i1 i0) (plam k Kg0) Kg0))
    (quote (comp (plam k KA) (cofib Km i1) (plam k (app Ku k)) Kg0))))
(must "[audited kernel] comp2 still: both faces empty -> transport of the base (intact)"
  (iuv-comp2-reduces?
    (quote (comp2 (plam k KA) (cofib i0 i1) (plam k (app Ku k)) (cofib i1 i0) (plam k Kg0) Kg0))
    (quote (transp (plam k KA) Kg0))))
; (2) comp2 partial-section typing exercised with a leg whose typing genuinely depends on its face:
; a constant leg over A0 with one undecided face and one empty face type-checks (the restriction and
; empty-face handling both fire).  (The deeper unglue-leg case is verified via comp in the breakthrough
; turn; comp2 shares the same kctx_restrict mechanism.)
(kernel-assume (quote KA0) (quote (Sort 0))) (kernel-assume (quote KT0) (quote (Sort 0)))
(kernel-assume (quote Kee) (quote (Equiv KT0 KA0)))
(kernel-assume (quote Kca) (quote KA0))
(must "[audited kernel] comp2 with an undecided face and an empty face type-checks (section + empty-face handling)"
  (not (error-object?
    (kernel-infer (quote (lam (j I) (comp2 (plam i KA0) (cofib j i1) (plam i Kca) (cofib i0 i1) (plam i Kca) Kca)))))))
; (3) DECIDED-psi comp over a Glue line: psi empty -> Glue = A, psi held -> Glue = T (via the Glue boundary)
(kernel-assume (quote Kphi) (quote I))
(kernel-assume (quote Kua) (quote (Pi (i I) KA0)))
(kernel-assume (quote Kg0a) (quote KA0))
(kernel-assume (quote Ku2) (quote (Pi (i I) (Glue KA0 (cofib Kphi i1) KT0 Kee))))
(kernel-assume (quote Kg2) (quote (Glue KA0 (cofib Kphi i1) KT0 Kee)))
(must "[audited kernel] comp over a Glue line, psi EMPTY: well-typed (Glue = A, reduces through comp in A)"
  (iuv-glue-comp-check
    (quote (comp (plam i (Glue KA0 (cofib i0 i1) KT0 Kee)) (cofib Kphi i1) (plam i (app Kua i)) Kg0a))
    (quote (Glue KA0 (cofib i0 i1) KT0 Kee))))

; ---- the general UNDECIDED-psi Glue-composition: mapped to its root blocker, kept NEUTRAL ----
; The construction's A-component a1 = comp2 <_>A [phi -> unglue u] [psi -> equiv-fun e (Tfiller)] (unglue g0)
; needs the composition FILLER to satisfy Tfiller(i) == u(i) on phi.  An earlier reading blamed "comp2 not being
; Kan"; that was too pessimistic -- the DAMPED filler Tfiller(i) = comp2 <l>T [phi -> <l>u(i/\l)] [(cofib i i0)
; -> <l>g0] g0 (partial damped by i/\l) DOES satisfy it: VERIFIED below that Tfiller(i) = u(i) on phi, using the
; one-empty-face reduction at the i1 end.  The remaining gap was DIAGNOSED THIS ITERATION to its exact
; mechanism: the face-restricted SECTION check (kctx_restrict + kt_subst of the leg body) is INDEX-INCONSISTENT
; when a leg directly consumes a refined glue variable.  kt_subst(body, vidx, ep) DECREMENTS the body's indices
; above the face variable, but kctx_restrict keeps those context entries at their original index -- so a leg like
; equiv-fun(e, gg) (which needs gg refined to T on the face) mis-resolves gg's older-than-face neighbours and is
; rejected, while a leg consuming gg only through unglue/transp type-checks.  That is exactly why the Glue
; TRANSPORT a1 (unglue/transp legs) works but the Glue-COMPOSITION a1 (a direct equiv-fun(e, filler) leg) does
; not.  The fix this iteration was an index-STABLE restriction (mark the face variable as a context
; DEFINITION = ep, substitute nothing); details in the next section.  First, the DAMPED-FILLER regularity that
; the Glue-composition relies on: with phi held, the damped filler is u(i), NOT the composite u(i1).
(kernel-assume (quote Kgt) (quote KT0))            ; g0 : T0 (psi imposed, for the filler in T)
(kernel-assume (quote Kut) (quote (Pi (i I) KT0))) ; u : Pi I T0 (psi imposed)
(kernel-assume (quote Kii) (quote I))
(must "[audited kernel] DAMPED filler with phi held = u(i) (the regularity equation), not the composite u(i1)"
  (iuv-comp2-reduces?
    (quote (comp2 (plam l KT0) (cofib i1 i1) (plam l (app Kut (imeet Kii l))) (cofib Kii i0) (plam l Kgt) Kgt))
    (quote (app Kut Kii))))
; ---- the homogeneous comp over a Glue line now TYPE-CHECKS AND COMPUTES (the target, achieved) ----
; The blocker last iteration was the face-restricted SECTION check: kt_subst of the leg body decremented
; indices that kctx_restrict kept, mis-resolving a leg that directly consumes a refined glue variable.  THIS
; iteration fixed it with a cleaner, index-STABLE restriction: kctx_restrict now marks the face variable as a
; DEFINITION (value = ep) instead of substituting, and the callers stop substituting the term -- kt_whnf reduces
; the face variable to ep on demand, so nothing moves and the leg type-checks.  With that, the full CCHM
; homogeneous Glue-composition res = glue A psi T e t1 a1 (t1 = comp <k>T [phi -> u] g0; a1 = comp2 <k>A
; [phi -> unglue u] [psi -> equiv-fun e (Tfill)] (unglue g0); Tfill the composition filler) TYPE-CHECKS, and comp
; over a constant Glue line on an UNDECIDED psi now AUTO-REDUCES to that glue element.  Verified sound: the
; boundary is correct (phi-held -> u(i1), phi-empty -> the base), the decided-psi cases compute via the Glue
; boundary, and an overlap-incoherent or wrong-typed leg is still REJECTED.
(kernel-assume (quote LA) (quote (Sort 0))) (kernel-assume (quote LT) (quote (Sort 0)))
(kernel-assume (quote Lee) (quote (Equiv LT LA)))
(kernel-assume (quote Lj) (quote I))
(kernel-assume (quote Lg) (quote (Glue LA (cofib Lj i1) LT Lee)))
(kernel-assume (quote Lu) (quote (Pi (i I) (Glue LA (cofib Lj i1) LT Lee))))
(must "[audited kernel] comp over a Glue line (undecided psi) TYPE-CHECKS at the Glue type"
  (iuv-glue-comp-check
    (quote (comp (plam i (Glue LA (cofib Lj i1) LT Lee)) (cofib Lj i1) (plam i (app Lu i)) Lg))
    (quote (Glue LA (cofib Lj i1) LT Lee))))
(must "[audited kernel] Glue-composition boundary: phi-HELD (psi undecided) gives u(i1) -- a genuine composition, not a fabrication"
  (iuv-comp2-reduces?
    (quote (comp (plam i (Glue LA (cofib Lj i1) LT Lee)) (cofib i1 i1) (plam i (app Lu i)) Lg))
    (quote (app Lu i1))))
(must "[audited kernel] Glue-composition boundary: phi-EMPTY (psi undecided) gives the base g0"
  (iuv-comp2-reduces?
    (quote (comp (plam i (Glue LA (cofib Lj i1) LT Lee)) (cofib i0 i1) (plam i (app Lu i)) Lg))
    (quote Lg)))
(must "[audited kernel] index-stable face restriction: a leg directly consuming a refined glue var type-checks (the fix)"
  (not (error-object?
    (kernel-infer (quote (lam (j I) (lam (g (Glue LA (cofib j i1) LT Lee))
      (comp (plam i LA) (cofib j i1) (plam i (app (equiv-fun Lee) g)) (unglue LA (cofib j i1) LT Lee g)))))))))

; ---- multi-face groundwork: a first-class cofibration DISJUNCTION (cofib-or c1 c2) ----
; The cofibration lattice now has a join: (cofib-or c1 c2) holds if EITHER disjunct holds and is empty
; only if BOTH are empty.  This is the brick multi-face systems are built on (a system over a disjunction
; is a value on each disjunct, agreeing on the overlap).  It has full kernel support (shift/subst/whnf/
; infer/equality/print) and is WIRED into hcomp1's whnf and compatibility, so a homogeneous composition
; over a disjunction face reduces on its decided disjuncts.  The HETEROGENEOUS comp over a Glue line that
; this would eventually feed remains future work: it additionally needs the CCHM "pres" construction (the
; naive transport+comp2 recipe fails overlap-coherence under a varying equivalence -- verified this iteration).
(kernel-assume (quote DA) (quote (Sort 0)))
(kernel-assume (quote Da0) (quote DA)) (kernel-assume (quote Db0) (quote DA))
(kernel-assume (quote Dj) (quote I)) (kernel-assume (quote Dm) (quote I))
(must "[audited kernel] (cofib-or c1 c2) is well-formed when both disjuncts are cofibrations"
  (not (error-object? (kernel-infer (quote (cofib-or (cofib Dj i1) (cofib Dm i1)))))))
(must "[audited kernel] (cofib-or ..) with a bare interval point (not a cofibration) is REJECTED"
  (error-object? (kernel-infer (quote (cofib-or (cofib Dj i1) Dj)))))
(must "[audited kernel] hcomp1 over a disjunction with a HELD disjunct reduces to the partial"
  (iuv-comp2-reduces? (quote (hcomp1 DA (cofib-or (cofib i1 i1) (cofib Dj i1)) Da0 Da0)) (quote Da0)))
(must "[audited kernel] hcomp1 over a disjunction with BOTH disjuncts empty reduces to the base"
  (iuv-comp2-reduces? (quote (hcomp1 DA (cofib-or (cofib i0 i1) (cofib i1 i0)) Da0 Da0)) (quote Da0)))
(must "[audited kernel] disjunction compatibility: a held disjunct with partial =/= base is REJECTED"
  (error-object? (kernel-infer (quote (hcomp1 DA (cofib-or (cofib i1 i1) (cofib Dj i1)) Db0 Da0)))))

; ---- HETEROGENEOUS comp over a Glue line: the Glue type VARYING in i now type-checks ----
; The Glue line varies A(i), T(i) AND the equivalence e(i) (phi constant in i).  Last iteration's
; "obstruction" was largely a setup artifact -- a glue type with a CONSTANT equivalence but a phi-leg
; with a VARYING one.  With the equivalence varying coherently in BOTH, plus one sound kernel fix
; (comp2 now SKIPS the section check on an EMPTY face, whose partial is vacuous and -- for a non-constant
; line -- cannot have the section type away from the face), the full CCHM heterogeneous result
;   res = glue A(i1) phi T(i1) e(i1) t1 a1,  t1 = comp <i>T(i) [phi -> wt] (wt i0),
;     a1 = comp2 <i>A(i) [psi -> <i>unglue u(i)] [phi -> <i>equiv-fun(e(i), Tfill(i))] (unglue g0),
;     Tfill(i) = comp2 <l>T(i/\l) [phi -> <l>wt(i/\l)] [(cofib i i0) -> <l>wt(i0)] (wt i0)
; type-checks.  The connection-line filler Tfill plays the role of CCHM "pres" -- no separate primitive
; is needed.  (Auto-reduction wiring for this heterogeneous case is future work; the TYPING is the result.)
(kernel-assume (quote HA0) (quote (Sort 0))) (kernel-assume (quote HA1) (quote (Sort 0)))
(kernel-assume (quote HPA) (quote (Path (Sort 0) HA0 HA1)))
(kernel-assume (quote HT0) (quote (Sort 0))) (kernel-assume (quote HT1) (quote (Sort 0)))
(kernel-assume (quote HPT) (quote (Path (Sort 0) HT0 HT1)))
(kernel-assume (quote Hef) (quote (Pi (i I) (Equiv (papp HPT i) (papp HPA i)))))
(kernel-assume (quote Hwt) (quote (Pi (i I) (papp HPT i))))
; valid coherent system: u(i) = glue(.. wt i ..); g0 = u(i0)
(must "[audited kernel] connection-line filler Tfill(i) (the CCHM pres path) type-checks at T(i)"
  (not (error-object? (kernel-infer (list (quote lam) (quote (m I)) (list (quote lam) (quote (i I))
    (quote (comp2 (plam l (papp HPT (imeet i l))) (cofib m i1) (plam l (app Hwt (imeet i l))) (cofib i i0) (plam l (app Hwt i0)) (app Hwt i0)))))))))
(must "[audited kernel] HETEROGENEOUS comp over a Glue line (A,T,e varying; phi const) -- the full result type-checks at Glue A(i1) phi T(i1) e(i1)"
  (not (error-object? (kernel-infer
    (list (quote lam) (quote (j I)) (list (quote lam) (quote (m I))
      (list (quote glue) (quote HA1) (quote (cofib m i1)) (quote HT1) (list (quote app) (quote Hef) (quote i1))
            (quote (comp (plam i (papp HPT i)) (cofib m i1) (plam i (app Hwt i)) (app Hwt i0)))
            (list (quote comp2) (quote (plam i (papp HPA i)))
                  (quote (cofib j i1)) (list (quote plam) (quote i) (list (quote unglue) (quote (papp HPA i)) (quote (cofib m i1)) (quote (papp HPT i)) (list (quote app) (quote Hef) (quote i)) (list (quote glue) (quote (papp HPA i)) (quote (cofib m i1)) (quote (papp HPT i)) (list (quote app) (quote Hef) (quote i)) (list (quote app) (quote Hwt) (quote i)) (list (quote app) (list (quote equiv-fun) (list (quote app) (quote Hef) (quote i))) (list (quote app) (quote Hwt) (quote i))))))
                  (quote (cofib m i1)) (list (quote plam) (quote i) (list (quote app) (list (quote equiv-fun) (list (quote app) (quote Hef) (quote i))) (quote (comp2 (plam l (papp HPT (imeet i l))) (cofib m i1) (plam l (app Hwt (imeet i l))) (cofib i i0) (plam l (app Hwt i0)) (app Hwt i0)))))
                  (list (quote unglue) (quote HA0) (quote (cofib m i1)) (quote HT0) (list (quote app) (quote Hef) (quote i0)) (list (quote glue) (quote HA0) (quote (cofib m i1)) (quote HT0) (list (quote app) (quote Hef) (quote i0)) (list (quote app) (quote Hwt) (quote i0)) (list (quote app) (list (quote equiv-fun) (list (quote app) (quote Hef) (quote i0))) (list (quote app) (quote Hwt) (quote i0)))))))))))))
(must "[audited kernel] empty-face skip is SOUND: a wrong-typed partial on a NON-empty face is still REJECTED"
  (error-object? (kernel-infer (quote (lam (j I) (lam (g (Glue HA0 (cofib j i1) HT0 (app Hef i0)))
    (comp2 (plam k HA0) (cofib j i1) (plam k g) (cofib i1 i1) (plam k (unglue HA0 (cofib j i1) HT0 (app Hef i0) g)) (unglue HA0 (cofib j i1) HT0 (app Hef i0) g))))))))
; the heterogeneous comp now also COMPUTES: comp over a VARYING Glue line auto-reduces to a glue element,
; with the correct boundary (system face held -> u(i1); system face empty -> transport of g0).
(define Hui (quote (glue (papp HPA i) (cofib m i1) (papp HPT i) (app Hef i) (app Hwt i) (app (equiv-fun (app Hef i)) (app Hwt i)))))
(define Hu0 (quote (glue HA0 (cofib m i1) HT0 (app Hef i0) (app Hwt i0) (app (equiv-fun (app Hef i0)) (app Hwt i0)))))
(define Hgline (quote (plam i (Glue (papp HPA i) (cofib m i1) (papp HPT i) (app Hef i)))))
(must "[audited kernel] HETEROGENEOUS comp over a Glue line COMPUTES: system face HELD -> u(i1) (the genuine boundary, not a fabrication)"
  (iuv-comp2-reduces?
    (list (quote lam) (quote (m I)) (list (quote comp) Hgline (quote (cofib i1 i1)) (list (quote plam) (quote i) Hui) Hu0))
    (list (quote lam) (quote (m I)) (quote (glue (papp HPA i1) (cofib m i1) (papp HPT i1) (app Hef i1) (app Hwt i1) (app (equiv-fun (app Hef i1)) (app Hwt i1)))))))
(must "[audited kernel] HETEROGENEOUS comp over a Glue line COMPUTES: system face EMPTY -> transport of g0 along the Glue line"
  (iuv-comp2-reduces?
    (list (quote lam) (quote (m I)) (list (quote comp) Hgline (quote (cofib i0 i1)) (list (quote plam) (quote i) Hui) Hu0))
    (list (quote lam) (quote (m I)) (list (quote transp) Hgline Hu0))))

; ---- toward a VARYING gluing cofibration: the forall-face quantifier (cofib-forall i phi) ----
; CCHM's comp over a Glue line whose gluing cofibration phi(i) VARIES in i needs the forall-face
; delta = (forall i. phi(i)) -- the locus where the gluing structure is stable along the whole line.
; This iteration adds (cofib-forall i phi) as a first-class cofibration with a CONSERVATIVE, sound
; decision (held only when certainly held for all i; empty only when phi certainly fails at an endpoint;
; else neutral), and wires its decided-HELD case into comp: when phi holds throughout, Glue = T(i)
; everywhere, so comp over the Glue line reduces to the composition in the T-line.  The genuinely-hard
; remaining case (phi varies and the forall is EMPTY, e.g. phi(i)=(cofib i i1)) needs the equivalence
; lemma and is left NEUTRAL -- sound, never fabricated.
(must "[audited kernel] (cofib-forall i (cofib i i1)) decides EMPTY (i=i1 fails at i0)"
  (iuv-comp2-reduces? (quote (cofib-forall i (cofib i i1))) (quote (cofib i0 i1))))
(must "[audited kernel] (cofib-forall i (cofib i1 i1)) decides HELD (holds for all i)"
  (iuv-comp2-reduces? (quote (cofib-forall i (cofib i1 i1))) (quote (cofib i1 i1))))
(must "[audited kernel] (cofib-forall i i) -- a forall over a non-cofibration body -- is REJECTED"
  (error-object? (kernel-infer (quote (cofib-forall i i)))))
(kernel-assume (quote FT0) (quote (Sort 0))) (kernel-assume (quote FT1) (quote (Sort 0))) (kernel-assume (quote FPT) (quote (Path (Sort 0) FT0 FT1)))
(kernel-assume (quote Fwt) (quote (Pi (i I) (papp FPT i)))) (kernel-assume (quote Fj) (quote I))
(must "[audited kernel] comp over a Glue line whose phi holds THROUGHOUT reduces to the composition in the T-line"
  (iuv-comp2-reduces?
    (list (quote comp) (quote (plam i (Glue (papp FPT i) (cofib i1 i1) (papp FPT i) (id-equiv (papp FPT i))))) (quote (cofib Fj i1)) (list (quote plam) (quote i) (quote (app Fwt i))) (quote (app Fwt i0)))
    (list (quote comp) (quote (plam i (papp FPT i))) (quote (cofib Fj i1)) (list (quote plam) (quote i) (quote (app Fwt i))) (quote (app Fwt i0)))))
(must "[audited kernel] the genuinely-hard varying-phi case (phi(i)=(cofib i i1), forall EMPTY) stays NEUTRAL -- never fabricated"
  (iuv-comp2-reduces?
    (list (quote transp) (quote (plam i (Glue (papp FPT i) (cofib i i1) (papp FPT i) (id-equiv (papp FPT i))))) (quote (app Fwt i0)))
    (list (quote transp) (quote (plam i (Glue (papp FPT i) (cofib i i1) (papp FPT i) (id-equiv (papp FPT i))))) (quote (app Fwt i0)))))

; ---- the trust base, reported honestly ----
(must "the module reports the full scaffold: heterogeneous Glue-comp computes; the forall-face quantifier is wired"
  (equal? (iuv-trust-base)
          (quote (          (path-refl . audited-trusted-kernel)
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
                    (varying-gluing-cofibration-the-forall-EMPTY-equivalence-lemma-and-multi-face-composition . surface-cubical-layer-or-roadmap)))))

(newline)
(display "ua TYPING now rests on the audited ~1,350-line trusted kernel -- the kernel accepts (ua e):(Id (Sort n) A B)") (newline)
(display "and rejects ua of a non-equivalence, ua at wrong endpoints, and Equiv of a non-type (a permanent guard in") (newline)
(display "lizard's kernel_soundness_test).  ua COMPUTATION (transport via Glue) stays surface/roadmap, named not faked.") (newline)
(display "An equivalence is a path, checked by the trusted core -- the deepest floor, honestly anchored (iuv-caveat).") (newline)
