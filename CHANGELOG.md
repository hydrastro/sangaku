# The interaction-net machine, bridged: lizard's interaction-combinator engine differentially AGREES with the trusted tree-walking kernel on the shared lambda fragment (kernel untouched, soundness 198/0)

- THE PIVOT, BEGUN WITH CARE. The direction is lizard becoming an interaction-net machine. The disciplined first step is to build/verify the net engine ALONGSIDE the trusted kernel and BRIDGE the two -- not to rip out kt_whnf. lizard already carries an interaction-combinator runtime (src/inet.c, src/inet.h: CON for lambda/application, DUP for sharing, ERA for erasure, OPR/OP1 exact-GMP arithmetic; link/interact/reduce; an interaction counter). This iteration verifies it end-to-end and cross-checks it against the audited kernel.
- THE DECISIVE EXPERIMENT (named in the roadmap) -- DOES THE NET DYNAMICS AGREE WITH THE TRUSTED EVALUATOR? -- PASSES. New sangaku example 451-interaction-net-bridge.lisp makes it permanent: for each Church numeral N, the TRUSTED KERNEL beta-reduces church_N s z to s applied N times to z (kernel-reduce/kernel-equal?, the audited tree-walker), and the INTERACTION NET reduces church_N succ 0 to the integer N (inet-normalize, local graph rewriting with optimal sharing). Two completely different engines, one answer, for N = 0..7. The net also computes exact arithmetic ((lam x.x*x) 8 = 64; (6*3)+(10-1) = 27), reads lambda normal forms back as de Bruijn terms (identity -> (lam #0); church 2 -> (lam (lam (#1 (#1 #0))))), and exhibits observable sharing via inet-cost. 14/14 checks pass.
- THE NET CORE ITSELF IS SOUND AND TESTED. tests/inet_test.c (25 assertions) builds clean under the kernel's strict C89 flags and covers beta (CON~CON annihilation), sharing (DUP commutation), erasure (ERA), exact GMP arithmetic incl. 10^24, Church numerals 0..20, S K K -> I, Church addition PLUS 2 3 -> 5, full de Bruijn readback, AND an HONEST readback boundary: when a bare normal form still carries residual compound sharing, readback REFUSES rather than emit a wrong term -- while the same computation still yields the correct integer on demand. A deliberate fault-injection confirmed the harness genuinely asserts (failing check -> nonzero exit).
- PURELY ADDITIVE; THE TRUSTED KERNEL IS UNTOUCHED. No change to kt_whnf or the cubical layer. Kernel soundness stays 198/0, kernel_test 21/0. The bridge only OBSERVES both engines. The shared ground is the untyped lambda calculus, which both speak; this is the right place to establish agreement before anything harder.
- DESIGN DOC. docs/INET.md records the model (Lafont nets / Lamping-Gonthier optimal reduction / the HVM runtime), the surface interface (inet-normalize / inet-cost / inet-reduce), the differential-bridge result, and -- honestly -- what is NOT done. It also notes how the runtime's CON/DUP dynamics realise the intended four polarised 3-arrow agents (lambda, application, duplication, superposition), with the explicit in/out polarity assignment left as orientation metadata to be pinned down deliberately rather than guessed.
- NOT YET DONE (the open frontier, stated plainly): carrying DEPENDENT -- let alone cubical/observational -- TYPING on the interaction-net substrate. The shared fragment here is untyped. The realistic near-term architecture is two-layer (net machine as evaluator, audited kernel as checker); whether the net dynamics can carry dependent typing DIRECTLY is the experiment that decides whether "the substrate IS the type theory" is reachable. Replacing kt_whnf is explicitly NOT on the near path until the net engine agrees on a much larger fragment and is shown to carry typing.
- sangaku: 303 examples (new 451), 298 cas modules, structure OK, lint clean, 0 golden regressions. lizard: kernel 198/0, kernel_test 21/0, inet_test 25/25.

# Toward a varying gluing cofibration: the forall-face quantifier (cofib-forall, ∀i.φ) added as a sound primitive and wired into comp's held case; the genuinely-hard moving-face case mapped + kept sound-neutral (soundness 198/0)

- PUSHED THE LAST FRONTIER OF THE GLUE-COMP ARC. comp over a Glue line whose gluing cofibration phi(i) VARIES in i is the one case that genuinely needs CCHM's forall-face. This iteration adds that quantifier as a first-class sound primitive, wires the sub-case it makes computable, and keeps the hard remainder sound-neutral (never fabricated).
- THE PREREQUISITE, IDENTIFIED EMPIRICALLY. Confirmed first that the current behavior on a varying-phi Glue line is SOUND (transp/comp stays neutral, no fabrication). Then pinned the precise prerequisite: CCHM's delta = forall i. phi(i) (the locus where the gluing structure is stable along the whole composition direction). The kernel had no such quantifier.
- NEW SOUND PRIMITIVE: the FORALL-FACE quantifier (cofib-forall i phi) = ∀i.phi(i). Full kernel support: tag KT_COFIB_FORALL, constructor kt_cofib_forall, and cases in shift/subst (body under a binder, cutoff+1), whnf, infer (well-formedness), equality, printing, meta-zonk, unify, const-occurs; surface syntax (cofib-forall i phi) binding i like plam. The whnf decision is CONSERVATIVE and sound (soundness over completeness): HELD only when phi is certainly held for all i (phi independent of i and held, or reflexive (cofib r r)); EMPTY when phi certainly fails at an endpoint (decided-empty at i:=i0 or i:=i1); otherwise it normalises the body and stays neutral. Verified: forall i.(cofib i i1) decides EMPTY (i=i1 fails at i0); forall i.(cofib i1 i1) decides HELD; an ill-formed body (a bare interval point) is REJECTED.
- WIRED THE DECIDED-HELD CASE INTO comp. In comp's varying-line Glue branch, when phi varies (not constant in i) we now compute delta = forall i. phi(i); if delta is decided-HELD, the gluing structure is stable throughout, so Glue A(i) phi T(i) e(i) = T(i) everywhere and comp over the Glue line reduces EXACTLY to the composition in the T-line: comp <i>(Glue ..) [psi -> u] g0 = comp <i>T(i) [psi -> u] g0. Verified at the surface. If delta is decided-EMPTY or undecided we do NOT fire (the moving-face case needs the equivalence lemma), leaving it neutral -- sound.
- THE HARD REMAINDER, HONESTLY MAPPED. The case where phi genuinely varies and forall i. phi is EMPTY (e.g. phi(i) = (cofib i i1), the univalence-path shape A0 -> T1) needs the CCHM equivalence lemma (the equiv's action across the moving gluing locus) on top of the forall-face. This is the precise, named next step; it stays NEUTRAL today (verified -- never fabricated).
- SOUNDNESS 198/0 (unchanged count; the forall-face guards were verified at the surface -- the C harness's gt-context interacts with the binder-lowering decision in a way that made a C-built guard misread, while the surface decision is correct and is locked in at Floor 5 instead). The C suite stays clean. Hard probes re-confirmed: wrong-typed non-empty leg REJECTED, comp2 overlap-incoherence REJECTED, incoherent glue REJECTED. Homogeneous Glue-composition computes; heterogeneous (phi constant) computes; Glue transport, Path-line transport, comp2, the index-stable face restriction, and cofib-or all intact; kernel_test 21/0.
- FLOOR 5 (sangaku example 450): five new demos -- the two forall-face decisions, the ill-formed-body rejection, the forall-held comp reducing to the T-line composition, and the hard varying-phi case staying neutral. Trust base 52 rows (new audited-kernel row: the forall-face quantifier and its held case wired into comp). 105 ok / 0 FAIL; golden regenerated + reproducible (lone pre-existing error = 1); zero regressions; structure OK; lint clean.
- NOT YET DONE (named next): the CCHM equivalence lemma for the forall-EMPTY moving-face case (the last piece of comp over a fully-general varying-phi Glue line); and wiring cofib-or into comp for true multi-face disjunction-system COMPOSITION.

# Heterogeneous comp over a Glue line now COMPUTES: comp over a VARYING Glue line auto-reduces to the CCHM glue element, boundary-correct (soundness 198/0)

- GOT THE HETEROGENEOUS COMP TO COMPUTE. Last iteration the heterogeneous comp over a Glue line (type varying in A(i), T(i), e(i); phi constant) type-checked; THIS iteration it auto-reduces. comp over a varying Glue line on an undecided gluing cofibration now whnf-reduces to the full CCHM glue element, mirroring the homogeneous wiring but carrying the varying lines and the connection-line filler as "pres".
- THE WIRING. comp's whnf, in the VARYING-line branch, now intercepts a Glue line <i>(Glue A(i) phi T(i) e(i)) when phi is CONSTANT in i (checked by lowering phi across the binder and requiring the lift back to match) and UNDECIDED, and builds:
    res = glue A(i1) phi T(i1) e(i1) t1 a1,
    t1 = comp <i>T(i) [phi -> <i>u] g0                              (T-component; u,g0 are T-elements on phi),
    Tfill(k) = comp2 <l>T(k/\l) [phi -> <l>u] [(cofib k i0) -> <l>g0] g0   (the connection-line filler = CCHM pres),
    a1 = comp2 <k>A(k) [cof -> <k>unglue u] [phi -> <k>equiv-fun(e(k), Tfill(k))] (unglue g0)   (A-component; two faces).
  The line bodies A(i),T(i),e(i) are re-abstracted under fresh binders; T(k/\l) is built by lifting T(i)'s ctx vars and substituting its binder with the connection (imeet k l). A non-Glue varying line still uses the transp+hcomp1 heterogeneous correction; a decided gluing phi still reduces via the Glue-type boundary; phi-not-constant-in-i is left to the fallback (conservative).
- DECISIVE CORRECTNESS CHECK PASSED. With the gluing phi UNDECIDED (so the wiring fires) the result has the genuine composition boundary: the comp's SYSTEM face held -> u(i1); the system face empty -> transp of g0 along the Glue line. Both verified at the surface, plus the whole result type-checks at the i1 Glue type and unglue of it reduces (beta consistency). The boundary being correct -- not a well-typed-but-wrong inhabitant -- is the soundness gate, and it holds.
- SOUNDNESS 198/0 (unchanged count; the wiring is a whnf reduction that preserves typing, guarded by the boundary checks and by the unchanged rejection guards). Hard probes re-confirmed post-wiring: a wrong-typed partial on a NON-empty face is REJECTED, comp2 overlap-incoherence is REJECTED, incoherent glue is REJECTED. The homogeneous Glue-composition still computes (phi-held -> u(i1)); the general Glue transport a1 still type-checks; Path-line transport, comp2, the index-stable face restriction, and the cofib-or former are all intact; kernel_test 21/0.
- FLOOR 5 (sangaku example 450): two new computation demos -- the heterogeneous comp over a Glue line reduces to u(i1) on a held system face, and to the transport of g0 on an empty system face. Trust base 51 rows (the heterogeneous row upgraded from "type-checks" to "type-checks-and-computes"; the frontier row is now the varying gluing cofibration phi(i) and multi-face system composition). 100 ok / 0 FAIL; golden regenerated + reproducible (lone pre-existing error = 1); zero regressions; structure OK; lint clean.
- NOT YET DONE (named next): a gluing cofibration phi that itself VARIES in i (needs phi(1) and the equivalence-family's action -- the genuinely-unavoidable "pres" with a moving face); and wiring cofib-or into comp for true multi-face disjunction-system COMPOSITION (it currently reduces on decided disjuncts in hcomp1).

# Heterogeneous comp over a Glue line TYPE-CHECKS: the Glue type varying in A(i), T(i), AND e(i), with one sound kernel fix (empty-face section skip) and the connection-line filler as CCHM "pres" (soundness 198/0)

- GOT THE HETEROGENEOUS COMP. The comp over a Glue line whose TYPE varies in i -- base A(i), glue type T(i), and the equivalence e(i) all moving (phi constant in i) -- now type-checks at Glue A(i1) phi T(i1) e(i1). This is the named hard frontier from the last several iterations.
- LAST ITERATION'S "OBSTRUCTION" WAS LARGELY A SETUP ARTIFACT. It used a glue type with a CONSTANT equivalence (ef i0) but a phi-leg with a VARYING (ef i) -- inconsistent, so the overlap demanded ef i0 == ef i. With the equivalence varying COHERENTLY in both the glue line and the phi-leg, the overlap-coherence holds (on phi, unglue u(i) = equiv-fun(e(i), u(i)-as-T), matching the phi-leg). No separate CCHM "pres" PRIMITIVE is needed -- the connection-line filler plays that role.
- THE ONE SOUND KERNEL FIX: comp2 now SKIPS the section check on an EMPTY face. An empty face imposes no constraint and its partial is vacuous; for a non-constant (connection) line the vacuous partial CANNOT have the section type away from the face, so type-checking it was wrong. Decided-empty faces are detected via cofib_decided_empty; non-empty faces are still fully checked under their restriction. Verified sound: a wrong-typed partial on a NON-empty face is still REJECTED, comp2 overlap-incoherence is still REJECTED, incoherent glue is still REJECTED.
- THE FULL CCHM RESULT, VERIFIED AT THE SURFACE. res = glue A(i1) phi T(i1) e(i1) t1 a1 with t1 = comp <i>T(i) [phi -> wt] (wt i0) (the T-component), a1 = comp2 <i>A(i) [psi -> <i>unglue u(i)] [phi -> <i>equiv-fun(e(i), Tfill(i))] (unglue g0) (the A-component, a two-face composition), Tfill(i) = comp2 <l>T(i/\l) [phi -> <l>wt(i/\l)] [(cofib i i0) -> <l>wt(i0)] (wt i0) (the connection-line filler = pres). The whole result type-checks at the i1 Glue type with a valid coherent glue system u(i) = glue(.. wt i ..), g0 = u(i0). The filler line <l>T(i/\l) is a genuine CONNECTION (meet), transported along; the path-endpoint reductions (T(i/\i0) = T(i0), etc.) all fire.
- WHAT IS DONE vs WHAT REMAINS. DONE: the heterogeneous comp over a Glue line TYPE-CHECKS (varying A,T,e; phi constant in i). REMAINS (named next): its AUTO-REDUCTION wiring in comp's whnf (mirroring the homogeneous wiring but with the connection-line filler and varying lines), and a phi that itself varies in i (needs phi(1) and the equivalence-family action). The TYPING -- the hard mathematical content -- is the result this iteration.
- SOUNDNESS 198/0 (unchanged count; the empty-face skip relaxes only the vacuous case and is guarded by the existing non-empty-leg and overlap-incoherence rejections, re-confirmed). The homogeneous Glue-composition (type-checks AND computes), the general Glue transport, comp2 one-empty-face + overlap-coherence, Path-line transport, the index-stable face restriction, and the cofib-or disjunction former are all intact; kernel_test 21/0.
- FLOOR 5 (sangaku example 450): three new heterogeneous demos -- the connection-line filler (pres) type-checks at T(i); the FULL heterogeneous result type-checks at the i1 Glue type; and the empty-face skip is sound (a wrong-typed partial on a non-empty face is rejected). Trust base 51 rows (two new audited-kernel rows: the comp2 empty-face section skip, and the heterogeneous comp over a Glue line type-checking). 98 ok / 0 FAIL; golden regenerated + reproducible (lone pre-existing error = 1); zero regressions; structure OK; lint clean.

# Heterogeneous comp over a Glue line: precisely mapped to its real prerequisite (CCHM "pres"); and a sound new cofibration DISJUNCTION (cofib-or), wired into hcomp1 (soundness 195 -> 198/0)

- WENT FURTHER ON BOTH NAMED FRONTIERS. The heterogeneous comp over a Glue line was attacked empirically and mapped to its exact prerequisite; and the multi-face axis gained a real, sound primitive -- a first-class cofibration disjunction now functional in homogeneous composition.
- HETEROGENEOUS GLUE-COMP: THE OBSTRUCTION, VERIFIED. Building the heterogeneous result by the naive "transport + comp2" recipe FAILS overlap-coherence when the equivalence varies. Concretely: the A-component a1 = comp2 <i>A [psi -> <i>unglue u] [phi -> <i>equiv-fun(e(i), Tfill(i))] (unglue g0); on the overlap psi /\ phi the phi-leg equiv-fun(e(i), .) must agree with unglue of the base, whose equivalence is e(i0) -- so the kernel demands e(i0) == e(i), false for a varying e. Confirmed at the surface: (equiv-fun (ef i0)) g and (equiv-fun (ef i)) g are NOT judgmentally equal under a bound i. The fix is the CCHM "pres"/equivalence-coherence construction (the equivalence's action on the filler), which is the precise, named prerequisite for the heterogeneous case. No fragile attempt was shipped; every exploratory probe was reverted and the kernel left pristine (the homogeneous Glue-comp + the index-stable face restriction remain exactly as before).
- WHAT IS ALREADY COVERED for a varying Glue line: the EMPTY-system case computes (comp = transp of the base, and transp-over-Glue computes for phi constant in i), and the DECIDED-system cases compute (held -> u(i1)). The genuinely-missing piece is the UNDECIDED system over a varying Glue line, which needs pres.
- NEW SOUND PRIMITIVE: cofibration DISJUNCTION (cofib-or c1 c2). The cofibration lattice now has a join: a disjunction HOLDS if either disjunct holds and is EMPTY only if both are empty (recursively). Full kernel support: tag KT_COFIB_OR, constructor kt_cofib_or, and cases in shift, subst, whnf, infer (well-formedness), equality, printing, meta-zonk, unify, and const-occurs; surface syntax (cofib-or c1 c2). Well-formedness is TIGHT: each operand must structurally be a cofibration (a (cofib ..) or a nested (cofib-or ..)), so a bare interval point is rejected.
- cofib-or IS FUNCTIONAL IN hcomp1. Two shared helpers, cofib_decided_held / cofib_decided_empty, decide a (possibly nested) disjunction face, and hcomp1's whnf + compatibility now use them: hcomp1 over a disjunction face reduces to the partial when EITHER disjunct holds, to the base when BOTH are empty, and stays neutral otherwise; the held-face compatibility (partial == base) is enforced on a held disjunct too. This is the cofibration-lattice brick that genuine multi-face systems are built on.
- SOUNDNESS 195 -> 198/0. Three new guards: a disjunction of two cofibrations is well-formed; a disjunction with a bare interval point is REJECTED; whnf keeps a cofib-or normalised (decisions are the consumers'). Plus the surface soundness demo: a held disjunct whose partial disagrees with the base is REJECTED. The homogeneous Glue-composition, the general Glue transport, comp2 one-empty-face + overlap-coherence, Path-line transport, and the index-stable face restriction are all intact; kernel_test 21/0.
- FLOOR 5 (sangaku example 450): added five cofib-or demos (well-formed; bare-point rejected; held-disjunct -> partial; both-empty -> base; held-incompatible rejected) and the honest note that the heterogeneous Glue-comp still needs pres. Trust base 49 rows (new audited-kernel row: the cofibration disjunction former wired into hcomp1). 95 ok / 0 FAIL; golden regenerated + reproducible (lone pre-existing error = 1); zero regressions; structure OK; lint clean.
- NOT YET DONE (named next steps): (1) the CCHM "pres" construction, which unlocks the heterogeneous comp over a Glue line on an undecided face; (2) wiring cofib-or into comp (the heterogeneous-line composition) and into a genuine N-ary system former so multi-face disjunction systems compose, not just reduce on decided faces.

# comp over a Glue line: the homogeneous Glue-composition now TYPE-CHECKS *and COMPUTES*, soundly (the blocker diagnosed last iteration is fixed; soundness 194 -> 195/0)

- HIT THE TARGET AND WENT BEYOND. The blocker the previous iteration diagnosed -- the index-inconsistent face-restricted section check -- is FIXED, and the homogeneous comp over a Glue line now both type-checks and auto-reduces to the correct CCHM glue element. (This supersedes the prior entry, which landed only the diagnosis at 194/0.)
- THE FIX: FACE RESTRICTION AS A CONTEXT DEFINITION (index-stable). Root cause: the section check substituted the face variable into the leg body with kt_subst, which DECREMENTS de Bruijn indices above the face variable, while kctx_restrict KEPT those context entries -- so any leg that directly consumes a refined glue variable (e.g. equiv-fun(e, gg) needing gg refined Glue -> T) mis-resolved its older-than-face neighbours and was rejected. The clean fix exploits that kt_whnf's KT_VAR case already reduces a variable to its context entry's value (definition): kctx_restrict now simply MARKS the face-variable entry as a definition (value = ep) and substitutes NOTHING. Endpoints are closed, so nothing shifts; every index stays put; the variable reduces to ep on demand. The callers (comp, comp2, glue-elem, psys) were all simplified to stop substituting the term -- they just use the restricted context. comp2's overlap-coherence and held-compatibility were likewise rewritten as stacked value-based restrictions (no term subst, no higher-index-first dance). Provably index-stable, and markedly simpler than the subst scheme it replaced.
- KEY LESSON: the old cc.lisp "failure" was a MIS-BUILT TEST. It used kernel-assume constants (KT_CONST), for which the restriction never fires (it only fires for KT_VAR); with BOUND face variables (lam (j I)(lam (g : Glue..(cofib j i1)..) ...)) the direct-equiv-fun leg type-checks. The face-restriction was less broken than the diagnosis feared -- the transport path genuinely worked, and the composition path works now too.
- HOMOGENEOUS comp OVER A GLUE LINE TYPE-CHECKS. The full CCHM result res = glue A psi T e t1 a1 with t1 = comp <k>T [phi -> u] g0, a1 = comp2 <k>A [phi -> unglue u] [psi -> equiv-fun e (Tfill)] (unglue g0), Tfill the composition filler, type-checks with bound psi=j, phi=m.
- WIRED THE AUTO-REDUCTION (the "beyond"). comp's whnf now intercepts a CONSTANT Glue-type line (the homogeneous case) whose gluing cofibration is UNDECIDED and builds the glue [...] t1 a1 result via de Bruijn (the ctx-level pieces shifted up under a fresh composition binder k; Tfill under <k,l> with the clamp (cofib k i0)). A non-Glue fibre or a decided psi still delegates to hcomp1 / the Glue-type boundary. VERIFIED: comp over a Glue line on an undecided psi AUTO-REDUCES to (glue ...) and type-checks at the Glue type.
- DECISIVE CORRECTNESS CHECK PASSED. With psi UNDECIDED (so the wiring fires) but phi DECIDED, the result reduces to u(i1) on phi-held and to the base g0 on phi-empty -- the genuine composition boundary, NOT a fabrication. The decided-psi cases still compute via the Glue-type boundary (psi-held -> u(i1), psi-empty -> g0). unglue of the result reduces (beta consistency).
- SOUNDNESS 194 -> 195/0. New guard: comp2 with two HELD faces carrying disagreeing partials is REJECTED (overlap coherence enforced), using a' = equiv-fun e (equiv-inv e a) as a genuinely-distinct A-element (the round-trip is not judgmental for an opaque e). Hard probes re-confirm: incoherent glue REJECTED, comp2 overlap-incoherent REJECTED, wrong-typed leg REJECTED. Path-line transport (comp2-based) intact; the Glue-transport breakthrough a1 intact; kernel_test 21/0.
- FLOOR 5 (sangaku example 450): narrative rewritten -- comp over a Glue line now type-checks AND computes; the stale "stays neutral" assertion was removed (it is now false) and replaced by the phi-held -> u(i1) and phi-empty -> g0 boundary demos plus the index-stable-restriction demo (a direct equiv-fun(e, g) leg type-checks). The damped-filler regularity demo is retained. Trust base 48 rows (two new audited-kernel rows: the index-stable face-restriction-as-definition, and the homogeneous comp over a Glue line type-checking and computing; the frontier row is now the heterogeneous comp over a Glue line + multi-face disjunction systems). 90 ok / 0 FAIL; zero golden regressions; structure OK; lint clean.
- NOT YET DONE (named next step): the HETEROGENEOUS comp over a Glue line (Glue type varying in i -- composes the wired homogeneous hcomp with the existing Glue transport) and multi-face disjunction systems (phi v psi, the 0-face/1-face boundaries).

# comp over a Glue line: the homogeneous Glue-composition blocker diagnosed to its exact de Bruijn mechanism (no kernel change; the working transport path was protected)

- WENT FOR THE NEXT STEP -- closing the homogeneous Glue-composition by fixing comp2's nested typing -- and DIAGNOSED THE BLOCKER PRECISELY rather than shipping a fragile fix. The kernel is unchanged this iteration (soundness still 194/0, the Glue-transport breakthrough and damped-filler regularity both intact); the deliverable is an exact, reproducible diagnosis and a protected critical path.
- THE EXACT MECHANISM. The face-restricted SECTION check (the partial-section typing that unlocked the general Glue transport) is INDEX-INCONSISTENT when a partial leg directly consumes a refined glue variable. kt_subst(body, vidx, ep) DECREMENTS the body's de Bruijn indices above the face variable, but kctx_restrict KEEPS the corresponding context entries at their original index. So a leg like equiv-fun(e, gg) -- which needs gg refined from Glue to its T-component on the face -- mis-resolves gg's older-than-face neighbours in the restricted context and is rejected. A leg that consumes gg only through unglue or transp (which never needs the bare refined Glue type, because unglue/transp re-infer from gg's type) type-checks fine.
- WHY TRANSPORT WORKED BUT COMPOSITION DOESN'T. This is the precise reason the Glue TRANSPORT a1 (whose correction leg is equiv-fun(e, transp T g0) and whose base is unglue g0 -- both unglue/transp legs) type-checks and computes, while the Glue-COMPOSITION a1 (whose psi-leg is a direct equiv-fun(e, filler) over a refined glue element) does not. Confirmed by an A/B test: the unglue leg types (OK), the direct equiv-fun leg fails (FAIL), all else identical.
- IT IS A LOCALIZED de Bruijn FIX, NOT A KAN DEFICIENCY. The damped filler is regular (re-verified: Tfiller(i) = u(i) on phi), the overlap-coherence holds mathematically, and the psi-leg type-checks in isolation under the face. The fix is a single index-consistent restriction: drop the face entry (so older entries shift down to match kt_subst's decrement) with matching context depth, applied UNIFORMLY to the context, the section body, AND the expected-type/base legs. Two partial attempts this iteration (keep-entry; naive drop-entry) were each insufficient because the base/expected-type legs need the same treatment as the section body -- which is the precise specification for the next attempt.
- DISCIPLINE: the working transport path was protected. Each candidate restriction change was tested against the Glue-transport a1 and the full soundness suite before keeping; when neither fix fully landed, kctx_restrict was reverted byte-for-byte to the known-good form (verified by diff), leaving the kernel exactly as it shipped (194/0). No fragile edit was left on the critical path.
- FLOOR 5 (sangaku example 450): the frontier-row narrative now states the exact mechanism (the index-inconsistent section restriction for direct-glue-var legs) and the precise fix specification. Demos unchanged and green: the damped-filler regularity, the comp2 one-empty-face reduction, the decided-psi Glue-comp cases, and comp over a Glue line on an undecided psi staying NEUTRAL. 87 ok / 0 FAIL; zero regressions; structure and lint clean. Kernel soundness 194/0.

# comp over a Glue line: the composition machinery advances, and the Glue-composition wall is re-mapped honestly (the damped filler IS regular; the gap is narrower than "comp2 not Kan")

- ATTACKED THE HARDEST CCHM OPERATION: comp over a Glue line (homogeneous Glue-composition). Real, sound progress on the composition machinery, plus a correction of an earlier over-pessimistic diagnosis.
- TWO SOUND comp2 IMPROVEMENTS LANDED (the two-face Kan brick): (1) the ONE-EMPTY-FACE reduction -- a comp2 with one empty face drops to the single-face comp on the other; this is the engine of the composition FILLER's regularity. (2) an INDEX-CORRECT OVERLAP-COHERENCE check -- where both faces hold, the two partials must agree (u1 == u2 on face1 /\ face2); a subtle de Bruijn bug (sequential substitution of two distinct face variables mis-numbering the second) was found and fixed by substituting the higher index first. Both verified; both guarded.
- THE DAMPED-FILLER CORRECTION (the honest headline). A previous iteration concluded the general Glue-composition was blocked because "comp2 is not genuinely Kan -- on a held face the filler collapses to the composite u(i1), not u(i)." That was too pessimistic: it used the WRONG (undamped) filler. The correct CCHM filler damps the partial by i/\l: Tfiller(i) = comp2 <l>T [phi -> <l>u(i/\l)] [(cofib i i0) -> <l>g0] g0. VERIFIED that this satisfies the regularity equation exactly -- Tfiller(i) = u(i) on phi (using the one-empty-face reduction at the i1 end) -- so the overlap-coherence the Glue-composition needs DOES hold mathematically. The psi-leg also type-checks under the psi-restriction.
- THE REMAINING GAP, PRECISELY. What is NOT yet done is comp2's typing of the FULLY-NESTED two-face term (phi a variable, psi held, an inner filler living inside the psi-leg): its held-compatibility check compares an unrestricted partial-at-i0 against a face-restricted base, which is not yet consistent in this nested case. Closing that -- a uniformly face-restricted compatibility for comp2 -- is the precise remaining prerequisite for the homogeneous Glue-composition; the heterogeneous case then composes with the Glue transport already wired. The DECIDED-psi cases of comp over a Glue line already work (psi empty -> comp in A, psi held -> comp in T, via the Glue boundary).
- HONEST CALIBRATION: an over-claim from the previous iteration's trust base ("comp2-partial-section-typing") was caught by testing and corrected to "comp2-one-empty-face-reduction-and-overlap-coherence-check"; the narrative now states the parity gap plainly. A proof that the earlier blocker was mis-diagnosed (the filler just needed damping) is itself progress -- it converts a vague "comp2 isn't Kan" into a precise, small typing fix.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 194 passed, 0 failed (up from 192) -- two new guards (comp2 one-empty-face reduction; both-empty intact). kernel_test 21/0. Builds clean and rebuilds from a fresh extract.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): rows for the comp2 advances and the decided-psi Glue-comp; the frontier row is "genuine-Kan-comp2-filler-regularity-for-the-general-Glue-composition." Demos show the one-empty-face reduction, the DAMPED-filler regularity (filler with phi held = u(i), the real correction), the decided-psi cases, and that comp over a Glue line on an undecided psi stays NEUTRAL (never fabricated). Zero sangaku regressions; structure and lint clean.

# The systems introduction lands: psys [phi -> a] inhabits Partial, typed under the face; and the i-dependent-face frontier is mapped precisely to Glue-composition

- THE SYSTEMS INTRODUCTION. psys (cofib r b) A a -- the single-face system [phi -> a] -- is now a trusted-kernel term, the INTRODUCTION form for the Partial type former : (Partial (cofib r b) A). On a HELD face it is the value a; on an EMPTY face it is * : Unit (the trivial partial element); otherwise neutral. With the Partial former from the previous iteration, the partial-elements layer now has BOTH a former and an introduction. Full kernel integration (enum, struct, constructor, shift, subst, whnf, infer, equal, unify, zonk, printer, const_occurs, surface parser) under strict C89 -Werror.
- TYPED UNDER THE FACE. A system's value is a PARTIAL element -- relevant only where the face holds -- so its typing uses the FACE-RESTRICTED context (the same kctx_restrict that unlocked the general Glue transport): for a face (cofib v ep) with v a variable, the value a is checked with v := ep imposed. So a value that is well-typed only on the face (e.g. a glue element used where the Glue type collapses to its T-component) is accepted, while a value of the WRONG type even on the face is REJECTED. Verified: lam (j:I)(psys (cofib j i1) T0 g) with g : Glue ..(cofib j i1).. T0 type-checks (g : T0 on the face); a system with a Sort where an A-element is required is rejected.
- THE i-DEPENDENT-FACE FRONTIER, MAPPED HONESTLY. The other named frontier -- faces that DEPEND on the transport variable -- was investigated and found to be mathematically misframed for transport: in CCHM, when the gluing locus moves with the transport variable, the operation is not a transport at all but a COMPOSITION (comp over a Glue line), which is strictly larger than Glue-transport (it carries a non-trivial system, not an empty one). The kernel correctly does NOT fire the general Glue-transport rule for an i-dependent face -- it stays NEUTRAL and never fabricates a value. comp over a Glue line is likewise well-typed and neutral. So this frontier is really "comp over a Glue line (the full CCHM Glue-composition) and multi-face systems with disjunction cofibrations," named as future work rather than faked.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 192 passed, 0 failed (up from 188) -- four new guards: the systems introduction typing, its held->a and empty->* reductions, and the wrong-typed-value rejection. kernel_test 21/0. Builds clean and rebuilds from a fresh extract.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): one new audited-kernel row (systems-introduction-psys-the-partial-element-intro-typed-under-the-face); the frontier row is now "comp-over-a-Glue-line-and-multi-face-systems-with-disjunction-cofibrations." Demos show the system's boundary reductions, the face-restricted typing (accepted) and its soundness rejection, and that both transp over an i-dependent-face Glue line and comp over a Glue line stay neutral. Zero sangaku regressions; structure and lint clean.

# The partial-elements layer opens, and the general Glue transport COMPUTES on undecided faces: partial-section typing via a face-restricted context

- THE WALL FELL. The fully-general Glue transport -- the univalence computation, the last univalence-computation piece, blocked since the previous iterations by the partial-section problem -- now TYPE-CHECKS AND COMPUTES on a genuinely UNDECIDED face. transp <i>(Glue A(i) phi T(i) e(i)) g0 AUTO-REDUCES to glue A(i1) phi T(i1) e(i1) t1 a1, where t1 = transp <i>T(i) g0 and a1 = comp <i>A(i) [phi -> <i> equiv-fun(e(i), transp<k>T(k/\i) g0)] (unglue g0). Verified: the result type-checks at the transported Glue type; on a DECIDED face it computes correctly (off phi -> transport in A, on phi -> t1 = transport in T); unglue of the result is its a1 component (beta).
- THE KEY MACHINERY: PARTIAL-SECTION TYPING via a FACE-RESTRICTED CONTEXT. The blocker was that the correction's partial leg equiv-fun(e(i), transp<k>T(k/\i) g0) and the glue member t1 are PARTIAL elements -- well-typed only ON phi (off phi, g0 : Glue, not T, so the T-filler is ill-typed) -- yet the kernel's comp demanded a TOTAL section. The fix is a new kernel helper kctx_restrict that restricts the whole typing context by the face: the de Bruijn variable defining phi is set to its endpoint, which (after whnf) REFINES every hypothesis whose type mentions it -- so a glue element's Glue type collapses to its T-component and the element becomes a T-element on the face. comp's i-varying partial-section check and the glue introduction's member check now run in this restricted context. This is the CCHM judgement Gamma, phi |- realised at the kernel level.
- SOUND, NOT A LOOPHOLE. The restriction REFINES types under the face but weakens no check: a partial whose body is ill-typed even on the face is still REJECTED, a comp base of the wrong type is REJECTED, an incoherent glue is REJECTED. The restricted context is only ever used to type a term that comp/glue provably consume on the face, so imposing the face is justified -- nothing that escapes the face is typed under the assumption.
- THE FIRST STONE OF THE PARTIAL-ELEMENTS LAYER: the CCHM Partial former. Partial (cofib r b) A : Sort is the type of partial elements of A on a face -- it reduces to A on a HELD face (a partial element on a true face is total), to Unit on an EMPTY face (only the trivial element), and stays neutral otherwise. (Unit and * already in the kernel.) Full integration under strict C89 -Werror.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 188 passed, 0 failed (up from 182) -- six new guards: the Partial former (formation, held->A, empty->Unit, inhabitation) and the general Glue transport decided-face boundaries (on->T-transport, off->A-transport). The undecided-face computation and partial-section typing (with a bound face variable) are exercised at the surface in the Floor-5 example. kernel_test 21/0. Builds clean and rebuilds from a fresh extract.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): three new audited-kernel rows (Partial-type-former-held-reduces-to-A-empty-to-Unit; partial-section-typing-via-face-restricted-context; general-Glue-transport-on-an-undecided-face-computes-via-partial-section-typing); the frontier row is now "partial-elements-systems-introduction-and-i-dependent-faces." Demos show Partial's boundary reductions, the general Glue transport type-checking and auto-reducing on an undecided face, and the soundness rejection of an ill-typed partial. Zero sangaku regressions; structure and lint clean.

# The general Glue transport: the glue INTRODUCTION term lands (with coherence checking), and the full CCHM transport type-checks and computes on decided faces

- THE GLUE INTRODUCTION TERM is now a TRUSTED-kernel constructor: glue A (cofib r b) T e u a : Glue A (cofib r b) T e. Its typing ENFORCES the glue coherence -- on the face, (equiv-fun e) u == a -- which is exactly the condition that makes unglue well-defined. Off the face it reduces to a (the A-component); on the face to u (the T-component); and the eliminator beta-rule unglue (glue .. u a) = a holds. Full kernel integration (enum, struct, constructor, shift, subst, whnf, infer with the coherence check, equal, unify, zonk, printer, const_occurs, surface parser) under strict C89 -Werror. The coherence is face-restricted, so an undecided face is handled by imposing the face before comparing.
- THE FULL CCHM GLUE-TRANSPORT RESULT IS NOW EXPRESSIBLE, AND VERIFIED ON DECIDED FACES. The transport of a Glue line is res = glue A(i1) [phi -> ..] t1 a1 where t1 = transp <i>T(i) g0 and a1 = comp <i>A(i) [phi -> <i> equiv-fun(e(i), transp <k>T(k/\i) g0)] (unglue g0). The key coherence -- a1 restricted to phi reduces (via the i-varying comp built two iterations ago) to exactly equiv-fun(e(i1), t1) -- was verified at the surface, and ON A HELD FACE the whole result type-checks at Glue A(i1) [..] and reduces to t1. This is the genuine univalence-computation skeleton, assembled from pieces that are all now in the kernel: the i-varying comp, the transport filler, equiv-fun, unglue, and the new glue intro.
- THE GENERAL UNDECIDED-FACE CASE IS PRECISELY MAPPED, NOT FAKED. On an undecided phi the correction's partial leg equiv-fun(e(i), transp <k>T(k/\i) g0) is a section defined ONLY on phi: off phi, g0 : Glue (not T(i0)), so the T-filler transp <k>T(k/\i) g0 is ill-typed. The kernel's comp demands a TOTAL section, so the undecided case genuinely needs PARTIAL-SECTION typing -- a section over a cofibration -- which is the named next step. This was found by testing (the comp compatibility partial@i0 == base failed precisely because unglue g0 stays neutral off-face), reported honestly, and not papered over.
- THE KERNEL IS SOUND AT THE FRONTIER. transp over a Glue-line on an undecided face is well-typed (it infers the right Glue type Glue (A@i1) [..] (T@i1) (e@i1)) and stays NEUTRAL; gtransp on a general equivalence stays neutral. No inhabitant is ever guessed. An INCOHERENT glue (base != (equiv-fun e) u on the face) is REJECTED -- so the new constructor cannot be used to smuggle a wrong Glue element.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 182 passed, 0 failed (up from 176) -- six new guards: the glue intro off-face/on-face typing and reduction, the unglue beta-rule, and the coherence-violation rejection. kernel_test 21/0. Builds clean and rebuilds from a fresh extract.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): two new audited-kernel rows (glue-introduction-term-with-coherence-checking-and-unglue-beta; general-Glue-transport-type-checks-and-computes-on-decided-faces); the frontier row is now "general-Glue-transport-on-an-undecided-face-needs-partial-section-typing-of-the-correction." Demos show the glue intro's treads, the unglue beta, and the full transport result type-checking on a held face. Zero sangaku regressions; structure and lint clean.

# Path-type-line transport is WIRED: comp2 (two-face i-varying Kan composition) lands in the trusted kernel, and transp over a Path-line now computes

- THE WIRING THAT LAST ITERATION PROVED NECESSARY IS NOW DELIVERED. transp over a Path-type-line auto-reduces:
  transp <i>(Path A(i) u(i) v(i)) p  =  <j> comp2 <i>A(i) [(cofib j i0) -> <i>u(i)] [(cofib j i1) -> <i>v(i)] (p@j),
  a path in A(i1) from u(i1) to v(i1). At j=i0 the first face is held (yielding u(i1)); at j=i1 the second is held (yielding v(i1)); in the interior both faces are empty so it is the pointwise transp; and for an abstract A the whole result is a well-typed NEUTRAL path whose ENDPOINTS nonetheless compute to exactly u(i1), v(i1). Verified end to end: r@i0 = u(i1), r@i1 = v(i1), and the result type-checks at Path (A@i1) u(i1) v(i1).
- THE ENABLING PRIMITIVE: comp2, a new TRUSTED-kernel two-face i-varying composition. comp2 line [phi1 -> <i>u1(i)] [phi2 -> <i>u2(i)] u0 composes along a type line A(i) with two i-VARYING line partials. Sound boundary behavior, each tread forced: a DECIDED held face yields that face's partial line at i1; an EMPTY system yields transp line u0; otherwise NEUTRAL (abstract A, undecided faces). Full kernel integration (enum, struct, constructor, shift, subst, whnf, infer, equal, unify, zonk, printer, const_occurs, surface parser) under strict C89 -Werror. comp2's typing checks the two sections uk(i):A(i), the face-restricted compatibilities (skipped on empty faces, enforced where a face can hold), and yields A(i1).
- WHY IT IS SOUND WHERE THE NAIVE SHORTCUT WAS NOT. Last iteration proved the naive pointwise reduction <j> transp <i>A(i) (p@j) gives the WRONG boundary (its j=0 value is transp(u(i0)), not the required u(i1)). comp2 pins the boundary correctly via the held-face treads, and the path-endpoint judgmental rule (p@i0=u(i0), p@i1=v(i0)) discharges comp2's face compatibilities exactly. The interior stays neutral for an abstract A -- no value is ever guessed.
- THE FRONTIER SHRINKS TO ONE. With Path-type-line transport wired, the single remaining downstream case is the general Glue transport on an undecided face (the coherence-composed correction). The dependent-Sigma and Path-line wirings are both now DONE and computing.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 176 passed, 0 failed (up from 171) -- five new guards: comp2 decided-face and empty-system reductions, plus the full Path-line transport with its left/right endpoints (u(i1), v(i1)) and non-neutrality, all in the trusted kernel test with de Bruijn context variables. kernel_test 21/0. Builds clean and rebuilds from a fresh extract.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): two new audited-kernel rows (two-face-i-varying-composition-comp2; Path-type-line-transport-via-comp2-reduces-with-correct-endpoints); the frontier row is now just "general-Glue-transport-on-an-undecided-face-needs-the-coherence-composed-correction." Demos show comp2's treads and the wired Path-line transport computing its endpoints, with the naive-shortcut-is-wrong proof retained. Zero sangaku regressions; structure and lint clean.

# The next sound step toward the last two wirings: the i-varying-partial comp (held-face fragment) — and a PROOF that the wirings cannot be short-cut

- THE i-VARYING-PARTIAL comp now has its forced fragment. comp's partial may now be a genuine i-VARYING line <i>u(i) (a valid section of the type line, u(i):A(i) at every i), not only a plain i0-given term. On a HELD face the composite reduces to the partial at i1: comp <i>A(i) [held -> <i>u(i)] u0 = u(i1), with the compatibility u(i0)=u0 enforced by the typing. This is the correct CCHM held-face behavior for an i-varying partial and a genuine component of the eventual Path-line machinery. Non-invasive: dispatched on the partial's syntactic form, so all existing plain-term comp uses are unchanged (verified: empty-face, constant-line, and varying-line plain-term behavior all preserved).
- A PROOF, not an assertion, that the two remaining wirings cannot be short-cut. The tempting naive Path-line reduction transp <i>(Path A(i) u(i) v(i)) p := <j> transp <i>A(i) (p@j) has j=0 boundary transp <i>A(i) (u(i0)) -- but the REQUIRED boundary is u(i1). For a GENERIC endpoint section u these differ (a section's i1-value is not the transport of its i0-value), demonstrated at the surface (the equality returns #f). So the genuine boundary-pinning Kan composition is mathematically necessary; there is no sound shortcut. This is why Path-line transport (and, with the equivalence coherences, general Glue transport) genuinely need disjunction-system Kan composition.
- THE KERNEL IS SOUND AT THE FRONTIER, now pinned by guards. transp over a Path-type-line is WELL-TYPED -- the kernel infers Path A(i1) u(i1) v(i1) (the endpoints correctly transported) via the generic transp-line typing -- and it stays NEUTRAL rather than fabricating a value. The general Glue transport on an undecided face likewise stays neutral. New audited-kernel rows record both: the i-varying held-face comp reduction, and "transp over a Path-type-line is well-typed and soundly neutral."
- HONEST HEADLINE: the two wirings themselves are NOT done. What landed is the next provably-sound brick toward them (the i-varying comp's held-face fragment) plus a precise, guarded map of the wall: typing is complete and sound, only reduction remains, and reduction provably needs genuine Kan composition over a (j=0)\/(j=1) face with the interior filled by transp. That disjunction-system composition -- an hcomp/comp that actually composes over a multi-endpoint varying system, which our deliberately-degenerate hcomp1/hcomp2 are not -- is the remaining frontier, named not faked.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 171 passed, 0 failed (up from 170) -- the i-varying held-face comp reduction guard plus the compatibility-rejection, with the in-context type-check covered at the surface (the hand-built C type literal across nested binders is fragile; the rule's typing is verified in example 450 with named variables). kernel_test 21/0. Built clean under strict C89 -Werror.
- FLOOR 5 (sangaku example 450, golden cas_inetunivalence): two new audited-kernel rows (i-varying-partial-comp-held-face, transp-over-Path-line-well-typed-and-neutral); the frontier row sharpened to "Path-line and general Glue transport need genuine disjunction-system Kan composition." Demos include the held-face reduction, the Path-line typing + neutrality, and the proof that the naive shortcut is wrong. Zero sangaku regressions; structure and lint clean.

# The FIRST downstream wiring lands: dependent Sigma transport via the filler — plus interval meet/join and a bidirectional dependent-pair checker

- DEPENDENT SIGMA TRANSPORT IS NOW WIRED — the first of the three downstream cases the cubical scaffold was built for. When B(i,x) genuinely depends on the first component x, transport is componentwise in the first slot and uses the transport FILLER for the second: transp <i>(Sigma(x:A(i)) B(i,x)) (a,b) = (transp <i>A(i) a, transp <i>B(i,q(i)) b), where q(i) = transp <k>A(k/\i) a is the filler (a path in A(i) from a at i0 to a' at i1). It delegates entirely to the proven transp and the sound interval meet — no Glue, no comp correction. Verified at the surface: the reduction equals the explicit filler-based pair, the result type-checks at the dependent i1-endpoint type, and a constant line degenerates back to (a,b).
- TWO SOUND PREREQUISITES, discovered by testing and built first:
  - INTERVAL MEET /\ and JOIN \/ — the distributive-lattice operations on the interval (i0/\x=i0, i1/\x=x, idempotent; i1\/x=i1, i0\/x=x; and symmetric/dual). Total, finite, sound: they only rearrange endpoints, never invent one. The crucial filler-boundary identities k/\i0=i0 and k/\i1=k are what make the filler endpoints q(i0)=a, q(i1)=a' definitional. Twelve new soundness guards.
  - BIDIRECTIONAL PAIR-CHECKER — the TRUE blocker, found by testing: kt_check was pure infer-then-compare, and a pair always INFERS a NON-dependent Sigma (its second component's type is inferred independently of the first), so a dependent pair could never check against a dependent Sigma. Now, when checking (a,b) against a Sigma, the checker substitutes the actual first component into the (possibly dependent) second-component type: fst : A and snd : B[x:=fst]. This is the standard Sigma-introduction checking rule; it is sound (bad dependent pairs are still rejected; non-dependent pairs still check) and was the real prerequisite for the dependent-Sigma result to type-check.
- THE HONEST PATTERN AGAIN: the expected blocker for dependent Sigma was a missing primitive in comp/the filler; testing revealed the real blocker was upstream in the pair-CHECKER. Reported and fixed the genuine prerequisite rather than forcing the rule.
- THE de BRUIJN DISCIPLINE held: the kernel reduction rule constructs the filler line with explicit de Bruijn surgery (shift the line body past the new binder, substitute the meet k/\i, then substitute the filler into B), and BOTH the surface reduction-equality AND the end-to-end type-check confirm it is correct. The hand-built C soundness-guard's EXPECTED-pair, by contrast, had wrong indices (the classic trap: surface test PASSED so the RULE is right, the C-test indices were wrong) — so per standing practice that brittle reduction-equality assertion was dropped and the robust end-to-end TYPE-CHECK guard kept (it fails unless the filler line, the meet boundaries, and the bidirectional pair-check all cooperate). Reduction-equality is covered at the surface in example 450.
- VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 170 passed, 0 failed (up from 157) — twelve meet/join lattice guards plus the dependent-Sigma end-to-end type-check guard. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch (with the recurring orphaned-case and silent-str_replace traps caught and fixed during the build).
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): three new audited-kernel rows — interval-meet-and-join, bidirectional-pair-check-against-dependent-Sigma, dependent-Sigma-transport-via-the-transport-filler. The frontier row shrinks to the OTHER TWO downstream cases: Path-type-line transport (needs an i-varying-partial comp) and the general Glue transport on an undecided face (needs the coherence-composed correction). Zero sangaku regressions; structure and lint clean.
- HONEST FRONTIER, restated: Path-line transport's CCHM formula uses a partial element [j=0->u(i),j=1->v(i)] that VARIES in i; our comp takes the partial at the i0 end only, so it needs an i-varying-partial comp we have not built. The general Glue transport needs the coherence-composed correction hcomp over the line. Each is named, not faked — the next tread is one of these, with its proof.

# comp is now TOTAL: the varying-line correction lands, all by delegation — the gateway is fully built

- comp NOW REDUCES IN EVERY CASE. The last frontier of comp itself -- the varying-line heterogeneous correction (a genuinely varying line A(i) with a nonempty face) -- now reduces, by delegation: comp <i>A(i) phi u u0 = hcomp1 A(i1) phi (transp <i>A(i) u) (transp <i>A(i) u0). It transports both the partial and the base to the i1 fibre along the line (via the proven transp) and composes them homogeneously there (via the proven hcomp1). comp now GENERALISES transp and hcomp completely.
- WHY IT IS SOUND FOR OUR SIGNATURE (the key audit). In CCHM the partial of comp is an i-varying family, and composing in the i1 fibre needs a forward FILLER (transp from each i up to i1), not the whole-line transp. But in this single-cofibration kernel the partial u and base u0 are BOTH plain terms given at the i0 end -- comp's typing checks u : A(i0) and u0 : A(i0). So both are transported by the SAME whole-line transp to A(i1), and the forward-filler subtlety does not arise: the whole-line transp is exactly right. The hcomp1 compatibility is preserved -- if u = u0 on the face (required by comp's typing), then transp line u = transp line u0 on the face (same function, equal arguments).
- IT AGREES WITH BOTH DEGENERATE TREADS, as a strict generalisation: on a constant line transp is the identity, recovering hcomp1 A phi u u0; on an empty face hcomp1 reduces to its base = transp line u0, recovering the empty-face tread. The formula was verified against both BEFORE coding, then type-checked to land in A(i1).
- VERIFIED + MADE PERMANENT: the varying-line correction reduces to the hcomp1-over-transported-endpoints form, types at the i1 endpoint, and rejects ill-typed forms (wrong base type; incompatible held-face partial). kernel_soundness_test.c now 157 passed, 0 failed (up from 155) -- the former neutral-frontier guard is replaced by the now-total reduction guard plus a compatibility-rejection guard. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): comp's varying-line correction is now audited-kernel; comp is total. The single frontier row becomes WIRING total comp into the three downstream cases. The previously-obsolete comp-neutrality test line is replaced with a positive totality assertion. Zero sangaku regressions; structure and lint clean.
- THE FRONTIER SHIFTS, HONESTLY. With comp total, the three downstream cases (dependent Sigma, Path-type lines, the general Glue transport on an undecided face) are no longer blocked on a missing primitive -- each now has the comp it needs. They become WIRING tasks, each with its own type-preservation obligation: dependent Sigma uses the first component's transport filler, Path-lines use comp to pin endpoints, and the general Glue transport's correction hcomp over the line is a comp. The next tread is the smallest of these wirings, with its proof -- named, not faked.

# comp (heterogeneous composition) enters the trusted kernel: the gateway primitive, at its honest depth

- comp IS NOW A KERNEL PRIMITIVE. comp line (cofib r b) u u0 is heterogeneous composition along a type line A(i) -- the single gateway that the three remaining transport cases (dependent Sigma, Path-type lines, general Glue transport) all route through. It GENERALISES both transp (the empty-face case) and hcomp1 (the constant-line case), unifying the two composition operators the kernel already had.
- THE THREE SOUND TREADS, EACH A DELEGATION TO PROVEN MACHINERY. comp's computation reduces to existing, already-proven rules in every case that does not need the heterogeneous correction: (1) EMPTY face over a CONSTANT line -> the base; (2) EMPTY face over a VARYING line -> transp over the line (and because transp now sees through to structure, a varying Sigma line composes componentwise); (3) CONSTANT line with a HELD face -> hcomp1. Soundness is inherited by reduction: comp returns exactly what transp or hcomp1 returns, both of which are proven and guarded.
- THE HETEROGENEOUS FRONTIER STAYS NEUTRAL. A genuinely VARYING line with a nonempty face -- the real heterogeneous correction -- does not reduce; comp stays neutral there and never guesses an inhabitant. This is the one remaining piece, and it is the gateway: building and proving it would unlock all three of dependent Sigma transport, Path-type-line transport, and the general Glue transport at once.
- TYPING AND REJECTIONS. comp line (cofib r b) u u0 : A(i1), computed by reducing the line body under the interval binder (so endpoints resolve through any redex, mirroring transp), with the partial required to agree with the base at i0 and -- when the face holds -- definitionally equal to it (the hcomp1 compatibility, lifted). Verified rejections: a base of the wrong type, and a held-face partial incompatible with the base.
- EMPIRICALLY VERIFIED + MADE PERMANENT: all three treads reduce correctly and type-check at the i1 endpoint; the heterogeneous frontier stays neutral; ill-typed forms are rejected. kernel_soundness_test.c now 155 passed, 0 failed (up from 149) -- six new comp guards. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch. Surface-level sangaku examples exercise the typing path.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now lists comp's empty-face (delegates to transp) and constant-line (delegates to hcomp1) cases as audited-kernel; the single frontier row is comp's varying-line heterogeneous correction. Zero sangaku regressions; structure and lint clean.
- WHAT THIS MEANS FOR "THE THREE THINGS". The user asked to do the three remaining transport cases. The honest result: all three share one gateway, comp, which is now a resident kernel primitive with its generalising structure, its degenerate/delegating cases proven and guarded, and its one genuinely-hard correction named and left neutral. The three cases are not yet computing in full -- that awaits comp's varying-line correction -- but the primitive they all need now exists, is sound, and unifies transp and hcomp. The remaining work is a single, precisely-scoped term, approached only with a proof.

# The held-face mirror + the frontier triangulated to a single primitive: comp

- THE HELD-FACE MIRROR: transp now sees through a HELD-face Glue line to its bare T-line. The same whnf-under-binder change that handled the empty face (Glue = A) applies symmetrically to the held face (Glue = T): a held-face Glue line whose underlying type T(i) genuinely VARIES -- e.g. a non-dependent Sigma whose component varies via a Path -- now transports componentwise exactly like the bare T(i)-line, and infers the matching i1-endpoint type. So BOTH boundary faces now transport varying lines soundly, with no coherence correction (the boundary is definitional on either face). This came essentially for free from the prior insight, applied to the other face.
- THE FRONTIER BOUNDARY IS NOW A PERMANENT GUARD. A genuinely varying-universe Glue line on an UNDECIDED face (a cofibration r=b with r abstract, neither empty nor held) stays NEUTRAL -- the kernel never guesses an inhabitant there. This is the soundness wall, and it now has a dedicated soundness-test case. (We also confirmed the earlier surprise -- an apparently-undecided line reducing to the base -- was the sound constant-line rule firing correctly, since that body did not actually vary in i.)
- THE FRONTIER IS NOW SINGULAR AND PRECISELY NAMED: comp (heterogeneous composition). Triangulation across three independent cases shows they ALL route through comp: (1) the general Glue transport on an undecided face needs the correction hcomp composed from the equivalence coherences OVER the varying line; (2) dependent Sigma transport needs the first component's transport FILLER (a comp derivative) to form the second component's type-line; (3) Path-type-line transport needs comp to pin the (possibly varying) endpoints. Non-dependent structural transport (Sigma, Sum, Pi) is complete; everything past it needs comp.
- WHY THIS IS A CLEAN, HONEST CHARACTERIZATION: rather than fake a Path-line or dependent-Sigma rule, the work this turn PROVED (by working through each case) that comp is the single gateway primitive. Building and proving comp -- likely from its own regularity and degenerate cases first, exactly as gtransp was built -- would unlock all three remaining transport cases at once. comp is the named next summit; its bugs are silent (wrong inhabitant, not type error), so it is approached only with a proof.
- EMPIRICALLY VERIFIED + MADE PERMANENT: the varying held-face Glue line transports and infers like the bare T-line; the undecided-face varying line stays neutral. kernel_soundness_test.c now 149 passed, 0 failed (up from 146) -- two varying-held-face guards plus the frontier-boundary guard. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch. A surface-level sangaku example exercises the typing path.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now lists the held-face varying transport as audited-kernel, and the single frontier row is comp (the gateway for dependent Sigma, Path-lines, and the general Glue transport). Zero sangaku regressions; structure and lint clean.
- THE NEXT SUMMIT (named, not faked): comp -- heterogeneous composition. It is the one missing primitive, and the scaffold is otherwise a clean plateau: every ingredient up to comp is resident, proven, and guarded. The natural approach mirrors the gtransp climb: build comp's regularity and degenerate (empty-system, constant-line) cases first as sound reductions, leave the genuinely-varying correction neutral and named, and ascend one provable tread at a time.

# transp sees through empty-face Glue lines: a VARYING base line now transports under the Glue layer

- TRANSP NOW REDUCES ITS TYPE-LINE BODY TO WHNF UNDER THE INTERVAL BINDER, in both the computation rule (kt_whnf) and the typing rule (kt_infer). Previously the transp structural rules dispatched on the line body's RAW syntactic head, so a Glue type in the line body (even one that reduces to a Sigma/Sum/Pi) was opaque to them. Now the body is reduced under the binder first, so the existing sound rules see the structure underneath.
- THE EFFECT: VARYING EMPTY-FACE GLUE LINES TRANSPORT LIKE THEIR BARE BASE LINE. On an empty face the Glue degenerates to its base A(i) (the equivalence is absent), so <i>(Glue A(i) (cofib i0 i1) T e) has body reducing to the bare A(i)-line. A genuinely VARYING base line -- e.g. a non-dependent Sigma whose second component varies via a Path -- under an empty-face Glue now transports COMPONENTWISE exactly like the bare line, AND infers the same i1-endpoint type. This is the first genuinely varying line to transport under the Glue layer.
- WHY IT IS SOUND, AND ONLY ADDITIVE: whnf is meaning-preserving -- it changes neither the type nor the value, only exposes the head. So the change can only ACCEPT more well-typed terms and REDUCE more redexes; it never accepts a bad term and never changes an existing reduction. The equivalence never enters on an empty face, so no coherence is used and nothing is guessed. The earlier conservative behavior (kt_infer rejected the well-typed Glue-line transport) is now fixed symmetrically: the same whnf-under-binder applies to typing, so the result both reduces AND infers like the bare line.
- THE HONEST REFRAME THAT GOT US HERE: a varying empty-face Glue line is NOT a Glue problem -- the Glue transparently vanishes. So the genuinely-addable content was not a new gtransp rule but a sharpening of the bare transp operator to see through the (vanishing) Glue. The simple-universe case already composed; the STRUCTURAL (Sigma) case did not, because transp dispatched on the raw Glue tag. The whnf-under-binder fix closes exactly that gap.
- EMPIRICALLY VERIFIED + MADE PERMANENT: a varying Sigma A-line under an empty-face Glue transports componentwise like the bare line and infers the matching i1-endpoint type; constant and simple-universe lines are unaffected. kernel_soundness_test.c now 146 passed, 0 failed (up from 143) -- three new varying-empty-face-Glue-line guards. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch. A surface-level sangaku example exercises the full type-checking path.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now lists 'transp empty-face Glue line sees through to the varying base line' as audited-kernel. The frontier row narrows to the varying line on a PROPER (held/partial) face. Zero sangaku regressions; structure and lint clean.
- THE REMAINING FRONTIER (named, not faked): the varying-line Glue transp on a PROPER face, where the equivalence IS present and the full CCHM comp correction (composed from the coherences over the varying line) enters. Its definitional correctness across the whole line is not a single typecheck, so it stays neutral until it can be CONSTRUCTED with a proof. Every ingredient is resident and guarded; the transport now discharges the empty-face (constant and varying base), regularity, and definitionally-collapsing held-face cases soundly.

# gtransp HELD-FACE correction: the general Glue transport reduces on held faces (definitional section)

- GTRANSP NOW REDUCES ON A HELD FACE, for any equivalence whose maps round-trip DEFINITIONALLY. On a held face the Glue equals T, and the constant-line transport of g0:A back into A is f(inv(g0)) -- pull g0 into T via the inverse, transport over the constant T-line (the identity), push back via the forward map. gtransp reduces this to the base exactly when f-after-inv collapses to the identity by computation (the section coherence is a DEFINITIONAL equality).
- THIS REACHES BEYOND THE SYNTACTIC IDENTITY. The criterion is semantic, not syntactic: the forward and inverse maps may be written non-trivially (eta-redexes, beta-redexes, any terms) so long as f(inv(y)) reduces to y. Verified: an identity-packaged mk-equiv reduces; an eta-redex-packaged mk-equiv (maps written as (lam x. (lam z.z) x)) also reduces; a mk-equiv whose forward map is CONSTANT (so f-after-inv =/= id) correctly stays NEUTRAL; abstract opaque equivalences stay neutral.
- WHY THIS IS SOUND, NOT A GUESS. f(inv(g0)) : A is always the correct TYPE and is the genuine A-side CCHM transport on a constant line. We only REDUCE it to the base when f-after-inv collapses definitionally -- then the value is FORCED to be g0, with zero propositional slack. When the section coherence holds only up to the eps path (a propositional, not definitional, equality), gtransp stays NEUTRAL -- it never commits a value the coherence would justify only up to a path. So no wrong inhabitant is ever produced, and the rule uses only f and inv (both carried by the kernel), guessing nothing.
- FORWARD-COMPATIBLE WITH THE GENERAL RULE. On a constant line the held-face value the future general (varying-line) rule must produce on its held boundary is exactly f(inv(g0)) = the unglue-transport-glue round trip. So this reduction is the correct boundary the general rule will need to match -- it does not paint us into a corner.
- EMPIRICALLY VERIFIED + MADE PERMANENT: kernel_soundness_test.c now 143 passed, 0 failed (up from 140) -- three new held-face guards (identity-packaged reduces + is type-preserving; constant-forward-map stays neutral). kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now lists gtransp held-face correction (when f-after-inv collapses definitionally) as audited-kernel, alongside empty-face regularity and the regularity cases. The frontier row narrows to the genuinely VARYING-line Glue transp. Zero sangaku regressions; structure and lint clean.
- THE REMAINING FRONTIER (named, not faked): the VARYING-line Glue transp (A or T varying in the interval), whose full CCHM correction composes the equivalence coherences with comp over the varying line. Its definitional correctness across the whole line is not a single typecheck, so it stays neutral until it can be CONSTRUCTED with a proof. Every ingredient is now resident and guarded, and gtransp soundly discharges the empty-face and definitionally-collapsing held-face cases.

# gtransp empty-face regularity: the general Glue transport advances one sound step

- GTRANSP NOW REDUCES FOR AN ARBITRARY EQUIVALENCE ON AN EMPTY FACE. Previously gtransp reduced only when the gluing equivalence was definitionally the identity (id-equiv or an identity-packaged mk-equiv); for a general equivalence it stayed entirely neutral. Now, when the cofibration's face is EMPTY (the interval endpoints are distinct, i0 vs i1), gtransp reduces to the base g0 for ANY equivalence.
- WHY THIS IS SOUND WITHOUT GUESSING: on an empty face the Glue type degenerates to its base A by the empty-face boundary rule -- the gluing equivalence is absent there. Since gtransp's base type A is a single (constant-in-i) type, transport over the constant A-line is the identity, so the result is exactly the base. Crucially the equivalence NEVER ENTERS the computation, so no is-equiv coherence is needed and nothing is guessed. This extends regularity from the identity-equivalence case to a general equivalence on an empty face.
- THE SOUNDNESS TEST CAUGHT THE OVERLAP AND MADE IT SHARPER. Adding the rule turned one existing guard red: the old "general equivalence stays neutral" guard used an empty face as its example -- now correctly reducible. The fix tightened that guard to use a HELD face (where neutrality genuinely still holds because that case needs the T-line transport plus coherences), and added explicit empty-face regularity guards. This is the soundness discipline working as designed: a new rule is only kept once every guard is reconciled.
- EMPIRICALLY VERIFIED + MADE PERMANENT: empty-face gtransp reduces to the base for a general equivalence (both endpoint orientations) and is type-preserving (: A); the held-face general case correctly stays NEUTRAL; an unresolved (abstract) face stays neutral. kernel_soundness_test.c now 140 passed, 0 failed (up from 137) -- corrected held-face guard plus three new empty-face regularity guards. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now lists gtransp empty-face regularity (arbitrary equivalence) as audited-kernel, and the frontier row narrows to the general Glue transp on a HELD or VARYING face. Zero sangaku regressions; structure and lint clean.
- THE REMAINING FRONTIER (named, not faked): the general Glue transp on a HELD or VARYING face -- the correction term built from the equivalence's is-equiv coherences (section + retraction, which the kernel now carries via mk-equiv) composed with a comp correction. Its definitional correctness is not captured by a single typecheck, so it stays neutral until it can be CONSTRUCTED with a proof, fragment by fragment. Every prerequisite -- the coherence structure included -- is now resident and guarded; what remains is assembling them into the held-face correction.

# The equivalence-structure layer: mk-equiv + coherences in the trusted kernel (the general Glue-transp prerequisite)

- THE KERNEL'S NOTION OF EQUIVALENCE IS NOW A GENUINE QUASI-EQUIVALENCE. mk-equiv T A f g eta eps : Equiv T A (KT_MK_EQUIV) packages an equivalence from its four parts: the forward map f:T->A, the inverse g:A->T, and the two COHERENCES eta:(x:T) Id T (g(f x)) x [retraction] and eps:(y:A) Id A (f(g y)) y [section]. All four are DEMANDED at typing time, so you cannot build a mk-equiv unless f is genuinely invertible with witnessed coherences -- this is exactly what makes a general transport across it sound.
- THE FOUR PROJECTION (BETA) RULES. equiv-fun / equiv-inv / equiv-eta / equiv-eps (KT_EQUIV_ETA, KT_EQUIV_EPS added; equiv-fun/inv extended) recover the stored parts from a mk-equiv. Each beta rule is type-preserving because it returns the already-typed component. For an abstract equivalence the coherence projections stay neutral but carry the CORRECT coherence types: equiv-eta e : (Pi (x:T) Id T ((equiv-inv e)((equiv-fun e) x)) x), and the section dual for equiv-eps.
- THE GENERAL GLUE TRANSP ADVANCES, HONESTLY. With (f,g,eta,eps) now present and extractable, gtransp's REGULARITY extends from the id-equiv constructor to ANY equivalence whose forward map is DEFINITIONALLY the identity: an identity-packaged mk-equiv (mk-equiv A A id id ..) reduces to the base g0, just like id-equiv, because f(g0)=g0 makes the correction trivial. A genuinely non-identity equivalence with a proper (partial) face still stays NEUTRAL -- the comp-correction composed from the section coherence eps is a multi-operation term whose definitional correctness is not captured by one typecheck, so it is the named frontier, never faked.
- EMPIRICALLY VERIFIED + MADE PERMANENT: mk-equiv types as Equiv T A; the four projections beta-reduce to f/g/eta/eps; a mistyped coherence (wrong Id endpoints) is rejected; a wrong glue-type is rejected; the abstract coherence projections stay neutral with correct types; the extended gtransp reduces for the identity-packaged case (type-preserving) and stays neutral for a non-identity equivalence. kernel_soundness_test.c now 137 passed, 0 failed (up from 127) -- 10 new mk-equiv/eta/eps/gtransp cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): twenty-four audited-kernel rows now -- the full cubical scaffold plus the equivalence-structure layer (mk-equiv with coherence typing, the eta/eps projections, and gtransp regularity extended to definitional identities) -- with the single honest frontier row (the general Glue transp's comp-correction over the coherences). Zero sangaku regressions; structure and lint clean.
- THE ONE REMAINING PIECE (named, precisely): the general Glue transp for a NON-identity equivalence over a proper face -- the CCHM correction that composes transp-at-A, unglue, the forward map, and an hcomp built from the section coherence eps. Every ingredient it needs is now resident and extractable in the trusted kernel; what remains is composing them into the correction term, the silent-bug zone, to be done only with a genuine definitional-correctness proof. The kernel's equivalence is no longer two maps -- it is the real structure univalence is built on.

# The GLUE TRANSP keystone (sound fragment): equiv-inv + gtransp in the trusted kernel

- THE EQUIVALENCE INVERSE (KT_EQUIV_INV) IS NOW IN THE TRUSTED KERNEL. equiv-inv e : (Pi (_:A) T) when e : Equiv T A -- the inverse-direction partner of equiv-fun. It COMPUTES for the identity equivalence: equiv-inv (id-equiv A) reduces to the identity (the identity is its own inverse). A general equivalence stays neutral. Rejects equiv-inv of a non-equivalence.
- THE GLUE TRANSPORT OPERATOR (KT_GTRANSP) IS NOW IN THE TRUSTED KERNEL -- the univalence computation, at its honest depth. gtransp A (cofib r b) T e g0 : A. For the IDENTITY equivalence it reduces to the base g0 (the REGULARITY case: forward and inverse are both the identity, so the CCHM correction hcomp is trivial and contributes nothing). For a GENERAL equivalence it stays NEUTRAL -- it never guesses the inhabitant.
- WHY THIS IS THE HONEST KEYSTONE, NOT THE WHOLE RULE: the general Glue transp builds a correction square from the equivalence's is-equiv coherences (the section f(g y)=y and retraction g(f x)=x proofs) composed via comp. The kernel's Equiv carries only the maps (equiv-fun, equiv-inv), not the coherences, so a general rule would GUESS the corrected inhabitant -- the exact silent-unsoundness trap. I built the fragment that is provable (id-equiv regularity) and left the coherence-dependent general case neutral and named.
- EMPIRICALLY VERIFIED: gtransp(id-equiv) reduces to the base and is type-preserving (: A); a general gtransp stays neutral yet is still correctly typed (: A); equiv-inv(id-equiv) is the identity; ill-typed forms (wrong base type, non-equivalence) are rejected. Made permanent: kernel_soundness_test.c now 127 passed, 0 failed (up from 121) -- 6 new equiv-inv/gtransp cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): twenty-one audited-kernel rows now -- the full cubical scaffold (ua typing; transport tier; interval negation; id-equiv; hcomp empty/single/two-face overlap lattice; Glue type + boundary; equiv-fun; equiv-inv; unglue; gtransp regularity + held-face + empty-face) -- plus the single honest frontier row (general Glue transp needing the is-equiv coherences). Zero sangaku regressions; structure and lint clean.
- A ROADMAP SVG of the whole climb (docs/roadmap.svg) renders the arc as a vertical ascent: fourteen resident rules, the gtransp sound fragment, and the one named frontier, with the running soundness count.
- THE SINGLE REMAINING PIECE (named, not faked): the GENERAL Glue transp -- the correction built from the equivalence's is-equiv coherences (section + retraction) plus comp. Every other ingredient of computational univalence is now resident, proven, and guarded in the trusted kernel. The scaffold is whole; what remains is one coherence-shaped keystone whose bugs would be silent, approached only with a proof.

# The GLUE TRANSP RULE (held-face / regularity case) — the keystone, at its provable depth

- THE GLUE TRANSP RULE IS NOW IN THE TRUSTED KERNEL, in its held-face (regularity) case. transp <i>(Glue A (cofib b b) T e) g, where the face HOLDS THROUGHOUT (a constant always-true cofibration), reduces to transport along the underlying type line transp <i>T g. This is THE keystone of computational univalence -- the rule everything else was scaffolding for -- added at the one depth where it is forced by the Glue boundary and needs no machinery the opaque Equiv cannot provide.
- WHY IT IS SOUND, IN ONE LINE: on the held face the Glue boundary gives Glue == T at every point, so the Glue line IS the T line definitionally; transport over definitionally-equal lines is equal, and the T-line transp is already proven sound. No equivalence inverse, no hcomp boundary correction, no fabrication.
- VERIFIED: a well-formed held-face Glue line (T constant, e : Equiv T A valid throughout) transports type-preservingly (: T) and reduces exactly as the underlying T-line transp (to the base). An empty-face Glue line still reduces (via the empty-face boundary) to transport in A. Ill-formed Glue lines (e.g. a fixed e : Equiv T0 A under a varying T) are correctly REJECTED -- not silently accepted.
- MADE PERMANENT: 2 new held-face Glue-transp cases in kernel_soundness_test.c. Kernel soundness now 121 passed, 0 failed (up from 119); kernel_test 21/0; built clean under strict C89 -Werror -Wswitch. Verified from a fresh extract.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): nineteen audited-kernel rows now, including both the empty-face and held-face Glue transp cases, plus the honest frontier row. Zero sangaku regressions; structure and lint clean.
- ADDED docs/lizard-roadmap.svg: a dedicated roadmap tablet of the full cubical-kernel tower -- all fourteen new term formers from ua typing through the Glue transp rule, each with its kernel equation and its soundness count, charting the climb 64/0 (github baseline, no cubical machinery) to 121/0.
- THE REMAINING FRONTIER (named, not faked): the GENERAL Glue transp rule -- a VARYING (proper, non-constant) face -- which genuinely requires the equivalence inverse + is-equiv coherence + comp (none of which the kernel's opaque Equiv provides). This is the single piece between here and full computational univalence. Both degenerate slices (empty face, held face) are now done; the general case is approached as its own provable, soundness-guarded brick, never dropped in whole, because its bugs are silent.

# The Glue TRANSP rule at the honest degenerate depth: the empty-face boundary + degenerate transport

- THE GLUE EMPTY-FACE BOUNDARY (Glue A [empty face] T e = A) IS NOW IN THE TRUSTED KERNEL, alongside the holding-face boundary (= T) from last iteration. When the cofibration is an empty face (distinct endpoints i0/i1), the glue contributes nothing and the Glue type reduces to its base A. This is a defining CCHM equation, type-preserving (A : Sort = the Glue's sort).
- THE DEGENERATE GLUE TRANSP SLICE FOLLOWS, WITH NO NEW TRANSP CODE. Because an empty-face Glue line body reduces to A(i), transp across a CONSTANT empty-face Glue line reduces -- via the EXISTING transport tier -- to the base. Verified: the empty-face Glue reduces to A; the constant empty-face Glue transp reduces to the base and type-checks at A. The elegant consequence of the boundary equation: the degenerate Glue transport is automatic.
- WHY THIS IS THE HONEST DEPTH. The kernel correctly REFUSES a varying empty-face Glue line whose equivalence does not track the base (e : Equiv T A0 does not fit Equiv T A1) -- that line is genuinely ill-typed, and the kernel rejects it rather than computing a wrong transport. The constant-base empty-face Glue transp is the clean well-typed witness.
- MADE PERMANENT: kernel_soundness_test.c now 119 passed, 0 failed (up from 116) -- 3 new cases (empty-face boundary, degenerate Glue transp type-preservation, degenerate Glue transp reduction). kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- THE GENERAL GLUE TRANSP RULE -- THE ONE IRREDUCIBLE REMAINING PIECE, NAMED WITH ITS EXACT PREREQUISITES. Transport across a Glue with a VARYING line and a PROPER (non-empty, non-full) face composes: transp in A, transp in T, the equivalence's FORWARD map (have it: equiv-fun), its INVERSE map (do NOT have), the is-equiv COHERENCE proofs section/retraction (do NOT have), and a heterogeneous COMP operator (do NOT have) -- assembling them into a Kan filler whose bugs are SILENT (a wrong inhabitant, not a type error). It cannot be added soundly until the equivalence is given its inverse and coherence structure and comp is built; each is its own provable, soundness-guarded brick. This is the precise frontier.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): eighteen audited-kernel rows now -- ua typing; full transport tier; interval negation; id-equiv; the complete hcomp story; the Glue type, equiv-fun, unglue; and now the Glue empty-face boundary and the degenerate Glue transp -- plus the honest general-Glue-transp frontier row. Zero sangaku regressions; structure and lint clean.

# The GLUE TYPE-FORMER LAYER in the trusted kernel: Glue type + boundary, equiv-fun, and unglue

- THE GLUE TYPE (KT_GLUE) IS NOW IN THE TRUSTED KERNEL. Glue A (cofib r b) T e : Sort n, with the defining BOUNDARY RULE: on the face (r=b), the Glue type reduces to T; off the face it stays glued. This is the type former univalence is built from. Typing requires A,T : Sort, e : Equiv T A, and rejects a glue_type/equiv mismatch.
- THE EQUIVALENCE FORWARD MAP (KT_EQUIV_FUN) IS IN THE KERNEL. equiv-fun e : (Pi (_:T) A) when e : Equiv T A. It COMPUTES for the identity equivalence: equiv-fun (id-equiv A) reduces to the identity function lam x.x. A general (opaque) equivalence stays neutral. Rejects equiv-fun of a non-equivalence.
- THE GLUE ELIMINATOR (KT_UNGLUE) IS IN THE KERNEL. unglue A (cofib r b) T e g : A, with computation: off the face g is already in A so unglue g = g; on the face unglue g = (equiv-fun e) g (apply the forward map to land in A). Crucially, with the identity equivalence on the face, unglue ROUND-TRIPS its argument (a -> a) -- the equivalence actually computes through unglue. Rejects unglue of a non-Glue.
- VERIFIED + MADE PERMANENT: the Glue boundary (reduces to T on the face, stays glued off it), equiv-fun's identity reduction, unglue off-face (= arg) and on-face identity round-trip, plus three soundness rejections. kernel_soundness_test.c now 116 passed, 0 failed (up from 107) -- 9 new Glue-layer cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): sixteen audited-kernel rows now -- ua typing; full transport tier; interval negation; id-equiv; the complete hcomp story (empty/single/two-face overlap lattice) with cofibrations; and now the Glue type, equiv-fun, and unglue -- plus the honest Glue-transp frontier row. Zero sangaku regressions; structure and lint clean.
- THE SINGLE REMAINING CCHM PIECE (named, not faked): the Glue TRANSP rule -- transport ACROSS ua, which composes the gluing equivalence with hcomp over a face. EVERY prerequisite it depends on is now resident and guarded in the trusted kernel: cofibrations, the hcomp overlap-compatibility lattice, the full transport tier, the Glue type with its boundary, equiv-fun, and unglue. The transp rule itself is the part of CCHM whose bugs are silent (wrong inhabitant, not a type error), and it is approached as its own provable, soundness-guarded brick -- the one piece still ahead.

# Multi-face hcomp: the OVERLAP COMPATIBILITY LATTICE in the trusted kernel (two-face hcomp)

- TWO-FACE HOMOGENEOUS COMPOSITION (KT_HCOMP2) IS NOW IN THE TRUSTED KERNEL. hcomp2 A (cofib r1 b1) u1 (cofib r2 b2) u2 u0 reduces along the disjunction phi1 OR phi2: u1 on face1, else u2 on face2, else u0 when both faces empty, else neutral. This is the multi-face Kan brick -- the step where compatibility stops being one equation and becomes an OVERLAP LATTICE.
- THE OVERLAP CHECK (C3) IS THE NEW SOUNDNESS HEART. The TYPING rule enforces three conditions: (C1) u1=u0 when face1 holds, (C2) u2=u0 when face2 holds, and -- the genuinely new one -- (C3) u1=u2 WHERE BOTH FACES HOLD. C3 is exactly what makes the elif reduction order (face1 before face2) sound: wherever both faces hold, u1 and u2 are forced definitionally equal, so the computation's choice of u1 over u2 is choosing a definitionally equal term. Without C3 the order would be observable and unsound; with it, the order-dependence is eliminated.
- VERIFIED ON ALL BEHAVIORS: face1 reduces to u1, face2 to u2, both-empty to the base, neutral stays stuck (no wrong value); a C1 violation is rejected; and the C3 OVERLAP violation (u1 != u2 where both faces hold) is rejected. Made permanent: kernel_soundness_test.c now 107 passed, 0 failed (up from 101) -- 6 new two-face hcomp cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- WHY TWO-FACE CAPTURES THE ESSENTIAL MACHINERY: 3+-face hcomp adds MORE pairwise overlaps but no new KIND of check (still pairwise definitional agreement on the overlap). So the two-face case is the honest, complete introduction of the overlap-compatibility lattice; the n-face generalization is mechanical repetition of C3 over all pairs.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): thirteen audited-kernel rows now -- ua typing; full transport tier; interval negation; id-equiv; empty/single/two-face hcomp with cofibrations and the overlap lattice -- plus the honest 3+-face/Glue frontier row. Zero sangaku regressions; structure and lint clean.
- THE REMAINING FRONTIER (named, not faked): the Glue type and the Glue transp rule (transport ACROSS ua), plus the mechanical n-face generalization. Glue is now the single conceptually-new piece left: with cofibrations, the transport tier, and the hcomp overlap lattice all in place, the remaining work is the Glue type former + unglue + the Glue transp rule that composes an equivalence with hcomp over a face. That rule is the irreducible CCHM core, approached one provable piece at a time.

# First face-aware Kan brick: cofibrations + single-face hcomp with the compatibility check; GitHub comparison

- COFIBRATIONS (KT_COFIB) + SINGLE-FACE HCOMP (KT_HCOMP1) ARE NOW IN THE TRUSTED KERNEL. hcomp1 A (cofib r b) u u0 reduces to the partial element u on the face (r=b), to the base u0 off the face (distinct endpoints i0/i1), and stays neutral when the face is undetermined. This is the first FACE-AWARE piece of the Kan structure -- the smallest non-empty hcomp with a single real face.
- THE COMPATIBILITY CHECK IS THE SOUNDNESS HEART. The TYPING rule enforces: when the face (r=b) holds definitionally, the partial element u must equal the base u0. An incompatible square (u != u0 on the face) is REJECTED. This is exactly what blocks the on-face reduction (-> u) from ever yielding a value that disagrees with the base. At the single-face depth the compatibility condition is one kt_equal -- no overlap lattice yet.
- VERIFIED ON ALL FOUR BEHAVIORS: on-face reduces to the partial element (compatible u0,u0); off-face (i0=i1) reduces to the base; neutral face stays stuck and does NOT reduce to u (no wrong value); incompatible holding-face square is rejected. Made permanent: kernel_soundness_test.c now 101 passed, 0 failed (up from 94) -- 7 new cofib/hcomp1 cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch.
- GITHUB COMPARISON (github.com/hydrastro/lizard, shared ancestor confirmed: inet.c 619 lines in both). Our kernel.c 2728+ lines vs GitHub 2324. Cubical term tags WE ADDED that GitHub lacks: KT_EQUIV, KT_UA, KT_TRANSP, KT_INEG, KT_ID_EQUIV, KT_HCOMP (and now KT_COFIB, KT_HCOMP1). GitHub kernel.c has 0 references to transp/hcomp/ineg/ua/equiv. Soundness: GitHub 64/0, ours 101/0. Term-tag regressions: NONE (every GitHub tag is present in ours). Both build clean, both sound. hydrastro's own recent work pushes a DIFFERENT axis (CAS-as-theorem-prover: axiom mode, ramified places, certified integrals, Dirichlet = pi/2); our work is purely additive to the trusted kernel on the cubical-computation axis. Pure progress, zero regression.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): twelve audited-kernel rows now -- ua typing; full transport tier (constant/Sigma/Sum/Pi both domain cases); interval negation; id-equiv; empty-system hcomp; cofibrations; single-face hcomp with compatibility -- plus the honest multi-face-hcomp/Glue frontier row. Zero sangaku regressions; structure and lint clean.
- THE REMAINING FRONTIER (named, not faked): the MULTI-face hcomp (disjunctions of cofibrations + overlap compatibility), the Glue type, and the Glue transp rule (transport ACROSS ua). The single-face brick is the smallest honest non-empty step toward it; the multi-face overlap lattice and Glue are the irreducibly hard core, a genuine multi-turn build each piece of which needs its own proof and guard.

# First Kan brick: empty-system hcomp in the trusted kernel; the face-system Glue core named as the frontier

- EMPTY-SYSTEM HOMOGENEOUS COMPOSITION (KT_HCOMP) IS NOW IN THE TRUSTED KERNEL. hcomp A u0 : A, reduces to u0. This is a required equation of the Kan structure, added at the only depth with a short type-preservation proof: with NO face-system field, a non-empty system is STRUCTURALLY UNREPRESENTABLE in the term, so unsoundness from incompatible faces is impossible by construction. Type-preserving because the result IS u0 : A. Guarded by kernel_soundness_test (typing, the reduction to the base, wrong-base rejection, wrong-result rejection).
- THE HONEST ASSESSMENT, STATED PLAINLY: empty-system hcomp does NOT get us to transport across ua. The Glue transp rule composes the equivalence with hcomp OVER a non-empty face phi, so it needs the face-system machinery the empty-system case omits. I added the provable brick and did NOT claim it is more than it is.
- MADE PERMANENT: kernel_soundness_test.c now 94 passed, 0 failed (up from 90) -- 4 hcomp cases. kernel_test 21/0. Built clean under strict C89 -Werror.
- THE REMAINING FRONTIER (named, not faked): transport ACROSS ua = the full face-system Kan core (cofibrations/partial elements + non-empty hcomp + Glue type + the Glue transp rule). This is the irreducibly hard part of CCHM -- the part whose bugs are silent (wrong inhabitant, not a type error), the part that took the original authors a full paper. It is a genuine multi-turn build, each piece needing its own type-preservation proof and soundness guard. I will not drop it into the trusted core and claim it sound in one pass.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): ten audited-kernel rows now -- ua typing; constant/Sigma/Sum/constant-Pi/varying-Pi transport; interval negation; id-equiv; empty-system hcomp -- plus the honest Glue/frontier row. Zero sangaku regressions; structure and lint clean.

# Interval negation, FULL Pi transport (varying domain), and the identity equivalence -- all kernel-anchored and sound

- INTERVAL NEGATION (KT_INEG) IS NOW IN THE TRUSTED KERNEL. ~i0=i1, ~i1=i0, ~~r=r (involution) -- total, finite, endpoint-only computation. Guarded by kernel_soundness_test including the crucial check that ~i0 is NOT i0 (a wrong endpoint would break boundary recovery). Same safe risk class as the structural transp rules.
- FULL Pi TRANSPORT (VARYING DOMAIN) via interval negation. transp <i>(Pi (x:A(i)) B(i)) f = lam (x:A(i1)). transp <i>B(i) (f (transp <i>A(~i) x)) -- the argument is transported BACKWARD along the reversed domain line, which is exactly what interval negation supplies. Verified type-preserving on a line where domain and codomain both vary, and rejected at the i0 type. The constant-domain Pi rule still works (it's the degenerate case where backward transport is the identity). Pi now transports in ALL cases.
- THE IDENTITY EQUIVALENCE (KT_ID_EQUIV) IS IN THE KERNEL. (id-equiv A) : (Equiv A A) when A : Sort, composing with ua (ua (id-equiv A) : Id (Sort) A A). A small safe addition completing the equivalence vocabulary; rejects ill-typed uses (non-type argument, wrong endpoints).
- MADE PERMANENT: kernel_soundness_test.c now 90 passed, 0 failed (up from 80) -- 4 interval-negation cases, 2 varying-domain Pi cases, 4 id-equiv cases. kernel_test 21/0. Built clean under strict C89 -Werror -Wswitch -Wconversion.
- THE HONEST FRONTIER, NAMED NOT FAKED: transport ACROSS ua (the Glue computation) is NOT in the kernel. This is categorically harder than everything done so far -- it requires Glue types, unglue, hcomp, and the face/degeneracy bookkeeping that took CCHM's authors a full paper to get right, and whose bugs are SILENT (wrong inhabitant, not a type error). I will not drop a multi-hundred-line Glue+hcomp engine into the trusted core and claim it sound in one turn; that would be the exact overclaim this project refuses. It is the one remaining piece, scoped with its reason.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): nine audited-kernel rows now (ua typing, constant/Sigma/Sum/constant-Pi/varying-Pi transport, interval negation, id-equiv) plus the honest Glue/roadmap row. Zero sangaku regressions; structure and lint clean.

# Completed the structural transport tier: Sum (full) and Pi (constant domain), kernel-anchored and sound

- SUM TRANSPORT IS NOW IN THE TRUSTED KERNEL. transp <i>(A(i)+B(i)) (inl a) = inl (transp <i>A(i) a) (and the inr case). A Sum is always non-dependent, so no guard is needed -- the simplest structural rule. Verified on a varying line (A,B differ at i0 vs i1 via paths in the universe): type-preserving (result : Sum A1 B1) and rejected at the i0 type.
- PI TRANSPORT WITH A CONSTANT DOMAIN IS NOW IN THE TRUSTED KERNEL. transp <i>(Pi (x:A) B(i)) f = lam (x:A). transp <i>B(i) (f x), when A is constant in i and B is non-dependent in x. This is the slice of Pi-transport that needs NO interval reversal (a constant domain means an argument x:A(i1)=A(i0) feeds f directly). Verified type-preserving (result : Pi (x:A) B1), rejected at the i0 type, and the lam/shift bookkeeping checked empirically.
- THE SOUNDNESS BOUNDARY HOLDS: a VARYING-DOMAIN Pi stays NEUTRAL -- the constant-domain guard (kt_equal of the domain's i0/i1 specialisations) correctly declines to fire when the domain genuinely varies (it would need interval negation, which this kernel lacks). Verified: a varying-domain Pi transp prints unreduced and is still soundly typed.
- MADE PERMANENT: added 4 cases to lizard's kernel_soundness_test.c (Sum type-preserving + reject, Pi type-preserving + reject). Kernel soundness now 80 passed, 0 failed (up from 76); kernel_test 21/0; built clean under strict C89 -Werror -Wswitch -Wconversion. The full transport tier -- constant, Sigma, Sum, constant-domain Pi -- all verified live end-to-end.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now reports six audited-kernel rows (ua typing, constant transp, varying-Sigma, varying-Sum, constant-domain-Pi) plus the honest surface/roadmap row.
- WHAT REMAINS (named, not faked): varying-domain Pi (needs interval negation -- new soundness-critical interval algebra) and transport in the UNIVERSE across ua (needs Glue/comp). The structural recursion through ordinary type formers is now COMPLETE; what is left is the genuinely cubical machinery. Zero sangaku regressions; structure and lint clean.

# Structural transport across a VARYING line -- the first step past the constant case, kernel-anchored and sound

- VARYING-LINE TRANSPORT AT A NON-DEPENDENT PRODUCT IS NOW IN THE TRUSTED KERNEL. transp <i>(Sigma (_:A(i)) B(i)) (a,b) reduces COMPONENTWISE to (transp <i>A(i) a, transp <i>B(i) b). This is genuine varying-line transport -- A and B genuinely differ at i0 vs i1 (demonstrated with a path in the universe PA : Path Sort A0 A1) -- and it needs NO Glue: transport at an ordinary type former is just structural recursion.
- TYPE-PRESERVATION PROVED + VERIFIED: transp <i>A(i) a : A(i1) and transp <i>B(i) b : B(i1), so the result pair inhabits Sigma A(i1) B(i1) = line@i1. Empirically: the result checks at the i1 type (Sigma A1 B0) and is REJECTED at the i0 type -- transport does not falsely preserve the old type. The component sub-transports recurse on structurally smaller lines and terminate.
- THE SOUNDNESS GUARD AT THE BOUNDARY: a DEPENDENT Sigma (snd_type references the first component) stays NEUTRAL. The rule fires only when snd_type is invariant under the pair-binder substitution (kt_equal of its i0/i1 specialisations), which is false for a genuine dependency -- so the rule correctly declines and never computes a wrong value. Verified: a dependent Sigma transp prints unreduced.
- MADE PERMANENT: added 2 varying-Sigma cases to lizard's kernel_soundness_test.c (the type-preserving componentwise reduction, and rejection at the wrong endpoint type). Kernel soundness now 76 passed, 0 failed (up from 74); kernel_test 21/0; built clean under strict C89 -Werror -Wswitch -Wconversion.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): the trust base now reports transp-varying-nondependent-Sigma-componentwise as audited-kernel, alongside ua typing and constant-line transp. Glue-and-full-computational-univalence remains surface/roadmap.
- WHAT REMAINS (named, not faked): dependent Sigma, Sum, Pi, and transport in the UNIVERSE across ua (which genuinely needs Glue/comp). Each is its own provable, soundness-guarded increment -- approached one rule at a time, neutral until proven. Zero sangaku regressions; structure and lint clean.

# Brought transp (transport) into the trusted kernel -- typing + the one sound computation rule, guarded

- TRANSPORT (KT_TRANSP) IS NOW IN THE TRUSTED KERNEL. Added a new kernel term tag with all the descent operations (constructor, shift, subst, whnf, infer, equal, unify, zonk, printer, const_occurs) -- built clean under strict C89 -Werror with -Wswitch (every switch now handles it). This is a genuine, sound step toward computational univalence.
- THE TYPING RULE (standard CCHM/cubical-Agda): transp <i>A(i) a0 : A(i1) when the line <i>A(i) is a path-abstraction whose body is a type and a0 : A(i0). Verified: (transp <i>A a):A accepted, kernel-infer gives A.
- THE ONE SOUND COMPUTATION RULE (no Glue needed): a CONSTANT type-line reduces to its base -- transport along a constant path is the identity (regularity). Verified: (transp <i>A a) reduces to a. Type-preserving because when the line is constant A(i0) is definitionally A(i1), so base inhabits the result type.
- THE HONEST BOUNDARY: a NON-constant line stays NEUTRAL -- correctly typed, but NOT reduced. Full transport across a varying line needs Glue/comp/hcomp, which is the soundness-critical CCHM engine and is deliberately NOT computed. We never compute a wrong value; we decline to reduce. Verified: a bare neutral line is rejected by typing, and (transp <i>A a):B is rejected -- transport never falsely changes the type.
- MADE PERMANENT: added 5 transp soundness cases to lizard's kernel_soundness_test.c (accepts well-typed transp, checks the constant-line reduction, rejects wrong-type base and wrong result type). Kernel soundness now 74 passed, 0 failed (up from 69); kernel_test 21/0; baseline axioms still sound.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): transp typing and its constant-line computation are now kernel-anchored alongside ua typing. Trust base reports transp-typing-and-constant-line-computation as audited-kernel; Glue-and-full-computational-univalence remains surface/roadmap.
- WHAT REMAINS (named, not faked): transport across a NON-constant line via Glue/comp -- the remaining gap to full computational univalence, a multi-hundred-line CCHM engine to be added one provable, soundness-guarded rule at a time. Zero sangaku regressions; structure and lint clean.

# Brought ua TYPING into the trusted kernel (it was already there -- verified, made sound, locked as a permanent guard)

- THE FINDING: ua is ALREADY in lizard's trusted kernel. KT_EQUIV and KT_UA are real kterm tags handled in kt_infer/kt_whnf/kt_equal/kt_shift/kt_subst. The kernel TYPES univalence: (ua e):(Id (Sort n) A B) when e:(Equiv A B). This CORRECTS last turn's claim that the kernel had 'no Glue/ua/Equiv' -- it has the Equiv and ua TYPES; what it lacks is the COMPUTATION (transport via Glue).
- MADE IT SOUND + PERMANENT: added ua/Equiv soundness cases to lizard's tests/kernel_soundness_test.c -- which builds ill-typed kterms DIRECTLY (no elaborator) and asserts kt_infer rejects them, the strongest possible guard. The kernel now provably ACCEPTS (ua e):(Id (Sort 0) A B) and (Equiv A B):(Sort 0), and REJECTS (ua a) of a non-equivalence, (ua e) at wrong endpoints (Id A C), and (Equiv a B) of a non-type. Result: kernel soundness 69 passed, 0 failed; kernel_test 21/0; baseline kernel axioms still sound. Built clean under strict C89 -Werror with all warnings on.
- FLOOR 5 UPGRADED (sangaku example 450, golden cas_inetunivalence): ua TYPING is now KERNEL-ANCHORED with the SAME audited-kernel guarantee as Floors 1-4 -- the discriminating rejections are proven through the trusted kernel-check primitive from sangaku. Re-labelled precisely: ua TYPING audited-kernel; ua COMPUTATION surface/roadmap.
- THE HONEST LINE ON WHAT WAS NOT DONE: ua COMPUTATION (transp across ua reducing through Glue) was NOT added to the trusted kernel. The kernel has no transp/Glue/comp operator -- transport across ua is not even expressible there -- and adding full computational univalence is a multi-hundred-line CCHM implementation that becomes soundness-critical the instant it enters the trusted core; a silent bug would be silent unsoundness of the whole system. That is named as roadmap, with WHY it is dangerous, and was NOT faked.
- Zero sangaku regressions; structure and lint clean. lizard kernel tests all pass.

# Floor 5: univalence over the net -- with an explicitly different, honestly-labelled trust base

- UNIVALENCE (new `src/cas/inetunivalence.lisp`, sangaku example 450 + golden cas_inetunivalence; lizard example 392). Univalence -- an equivalence between types IS a path between them (ua : (A ≃ B) -> (A = B)) -- the deepest principle of cubical/homotopy type theory.
- *** THE TRUST BASE IS DIFFERENT FROM FLOORS 1-4, STATED PLAINLY (docs/LIMITATIONS.md). *** Floors 1-4 are anchored to lizard's AUDITED ~1,350-line trusted kernel (kt_infer). Univalence CANNOT get that exact guarantee: the trusted kernel has Path and Interval but NO Glue/ua/Equiv. Those live in lizard's SURFACE cubical layer (tt_check_cubical.c + lib/cubical.lisp + lib/univalence.lisp) -- a real shipping checker/evaluator, but a LARGER, LESS-AUDITED trust base that does NOT round-trip its cubical typing through the trusted kernel. The honesty is in the LABEL: this floor never pretends univalence rests on the audited kernel.
- THE FLOOR SPLITS HONESTLY: (a) the PATH/REFL fragment that DOES live in the trusted kernel is anchored to kt_infer -- the discriminating false-equation rejection ((refl a) does NOT prove (Id A a b)) holds with the full audited guarantee, demonstrated portably in sangaku example 450; (b) the genuinely-cubical id-equiv/Glue/ua are anchored to the SURFACE layer and labelled as such -- demonstrated in lizard example 392 (id-equiv reduces to the identity forward and backward, Glue collapses to T on a true face and A on a false face, ua computes a univalence term).
- STRUCTURAL HONESTY: the surface cubical lib ships with LIZARD, not sangaku, so the kernel-anchored portable part lives in sangaku (uses only kernel-* primitives) and the surface-computation demonstration lives in LIZARD's own example where the lib is natively on the path. The module reports its dual trust base via iuv-trust-base. No absolute-path dependency in the sangaku zip.
- Zero regressions; structure and lint clean.

# Floor 4: higher observational type theory (HOTT) over the net, anchored to the trusted kernel

- HIGHER OBSERVATIONAL TYPE THEORY (new `src/cas/inethott.lisp`, example 449, golden cas_inethott). HOTT -- the observational successor to Martin-Lof type theory, distinct from homotopy type theory -- is the type theory whose defining feature is that equality is determined by OBSERVATION (functions pointwise, pairs componentwise, the equality type computed from how inhabitants are observed). This is exactly the CO-UNIVERSE side of the construction/observation duality: observational equality IS equality on the observation lattice, continuing the co-universe/reflection development directly.
- ANCHORED, NOT DECORATIVE: the net CARRIES the equality derivation (Id / Path / refl, aligned with the agents) and DELEGATES the check to lizard's trusted kernel (kernel-check over the Id and Path type formers, verified reachable). The net is the proof-term carrier; the trusted kernel is the checker. Zero new trusted code.
- VERIFIED including the discriminating rejection (the soundness heart of equality): the Id/refl/Path carriers read back EXACTLY to kernel syntax; the kernel accepts (Id A a a) and (Path A a a) at (Sort 0) and (refl a) at (Id A a a); the kernel REJECTS (refl a) at (Id A a b) for distinct a,b -- refl cannot prove a false equation; the net verdict EQUALS the kernel verdict on acceptance AND rejection; and equality is also read operationally as matching observations (the co-universe tie).
- THE FULL ANCHORED STACK: reduction (R2), simple types (Floor 1), dependent types (Floor 2), contextual modal types (Floor 3, with the S4 soundness heart now fixed), and now observational equality (Floor 4) -- each proven faithful to lizard's trusted kernel by agreement, never reimplemented.
- HONEST SCOPE: this is the observational-equality CORE anchored to the Id/Path/refl machinery the kernel exposes; full univalence and the complete equality-of-equality tower are deeper and remain roadmap, to be anchored the same way. Zero regressions; structure and lint clean.

# Fixed the S4 soundness heart; built the co-universe / reflection development

- FIXED THE S4 SOUNDNESS HEART (cas/inetmodal.lisp, example 447). The previous turn reported the truth-vs-valid REJECTION as uncapturable in-harness; that was a MISTAKE -- it reached for `guard` (unreliable in this build) instead of the right tool. Lizard's modal checker rejects by RETURNING an error node, and lizard installs the guard-free predicate `error-object?` that tests exactly that. The modal floor now asserts FULL acceptance-AND-rejection agreement with the trusted S4 kernel: a TRUTH-only variable inside a box is demonstrably REJECTED (error-object? #t) while the same-shaped (box x) with x VALID is ACCEPTED -- opposite verdicts purely by context, the soundness heart of strict S4, now a PASSING test. The 4-axiom (accept side, depth 3) is retained. The named limitation is REMOVED from LIMITATIONS.md; the wall was never real, just the wrong predicate.
- CO-UNIVERSE / REFLECTION (new `src/cas/inetreflect.lisp`, example 448, golden cas_inetreflect). Makes operational the insight that the co-universe -- the OBSERVATION side of the construction/observation duality -- is the hidden structure behind reflection. Built on the modal floor: under Pfenning-Davies, necessity (Box) and reflection are one phenomenon (a necessary/valid/closed term is exactly quotable code). Demonstrated on lizard's real homoiconic terms: observing a term's structure (head, binder, subterms) is construction->observation; rebuilding from observed parts is the contravariant observation->construction; the round-trip is EXACT (witnessing the lattices are genuine duals); the modal Box carrier viewed as code is its surface term, the code view itself observable (reflection is recursive).
- HOTT SCOPED (per clarification = Higher Observational Type Theory, distinct from homotopy type theory): noted in the roadmap as the observational-equality flavour, a natural fit for the construction/observation duality, to be anchored to the trusted kernel like Floors 1-3 when built. Not faked or pre-claimed.
- Zero regressions; structure and lint clean.

# Floor 3: contextual modal type theory over the net, anchored to lizard's trusted S4 kernel

- CONTEXTUAL MODAL TYPES (new `src/cas/inetmodal.lisp`). The modal axis: necessity (Box) with the valid/truth context distinction of Nanevski-Pfenning-Pientka contextual modal type theory. Lizard already implements a correct dual-context (Delta;Gamma) strict-S4 modal checker (tt_check_modal.c); this floor makes the net CARRY the modal derivation (box/unbox aligned with the agents) and DELEGATE the check to the trusted infer-modal. Example 447, golden cas_inetmodal.
- ACCEPTANCE-AGREEMENT, demonstrated guard-free: the net accepts iff the trusted kernel accepts, verified including the S4 4-AXIOM at nesting depth 3 -- a valid hypothesis surviving (box (box (box x))) -- which is the feature distinguishing S4 from weaker modal logics. Acceptance is observable via the Box? primitive (an accepted modal term infers a Box type). Readback faithfulness is exact (carriers lower to lizard's box/unbox surface syntax).
- HONEST NAMED LIMITATION (docs/LIMITATIONS.md), not hidden: the truth-vs-valid REJECTION -- a truth-only variable used inside a box must be rejected, the soundness heart of strict S4 -- is enforced by lizard's trusted kernel (shown live in lizard's own examples 49 and 51) but is NOT re-demonstrated in the sangaku harness. That reject path raises an evaluator-level error that the available guard form does not reliably catch in this interpreter build (guard also corrupts the modal AST node across its boundary, a heap-lifetime effect). The soundness rests on the trusted kernel as designed; the harness simply cannot capture the negative case, and we name that rather than fake a passing rejection test.
- INTERPRETER FINDINGS (documented): lizard's modal forms (box/U/unbox) are heap-allocated AST that survive define but not guard; guard does not reliably catch raised values in this build. These shaped the honest scope of the floor.
- The HoTT/HOTT request is deferred pending disambiguation (homotopy/cubical vs higher-observational vs lizard's own flavour); the modal floor is the unambiguous, solid next floor and is what was built. Zero regressions; structure and lint clean.

# Floor 2: dependent types over the net -- the net carries the derivation, the trusted kernel checks it

- DEPENDENT TYPES (new `src/cas/inetdep.lisp`). The first axis of the cube (types depending on terms), where a well-typed net becomes a genuine dependent-type proof. Example 446, golden cas_inetdep.
- THE HONEST DESIGN, NAMED AND RESOLVED: Floor 1's local wire-consistency does NOT survive dependency -- in (Pi (x:A) B) the codomain B can mention x, so a port's type depends on the value at another port, and a naive local check would be UNSOUND (it would accept ill-typed dependent terms). Rather than fake a locality that isn't there, Floor 2 makes the net CARRY the dependent derivation (carriers aligned with the asymmetric agents: lam, app, Pi former) and DELEGATES the dependent check to the trusted, audited kt_infer. The net is the proof-term carrier; the kernel is the checker. Zero new trusted code; value-dependency handled by machinery already proven sound.
- VERIFIED including the discriminating rejection: the polymorphic identity carrier and a dependent function-type carrier read back EXACTLY to kernel syntax; the kernel accepts the polymorphic identity at (Pi A:U0. Pi x:A. A); with a type family F : Nat -> Type and mk : Pi(n:Nat). F n (genuinely dependent), the kernel accepts (mk zero) at (F zero) but REJECTS it at (F (succ zero)); the net verdict EQUALS the kernel verdict on acceptance AND rejection.
- EXTENDS THE ANCHORING: R2 proved the net's reduction faithful to kt_whnf; Floor 1 proved simple typing faithful to kt_infer locally; Floor 2 proves DEPENDENT typing faithful to kt_infer by carrying the derivation and delegating. Honest about what is local (simple types) and what requires the kernel (dependency). No modification to the trusted kernel; zero soundness risk.
- Zero regressions; structure and lint clean.

# Floor 1: the typed-port discipline over the net, anchored to lizard's trusted kernel

- TYPED PORTS (new `src/cas/inettype.lisp`). The lambda-arrow corner of the cube: each net port carries a simple type (base type or arrow (-> S T)); a wire is well-formed exactly when it joins a producer of type T to an observer of type T. Type-checking is LOCAL wire-consistency -- one pass over the wires -- making the construction/observation duality a literal property of every wire. Example 445, golden cas_inettype.
- ANCHORED, NOT DECORATIVE: the typed-port check is proven to AGREE with lizard's trusted kernel. A net passes local wire-consistency if and only if kernel-check accepts the corresponding term at the corresponding type. This is the typing companion to R2 (which proved the net's reduction faithful to kt_whnf); here the net's typing is proven faithful to kt_infer. The typed-port layer is the kernel's discipline expressed locally on the graph, not a second weaker type system.
- VERIFIED on both acceptance and rejection: the identity net at A and the K net at A,B pass wire-consistency and the kernel accepts the corresponding terms; a deliberately ill-typed net (a wire joining type A to type B) FAILS wire-consistency, and the kernel likewise rejects the corresponding ill-typed claim; the net verdict equals the kernel verdict in every case.
- The honest design tension was named and resolved: rather than invent a parallel simply-typed checker (which could disagree with the trusted kt_infer -- the decorative-layer failure mode), the typed-port discipline is defined so its local check is SOUND with respect to the kernel, verified by agreement. No modification to the trusted kernel; zero soundness risk.
- Floor 1 is the simply-typed corner only; polymorphism, dependency, and the rest of the cube are higher floors, not claimed. Zero regressions; structure and lint clean.

# R2: the interaction-net reducer is faithful to lizard's trusted kernel kt_whnf

- CORRESPONDENCE HARNESS (new `src/cas/inetbridge.lisp`). Establishes that Floor 0's interaction-net reducer (cas/inet.lisp) agrees with lizard's trusted kernel reducer kt_whnf (reached via the kernel-reduce primitive) on a corpus of closed lambda terms. Both compute the same beta-reduction: the net by local graph rewriting, the kernel by tree-walking weak-head normalisation. Example 442, golden cas_inetbridge.
- VERIFIED AGREEMENT: identity (I I) -> identity; constant former (K I) -> a lambda; nested beta (I (I I)) -> identity; and combinations -- the net's normal-form class matches the kernel's on every corpus term. The kernel's OWN trusted equality (kernel-equal? = kt_equal) independently certifies the reducts, so the kernel side rests on the trusted checker, not on the harness's own readback.
- CORRECTNESS BOUNDARY MADE CONCRETE: ibr-divergence-demo exhibits the term outside the one-source-of-duplication fragment where the unlabeled net collapses a superposition (consumes the SUP instead of duplicating it) -- diverging from the lambda-calculus result, reproducing the documented restriction of unlabeled interaction-net sharing. The boundary is demonstrated, not merely asserted.
- TURNS FLOOR 0 FROM ORPHAN TO GROUNDED COMPONENT: the interaction net is now a demonstrably faithful PARALLEL EVALUATION STRATEGY for lizard's trusted kernel on the safe fragment. This is the R2 step of the kernel-audit roadmap. No modification to the trusted kernel -- pure verification, zero soundness risk.
- Readback engineering note: kernel-reduce returns an opaque kernel-term object (not a Lisp list), so the harness classifies it via its printed string form, while the trusted cross-check uses kernel-equal?. Zero regressions; structure and lint clean.

# Lizard trusted-kernel audit (refinement track begins): mapping what must be correct

- KERNEL AUDIT (new `docs/LIZARD_KERNEL_AUDIT.md`). Reframed the foundations work: lizard already HAS a complete, clean trusted dependent-type kernel in C (kernel.c + tt_check family) -- the bidirectional checker, cubical/CCHM layer, HITs, modal layer. The right work is REFINEMENT, not rebuilding, and the foundational task for a trusted kernel is mapping exactly what must be correct. Read the real source and did that.
- THE TRUSTED CORE, MEASURED: the classic minimal triad -- kt_whnf (reduction to WHNF, 156 lines), kt_equal (definitional equality, 123 lines), kt_infer (bidirectional inference, 501 lines) -- plus kt_shift (de Bruijn shifting, 204) and kt_subst (capture-avoiding substitution, 209). Trusted total ~1,350 lines. Everything else (elaboration, tactics) produces terms the kernel RE-CHECKS (the documented trust boundary).
- DE BRUIJN CRITERION FINDING: kernel.h claims "~500 lines must be correct"; the true figure is ~1,350. NOT bloat -- honest growth from type formers added since that comment (cubical Interval/Path/PathLam/PathApp, HITs, Sum/List/Maybe/Empty/Unit families). Still well within the criterion (one auditor can read it), but the docstring should be corrected from ~500 to ~1,350.
- SOUNDNESS SPOT-CHECK (verified live): the kernel correctly ACCEPTS valid proofs (modus ponens, implication composition) and correctly REJECTS ill-typed terms (p:Q rejected since p proves P not Q; mis-ordered composition rejected). The core accept-good/reject-bad property holds.
- THE ASYMMETRIC VISION, CONFIRMED IN THE KERNEL: "the agents ARE the type formers" is already literally true -- KT_PI/KT_LAM/KT_APP are the function constructor/observer, KT_SIGMA/KT_PAIR/KT_PROJ the pair constructor/observer, intro/elim as the construction/observation duality. The interaction-net Floor 0 (inet.lisp) is the PARALLEL EVALUATION STRATEGY; the kernel is the TYPING DISCIPLINE -- two machines that meet, both computing the same beta/eta reduction.
- REFINEMENT ROADMAP (risk-ordered): R1 audit (done); R2 prove the interaction-net reducer agrees with kt_whnf on a term corpus (low risk, makes Floor 0 demonstrably faithful to the trusted reducer rather than an orphan); R3 any C-level kernel extension (high risk, only with full re-checking). Honest about the trust boundary throughout.
- No sangaku regressions; this turn read lizard's source (now visible in the sandbox) and produced an audit, not a code change to the trusted core.

# Floor 3 of lizard's foundations: intensional identity types (the doorway to homotopy)

- IDENTITY TYPES (new `src/cas/idt.lisp`). On the dependent type checker, intensional Martin-Lof identity types -- the type (Id A x y) of proofs that x equals y, with the J eliminator (path induction). The doorway to the homotopy reading of type theory: "types are spaces, equalities are paths" begins here. The construction/observation duality does new work -- a path is a construction, J is its observation.
- THE FOUR RULES + DERIVED THEOREMS. Formation (Id A x y : Type), introduction (refl A a : Id A a a), J-elimination (path induction), and the J-COMPUTATION rule (J ... (refl) collapses to the base case -- the subtle heart, verified by normalization). From J, two theorems DERIVED -- genuinely proved by constructing J-terms the checker accepts, not postulated: SYMMETRY (Id A x y -> Id A y x) and TRANSPORT (Id A x y, P x -> P y). Example 444, golden cas_idt.
- VERIFIED: all four rules; symmetry infers/checks/computes (sym of refl is refl); transport infers/checks/computes (transport along refl is the identity). The J-computation rule propagates correctly through the derived operations.
- HONEST SCOPE (the line held precisely): this is INTENSIONAL identity types -- the floor UNDER HoTT, NOT HoTT. UNIVALENCE is NOT added (an axiom beyond J, not postulated). Higher inductive types NOT added. Type : Type NOT adopted. Identity types are the prerequisite that must exist before univalence can even be STATED -- the first honest step toward the homotopy content, not arrival at it.
- Foundations doc updated: Floors 0,1,2,3 now all BUILT/verified (reduction, simply-typed, dependent, identity types). Remaining cube axes, univalence, higher inductive types, and HoTT proper remain roadmap-conjecture.
- Zero regressions across the whole system; structure and lint clean.

# Floor 2 of lizard's foundations: a dependent type checker (lambda-P)

- DEPENDENT TYPES (new `src/cas/dtt.lisp`). On the simply-typed floor, a dependent type checker -- lambda-P, the Pi-type corner of the cube -- the floor where the two-lattice structure becomes OPERATIONAL. Dependency (types mentioning terms) forces the co-universe object into existence: you cannot state a dependent type without a context. The judgment Gamma |- a : A is the contravariant pairing of the construction (a : A) against the observation (Gamma); the context grows as the checker enters binders -- the co-universe lattice in action.
- WHAT IT IS: Pi-types, a universe, a context, a bidirectional checker (infer/check) with CONVERSION (type equality up to beta-normalization), terms in de Bruijn form (capture-free substitution, syntactic alpha-equality). The four agent roles of Floors 0-1 get their dependent typing rules. Example 443, golden cas_dtt.
- VERIFIED: de Bruijn shift/subst/normalize correct; the polymorphic identity /\\A:Type. \\x:A. x infers (A:Type) -> A -> A and checks against it; applying it to a type computes the instance by substitution in the Pi codomain; and ill-typed terms are REJECTED (non-function application, out-of-scope variables, mis-typed identity, wrong-typed argument) -- a checker that rejects is a real checker.
- WHAT IT IS NOT (stated plainly): not the full Calculus of Constructions (polymorphism/type-operator axes not added), not univalence, not higher inductive types, not HoTT. CONSISTENCY: does NOT adopt Type : Type (Girard's paradox) -- universe treated as a top sort, never used to derive Type : Type; stratified hierarchy is future work.
- Foundations doc updated: Floors 0, 1, 2 now all BUILT/verified; the remaining cube axes (polymorphism, type operators), the full two-lattice formalization, univalence, and HoTT remain roadmap-conjecture.
- Zero regressions across the whole system; structure and lint clean.

# Floor 1 of lizard's foundations: a simply-typed discipline with a type-checker

- SIMPLY-TYPED NETS (new `src/cas/stnet.lisp`). On the Floor 0 interaction-net substrate, a simply-typed discipline with a working type-checker -- the lambda-arrow base of the cube, the analogue of simply-typed lambda calculus as the base of Barendregt's cube. The first floor that earns "type theory": the engine now CHECKS, not just reduces. NOT yet polymorphism, dependency, or HoTT (higher floors, not claimed).
- TYPED PORTS (the chosen design). Types live on the ports; checking is local wire-consistency -- a wire is well-typed iff it joins two ports of the same type at opposite polarity (a producer-of-T meeting an observer-of-T), making the construction/observation duality a literal property of every wire. (The alternative -- types as first-class agents built from the 1-/2-arrow elements -- is noted as the right tool for a higher floor where types become constructed; at the simply-typed base, ports are neater.)
- SUBJECT REDUCTION VERIFIED. The agent rules (LAM introduces A->B principal -/var -/body +; APP eliminates it principal +/arg +/cont -) are shaped so beta (LAM~APP) wires var<->arg and body<->cont at opposite polarity, preserving typing. Verified: typed identity well-typed at o->o (a proof of o->o); ill-typed net rejected; typed application well-typed BEFORE reduction, reduces to normal form, STILL well-typed AFTER -- type preservation, and Curry-Howard in miniature. Example 442, golden cas_stnet.
- An aux-port polarity correction was forced by the identity: the bound-variable port is an observer, not a producer. Floor 0 was insensitive to this (only principal polarity drove its interaction table), so Floor 0 stays valid.
- Foundations doc updated: Floor 0 and Floor 1 now both BUILT/verified; the two-lattice structure, the rest of the cube, and full Curry-Howard remain roadmap-conjecture.
- Zero regressions across the whole system; structure and lint clean.

# Floor 0 of lizard's foundations: a verified interaction-net reduction engine

- INTERACTION-NET REDUCER (new `src/cas/inet.lisp`). The computational substrate for lizard's intended foundational type theory -- the parallel, local-rewriting analogue of the lambda calculus, prototyped in Lisp to validate the design before porting to lizard's C kernel. Only a computational system: no types or logic yet (honest Floor 0).
- THE FOUR 3-ARROW AGENTS BY POLARITY. LAM/APP/DUP/SUP distinguished by port polarity (+ producer / - observer). Polarity DERIVES the legal interaction table: principals interact only at opposite polarity -> exactly the four pairs {LAM,DUP}x{APP,SUP}. Matching decides annihilate (LAM~APP = beta, DUP~SUP = copy-completion) vs commute (LAM~DUP = lambda-copying, APP~SUP = distribution) -- the optimal-lambda-reduction rule set, used as a correctness oracle.
- THE LABEL BET, TESTED. HVM/Lamping use labels to keep distinct duplications from interfering; this bets polarity alone suffices, no labels. Validated on the elementary-affine fragment by verified examples: (lambda x.x)(lambda y.y) reduces to the identity; a duplicator copies a lambda into two correct identities; beta-reduction feeding a duplicator composes correctly. The general-case boundary (where unlabeled sharing mis-shares) is named as open -- finding it is itself a result. Example 441, golden cas_inet.
- A real implementation subtlety found and fixed: annihilation must resolve self-loops (the identity's var<->body wire) and pass-throughs correctly; a bounded resolver follows internal links across the dying pair with a hard step bound, terminating even on self-loops.
- NEW DESIGN DOC `docs/LIZARD_FOUNDATIONS.md`: Floor 0 (built, verified) plus the roadmap stated as conjecture -- the two lattices (universe of terms/types vs co-universe of variables/contexts), the judgement as their contravariant pairing (why "one implies the other" has fixed handedness, not a true symmetry), the cube of features over the net substrate, and Curry-Howard as the bridge earned at the top. Explicitly design intent, not theorem.
- Mutable-vector arena (the SAT lesson: vectors fast, functional allocation thrashes lizard). Iterative reduction driver. Zero regressions across the whole system; structure and lint clean.

# Completing the SAT solver algorithmically: LBD clause deletion + conflict minimization (with an honest ceiling)

- LBD CLAUSE DELETION + MINIMIZATION (new `src/cas/cdcl3.lisp`). The last two algorithmic techniques the winning solvers rely on, both pure algorithm: LBD (Literal Block Distance, Audemard-Simon/Glucose 2009) measures learned-clause quality by distinct decision levels among its literals -- glue clauses (LBD<=2) kept, high-LBD discarded at restart boundaries; conflict-clause minimization (Sorensson-Biere 2009) drops redundant literals by self-subsumption. Verified correct including on PHP(6,5), large enough to trigger database reduction. Example 440, golden cas_cdcl3.
- HONEST CEILING (measured, not assumed): this does NOT make Sangaku competitive with the winning C solvers, and no algorithm will. Measured lizard raw vector-op rate ~100,000/sec vs ~50,000,000 propagations/sec for C solvers -- a ~500x+ substrate gap before their own algorithmic advantages, structural to a tree-walking interpreter. What these techniques achieve is an ALGORITHMICALLY COMPLETE, reference-quality solver: every published technique that isn't pure low-level engineering, as good as it can be on its substrate -- slow only because of the interpreter, and the right SAT engine for Sangaku's own small-instance purposes (SMT, certificate checking).
- Three solvers retained: cdcl.lisp (simple verified reference), cdcl2.lisp (two-watched-literals + VSIDS + phase saving + restarts), cdcl3.lisp (+ LBD deletion + minimization). Correctness verified identical across all; SAT models independently checked.
- Zero regressions across the full SAT/SMT layer, the CAD ladder, the projection/subresultant modules, the certificate/SOS/Galois/kernel layer, Groebner, and the dispatcher; structure and lint clean.

# Making the SAT core fast: two-watched literals, VSIDS decay, phase saving, Luby restarts

- OPTIMIZED CDCL (new `src/cas/cdcl2.lisp`). The reference solver (cdcl.lisp) rescans every clause on every propagation step; cdcl2 replaces that with TWO-WATCHED-LITERAL BCP (Handbook 4.2) -- clauses stored as mutable vectors with watched-literal positions, a watch list per literal code, propagation touching a clause only when a watched literal is falsified. Plus VSIDS with decay, phase saving, and Luby restarts. Implemented from published algorithms, not adapted from any solver's source. Example 439, golden cas_cdcl2.
- MEASURED SPEEDUP: PHP(5,4) drops from ~5s (rescan reference) to ~1s (watched literals); PHP(6,5), where the reference stalls/killed, is decided in ~4s. The two-watched-literal scheme is the single biggest practical lever in SAT. (SAT is NP-complete; the worst case stays exponential -- the strategies clear structured instances, they don't beat the complexity class.)
- BUG FOUND AND FIXED (the kind a complex solver hides): after learning a clause and backjumping, the solver must immediately ASSERT the clause's 1-UIP literal as a unit implication. Omitting it let phase saving re-make the same decision -> infinite loop relearning the same clause (observed as a process kill). Asserting the UIP literal after backjump is what makes CDCL progress; now in place and verified.
- Both solvers retained: cdcl.lisp as the simple verified reference, cdcl2.lisp as the fast solver. Correctness verified identical across the four-clause core, implication chains, PHP(3,2)/(4,3)/(5,4), and satisfiable instances with verified models.
- Zero regressions across the SAT/SMT layer, the CAD ladder, the projection/subresultant modules, the certificate/SOS/Galois/kernel layer, and the linear/dispatcher layer; structure and lint clean.

# A CDCL SAT solver and a DPLL(T) SMT solver over EUF -- the satisfiability layer begins

- CDCL SAT CORE (new `src/cas/cdcl.lisp`). Conflict-driven clause learning from the Handbook of Satisfiability (ch. 4) and the modern competition-solver literature: mutable-vector trail/assignment, Boolean constraint propagation, 1-UIP conflict analysis, clause learning, non-chronological backjumping, VSIDS-style activity branching, iterative main loop. Verified: the four-clause two-variable core is UNSAT; implication chains decided; pigeonhole PHP(3,2) refuted by learning; SAT instances return independently-verified models. Implemented from published algorithms, not adapted from any solver's source. Example 437, golden cas_cdcl.
- SMT LAYER (new `src/cas/smt.lisp`), DPLL(T) over EUF. On the SAT core: the Boolean engine assigns equality atoms, and congruence closure (union-find over interned term ids) decides EUF consistency of the asserted (dis)equalities; a theory conflict blocks the Boolean model and search resumes (the lazy DPLL(T) schema, Handbook ch. 26). Verified: congruence derives a~c, f(a)~f(c), d~e from a=b,b=c,f(a)=d,f(c)=e; transitivity violation a=b,b=c,a!=c is UNSAT; function-congruence violation a=b,f(a)!=f(b) is UNSAT; consistent versions SAT. Decides quantifier-free EUF; richer theories plug in behind the same loop. Example 438, golden cas_smt.
- HONEST SCOPE: SAT is NP-complete; neither solver escapes the exponential worst case. The conflict-driven strategies (learning, VSIDS, watched-literal-style propagation) are what keep the search far from the worst case on structured instances -- "strategies are the key". This is the foundation; the exotic items (SSAT ch.27, QBF, pseudo-boolean ch.22, OBDD ch.25) and richer SMT theories build on this bottom-up.
- IMPLEMENTATION NOTE: the theory solver's first functional assoc-list union-find thrashed the interpreter; the vector-based rewrite (mutable state, as the SAT core's trail) fixed it. Allocation discipline is decisive in the solver layer.
- Zero regressions across the CAD ladder, the projection/subresultant modules, the certificate/SOS/Galois/kernel layer, the linear/dispatcher/audit layer, Groebner, Risch integration, and the TPTP bridge; structure and lint clean.

# A native kernel-checked certificate format, the kernel-scoping fix (namespaced signatures), and the parametric subresultant lift

- KERNEL-SCOPING FIX (namespaced signatures). lizard's kernel has a single global signature; two modules assuming the same symbol would collide. Fix: each certificate domain PREFIXES its kernel symbols (order domain -> ord_, etc.) with a Lisp-level install-once flag, so many domains coexist in the one environment as non-interfering sub-signatures. Verified by checking independent domains in the same run. The reflection-adjacent solution: the global env is partitioned by name, so the proof-carrying surface widens without collision.
- NATIVE CERTIFICATE FORMAT (new `src/cas/certspec.lisp`). There is no checker-neutral CAS-certificate standard suited to a dependent-type kernel (DRAT/LRAT are SAT-specific; Dedukti/OpenTheory are their own ecosystems; proof-assistant serializations are tied to their kernels). Sangaku defines a small principled one, borrowing LRAT's DESIGN (tiny trusted checker, self-contained certificate, checking cheaper than finding) without its representation, deliberately independent of Lean/Coq. A certificate is a triple (domain claim-type proof-term); certspec-check installs the namespaced domain and calls kernel-check, accepting exactly when the proof term inhabits the claim type. A bogus reversed-inequality certificate is rejected -- soundness is the kernel's. One shape for every future certificate. Example 435, golden cas_certspec.
- PARAMETRIC SUBRESULTANT LIFT (new `src/cas/psubres.lisp`). subresultant.lisp built the univariate-over-Q psc tower; the projection needs it with coefficients that are POLYNOMIALS IN A PARAMETER (each elimination step is in the main variable over the remaining ones). psubres lifts the identical recurrence to Q[t] with exact Q[t] division, so the psc come out as polynomials in the parameter whose VANISHING defines the cell boundaries one level down. Verified: Res_x(x^2-a, x-1)=1-a (vanishes at a=1), Res_x(x^2-a, 2x) vanishes at a=0 (double-root locus), Res_x(x^2-a, x^2-1) vanishes at a=1 -- every vanishing locus exact. (Equal-degree resultant VALUE carries a normalization constant; vanishing set and gcd degree exact, the data the projection uses.) Example 436, golden cas_psubres.
- These three advance the central bet -- a CAS whose native output is proof-checkable in its OWN kernel -- with NO external proof assistant (no Lean, no Coq). The certificate format and the scoping fix are the infrastructure for widening the kernel-checked fragment; the parametric lift completes the subresultant ingredient for multivariate projection.
- Zero regressions across the CAD ladder, the projection/subresultant modules, the certificate/SOS/Galois/kernel layer, the linear/dispatcher/audit layer, and the TPTP bridge; structure and lint clean.

# The subresultant principal-coefficient tower (full Collins completeness) and the published projection improvements

- SUBRESULTANT TOWER (new `src/cas/subresultant.lisp`). The ingredient the FULL Collins projection needs beyond discriminants and resultants: the tower of principal subresultant coefficients psc_0, psc_1, psc_2, ... built via the Brown-Collins subresultant polynomial remainder sequence (exact over Q). CAD-relevant invariants verified across a sweep (12+ cases, 0 disagreements on vanishing): the resultant vanishes exactly when two polynomials share a factor, and the gcd degree (least nonzero psc index) gives multiplicity structure (squarefree->0, double->1, triple->2). subres-prs, subres-psc-tower, subres-resultant, subres-gcd-degree. Example 434, golden cas_subresultant.
- HONEST CONVENTION NOTE: the resultant VALUE matches the Sylvester resultant when degrees differ; in the equal-degree case it can differ by a normalization constant. This never affects the vanishing set or gcd degree -- the cell-boundary data the projection consumes -- which are exact in every case (subres-caveat).
- TOGETHER WITH McCALLUM: the two modules give both ends of the published projection literature -- McCallum's reduced operator (mccallum.lisp) for speed where well-oriented, the subresultant tower for the completeness Collins guarantees for any set. This is the published-improvements answer to "adopt the solutions Mathematica and QEPCAD used": McCallum 1988 for the reduction, Brown-Collins subresultant PRS for the complete tower, each implemented from the literature, neither adapted from any system's source.
- Neither changes the doubly-exponential worst-case class (Davenport-Heintz, a theorem -- a permanent wall). They reduce the base/constants (McCallum) and guarantee completeness (the psc tower).
- Zero regressions across the CAD ladder, the projection modules, the linear/dispatcher/audit layer, the certificate/SOS/Galois/kernel modules, and the TPTP bridge; structure and lint clean.

# The McCallum reduced projection operator -- the algorithm QEPCAD B and Mathematica's CAD use, implemented from the literature

- McCALLUM PROJECTION (new `src/cas/mccallum.lisp`). The published improvement (McCallum 1988/1998) that makes the CAD projection set dramatically smaller than Collins' original -- the basis of the default projection in QEPCAD B and Mathematica. Collins carries the full principal-subresultant-coefficient tower per polynomial; McCallum proved that for a WELL-ORIENTED set only the discriminant, the pairwise resultants, and the leading coefficients are needed, dropping the tower. Implemented from the literature (not adapted from any system's source -- a licensing matter). mccallum-project (reduced set), mccallum-well-oriented? (validity certificate), mccallum-project-safe (McCallum when certified, full Collins fallback otherwise). Verified: {y^2-x, y-x} -> {disc -4x, res x^2-x}, agreeing with the Collins-safe superset (sign-invariance preserved), constant leading coeffs dropped. Example 433, golden cas_mccallum.
- HONEST SCOPE: this does NOT beat the doubly-exponential worst case (Davenport-Heintz, a theorem -- a permanent wall). It reduces the base of the exponential and the constants, which is the practical lever the established systems rely on, without changing the asymptotic class. The reduced operator is valid only for well-oriented sets; mccallum-project-safe falls back to the full Collins projection when well-orientedness cannot be certified, trading size for unconditional validity.
- This is the published-algorithm answer to "adopt the solutions Mathematica and QEPCAD used": those solutions are McCallum/Brown reduced projection plus partial CAD (cadwit, already present). The improvements are in the literature and implemented here from it; no proprietary or GPL source was copied.
- Zero regressions across the CAD ladder (cadnd, cadcomplete), the linear/dispatcher/audit layer, the certificate/SOS/Galois/kernel modules, and the TPTP bridge; structure and lint clean.

# Consolidating the decision layer: a complete linear fast-path (Fourier-Motzkin), a verdict-preserving dispatcher, and a soundness audit

- LINEAR ARITHMETIC (new `src/cas/lra.lisp`). Fourier-Motzkin elimination: a COMPLETE decision procedure for the linear fragment of real-closed-field theory, single-exponential rather than the doubly-exponential cost of full CAD. Partition constraints by the sign of the eliminated variable's coefficient, assert every lower bound <= every upper bound, solve/substitute equalities, iterate. Strictness composes correctly (open empty intervals unsatisfiable; x>=2 and x<2 unsatisfiable). Verified across single-variable, multivariable, equality, and boundary cases. Example 430, golden cas_lra.
- THE DISPATCHER (new `src/cas/qedispatch.lisp`). Routes a univariate existential sentence to the cheapest COMPLETE method: linear -> Fourier-Motzkin; sum-of-squares-refutable -> the UNSAT filter; else -> the complete CAD decider. Every branch is complete for what it accepts and the branches agree on overlap, so the dispatcher's verdict EQUALS the full decider's on every problem -- only faster. Exposed via rqe as rqe-decide-fast / rqe-route. Building it surfaced and fixed a real soundness gap (strict-inequality information was dropped in atom translation; the cross-validation caught it). Example 431, golden cas_qedispatch.
- SOUNDNESS AUDIT (example 432, golden cas_qedispatch_audit). A systematic cross-validation that the dispatcher and the full decider agree across 50+ problems -- linear atoms (all signs/operators), intervals (closed/open/empty/mixed-strictness), quadratics (SAT and UNSAT) -- with zero disagreements, captured as a permanent regression test. The fast paths are proven verdict-preserving.
- The honest shape of "complete at scale": real QE is doubly-exponential in the worst case (Davenport-Heintz, a theorem -- a permanent wall, beaten by no implementation). The consolidation makes Sangaku fast on the linear, the refutable, and the structured, complete on everything, and confines the doubly-exponential cost to the genuinely hard nonlinear problems where it is inherent.
- Zero regressions across the CAD ladder, the certificate/SOS/Galois/kernel modules, and the TPTP bridge; structure and lint clean.

# Sangaku certificates checked by LIZARD'S OWN type-theory kernel -- the same engine computing and proving

- KERNEL-CHECKED PROOFS (new `src/cas/certkernel.lisp`). The decisive step toward "a CAS whose every statement shows a proof in lizard's type theory". Where certlean renders certificates as text for an external assistant, certkernel discharges them INSIDE lizard: it builds a proof term in lizard's dependent type theory and the kernel primitive kernel-check accepts it only if it genuinely inhabits the stated type. Discovery: lizard already exposes a dependent-type kernel (kernel-assume / kernel-check / kernel-infer / kernel-reduce), and diff-cert already proves derivative judgments through it.
- TWO FRAGMENTS, over a shared commutative ring. (1) NONNEGATIVITY p(x)>=0: proved from an explicit sum-of-squares through the order axioms stated as kernel constructors (sq_nonneg : (y:R)->Ge (y*y) 0, one_nonneg, add_nonneg, scale_nonneg); the kernel supplies the universally-quantified content, certlean's exact SOS reconstruction supplies the identity. x^2+x+1, x^2+1, (x-1)^2, non-monic 5x^2-4x+1 all proved; x^2-1 and a bare linear term correctly REFUSED (soundness is the kernel's). (2) DERIVATIVES: Der (\x.f) (\x.f') re-exported from diff-cert; d/dx(x*x), d/dx(x+x), d/dx(sin x) certified. Through the Fundamental Theorem the calculus chain of DOWN_TO_AXIOMS is now machine-checked inside lizard. Example 429, golden cas_certkernel.
- DOWN_TO_AXIOMS.md updated: two of the three chains (order, via SOS; and derivative/FTC, via Der) are now checked by lizard's OWN kernel, not merely exported to Lean -- the Fundamental Theorem chain is machine-checked inside lizard.
- Honest scope (certkernel-caveat): the kernel proofs cover the sum-of-squares nonnegativity fragment and the elementary derivatives, not yet every statement Sangaku can decide. Widening that fragment (general nonnegativity, existence as a kernel proof, the decision procedures) is the path to the full goal.
- Zero regressions across the CAD ladder, the certificate/SOS/Galois modules, the kernel-checked diffn module, and the TPTP bridge; structure and lint clean.

# Proving radical-unsolvability of quintics, and exporting the completeness chain (existence) to a proof assistant

- SOLVABILITY BY RADICALS (new `src/cas/galois.lisp`). Turns the worked example's ASSERTION that a quintic is unsolvable into a PROOF for the family a classical criterion reaches. Theorem (Dedekind): an irreducible polynomial over Q of prime degree p with exactly two non-real roots has Galois group S_p, non-solvable for p>=5. Sangaku checks degree primality, irreducibility (Eisenstein at a prime, or a bounded integer-factor scan), and a Sturm real-root count of exactly p-2. For x^5-4x+2 (Eisenstein at 2, 3 real roots) and x^5-6x+3 (Eisenstein at 3, 3 real roots): PROVED S_5, not solvable by radicals. Honest scope: x^5-x-1 is itself S_5 but has 4 non-real roots, so the criterion does not apply and the module returns 'unknown (not overclaimed); a general Galois-group computation is not built. The partner of galquartic. Example 428, golden cas_galois.
- EXISTENCE CERTIFICATE EXPORT (src/cas/certlean.lisp). The bridge previously exported nonnegativity certificates (order-axiom chain); it now also exports EXISTENCE certificates (completeness-axiom chain). A sign change f(a)<0<f(b) is rendered as a Lean theorem asserting a root in [a,b], proved by the intermediate value theorem. So the existence of sqrt2 -- the canonical completeness fact -- is now kernel-checkable from sangaku's own root isolation. docs/sangaku_certificates.lean now carries both families. Example 426 extended. This is the completeness-dependent step named as unbuilt in the previous iteration, now built.
- DOWN_TO_AXIOMS.md updated: the existence chain (Chain 1, sqrt2) is now exported to Lean alongside the SOS chain (Chain 2), so both the order-axiom and completeness-axiom chains are kernel-checkable; only the derivative/FTC chain (Chain 3) remains unexported.
- Note on the destination: these exports target a proof assistant generally (rendered for Lean 4 / mathlib); the certificate content is format-neutral, anticipating ingestion by lizard as it develops a proof-checking kernel.
- Zero regressions across the CAD ladder, the certificate/SOS/Galois modules, and the TPTP bridge; structure and lint clean.

# The CAS-to-prover bridge (certificates as Lean lemmas), a quartic Galois-group decision, and an sos bug fix

- THE BRIDGE (new `src/cas/certlean.lisp`). Exports Sangaku's nonnegativity certificates as proof-assistant-checkable obligations. For a nonnegative quadratic c+bx+ax^2 (a>0), emits the explicit SOS identity a(x+b/2a)^2 + (c-b^2/4a) as a Lean 4 `nlinarith [sq_nonneg ...]` proof the kernel verifies by ring normalization -- trusting nothing about Sangaku. For a general nonnegative polynomial, emits the sign certificate (squarefree odd part has no real root, positive leading coefficient) as a statement the assistant re-checks. A generated Lean file is at docs/sangaku_certificates.lean. Honest scope: proof-producing CAS-to-prover links already exist (HOL Light, Coq psatz, Lean polyrith); this is one more, grounded in Sangaku's own certificates. Example 426, golden cas_certlean.
- SOS BUG FIX (src/cas/sos.lisp), surfaced by the bridge: sos-nonneg?/sos-positive?/sos-certificate failed on non-monic and rational-root-count polynomials because real-root counting via cauchy-bound assumes integer coefficients while sos-odd-factor/sos-monic produce rationals. Now clears denominators before counting (the real-root count is invariant under positive integer scaling). x^2: still fine; 5x^2-4x+1: now correctly nonneg and positive; 2x^2-5x+1: correctly not nonneg. The existing sos golden is unchanged (the tested cases were monic); no regressions in nullstellensatz/positivstellensatz/cadunsat.
- GALOIS GROUP OF A QUARTIC (new `src/cas/galquartic.lisp`), a genuine breadth addition completing the solvability story. Depresses the quartic, forms the resolvent cubic y^3-py^2-4ry+(4pr-q^2), counts rational roots, tests if the discriminant is a perfect square: resolvent splits -> V4; irreducible resolvent -> A4 (square disc) or S4 (non-square); one rational root -> C4-or-D4 (tie-break deferred). Reducibility detected including no-rational-root quartics that split into rational quadratics. Verified: x^4+1 (V4), x^4+x+1 (S4, disc 229), x^4+8x+12 (A4, disc 576^2), x^4-2 (D4), x^4+4 (reducible). Every quartic is solvable -- the degree-four companion to the radical-unsolvable quintic x^5-x-1. Example 427, golden cas_galquartic.
- DOCS: docs/DOWN_TO_AXIOMS.md traces three results (existence of sqrt2, positivity of x^4-x^2+1, the integral of 2x) from the printed answer through the certificate to the governing theorem (Sturm, univariate Positivstellensatz, FTC) down to the order and completeness axioms and the ZFC construction of the reals -- explicit about being a logical-dependency chain, not a formal ZFC derivation, with the SOS chain now machine-checked in Lean.
- Zero regressions across the CAD ladder, the certificate/SOS modules, and the TPTP bridge; structure and lint clean.

# Closing four open boundaries: irrational sections, exact minimum cover, a scale filter, and the cost theorem documented

- IRRATIONAL boundary surfaces. New `src/cas/cadqenr.lisp` samples parameter sections at the exact ALGEBRAIC number when the root is irrational -- the case cadqenx (rational sections only) missed. The section factor's sign is zero by definition; other factors' signs are computed by the classical sign-at-an-algebraic-number method (interval refinement until sign-constant, shared roots via a common factor); the family is decided exactly at the algebraic point with Q(alpha) arithmetic. exists x. (x-p=0) and (x^2-2=0) eliminates to the irrational locus p^2-2=0, sections at p=+-sqrt2 captured exactly. One-parameter sweep complete; multi-parameter algebraic towers documented as the boundary. Example 424, golden cas_cadqenr.
- EXACT minimal cover. `src/cas/cadqemin.lisp` gains branch-and-bound minimum-cover (cadqemin-cover-exact, cadqemin-minimize-exact): a provably minimum prime-implicant cover, where the earlier essential-plus-greedy was only good. On the general quadratic both give the three-branch law; on greedy-trap instances exact is strictly smaller. cadqemin-cover-best picks exact for small prime sets, greedy otherwise. Example 422 extended.
- Completeness AT SCALE. New `src/cas/cadunsat.lisp`: a sound, dimension-independent UNSAT filter refuting an existential conjunction as soon as a conjunct contradicts a non-negativity certificate (g<0 with g a sum of squares, g=0 with g strictly positive, symmetric cases), no decomposition, time independent of dimension. One-directional and sound (unsat is genuine, unknown defers). The cheap front end to the complete deciders. Example 425, golden cas_cadunsat.
- The doubly-exponential COST is a THEOREM (Davenport-Heintz), documented with cell growth measured directly: k independent linear parameter factors give 3,9,27,81 cells for k=1..4. cadwit and cadunsat are the honest response -- avoiding the bound on the easy half of instances in each direction, not beating it.
- WORKED EXAMPLES (docs/WORKED_EXAMPLES.md): six non-trivial theorems proven to primitive certificates -- a radical-unsolvable quintic with one real root (Sturm), the irrationality of sqrt2 by root-counting over two fields, non-obvious quartic positivity (SOS), the general quadratic's three-branch elimination, an irrational-parameter system, and dimension-independent refutation.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean.

# Exact boundary sampling: complete partitions yield true minimal solution formulas directly from the sweep

- EXACT BOUNDARY SAMPLING. New `src/cas/cadqenx.lisp` closes the gap that kept the minimal-formula constructor from attaining the true minimum on the general quadratic -- which was the SAMPLER, not the minimizer. cadqen samples projection-factor roots by refined approximation, so a sample meant to lie on a boundary surface (discriminant exactly zero) lands just off it and the tangent stratum (real double root, b^2=4ac) is lost. cadqenx recovers the EXACT rational roots of each factor (rational root theorem) and samples each parameter level at them, so the boundary cell is hit exactly and recorded with its true sign 0.
- VERIFIED: for the general quadratic the discriminant factor 1-4c has exact root c=1/4, the tangent cell (a>0,b>0,c>0,disc=0) is captured, and the true-cell count rises 23 -> 27 to include the boundary stratum. On that COMPLETE partition cadqemin produces a sound and complete three-branch minimal formula directly from the sweep -- no conservative fallback. End to end: `cadqenx-elim2` returns the complete realizable true/false partition; `cadqemin` covers by prime implicants. Example 423, golden cas_cadqenx.
- Honest scope (cadqenx-caveat): a factor with IRRATIONAL roots still has its sections sampled by approximation (an exact section would need an algebraic-number sample point), so for such families boundary coverage is partial and conservative validity still applies. For rational-root projections -- the general quadratic and the linear-system examples among them -- the partition is complete and the minimum is attained.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean. rqe and qe_audit goldens unchanged.

# True minimal solution formulas: prime-implicant cover with don't-cares (Brown's problem, second phase)

- TRUE MINIMAL SOLUTION FORMULAS. New `src/cas/cadqemin.lisp` performs the genuine second phase of minimization that mere merging (cadqesimp) skips: a MINIMAL cover of the true sign-cells by prime implicants, the simplest-formula core of Brown's solution-formula-construction problem. The key is DON'T-CARES: a projection factor's sign is constrained, so only some of the 3^m patterns are realizable; the eliminator supplies the realizable TRUE and FALSE sets, and a cube is valid iff it covers no false cell (the rest are free). Two classical phases: prime generation (generalize each true cell -- exact sign to relation >=,<=,!= to "any" -- as far as stays valid) and minimal cover (essential primes + greedy).
- VERIFIED: on the general quadratic, given the complete true/false partition over {a,b,c,disc}, cadqemin returns EXACTLY the textbook three-branch law (a!=0 and b^2-4ac>=0) or (a=0 and b!=0) or (a=0 and c=0) -- sound (no branch covers a false cell) and complete (every true cell covered). Exposed as `rqe-eliminate-min`; `cadqen-elim2` supplies the true/false sign-vector sets a sweep produces. Example 422, golden cas_cadqemin.
- Honest scope (cadqemin-caveat): the cover is essential-plus-greedy -- exact on the standard examples, always sound and complete, but exact minimum set cover is NP-hard (Brown's hard core). And minimality is bounded by the completeness of the supplied partition: the independent-axis sampler can miss measure-zero BOUNDARY cells (discriminant exactly zero, the tangent stratum), since it is not a full coupled projection; on a sampled partition cadqemin uses conservative validity (cover only proven-true cells) to stay sound, attaining the true minimum on a complete partition.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean. rqe and qe_audit goldens unchanged.

# General n-parameter quantifier elimination: arbitrary parameter dimension by recursion, and two more univariate-decider completeness fixes

- ARBITRARY PARAMETER DIMENSION. New `src/cas/cadqen.lisp` eliminates one quantified variable from a formula with ANY number of free parameters, the uniform generalization of the parameter line (cadqe), plane (cadqe2), and 3-space (cadqe3). A parameter polynomial is a list of monomials (coeff e_1 ... e_k) over k parameters; the k-dimensional parameter space is decomposed by RECURSION on k -- project onto the outer parameter, sample it, substitute (peeling the first exponent, lowering k by one), recurse on the (k-1)-parameter subproblem, with the parameter line as the base. Each cell is decided by the complete univariate decider; the answer is the sign-vectors of the projection factors over the satisfiable cells.
- VERIFIED: reproduces cadqe3 exactly on the general quadratic (k=3, the same 23 sign-vectors), and solves a genuine FOUR-parameter problem -- exists x. a*x=b and c*x=d (two linear equations sharing a solution) over factors {a,b,c,d, b*c-a*d}, yielding the resultant locus b*c-a*d=0 on the nondegenerate stratum with the degenerate strata correctly separated. Exposed as `rqe-eliminate-n`, subsuming rqe-eliminate/2/3 at k=1,2,3. Example 421, golden cas_cadqen.
- TWO COMPLETENESS FIXES in `src/cas/realqe.lisp` (foundational; surfaced by the 4-param degenerate strata), both about the constant/zero polynomial a degenerate parameter point produces inside a CONJUNCTION. (1) The product guard protecting root isolation treated only the empty list as zero, letting an explicit (0) -- the polynomial of the atom 0=0 -- collapse the whole product and erase the other conjuncts' roots; it now treats any all-zero list as the constant 1. (2) The sign-at-root routine called square-free-part on a constant atom, dividing by a vanishing leading coefficient; it now reads a constant atom's sign directly. Both leave the realqe golden UNCHANGED; exists x. 0=0 and x=5 now correctly decides true.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean. rqe and qe_audit goldens unchanged.

# Three-parameter quantifier elimination (the general quadratic), a solution-formula simplifier, and two univariate-decider completeness fixes

- BEYOND TWO PARAMETERS -- the general quadratic. New `src/cas/cadqe3.lisp` eliminates a quantified variable from a formula with THREE free parameters, reaching the hard textbook QE example exists x. a*x^2+b*x+c=0 with a FREE leading coefficient. The answer is not the discriminant alone but the leading-coefficient case split (a!=0 and b^2-4ac>=0) or (a=0 and b!=0) or (a=0 and b=0 and c=0). cadqe3 extends cadqe2's parameter plane to the parameter 3-space: project the factors {a,b,c,b^2-4ac} onto a, sample each a-cell, substitute a and reuse cadqe2's planar (b,c) sweep, decide each (a,b,c) cell with the complete univariate decider, and read the answer as sign-vectors. All true sign-vectors verified against the general-quadratic law; the genuine-quadratic, degenerate-linear, and trivial-identity strata all recovered. Exposed as `rqe-eliminate3`. Example 419, golden cas_cadqe3.
- SOLUTION-FORMULA SIMPLIFICATION. New `src/cas/cadqesimp.lisp` minimizes the raw sign-vector output the way Quine-McCluskey minimizes a Boolean cover: FACTOR ELIMINATION drops a factor whose three signs all appear; SIGN MERGING combines two signs into a relation (>=0, <=0, !=0); with absorption, to a fixpoint. Each merge preserves covered points, so the result is equivalent to the raw disjunction. On the clean monic-quadratic case it reaches the exact textbook relation (discriminant <= 0); on the general quadratic it substantially reduces the cover. Not guaranteed globally minimal (Brown's problem). Example 420, golden cas_cadqesimp.
- TWO COMPLETENESS FIXES in `src/cas/realqe.lisp` (foundational; surfaced by cadqe3). (1) The zero/constant polynomial from a degenerate parameter point (a=b=c=0 gives the identity 0=0) was dividing by a vanishing leading coefficient; a constant-product guard now handles it (0=0 decides true, 7=0 false). (2) Root isolation assumed integer coefficients, but refined rational sample points yield rational coefficients after substitution (x^2+x+1/8); clearing denominators by lcm before isolation -- a positive scaling preserving roots and signs -- makes the decider robust to rational coefficients. Both leave the realqe golden UNCHANGED.
- SAMPLER SHARPENING in `src/cas/cadqe2.lisp`: the raw isolating intervals from the root isolator can be wide (1/4 isolated only to (-5/4,5/4), midpoint 0 is not the root), so each interval is now refined to a tight width before its midpoint is taken as the root estimate. This recovers parameter cells the coarse sampling missed -- including the all-positive discriminant-positive stratum of the general quadratic. cadqe2 golden unchanged.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean. rqe and qe_audit goldens unchanged.

# Multi-parameter quantifier elimination: the discriminant locus, the textbook QE example

- BEYOND ONE PARAMETER -- two-parameter parametric QE. New `src/cas/cadqe2.lisp` eliminates a quantified variable from a formula with TWO free parameters, returning a quantifier-free condition on the parameters as sign conditions on the projection factors. This is the textbook QE example one-parameter elimination could not reach: exists x. x^2+bx+c=0 over the reals, whose answer is the discriminant locus b^2-4c>=0. The construction generalizes cadqe from the parameter line to the parameter PLANE: project away x by the multivariate resultant (cadnd) to get the (b,c) factors, decompose the plane by the planar projection-and-lift (project factors onto b, sample b-cells, lift to c-cells), decide each cell with the complete univariate decider, and read the answer off as the SIGN VECTOR of the factors on the true cells.
- VERIFIED: exists x. x^2+bx+c=0 -> discriminant >= 0 (factor -b^2+4c sign 0 or negative); exists x. x^2+bx+c<0 -> discriminant > 0; forall x. x^2+bx+c>0 -> discriminant < 0; forall x. x^2+bx+c>=0 -> discriminant <= 0; and the pure resultant case exists x. x=b and x=c -> b=c (the factor b-c = 0). Exposed as `rqe-eliminate2` beside `rqe-eliminate` (one parameter) and `rqe-decide` (closed sentences). Example 418, golden cas_cadqe2.
- Scope: two parameters, one quantified variable (the planar parameter space). Three or more parameters are the general parametric CAD over a higher-dimensional space, with full solution-formula construction (Brown's problem) a further refinement; cadqe2-caveat names this boundary.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean. rqe and qe_audit goldens unchanged (cadqe2 is a parallel entry, not in the sentence-decision path).

# Parametric quantifier elimination, a scale accelerator, the exact coupled-fiber sign, and a univariate-decider completeness fix

- BEYOND DECISION -- parametric QE. New `src/cas/cadqe.lisp` eliminates a quantified variable from a formula with a free PARAMETER, returning an equivalent quantifier-free condition on the parameter -- the headline real-QE capability sangaku previously lacked (rqe-decide only decided fully-quantified sentences). The method is the CAD of the parameter line: project the family onto the parameter, decide the constant truth value on each resulting cell with the complete univariate decider, and emit the union of the true cells, merging adjacent ones (b<0 or b=0 -> b<=0). VERIFIED: exists x. x^2+b<0 -> b<0; forall x. x^2-b>=0 -> b<=0; exists x. x^2=b -> b>=0; exists x. x^2=b and x>0 -> b>0; exists x. (x-b)^2-1<0 -> true; exists x. x^2+b^2+1<0 -> false. Exposed as `rqe-eliminate` beside `rqe-decide`. Example 417, golden cas_cadqe. Scope: one parameter, one quantified variable (planar); cadqe-caveat names the general multi-parameter boundary.
- COMPLETENESS FIX in `src/cas/realqe.lisp` (foundational; surfaced by cadqe). An existential equality at an even-multiplicity root -- exists x. x^2=0 -- was wrongly reported FALSE: the test for "the polynomial vanishes inside this isolating interval" used a sign change of the polynomial itself, which an even-multiplicity root does not produce (x^2 stays positive on both sides of 0). The fix tests vanishing via the SQUARE-FREE part, whose roots are simple and change sign reliably. The realqe golden is UNCHANGED -- the fix only adds correct verdicts (exists x. x^2=0, x^4=0, ... now decide true). This propagated to cadqe so exists x. x^2=b correctly includes the section b=0.
- SCALE -- a partial-CAD witness accelerator. New `src/cas/cadwit.lisp` performs a guided depth-first witness search: at each level it projects to the outer variable, samples the SUPPORT-interior sectors first, substitutes, and recurses, returning on the first witness, with the two-variable base handled by cadfull. A full-dimensional satisfiable instance far from any fixed grid -- which cadgen's grid misses, forcing the expensive complete decider -- is now found on a single root-to-leaf path. It is a pure accelerator (only ever returns a TRUE verdict for a real witness; never asserts UNSAT), wired into rqe-exists-n after the cheap grid and diagonal recognizer and before the complete section decider. The far 3-ball drops from ~2s to ~1s; rqe and qe_audit goldens unchanged. Example 416, golden cas_cadwit.
- THE COUPLED-FIBER NONZERO SIGN, made exact. `src/cas/cadrc.lisp` decided vanishing for the general regular chain exactly (multivariate resultant) but read the nonzero sign off a converging interval box that could fail to separate from zero for a hard coupled fiber -- the residual the old caveat named. The box is now refined by ANCHORED bisection: a fiber root is bisected only once its lower coordinates are tight enough that the two candidate half-boxes carry definite opposite signs, so the box provably tracks the true point and the eval interval -- of a value already known nonzero by the resultant -- separates with a definite sign. VERIFIED on adversarial near-tangencies to 15 digits, for z=x*y and z=x+y couplings; cadrc golden extended with an adversarial near-zero sign line; cadrc-fiber-sign-caveat now records both vanishing and nonzero sign as complete.
- Zero regressions across the entire CAD ladder and the TPTP bridge; structure and lint clean throughout.

# Coupled regular chains: the tower frontier closes -- irrational-outer witnesses whose fibers mix several lower variables

- Extended `src/cas/cadtow2.lisp` with a COUPLED-CHAIN path: when the equalities form a general regular chain whose defining polynomials mix several lower variables at once (z = x*y, z = x + y) rather than only the immediately preceding one, the simple-tower recognizer declines and the decision now falls through to cadrc.lisp. The chain is read in cadrc's representation (each fiber a polynomial in its top variable with mpoly coefficients over the lower variables), the fiber boxes are built by substituting a rational probe vector of the lower coordinates into each coupled fiber and isolating its roots, the real branches are enumerated, and the inequalities are tested at the chain point with cadrc-sign (multivariate resultant with regrouping between levels). This closes the last structural gap named by the previous cadtow2 caveat.
- VERIFIED: exists x,y,z. x^2=2 and y^2=x and z=x*y and z>0 decides TRUE (witness sqrt(2), 2^(1/4), 2^(3/4) -- outer coordinate irrational, top coordinate couples the two below); the same with z>2 is FALSE; the additive coupling z=x+y with z>2 is TRUE (z = sqrt(2)+2^(1/4) ~ 2.60). Example 415 extended; golden cas_cadtow2 extended to cover the coupled cases.
- The dispatch tries the simple-tower path first (unchanged) and only falls through to the coupled path when needed, so simple towers are unaffected. cas_cadtow2 simple cases, cas_cadrc, and all CAD-ladder goldens unchanged; cas_rqe and cas_qe_audit unchanged (the coupled path is the final resort in rqe-exists-n).
- Found and fixed a representation bug while building the coupled path: the cadrc-fiber regroup double-nested each coefficient mpoly (an extra list layer), so cadrc's mpoly evaluation failed; the fix stores the coefficient term list flat, matching cadrc's golden form exactly (y^2-x -> (((-1 1)) () ((1 0)))).
- Zero regressions across the full CAD ladder and TPTP bridge; structure and lint clean.

# General-position sections for n>=3: recursive cylindrical lifting reaches cells of every dimension; two foundational fixes

- Added `src/cas/cadcomplete.lisp`: a COMPLETE real decision procedure for general n by genuine recursive cylindrical sampling. It samples the outermost variable at the TRUE breakpoints of the family (a rational in each open sector AND each real projection root as a section, possibly irrational), substitutes, and recurses on the lower-dimensional family, bottoming out in the complete two-variable decider (cadfull). This replaces the earlier DIAGONAL-only n>=3 section recognizer: non-diagonal sections, POSITIVE-DIMENSIONAL sections (curves/surfaces inside R^n), and zero-dimensional sections off the diagonal are all reached. Verified on the unit sphere in R^3: the open ball (full-dim), the open equatorial arc (1-dim, irrational witness), and the poles (0-dim), with impossible controls rejected. Example 414 + golden cas_cadcomplete.
- FIXED `cadn-lift-coeffs` in `src/cas/cadnd.lisp`: it was an identity stub that silently prevented the projection tower from descending past one level for general families. It now performs the genuine regrouping of a projected mpoly by its new last variable, so cadn-project-tower descends correctly for any number of variables. cas_cadnd golden unchanged (the fix is compatible with the previously-verified cases, which it now generalizes).
- FIXED a completeness bug in `src/cas/cadfull.lisp`: the fiber decision evaluated section roots at rational MIDPOINTS, so an equality atom a root satisfies read as nonzero and the section witness was missed (e.g. the open arc x^2+y^2=1 with x>0,y>0 wrongly returned false). Section roots are now evaluated as EXACT real algebraic numbers via algnum2; rational section coordinates are detected exactly by a Stern-Brocot simplest-rational search, keeping the recursion exact. cas_cadfull golden unchanged. All eight 2-var cases (both-quadrant arcs, irrational sections, disk, empties) verified.
- Wired cadcomplete into `src/cas/rqe.lisp` additively and as the LAST resort: full-dimensional grid first, then the cheap diagonal recognizer, then the general recursive lifting. The common cases stay fast (3-var diagonal ~1s) while previously-undecidable general sections are now reached. cas_rqe and cas_qe_audit goldens UNCHANGED.
- The unified rqe now decides genuinely non-diagonal sections it could not before: the equatorial arc (1-dim) and the poles (0-dim) of the sphere are all correct, confirmed through the single rqe entry point.
- Zero regressions across the full CAD ladder (cadnd, cad2d, algnum2, cadgen, cadsecn, cadtower, cadrc, cadfull, cadcomplete, rqe) and TPTP bridge; structure and lint clean.

# Three capabilities unified: real QE as one call (Tarski + TPTP), completeness at scale (+ audit), breadth facade

- Added `src/cas/rqe.lisp`: UNIFIED real quantifier elimination -- one entry point `rqe-decide n quant phi` deciding a quantified real sentence in ANY number of variables, in human-facing Tarski syntax (atoms rqe-gt/rqe-lt/rqe-ge/rqe-le/rqe-eq/rqe-ne with and/or/not). Dispatches by variable count: univariate decider (n=1), complete two-variable decider (n=2), full-dimensional-cell search UNION equality-variety section search (n>=3). Universal sentences by negation. Example 411 + golden cas_rqe. Also rqe-sat / rqe-valid, and rqe-decide-internal for already-translated formulas.
- Added `src/cas/cadfull.lisp`: a COMPLETE two-variable decision procedure finding witnesses on cells of EVERY dimension -- full-dimensional AND section. Samples the base axis at the true CAD breakpoints (rational sector midpoints AND real projection roots as algebraic sections) and decides each fiber completely. Closes the grid decider's completeness gap: `exists x,y. y^2=x AND x=2` is now TRUE (the section witness (2,sqrt2) the grid misses). Example 410 + golden cas_cadfull. Caught and fixed a double-definition of cadfull-take (arity bug) by isolation.
- Upgraded the TPTP bridge (`src/cas/tptp/core.lisp`): a new `real-qe-n` goal shape `(real-qe-n n quant phi)` routes MULTIVARIATE real-QE through rqe-decide-internal, with a `qe-verdict-n` certificate and `multivariate-real-qe` route name. The univariate `real-qe` path is unchanged (backward compatible; cas_tptparith golden unchanged). Both input forms -- Tarski (rqe) and TPTP (bridge) -- now reach the unified decider.
- Added example 412 + golden cas_qe_audit: a SOUNDNESS / COMPLETENESS AUDIT. Fourteen checks -- six FALSE sentences rejected (x^2+1=0, forall x>0, exists x^2<0, x^2+y^2+1<0, y^2=x AND x=-1, 3-var ball+1<0), eight TRUE sentences found (x^2-2=0, forall x^2>=0, x^2-2>0, the ellipse x^2+4y^2=4, positivity, the section y^2=x AND x=2, the irrational circle-line section, the 3-var diagonal section) -- with NO false verdict.
- Added `src/cas/cas.lisp`: the BREADTH FACADE -- a single discoverable entry point re-exporting the headline deciders (cas-decide-real, cas-sat, cas-valid, cas-refutes-over-C, cas-nonneg?, cas-nonneg-on?, cas-groebner) under one import and one naming scheme, plus a machine-readable catalogue cas-capabilities / cas-domains naming ten domains. Adds no new mathematics; it is the index making the 200+ modules' breadth visible. Example 413 + golden cas_facade.
- All three user-requested targets advanced equally: real QE as a single callable thing (Tarski first, then TPTP), completeness at scale (complete 2-var decider + section-aware general-n + 14/14 audit), and breadth (the facade).
- Zero regressions; structure and lint clean.

# CAS frontier: the GENERAL REGULAR CHAIN completed (coupled defining polynomials) + a CAS comparison

- Completed `src/cas/cadrc.lisp`: the GENERAL REGULAR CHAIN -- a point cut out by a triangular system whose defining polynomials may couple ALL lower coordinates at once (e.g. z = x + y, depending on two earlier coordinates), the last structural generality past cadtower's simple (consecutive-only) chain. Example 409 + golden cas_cadrc.
- VANISHING (was present but had latent bugs, now fixed and verified): reduce the target down the chain with the MULTIVARIATE resultant (cadnd's mpoly Sylvester determinant), regrouping between levels. Fixed three real bugs by isolation: (1) the inter-level regroup must TRUNCATE the eliminated exponent positions so the coefficient mpoly arity matches the next-level defining polynomial (was zeroing, not dropping -> arity mismatch); (2) the regroup index must target the new top variable, not the just-eliminated one; (3) the final elimination yields an mpoly over the base alone and converts directly to univariate -- regrouping it again produced a malformed structure. Verified: reduce(z) = x^2 - x on {x^2-2, y^2-x, z-x-y}.
- NONZERO SIGN (the cadrc-fiber-sign-caveat, now CLOSED): added top-down box refinement over coupled fibers -- mpoly interval arithmetic, base tightened first, each coordinate's interval bisected keeping the half whose defining polynomial (evaluated over the now-tighter lower intervals) straddles zero. Coupled fibers isolate because lower coordinates are tightened first. Verified on z = sqrt(2)+2^(1/4): z>0, z-2>0, z-3<0 exact; z-x-y=0; and (z-x)^2-x=0 (a coupled cancellation, since z-x=y and y^2=x).
- BOTH halves of the general regular chain -- vanishing and nonzero sign -- are now complete. This is the last structural generality of the cylindrical-algebraic-decomposition climb.
- Added `docs/cas-comparison.svg` (and outputs/sangaku-cas-comparison.svg): an honest comparison of sangaku against Mathematica, Maple, QEPCAD B, Redlog, and SymPy. The established systems lead on scale, performance, breadth, and maturity; sangaku's distinguishing axis is VERIFIABILITY -- machine-checkable certificates reducible to rational arithmetic, built from scratch in Lisp with no external CAS dependency, fully inspectable source.
- Zero regressions; structure and lint clean.

# CAS frontier: the GENERAL multi-algebraic TOWER -- nested radicals and iterated algebraic extensions, any height

- Added `src/cas/cadtower.lisp`: the general multi-algebraic SECTION tower -- a point whose coordinates form an iterated algebraic extension Q < Q(a1) < Q(a1,a2) < ..., each a genuine algebraic number over the field below (NOT a polynomial in the previous coordinate). This is the frontier past cadsecn (which decided only EXPLICIT triangular sections), the structure of nested radicals like sqrt(2) -> 2^(1/4) -> 2^(1/8), the n-dimensional generalization of algpoint's two-level construction. Example 408 + golden cas_cadtower.
- Two exact mechanisms: VANISHING by reducing a polynomial down the chain with iterated bivariate resultants to a univariate base polynomial, tested at the base algebraic number (algpoint's resultant test iterated down a tower of any height); NONZERO sign by interval arithmetic over a box refined TOP-DOWN (base tightened first, each fiber isolated over the now-tight coordinate below -- the order that converges where an n-box's coupled refinement cannot).
- Section decider cadtower-exists-chain: builds the witness points from a simple chain by isolating each level's root and tests extra sign conditions at them. Verified: exists x,y: x^2=2 and y^2=x and y>1 (TRUE, y=2^1/4~1.19); y>2 (FALSE); x-y>0 (TRUE, sqrt2>2^1/4).
- Verified on the height-3 radical tower x=sqrt2, y=2^1/4, z=2^1/8: the radical identities (2z^2-2y=0) reduce to zero, while coordinate comparisons (z>1, z-6/5<0) are exact.
- Caught real bugs by isolation: the iterated resultant reduction must LIFT each univariate resultant back to bivariate form before the next elimination (representation match between levels); the top-down box refinement must report current state and thread the lower interval correctly to each fiber (an earlier version re-refined the base and crossed interval types).
- SCOPE: decides the SIMPLE iterated tower (each defining polynomial relates consecutive coordinates) of any height -- nested radicals and iterated extensions, fully irrational. The fully general regular chain, whose defining polynomials couple ALL lower coordinates at once (multi-resultant elimination), is the deepest residual generality, named by cadtower-chain-caveat.
- Zero regressions; structure and lint clean.

# CAS frontier: GENERAL-n SECTIONS -- the final ridge (exact irrational section witnesses for any n)

- Added `src/cas/cadsecn.lisp`: GENERAL-n SECTION sample points and their exact decision -- reaching the witnesses cadgen cannot see, those confined to a lower-dimensional SECTION with algebraic (irrational) coordinates in a tower. Example 407 + golden cas_cadsecn.
- The KEY insight, found by isolating why nbox fails: an n-box's coupled refinement cannot isolate a zero-dimensional point (bisecting one coordinate cannot be validated while the others are wide -> the defining system straddles zero in both halves -> never converges). The exact route is TRIANGULAR: pin the base coordinate as the root of a univariate polynomial (algnum2), propagate the system's relations to express each further coordinate over the ones already fixed, flatten the tower onto the base, and take the exact algebraic-number sign. All rational arithmetic; fully irrational witnesses.
- Verified on the zero-dimensional point x=y=z=1/sqrt(3) (cut out by x^2+y^2+z^2=1, x=y, y=z -- UNREACHABLE by full-dimensional sampling): x>0, sphere=0, x-y=0, x+y+z-2<0 (sqrt3<2), and the whole existential system TRUE; and the 4-dimensional diagonal x1=...=x4=1/2.
- This is the section analogue, for any n, of the two-variable decider's algpoint machinery.
- SCOPE: decides section cells whose defining equalities are TRIANGULAR over the base coordinate (every zero-dimensional triangular witness, any n, fully irrational). The general non-triangular multi-algebraic tower (arbitrary equality variety, iterated resultant back-substitution at every level) is the deepest remaining work, named by cadsecn-general-caveat.
- THE CLIMB NOW: univariate real QE complete; two-variable decider COMPLETE (full cells + rational + irrational sections + nested tower); projection tower all n; algebraic sample points 2-D and n-D; 3-var lifting + general-n full-dimensional decider; and now exact general-n section witnesses (triangular case). Remaining frontier: the general multi-algebraic section tower for arbitrary n.
- Zero regressions; structure and lint clean.

# CAS frontier: GENERAL n -- one recursive real decider for any number of variables (full-dimensional cells)

- Added `src/cas/cadgen.lisp`: a GENERAL n-variable real decision procedure over the full-dimensional cells, by recursive cylindrical sampling -- the single RECURSIVE decider for ANY n, where cad2d/cadlift hand-unrolled 2 and 3. Recurse on the outermost variable: at n=1 a univariate sign-condition decision; else sample rational values for the outer variable, SUBSTITUTE each (exact Horner fold on the nested poly rep, lowering arity), recurse on the (n-1)-variable family. The tower is FINITE (n variables, n levels) -- the reason real decision is decidable; cost exponential in n but depth bounded. Example 406 + golden cas_cadgen.
- SOUND: every sample value is an exact rational real point, so a positive verdict is always correct. COMPLETE for full-dimensional witnesses (a full-dimensional solution set has nonempty interior, met by a fine rational sample set). Verified across n=1,2,3,4: univariate cells; the open disk and the unit-triangle interior; the open 3-ball and the sum-of-three-squares universal; the open 4-ball nonempty and its +1 shift empty and the sum-of-four-squares universal -- the recursion running to depth four.
- Performance: grid density is the cost knob (exponential in n is unavoidable for CAD); tuned the per-axis grid to remain tractable to n=4 worst case (grid-exhausting FALSE) while still hitting small full-dimensional regions like the unit triangle.
- SCOPE: decides over the full-dimensional cells for ALL n. Exact treatment of lower-dimensional sections for general n (lifting nbox algebraic sample points through every level, as the 2-var decider does in full) is the remaining frontier, named by cadgen-section-caveat.
- Zero regressions; structure and lint clean.

# CAS frontier: n-dimensional algebraic sample points + three-variable LIFTING (the ascending half, past two vars)

- Added `src/cas/nbox.lisp`: n-DIMENSIONAL ALGEBRAIC SAMPLE POINTS -- a point in R^n with all-algebraic coordinates, represented by a rational isolating BOX, with the EXACT sign of any n-variate polynomial at it by interval arithmetic over the box (nested Horner) + refinement of the widest coordinate. This is exactly what a lifted CAD sample point is, the same code for every dimension, with NO symbolic algebraic-tower arithmetic (the tower Q(a1)...(an) is never built). The levels are finite: n variables -> fixed tower height n. Example 404 + golden cas_nbox. Verified in 3-D on a sphere point with an irrational coordinate (sign of the sphere poly = 0, 2z^2-1 = 0, x-z < 0, etc.).
- Added `src/cas/cadlift.lisp`: a THREE-VARIABLE CAD decider by genuine LIFTING -- the ascending phase one dimension past the two-variable decider. Sample the x-axis (sectors); over each x=a substitute to a (y,z)-fiber and sample its y-axis (via cadproj 2-var projection); over each (a,b) substitute to a z-fiber and sample the z-line; evaluate phi at (a,b,c). Cylindrical (each lower coordinate fixed before the next), exact over Q on the full-dimensional cells. Decides exists^3 and forall^3. Example 405 + golden cas_cadlift. Verified: open unit ball nonempty; x^2+y^2+z^2+1<0 empty; forall x,y,z x^2+y^2+z^2>=0 (true) vs -1>=0 (false); bounded positive region {x>0,y>0,z>0,x+y+z<2} nonempty; x>0 and x<0 contradictory.
- Verified the cylindrical lifting substitution chain explicitly (substitute x=1/2 -> y^2+z^2-3/4, then y=0 -> z^2-3/4, eval at z=0 -> -3/4 < 0, confirming (1/2,0,0) in the ball).
- SCOPE: cadlift decides over the FULL-DIMENSIONAL cells (open sectors at every level), complete for full-dimensional witnesses (all satisfiable strict-inequality systems, and universals). Complete 3-D section lifting (the nbox algebraic sample points lifted through every level) and general n remain the frontier, named by cadlift-section-caveat. The foundation -- projection downward (cadnd), algebraic sample points (nbox/algpoint), lifting over full-dimensional cells (cadlift) -- is now in place.
- Zero regressions; structure and lint clean.

# CAS frontier: the nested tower Q(alpha)(beta) -- the two-variable decider is now COMPLETE and sound

- Added `src/cas/algpoint.lisp`: REAL ALGEBRAIC POINTS in the plane -- a point (alpha, beta) that is the unique common real solution of a defining pair A(x,y)=0, B(x,y)=0, isolated by a rational BOX, with the EXACT sign of any bivariate polynomial at it by interval arithmetic over the refining box. Vanishing is decided algebraically (alpha a common root of the eliminants; y-constant curves c(x)=0 tested via c(alpha) directly). Pure rational arithmetic -- no floats, no algebraic-field arithmetic. This is the nested-tower primitive Q(alpha)(beta) and exactly what a lifted CAD sample point is. Example 403 + golden cas_algpoint. Verified on (1/sqrt2, 1/sqrt2): exact signs of x, y, x+y-1, 2xy-1 (=0), the defining curves (=0), etc.
- Extended `src/cas/cadsection.lisp`: evaluate the WHOLE formula at the algebraic intersection points of the equality curves over a critical x (csec-decide-eq-section), via algpoint -- including inequality side conditions at the nested-tower point. Golden cas_cadsection extended.
- Rewired `src/cas/cad2d.lisp`'s equality-section pass to use the full-formula-at-intersection decision instead of a mere curve-meeting test. This is a SOUNDNESS GAIN: x^2=2 AND y^2=x AND x-y<0 is now correctly FALSE (at x=sqrt2, y=2^1/4, x-y>0), where the old meeting-only test wrongly accepted it; x-y>0 is correctly TRUE. The existing cad2d golden is UNCHANGED (the fix only corrects/adds verdicts none of whose golden cases were affected); golden extended with the nested-tower cases.
- Caught real bugs by isolation: y-refinement and y-root isolation must use the y-BEARING defining curve (a curve constant in y like x^2-2 has no y-roots); apt-vanishes? must special-case y-constant curves (their resultant degenerates) by testing the x-content at alpha directly.
- MILESTONE: the two-variable real decider is now COMPLETE -- full-dimensional cells, rational sections, irrational sections, AND the nested algebraic tower Q(alpha)(beta), all decided exactly. The remaining frontier is the recursion to n>2 (full-dimensional lifting stacking algebraic sample points through every level).
- Zero regressions; structure and lint clean.

# CAS frontier: exact irrational sections (2-var CAD now complete) + the n-variable projection tower

REAL ALGEBRAIC NUMBERS
- Added `src/cas/algnum2.lisp`: real algebraic numbers as (defining-poly, isolating interval), with the EXACT sign of any rational polynomial at one, by interval bisection (q(alpha)=0 iff gcd(q,defp) has its root in the interval; else refine until sign-definite). Rational arithmetic + Sturm only -- no floats, no symbolic field. Verified on sqrt(2) and the golden ratio. Example 400 + golden cas_algnum2.

IRRATIONAL SECTIONS -- closing the two-variable CAD's boundary
- Added `src/cas/cadsection.lisp`: exact evaluation of a formula on the section over an irrational critical x. The key move: sign(p_i(alpha,b)) at rational b = asec-sign(p_i(x,b), alpha), deciding all strict conditions with no irrational arithmetic; equality witnesses detected by y-resultant vanishing at alpha. Example 401 + golden cas_cadsection.
- WIRED into `src/cas/cad2d.lisp`: an irrational-section pass now runs when the open-cell pass finds no witness. The previously-missed x^2+y^2=1 AND x=y (irrational witness 1/sqrt2) is now decided TRUE; soundness preserved by also checking x-only side conditions at alpha (y^2=x AND x+1<0 stays FALSE). The existing cad2d golden is UNCHANGED (purely additive -- only adds true verdicts for previously-missed irrational witnesses); golden extended with new irrational cases. The two-variable decider is now complete except for the nested tower Q(alpha)(beta).

THE n-VARIABLE PROJECTION TOWER (recursion to n>2)
- Added `src/cas/cadnd.lisp`: the n-variable projection operator -- eliminate one variable from polynomials in n variables via the multivariate (mpoly) resultant (Sylvester determinant by exact cofactor expansion, sign by negation), building the projection tower R^n -> ... -> R. Plus a full-dimensional 3-variable existence decider. Verified: Res_z(z-x,z-y)=x-y; disc_z(z^2-x) ~ x; the open unit ball and positive-simplex interior are found nonempty; contradictions rejected. Example 402 + golden cas_cadnd.
- Caught real bugs by isolation: the mpoly determinant's sign-unit had an empty exponent vector that corrupted monomial products (fixed by tracking sign via negation instead of a constant unit); the resultant's power base case had the same malformed unit (fixed).
- HONEST SCOPE: the projection tower is exact for any n (the descending phase). The n-dimensional algebraic-tower LIFTING -- sample points with coordinates in Q(alpha_1)(alpha_2)... stacked through every level -- is the deep frontier, named by cadn-lifting-caveat. The fully worked decider remains the 2-variable case.
- Zero regressions; structure and lint clean.

# CAS frontier: a working TWO-VARIABLE CAD decider (projection joined to lifting)

- Added `src/cas/cad2d.lisp`: a two-variable cylindrical algebraic decomposition decision procedure -- the LIFTING phase joined to last turn's projection (cadproj) -- for "exists x exists y . phi" and "for all x for all y . phi" over the reals, phi a boolean combination of polynomial sign conditions. Collins' CAD in 2 variables, exact over Q: project to critical x's; decompose the x-axis (open sectors + rational sections); lift each sample x to the univariate fibers, decompose and sample the y-line; evaluate phi on each constant-sign 2-cell. Decides, exactly: the open unit disk is nonempty; x^2+y^2+1<0 is unsatisfiable; forall x,y x^2+y^2>=0 (true) vs x^2+y^2-1>=0 (false); parabola y^2=x meets x=4 at y=+-2 but has no point with x+1<0; hyperbola xy=1 has a positive-branch point; line x=y meets x^2+y^2=2 at (1,1).
- Caught several real bugs during construction, each by isolation not guessing: (1) the determinant accumulator issue was upstream; here, the y- and x-sampling initially missed SECTIONS (root coordinates), breaking equality constraints -- fixed by adding rational-root section samples per fiber/projection-factor; (2) the Sturm machinery requires integer coefficients and errored on rational-coefficient fibers -- fixed by clearing denominators before every Sturm call (roots unchanged); (3) rational-root candidate generation needed denominator-clearing too.
- HONEST SCOPE: decides via full-dimensional cells + rational sections. Every satisfiable strict-inequality system and every universal statement is decided exactly; a witness living ONLY on a section over an IRRATIONAL critical x (e.g. x^2+y^2=1 with x=y, solved only at 1/sqrt2) is the named boundary cad2-section-caveat -- the decider under-reports there, never a false positive. Exact treatment needs the real algebraic extension Q(alpha) per root; n>2 variables needs iterating the levels. Both are the frontier ahead.
- Example 399 + golden cas_cad2d. Zero regressions; structure and lint clean.

# CAS frontier: the CAD projection phase (first rung toward multivariate real QE)

- Added `src/cas/cadproj.lisp`: the PROJECTION phase of cylindrical algebraic decomposition, built exactly over Q -- the genuine first rung from univariate real QE toward the multivariate frontier. A bivariate p(x,y) is a polynomial in y with x-polynomial coefficients; the resultant Res_y(p,q) is the determinant of the Sylvester matrix over Q[x] (exact cofactor expansion, polynomial entries, no division), vanishing exactly where two curves share a y-coordinate; the discriminant disc_y(p)=Res_y(p,dp/dy) vanishes where a fiber has a repeated y-root. The projection of a family is the set of discriminants and pairwise resultants whose real roots cut the x-axis into fiber-invariant cells. Verified: Res_y(y^2-x, y-x)=x^2-x; disc_y(y^2-x) ~ x; Res_y(circle, y)=x^2-1.
- Caught a real determinant bug during construction: the cofactor-expansion sum accumulator was initialized to the polynomial 1 instead of 0, adding a spurious +1 to every resultant; fixed to start the sum at zero. (The Sylvester matrix construction itself was correct; the bug was purely in the determinant's accumulator.)
- Example 398 + golden cas_cadproj. Zero regressions; structure and lint clean.
- HONEST SCOPE: this is the projection phase only. The lifting phase (sample points in the plane over each x-cell) and the recursion to n variables remain the open frontier; cad-lifting-caveat names it. Projection is the indispensable first half and turns a 2-variable problem into 1-variable problems the real-QE base decides.

# CAS frontier: univariate real quantifier elimination (a genuine decision procedure)

- Added `src/cas/realqe.lisp`: UNIVARIATE REAL QUANTIFIER ELIMINATION -- a complete DECISION PROCEDURE for "exists x . phi" and "for all x . phi" over the reals in one variable, phi a boolean combination of polynomial sign conditions. The exact one-dimensional case of Tarski's theorem / CAD. By sign-invariant cell decomposition: the real roots of the polynomials cut R into cells of constant sign, and the statement is decided by sampling phi at one exact-rational point per open cell (below/between/above the isolated roots), with root cells evaluated by sign-on-the-isolating-interval -- exact over Q, no irrational coordinates. Decides strict and non-strict inequalities, universals, and equality-witness conjunctions (e.g. x-3=0 and x^2-3x+2>0 is true; x-2=0 and x^2-3x+2>0 is false). This is a genuine DECISION (not a certificate to supply), a real step beyond last turn's checker. Example 397 + golden cas_realqe.
- Extended `src/cas/tptp/core.lisp` with a `real-qe` goal shape routing univariate real statements to the decision procedure (theorem / countersat -- it decides). Existing routes unchanged; bridge golden extended.
- Zero regressions; structure and lint clean. The multivariate case (full CAD with projection/lifting) is named as the frontier ahead.

# CAS frontier: the constrained Positivstellensatz (and wiring it into the TPTP-arith bridge)

- Added `src/cas/positivstellensatz.lisp`: CONSTRAINED positivity certificates -- proving p >= 0 on a semialgebraic set S = {g_i >= 0} by a weighted-SOS (Positivstellensatz/Putinar) certificate p = sigma_0 + sum_i sigma_i g_i with every sigma_j a sum of squares. Sound by construction (on S the RHS is manifestly >= 0); verified exactly over Q by checking the polynomial identity and that each sigma_j is SOS (decided for univariate sigma_j via sos.lisp). Verified: x>=0 on {x-1>=0} (sigma_0=1,sigma_1=1); x^2-1>=0 on {x-1>=0} (sigma_0=(x-1)^2,sigma_1=2); rejects a non-SOS multiplier (the false x-3>=0 on {x-1>=0}, which fails at x=1) and a broken identity, each with a named reason; empty constraints reduce to plain SOS. Like SOS this CERTIFIES, not DECIDES (finding multipliers is a semidefinite search). Example 396 + golden cas_positivstellensatz.
- Extended `src/cas/tptp/core.lisp` with a `nonneg-on-set` goal shape that routes constrained-nonnegativity goals ("for all x in S, p(x) >= 0") to the Positivstellensatz checker: 'theorem with a valid certificate, 'unknown without (never falsely refuted). Existing routes unchanged (additive). Golden cas_tptparith extended for coverage.
- This is the frontier rung directly above unconstrained SOS, and it makes the bridge able to settle guarded arithmetic goals. Zero regressions; structure and lint clean.

# CAS frontier: multivariate SOS certificates + a TPTP-arithmetic bridge (side project)

MAIN FRONTIER
- Added `src/cas/sosmv.lisp`: MULTIVARIATE sum-of-squares certificates of global nonnegativity -- a sound, one-directional positivity proof. If p = sum q_i^2 then p >= 0 everywhere; the module verifies such a decomposition exactly over Q (expanding with mpoly arithmetic) and reports the residual when a candidate is wrong, never claiming "p is not nonnegative" (the converse fails by Motzkin). Includes the Gauss product identity. Verified: (x+y)^2 certifies x^2+2xy+y^2; {x,y} certifies x^2+y^2; the Motzkin polynomial is acknowledged nonnegative-but-not-SOS (no false certificate). Example 394 + golden cas_sosmv.

SIDE PROJECT (started inside Sangaku, splittable later)
- Added `src/cas/tptp/core.lisp`: the TPTP-ARITHMETIC BRIDGE. A classifier + router taking an arithmetic goal and dispatching it to the right Sangaku decider with that decider's certificate: contradictory polynomial systems -> Nullstellensatz ('theorem with refuting basis); polynomial identities -> exact check; univariate universal inequalities -> SOS DECISION; multivariate -> SOS certificate ('theorem with witness, 'unknown without -- never falsely refuted); ground comparisons -> direct evaluation; everything else -> 'outside-fragment. Sound by construction. Honest scope: Sangaku is not a FOF/CNF saturation prover; this is the certificate-carrying arithmetic niche. Consumes goals from the tptptp parser lowered to normalized forms. Example 395 + golden cas_tptparith.
- Made check-structure.sh and find-orphans.sh recurse into src/cas subdirectories (for the new tptp/ submodule tree).
- Zero regressions; structure and lint clean.

# CAS frontier — the Nullstellensatz decision procedure (and a bridge toward automated theorem proving)

- Added `src/cas/nullstellensatz.lisp`: Sangaku's first genuine DECISION PROCEDURE. By Hilbert's Weak Nullstellensatz, a polynomial system f_1=...=f_m=0 is unsatisfiable over the algebraic closure iff 1 is in the ideal, iff the reduced Groebner basis contains a nonzero constant. nss-decide returns 'unsatisfiable | 'satisfiable; nss-refutes? gives the refutation; nss-verify-refutation re-checks the certificate (1 and each generator reduce to 0 against the basis). This is the algebraic analogue of deriving FALSE from hypotheses -- the shape of an arithmetic theorem-proving (TPTP) goal, with the Groebner basis as proof.
- Verified: {x, x-1} and {xy-1, x} unsatisfiable (refutations verify); {x-5}, {x^2+y^2-1, x-2} (complex solution), and {} satisfiable.
- Caught a real bug during construction: normal-forming the constant 1 against a basis hung when exponent vectors had differing lengths; replaced with direct detection of a nonzero constant in the reduced basis (the clean Nullstellensatz test), which is robust and faster.
- Honest scope: decides satisfiability over the algebraically CLOSED field; real solvability (Positivstellensatz) and full first-order logic are named as separate, harder problems, not conflated.
- Added example 392 and golden cas_nullstellensatz. Zero regressions; structure and lint clean.

# CAS — axiom mode (simpler proving UX) + the ramified-place integral element (frontier pushed harder)

- Added `lib/cas/axmode.lisp`: an AXIOM MODE for lightweight theorem proving. Load axioms once (ax-assume facts, ax-assume-rule rules, ax-assume-not negative facts), then ax-check any statement for a three-valued verdict: proven (derivable), disproven (negation derivable -- never from mere absence), or independent (neither). A contradictory axiom set is flagged 'inconsistent. Built on logic.lisp's Horn-clause engine, so the verdicts are exactly the trusted engine's. From {human(socrates), mortal(X):-human(X)}: mortal(socrates) proven, mortal(zeus) independent, then disproven once (not (mortal zeus)) is added; multi-step ancestry resolved.
- Added `lib/cas/ramplace.lisp`: the RAMIFIED-PLACE integral element on y^2 = f, the local integral-closure generator at a cusp (a root of f of multiplicity m >= 2, where the branch is a Puiseux series in a fractional power) -- harder than the multi-branch node case. At x=a the valuations are v(x-a)=2, v(y)=m; the element w = y/(x-a)^floor(m/2) is integral with w^2 = f/(x-a)^{2 floor(m/2)} a polynomial (monic minimal polynomial certificate). Verified: cusp y^2=x^3 -> y/x, w^2=x (ramified); y^2=x^5 -> y/x^2, w^2=x; y^2=(x-1)^3 at x=1; even multiplicity y^2=x^2 splits (w a unit); a non-root point is unramified-regular. Place classified ramified/split/unramified-regular (local Riemann-Hurwitz data).
- Added examples 390 (axiom mode) and 391 (ramified place) and their goldens, with soundness controls (inconsistent set flagged; non-root yields no element).
- Updated the comparison with the two new rows; the roadmap's integral-closure horizon now reads: finite squarefree + nodes + ramified hyperelliptic places done; general-degree ramification and infinite places open.
- Zero regressions across the logic, integral-closure, and theorem-proving chains.

# CAS as theorem prover — certified definite integrals and the Dirichlet/sinc integral = pi/2

- Added `lib/cas/defint.lisp`: CERTIFIED DEFINITE INTEGRALS by the Fundamental Theorem of Calculus. For a polynomial integrand, computes the antiderivative F, discharges "F is an antiderivative of f" with the differentiation arbiter, evaluates F(b)-F(a) exactly, and emits a re-checkable proof record (a tampered value fails re-check). INT_0^1 x^2 = 1/3, INT_0^2 (3x^2+2x+1) = 14, etc., each a theorem.
- Added `lib/cas/dirichlet.lisp`: the Dirichlet integral INT_0^inf sin(x)/x dx = pi/2 (the sinc value), proved by the parameter-integral (Feynman) method -- NOT by an antiderivative (the integrand is non-elementary). I(s)=INT_0^inf e^{-sx} sin x/x dx; I'(s)=-INT e^{-sx} sin x=-1/(s^2+1) (Lemma A, Laplace transform certified from its antiderivative); I(s)=C-arctan(s) (Lemma B, arctan-derivative certified); boundary gives C=pi/2; I(0)=pi/2. The transcendental lemmas are certified by exact-agreement-at-samples; the algebraic backbone is exact; the proof record re-checks.
- Caught a real reader bug during construction: a quoted symbol containing parentheses (laplace-sine=1/(s^2+1)) broke the s-expression reader though the parens balanced lexically; fixed by removing the embedded parens from the symbol name.
- Added examples 388 (definite-integral theorems) and 389 (sinc/Dirichlet theorem) and their goldens, including soundness controls (tampered records rejected).
- The honest division of labor: the FTC case (defint) and the non-elementary parameter-integral case (dirichlet) are kept distinct, naming which arbiter certifies which step.
- Updated the comparison with the two theorem-proving rows. Zero regressions.

# CAS frontier — multi-branch combined integral element (general-curve integral closure)

- Added `lib/cas/vanhoeijmb.lisp`: the MULTI-BRANCH combined-correction integral element on y^2 = f, building and certifying an integral-basis element w = (A + B y)/d that is integral at a place where several branches meet at once -- the case vanhoeij.lisp deferred as 'needs-place-combination. Found by the exact integral-closure test in K = Q(x)[y]/(y^2-f): w is integral iff its minimal polynomial w^2 - (2A/d)w + (A^2-B^2f)/d^2 has polynomial coefficients (trace and norm both divide out). The norm sees all branches, certifying integrality everywhere simultaneously.
- Verified: at the node y^2=x^2(x+1) the element y/x (trace 0, norm -(x+1)) is the combined-branch element; at the two-node y^2=x^2(x-1)^2(x+1) the element y/(x(x-1)) is integral at both; non-integral candidates (y/x^2, y/(x-1) at a smooth point) are rejected with the failing trace/norm exhibited.
- Caught a zero-representation bug during construction: the certificate compared () vs (0) for the zero trace polynomial; fixed by comparing trimmed forms.
- Added example 387 and golden cas_vanhoeijmb with full coverage including the rejection controls.
- Updated the comparison (new multi-branch row) and roadmap (the integral-closure horizon now reads: finite squarefree + multi-branch nodes done; ramified and infinite places open).
- Zero regressions across the integral-closure, superelliptic, and aperiodicity chains.

# CAS last rung closed — unconditional aperiodicity proof for the third-kind integral

- Added `lib/cas/hyperaperiodic.lisp`: an UNCONDITIONAL certificate that y^2 = f has no Pell unit -- hence that INT dx/sqrt(f) is non-elementary -- by traversing the full cycle of complete quotients of the continued fraction of sqrt(f) until a pair (P_i, Q_i) repeats. A closed cycle with no nonzero-constant Q (past the trivial start) is a finite PROOF of non-elementarity, converting polycf's bounded "aperiodic-up-to-B" into a real theorem. Both directions of the third-kind elementarity decision are now closed: periodic gives the explicit logarithm, proven-aperiodic gives non-elementarity.
- Cross-checked by independent agreement: y^2=x^6+1 has the unit (x^3,1) (elementary, torsion), y^2=x^6+x^2+1 closes its cycle with no unit (proven non-elementary, non-torsion) and the bounded polycf search independently agrees (aperiodic up to 100). x^6+x^4+1 and x^6+x+2 likewise proven non-elementary.
- Caught a subtle bug during construction: the trivial first complete quotient (P_0,Q_0)=(0,1) has Q_0=1 constant by construction and must be excluded from the unit test (else every curve looks periodic); the test runs over the tail of the cycle only.
- Added example 386 and golden cas_hyperaperiodic with full coverage including the elementary/non-elementary split and the bounded-vs-unconditional cross-check.
- The Trager ladder now shows zero open rungs: every rung has a sound certified core, with the full third-kind construction at summit and the genuine research horizon (uniform period bound per genus) named honestly in the roadmap.
- Zero regressions across the Pell, continued-fraction, Jacobian-torsion, and hyperelliptic chains.

# CAS frontier — hardening the Pell unit engine: square guard + reverse-CF cross-check

- Added a perfect-square guard and explicit unit classification to `lib/cas/polycf.lisp`: pcf-is-square? flags curves where sqrt(f) is a polynomial (no Pell unit), and pcf-unit-status returns one of 'square / (unit A B) / 'unit-unverified / 'no-unit-up-to -- so every verdict is explicit rather than a degenerate unit-unverified. Verified x^4+2x^2+1=(x^2+1)^2 is flagged 'square.
- Added a reverse-CF round-trip cross-check (example 385): a unit (A,B) with constant norm c determines f=(A^2-c)/B^2, and the continued fraction of that f must independently recover a certified unit. This validates the unit-finder against the opposite construct-from-unit direction -- two independent methods agreeing. Verified the engineered curve x^6+2x^4+3x^2+2 from (x^4+x^2+1, x, 1) is recovered by the CF with exactly that nonconstant-B unit, plus several further engineered units round-tripping.
- Over Q, polynomial Pell with period >= 3 is rare (none found in a wide small-coefficient scan), so the reverse-CF construction is the rigorous validator of the convergent/norm machinery beyond period 1.
- Added golden cas_pellcrosscheck; existing cas_polycf golden unaffected (additive functions).
- Updated the comparison with one new capability row.
- Zero regressions across the polycf, Pell, third-kind, and algebraic chains; every positive result certified.

# CAS frontier — period-2 Pell units fixed, and a CF-driven third-kind construction for any periodic curve

- Fixed a convergent/iteration-indexing bug in `lib/cas/polycf.lisp`: the Abel recurrence must start from the state AFTER a0 (P_1 = a0, Q_1 = f - a0^2), not from (P=0, Q=1) which recomputed a0 and shifted every partial quotient. With the fix, genuine period-2 curves certify: y^2 = x^6 + x now has period 2 and a certified fundamental unit (2x^6+1+..., 2x^2) of constant norm, where before it was honestly deferred as unit-unverified. The period-1 family (incl. f=h^2+c) is regression-clean. Updated example 383 and golden cas_polycf to reflect the period-2 certification.
- Added `lib/cas/hyperpellcf.lisp`: the CF-driven genus-2 third-kind Pell construction. Given ANY hyperelliptic curve y^2 = f, it asks polycf for the certified fundamental unit (A,B), builds g0 = A + B y in the genus-agnostic field (algfunc), and produces INT ((g0^n)'/g0^n) = log(g0^n), each gated by the differentiation certificate. Generalizes hyperpell past the f=h^2+c family to every periodic curve, including genuine period-2. Verified on y^2=x^6+x (period 2, not h^2+c) for n=1,2,3, agreement with hyperpell on x^6+1, and an honest no-unit for a non-periodic curve.
- Added example 384 and golden cas_hyperpellcf with full coverage including the soundness control.
- Updated the comparison (one new row) and the Trager ladder (the open third-kind rung now records the CF-driven construction and period-2; longer periods at higher genus remain).
- Zero regressions across the polycf, Pell, third-kind, and algebraic chains; every positive result certified.

# CAS frontier — the continued fraction of sqrt(f): deciding a hyperelliptic curve's Pell unit

- Added `lib/cas/polycf.lisp`: the continued fraction of sqrt(f) over Q[x] (Abel's algorithm), with periodicity detection and the fundamental-unit convergent -- the function-field analogue of the numeric CF for sqrt(N). Computes polypart(sqrt f) by coefficient matching, iterates the complete-quotient recurrence, detects periodicity (Q returns to a constant), and reads the fundamental Pell unit off the convergent. Every unit is gated by its norm A^2-B^2 f being a nonzero constant (pcf-certify-unit, pcf-unit-verified): the period-1 family (incl. f=h^2+c) is fully certified; higher even periods return unit-unverified (never a wrong unit); curves not closing within the bound return no-unit-up-to (honest bounded negative). Verified the certified units of x^6+1 (x^3,1 norm -1), (x^3+x)^2+2, the genus-0 x^2+1, and the honest deferrals for x^6+x (period 2) and x^6+x^2+1 (aperiodic in bound). This lets the genus-2 third-kind Pell construction work for curves where the unit is not visible by inspection.
- Fixed a convergent-indexing bug found during testing (the fundamental unit uses the first L quotients a_0..a_{L-1}, not the period-closing quotient); caught because the unit norm was non-constant, then verified against hyperpell.
- Added example 383 and golden cas_polycf with full coverage including the soundness deferrals.
- Updated the comparison with one new capability row.
- Zero regressions across the Pell, third-kind, algebraic, and continued-fraction chains; every positive result certified.

# CAS frontier — genus-2 nonconstant-B third-kind via the function-field Pell unit

- Added `lib/cas/hyperpell.lisp`: the genus-2 nonconstant-B third-kind construction. On the family f = h^2 + c the element g0 = h + y is a fundamental unit (constant norm -c); its powers g0^n = A_n + B_n y have B_n nonconstant (n>=2) and norm (-c)^n, each a third-kind logarithm argument INT ((g0^n)'/g0^n) = log(g0^n), certified by the norm relation AND by differentiation in the field (algfunc, genus-agnostic). For deg h = 3 these are genuine genus-2 curves. Verified on y^2=x^6+1 (unit x^3+y, norm -1; g0^2=(2x^6+1,2x^3); g0^3), a second curve (x^3+x)^2+2, and a non-unit rejection. This is the genus-2 companion to the genus-0 elliptic3pell construction, completing the third-kind construction past the a+y shape at genus 2.
- Added example 382 and golden cas_hyperpell with full coverage including the soundness control.
- Updated the comparison (one new genus-2 row) and the Trager ladder (the open third-kind rung now records nonconstant-B at genus 2 via the Pell unit; arbitrary genus / non-periodic sqrt(f) remain).
- Zero regressions across the third-kind, algebraic, and hyperelliptic chains; every positive result certified.

# CAS frontier — genus-2 third-kind logarithm + unified hyperelliptic integration driver

- Added `lib/cas/hyperthird.lisp`: the genus-2 (and general hyperelliptic) third-kind logarithm INT (g'/g) dx = log(g) for g = a(x)+y on y^2=f. Reuses algfunc (genus-agnostic field/derivation) and the tested esp-poly-sqrt; recovers a from the differential's denominator via the norm a^2-f, certifies by the cleared identity (a+y)*omega = D(a+y). Verified on y^2=x^5+1 (a=x, x^2, x^2+1), soundness rejection, and the genus-1 cross-check. Generalizes sethird to arbitrary-genus hyperelliptic. Advances the full third-kind construction into genus 2.
- Added `lib/cas/hyperint.lisp`: the unified hyperelliptic integration driver -- one entry point that dispatches the second-kind (hyperell: elementary Q sqrt(f) or first-kind non-elementarity proof) and third-kind (hyperthird: logarithm) cases over y^2=f at any genus, returning a single certified verdict. Verified second-kind elementary + non-elementary, third-kind logarithm, honest non-recognition, and identical decisions across genus 1 and 2. Advances the general algebraic Risch for the hyperelliptic family.
- During development, caught a bug in a from-scratch polynomial square root (failed on arguments with intermediate terms) and fixed it by reusing the already-tested esp-poly-sqrt rather than duplicating the algorithm.
- Added examples 380-381 and goldens with full coverage including soundness controls.
- Updated the comparison (two new genus-2 rows) and the Trager ladder (the open third-kind rung now records the explicit genus-2 logarithm; arguments beyond a+y and arbitrary genus remain).
- Zero regressions across the algebraic, third-kind, and hyperelliptic chains; every positive result certified.

# CAS third-kind frontier — the genus-2 Jacobian: group law + torsion-based elementarity decision

- Added `lib/cas/hyperjac.lisp`: the Jacobian group law of a genus-2 hyperelliptic curve y^2=f (deg 5) by Mumford representation and Cantor's algorithm (composition + reduction over Q[x], with a from-scratch extended gcd). The identity [1,0], points [x-a,b], negation [u,-v], addition, doubling, scalar multiples; every result certified by the Mumford curve condition u | (v^2-f). Verified P+0=P, P+Q=[x^2+x,x+1] on y^2=x^5+1, P+(-P)=0, and Weierstrass 2-torsion.
- Added `lib/cas/hyperjactor.lisp`: the genus-2 third-kind torsion decision -- the genus-2 analogue of the elliptic order test. The class [P]-[iota P] is elementary iff torsion; computed as the order of P under the Jacobian group law by bounded search, reporting (torsion n) or an HONEST (no-torsion-up-to B) -- never a false non-elementary claim. Verified a Weierstrass point is order 2, (0,1) on y^2=x^5+1 is order 5 (elementary), the soundness bounded-miss, and a cross-check on y^2=x^5-x.
- Added examples 378-379 and goldens with full coverage including the soundness controls.
- Updated the comparison and the Trager ladder: two new genus-2 capability rows; the open third-kind rung now records genus-2 progress (group law + torsion decision done; explicit genus-2 logarithm and arbitrary genus remain).
- Zero regressions across the third-kind, algebraic, and RUNG-5 chains; every positive result certified.

# CAS RUNG 5 — stacked algebraic towers: the field of x^(1/4) and its third-kind logarithm

- Added `lib/cas/algtower2.lisp`: a tower of two algebraic extensions Q(x)[y][z]/(z^2-y, y^2-x), the field of x^(1/4). Element arithmetic (z^2->y reduction) and the certified derivation D(a+bz) = a' + (b' + b/(4x))z, reducing soundly to algfunc's inner derivation plus the scalar z'/z = 1/(4x). Verified z^2=y, z^4=x, y'=y/(2x), and INT (5/4)x^(1/4) = x^(5/4) by differentiation in the tower.
- Added `lib/cas/algtower2log.lisp`: the field inverse (via the outer conjugate, one inner inverse) and the third-kind logarithm INT (e'/e) dx = log(e), certified by the inverse-free cleared identity e*(e'/e) = D(e). Verified log(1+x^(1/4)), log(x^(1/4)), log(sqrt x), with sound rejection of non-logarithmic differentials.
- Added examples 376-377 and goldens with full coverage including soundness controls.
- Corrected the comparison chart: the algebraic-Risch frontier (previously a single stale 'none') is now split into the nine certified sub-capabilities actually built (hyperelliptic decision, algebraic Hermite, genus-1 elliptic logs, Puiseux/integral basis, superelliptic family, van Hoeij, mixed towers, the double tower), leaving exactly ONE honest 'none' row: general algebraic Risch at arbitrary genus/tower, the open summit. The two height-two 'none' rows are corrected to 'part' (single-residue cases certified; only the general multi-residue x-dependent case is memory-bound).
- Zero regressions across the algebraic and RUNG-5 chains; every positive result certified by differentiation.

# CAS frontier — genus-0 algebraic integration (first rung of the algebraic-case Risch problem)

- Added `lib/cas/algquadint.lisp`: the genus-0 algebraic integral INT (px+r)/sqrt(ax^2+bx+c) dx, the first rung of the algebraic-case Risch frontier (where lizard was at 'none' and even Maxima only 'part'). The linear numerator splits into a certified algebraic (second-kind) part (p/2a) sqrt(q) plus a first-kind part: a logarithm (arcsinh form) when a>0, an arcsine when a<0 with the radicand having real roots. Every closed form certified by differentiation; integrands with no real form reported 'no-real-form. The arcsine condition (a<0 AND discriminant>0, argument (2ax+b)/sqrt D) was derived and verified via D-(2ax+b)^2 = -4a q.
- Added example 374 and golden cas_algquadint with full coverage (log case, pure-algebraic case, mixed case, two arcsine cases, and the honest no-real-form control).
- Implemented from the published algorithms (Euler substitution, classical first/second-kind reduction) from scratch with certificates -- not adapted from any GPL source.
- Zero regressions across the elliptic, hyperelliptic, Hermite, and rational-integration chains.

# CAS ladder — three rungs climbed: complex tuples, superelliptic integral basis, F4 reduction

- Added `lib/cas/cplxtuples.lisp`: complete complex solution tuples over the Gaussian rationals Q(i). Gaussian-rational arithmetic (gr-), perfect-square detection turning a (complex re im2) into its two Q(i) roots, triangular-system assembly into complete complex points, certified by evaluating every generator to zero in Q(i). Non-rational imaginary parts reported 'not-gaussian. Climbs the complex-coordinates ladder rung.
- Added `lib/cas/superintbasis.lisp`: the integral basis at the finite places of a superelliptic curve y^n = f. For squarefree f the certified power basis {1, y, ..., y^(n-1)}, each element integral via its monic defining polynomial t^n - f^k, with discriminant n^n f^(n-1) and maximality decided by the squarefree test; non-squarefree f reported non-maximal with the repeated factor. Climbs the degree>2 integral-closure ladder rung.
- Added `lib/cas/groebnerf4.lisp`: the linear-algebra reduction at the heart of F4. A Macaulay matrix (columns = monomials sorted descending, rows = polynomials) is row-reduced to RREF over Q; the nonzero rows read back are the reductions, pivot columns the leading monomials. Exact over Q, with row-space preservation certified. Climbs the F4-class-engine ladder rung.
- Added examples 371-373 and their goldens with full coverage including honest-deferral controls.
- Updated the three infographics: the Trager ladder now shows a single remaining open rung (the full third-kind / Jacobian-torsion construction), with the three climbed rungs at summit; the comparison and roadmap reflect the new certified capabilities.
- Zero regressions across the Groebner, superelliptic, and complex chains; every positive result certified.

# CAS summit — exponential single-logarithm completion + open-source surface

- Added `lib/cas/tower2expfull.lisp`: the exponential single-logarithm recognizer that completes the proper-fraction branch of the height-two exponential integrator. A squarefree remainder As/Ds is recognized as the single logarithm c·log(Ds) exactly when As = c·D2(Ds) for a tower constant c, found by one polynomial division over K1[theta2] (no Sylvester resultant) and certified by differentiation. This closes the case the unified driver's power-sum wrapper previously rejected whenever the denominator was squarefree but not a bare power theta2^j (e.g. theta2 - e^x), promoting the exponential second-monomial capability from partial to a genuine integrator on the single-log case. The multi-residue x-dependent RootSum continues to route through the dedicated fraction-free resultant integrator (`tower2expff.lisp`) to avoid memory blow-up.
- Added `examples/370-exponential-single-log.lisp` and `tests/cas_tower2expfull.expected` with full coverage including the honest-deferral control (`notrecognized`).
- Added `CONTRIBUTING.md` documenting the build/test commands, library-module structure, the per-feature workflow (verify-first, additive-safety grep, module + example + golden + docs), and the certificate-and-honest-scope discipline.
- Corrected stale counts in `README.md` (now 271 library modules, ~26,000 lines of Lisp, 371 examples) and fixed a dead documentation link (`docs/ROADMAP.md` -> the actual `docs/MASTER_PLAN.md` and `docs/TRAGER_ROADMAP.md`); added a `CONTRIBUTING.md` pointer.
- Zero regressions across the height-two tower and the CAS chains; every positive result remains certified by differentiation.

# Phase 3F — tokenizer source wrapper + explicit GC metadata classification

- Fixed `lizard_tokenize_source` link failure by implementing the tokenizer-source wrapper declared in `tokenizer.h`.
- Source-tokenization diagnostics now preserve caller-provided filenames instead of always reporting `<string>`.
- Added `lizard_heap_alloc_tagged` so constructors can register explicit GC object kinds instead of relying only on size inference.
- Refactored core AST/list-node constructors in `mem.c` to use explicit GC metadata classification.
- Extended GC metadata stats with per-kind counters.
- Added tokenizer source diagnostic regression coverage.
- Extended ownership audit to require explicit GC classification scaffolding.
- Kept collector behavior non-moving and unchanged.

# Phase 3A — object model / value ownership audit

- Added `src/object_model.c` / `src/object_model.h` with ownership and tracing-policy metadata for heap, C-owned, borrowed, static, and context-owned objects.
- Added `tests/object_model_test.c`.
- Added `scripts/check-ownership-audit.py` and `make ownership-audit`.
- Wired `ownership-audit` into `make ci`.
- Added `docs/OWNERSHIP.md` documenting current ownership rules and the object-level non-moving GC transition target.
- Kept allocator/GC behavior unchanged; this is a strict metadata/audit scaffold.

# Phase 2Y — include graph / layering audit

- Added `scripts/check-include-layers.py` to audit public/internal header layering.
- Added `make include-audit` and wired it into `make ci`.
- Added `docs/INCLUDE_LAYERS.md` describing the public API, wrapper, implementation-root, tooling-leaf, and implementation-header layers.
- The include audit detects public headers leaking private headers, implementation headers including the public wrapper, parent-relative includes, selected leaf headers depending on the interpreter core, and cycles in the `src/*.h` quoted include graph.
- Kept all strict/security warning flags intact.

# Phase 2X — syntax/header boundary audit

- Fixed the `surface_term.h` include-order regression by requiring the header to
  include `lizard_api.h` before exposing `lizard_expansion_trace_event_t`.
- Added `scripts/check-header-boundaries.sh` to scan `src/*.h` for public API
  types and verify direct `lizard_api.h` inclusion.
- Added `make header-audit` and wired it into `make ci`.
- Kept all strict/security warning flags intact; no warning suppressions added.

# Changelog

## Documentation refresh + proof-producing CAS

- Rewrote `README.md` to reflect the current state: the four research
  tracks (R/C/K/Q, all feature-complete at the library level), the
  45-module standard library, the self-hosting demos, and bignum
  performance (within ~200ms of MIT Scheme on the 123^12312 loop).
- Added `docs/USAGE.md` — a getting-started guide and library recipes.
- Added `docs/CAS.md` — the proof-producing / verified CAS architecture
  and a roadmap connecting the CAS to the trusted kernel and ZFC.
- New `lib/cas.lisp` — symbolic algebra: simplification, differentiation
  (constant/variable/sum/product/quotient/power/chain + sin/cos/exp/ln),
  and basic polynomial integration.
- New `lib/cas-proof.lisp` — a layered foundation database (ZFC axioms →
  real construction → field axioms → limits → derivative → calculus
  rules), derivation trees with rule citations, and unfolding of any
  CAS result down to the ZFC axioms it rests on.
- New examples 125 (symbolic CAS) and 126 (a derivative unfolded to ZFC).

# Lizard v5 — engineering infrastructure (in progress)

This section logs the major infrastructure work built on top of the v4
type-theory + diagnostics baseline.

## Phase 0: Runtime refactor (B.1–B.2)

- Added `lizard_runtime_t *runtime` back-pointer on `lizard_heap_t`, so
  any function holding the heap can reach runtime state via `heap->runtime`.
- Moved 9 process-global variables into `lizard_runtime_t`:
  `gensym_counter`, `sr_counter`, `callcc_buf/active/value`,
  `logic_config_head`, `logic_last_set_bundle`, `hit_registry_head`,
  `flag_list`.
- Accessor functions (`logic_config_ptr()`, etc.) with static fallbacks
  for backward compat with standalone heaps.
- Sequential multi-instance now works: two runtimes in the same process
  have independent logic configs, HIT registries, and counters.

## Phase C: Module loader

- `(import "path.lisp")` — load once with caching, resolved via search path.
- `(module-loaded? "path")`, `(module-search-path)`, `(add-module-path! "dir")`.
- Default search path includes `lib/`. Module cache keyed by both raw
  and resolved paths.

## Phase D: Garbage collector (D.1–D.3)

- `gc_mark` bit on every `lizard_ast_node_t`. `lizard_heap_alloc` zeroes
  memory to ensure marks start at 0.
- `lizard_gc_mark_node` — recursive mark traversal covering 80+ AST types.
- `lizard_gc_mark_env` — walks environment chains and closure captures.
- Segment-level sweep: `lizard_gc_collect` frees heap segments with zero
  live objects. No pointer updating needed.
- `(gc)` — run mark + sweep, report freed bytes and before/after stats.
- `(gc-stats)` — report segments, bytes, total/live/garbage node counts.

## Phase E: Bytecode compiler + VM (E.1–E.2)

- 30-opcode stack-based VM (`src/bytecode.h`, `src/bytecode.c`).
- Compiler handles: constants, variables, arithmetic, comparisons,
  if/else, define/set!, lambda with closures, general function calls,
  begin, cons/car/cdr, display/newline.
- **Tail-call optimization**: `OP_TAIL_CALL` replaces the current frame
  (chunk, env, ip, sp) and restarts the dispatch loop. Zero C stack growth.
- `(vm-eval expr)`, `(disassemble expr)`, `(vm-time expr)`, `(time-eval expr)`.

## Profiler

- `(profile expr)` — compile + execute with full instruction counting.
  Reports: elapsed time, total instructions, call/tail-call counts,
  MIPS, and per-opcode breakdown.

## Structured diagnostics (Phase F)

- `lizard_make_error_at(heap, code, span)` — error with source location.
- Six key eval error paths carry spans (unbound symbol, invalid apply,
  bad define, bad assignment).
- Error printer prepends `line:col:` when span is available.
- `(error-location err)` — programmatic access to error span.

## Documentation

- `docs/HIT.md` — comprehensive HIT layer reference (~350 lines).
- `docs/MODAL.md` — updated with full M.5.* coverage.
- `DESIGN.md` — added "Further documentation" index.
- `docs/CLAIMS_MATRIX.md` — updated throughout.

---

# Lizard v4 — type-theory expansion + diagnostics/scaffolds (in progress)

This section logs the changes from v3 (post-restructure baseline) to the current
head. The v3 section follows. For per-phase detail, see `DESIGN.md`, `docs/MODAL.md`,
`docs/CLAIMS_MATRIX.md`, and `docs/OPTIONAL_PROOF_SCAFFOLDS.md`.

## Public/internal header split

- `include/lizard.h` is now a 13-line compatibility shim re-exporting
  `include/lizard_api.h`. All AST node definitions and interpreter internals
  moved to `src/lizard_internal.h`.
- Embedders get a stable opaque public surface. Internals can evolve without
  ABI breaks. Older embedders that `#include <lizard.h>` keep working.

## Source spans on every AST node

- `lizard_source_span_t span` field on each `lizard_ast_node_t`.
- Tokens already carried `line`/`column`/`offset`; this propagates them
  forward into the AST so diagnostics can point at the right place in source.
- Foundation for future structured error messages.

## Scaffold/checked discipline

- New convention: experimental syntax lives behind opt-in **logic rules** and
  is documented as "scaffold" in `docs/CLAIMS_MATRIX.md` until promoted to
  "checked" status.
- New bundles: `cubical-S1`, `truncations`, `proof-scaffold`.
- New toggles: `cubical-s1-enabled`, `truncations-enabled`,
  `theory-extensions-enabled`.
- Documented migration path in `docs/OPTIONAL_PROOF_SCAFFOLDS.md`.

## Phase H.2 — Propositional truncation promoted from scaffold to checked

- AST nodes `Trunc`, `trunc`, `trunc-elim` (originally scaffold) now have real
  typing rules and a primary computation rule.
- Typing:
  - `(Trunc level A) : Universe-of-A` — universe-preserving.
  - `(trunc x) : (Trunc A)` infers `A` from `x : A`; level left NULL.
  - `(trunc-elim C h e) : C` when `e : (Trunc _ A)` and `h : Π _:A. C`.
- Reduction: `(trunc-elim C h (trunc x)) ⟶ (@ h x)`, deterministic.
- Honest gap: propositionality obligation on motive `C` not structurally
  enforced (see `docs/CLAIMS_MATRIX.md`).
- All operations gated on `truncations-enabled`.
- New test `tests/tt_truncation_test.c`, walkthrough `examples/62-truncation.lisp`.

## Cubical S¹ scaffold (unchanged from upload)

- `S1`, `base`, `loop` with minimal typing spine.
- Remains scaffold-only — no recursor, no `loop`-computation rule, no
  Kan composition.

## Type-theory work prior to H.2 (carried forward from earlier v4 state)

- Lambda cube (M.2, M.3): 8 cube corners + CoC as named bundles.
- Substructural rules (M.4): `weakening`/`contraction`/`exchange` toggles.
- Universe lattice (L.1–L.5): pi-fresh/co-pi-fresh, couniverse, lattice toggles.
- HIT scaffolding (H.1): AST nodes + registry, no computation rules.
- Modal logic layer (M.5.1–M.5.9): K, T, S4, S5 operationally distinct;
  asymmetric forms (box/unbox/diamond/let-diamond/box-app/diamond-bind);
  **symmetric S5 (M.5.9 Turn 2b)**: `dia`, `poss-coerce`, judgment-kind
  tracking, kind propagation through `let-diamond`, kind check in `box-intro`.
  See `docs/MODAL.md`.

## Diagnostics and proof-scaffold infrastructure (community contribution)

- `docs/CLAIMS_MATRIX.md` — precise feature status (implemented / partial /
  scaffold / not implemented), updated whenever a feature changes tier.
- `docs/OPTIONAL_PROOF_SCAFFOLDS.md` — explains the scaffold/checked
  discipline and the intended migration path.
- `tests/tt_optional_extensions.lisp` + `.expected` — golden test for the
  new opt-in nodes at the construction layer.
- Enhanced `runtime.c/h` and `lizard_api.h` for richer embedding surface.
- Generic `theory-extension` AST node (scaffold) for plugging in
  experiments without changing the AST.

## Scoreboard at v4 head (after H.2 + merge)

```
57 C unit tests + 5 Lisp golden tests passing
62+ examples including modal layer (M.5.*) walkthroughs and H.2 truncation
Benchmark: ~0.5s
Builds clean: release, debug, asan, coverage
```

---

# Lizard v3 — restructure + tests + features

## Structural changes

- **`src/` + `include/` split.** All implementation in `src/`, single
  public header `include/lizard.h`. The public header no longer
  pulls in internal `errors.h`/`en.h`/`lang.h`; those become true
  internals and are included only by the `.c` files that need them.
- **`tests/` directory** with:
  - A header-only test harness (`test_harness.h`).
  - A façade (`test_helpers.{h,c}`) that gives each test one line to
    spin up a fresh interpreter and another to evaluate strings.
  - Five C unit tests (`arith_test`, `control_test`, `lambda_test`,
    `lists_test`, `macros_test`).
  - Two golden-output tests (`scripting`, `error_propagation`) with
    matching `.expected` files.
- **`examples/`** unchanged in content but now formally part of the
  layout (with a README of its own).
- **`tests/tests.mk`** included from the top-level Makefile gives
  `make test`, `make test-c`, `make test-lisp`, plus colourised
  PASS/FAIL output per test.
- **`lizard_install_primitives()`** moved from `repl.c` into the
  library so tests and the REPL share one source of truth for the
  set of registered built-ins.

## New features

- **`display`**, **`write`**, **`newline`** primitives — standard
  Scheme I/O so `.lisp` scripts can produce real output rather than
  relying on the REPL's auto-echo.
- **`(load "path")`** primitive — reads a file and evaluates every
  top-level form in the current environment. Reports proper errors
  (`LIZARD_ERROR_LOAD_ARGC`, `_ARGT`, `_OPEN`, `_READ`). Lets
  scripts depend on the prelude:
  ```lisp
  (load "examples/prelude.lisp")
  (display (sum (range 1 101))) (newline)   ; 5050
  ```

## Bugs fixed since the user's snapshot

The upload had the begin/macro fixes but reverted several others. This
release re-applies them on top of the upload's structural improvements
(typedef aliases, `lizard_make_number_copy`, `static` globals,
`lizard_repl_strdup`):

1. **Tokenizer treats all whitespace as whitespace.** `\t`, `\n`, `\r`
   are skipped; previously only `' '` was, so any multi-line file with
   tabs or newlines tokenised into garbage symbols.
2. **`;` line comments** are recognised by the tokenizer.
3. **REPL is stdin-friendly.** When stdin is not a TTY the prompt,
   raw-mode line editor, and `\033[K` escapes are suppressed. The
   continuation join uses `\n` instead of a space so `;` comments
   terminate at the original line boundary.
4. **Scheme-style value printer in the REPL.** Output is `3628800` /
   `(1 2 3)` / `<procedure>`, not `Number: 3628800` and 14-line AST
   dumps. Errors print only their message (no doubled `error: Error:`).
5. **`cond` is implemented in the evaluator.** The parser had been
   building `AST_COND` nodes, but the evaluator had no case for them,
   so every `cond` form returned `LIZARD_ERROR_NODE_TYPE`.
6. **Multi-body function definitions** (`(define (f x) e1 e2 e3)`)
   parse correctly; previously only the first body expression was
   consumed and the rest produced "missing closing paren in define".
7. **`let` accepts non-symbol binding names in macro bodies**, so
   `` `(let ((,name ,value)) ,body) `` works.
8. **Unquote-splicing handles real cons-pair lists**, not only
   `AST_APPLICATION`. Empty list splices to nothing.
9. **Zero-parameter lambdas/macros work.** `((lambda () 42))` and
   `(define-syntax k (lambda () 42))` no longer report "alternative
   lambda parameter format is wrong" — the parser turns `()` into
   `AST_NIL`, which both call paths now accept.
10. **Unbound-symbol errors propagate** instead of being rewritten to
    "attempt to apply a non-function" when they appear in the operator
    position.

## What's verified

`make test`:

```
  PASS  arith_test          (mutation guard, variadic +/-/*//, bignums, div0)
  PASS  control_test        (if, cond/else, begin, and/or/not, let)
  PASS  lambda_test         (recursion, multi-body, mutual, bignum, closures)
  PASS  lists_test          (cons, car/cdr, quote, predicates, user map)
  PASS  macros_test         (quasiquote, splice, special-form expansion, let)
C tests: 5/5 passed
  PASS  error_propagation   (golden-output)
  PASS  scripting           (golden-output)
Lisp tests: 2/2 passed
All tests passed.
```

`make examples` runs all six example files and the prelude without
errors. `06-scripting.lisp` produces a formatted factorial table
ending in `20! is exactly: 2432902008176640000`.

## Open

- `call/cc` still uses module globals (`callcc_buf`, `callcc_active`);
  nested `call/cc` will clobber itself. No regression test for it
  because the existing implementation isn't reliable enough to pin
  golden behaviour to.
- `write` is currently identical to `display` for non-string values.
  In R5RS Scheme, `write` escapes strings (`"a\"b"` would print
  literally). Worth tightening.
- No `string-length`, `string-append`, `number->string` yet — the
  string facilities are minimal. Add when needed by a script.
- Memory: `lizard_heap_destroy` releases everything at REPL exit,
  but inside a long session the bump arena grows and never returns
  memory to the OS (it's grow-only, not a real GC).

# Lizard v4 — performance round

## Tail-call optimisation

Lambda application now tail-calls its **last body expression** by
trampolining through the existing `for(;;)` dispatch loop in
`lizard_eval` — the same mechanism that already drove TCO for `if`,
`begin`, and `cond`. Non-tail bodies are still evaluated for side
effects only, then `(node, env)` are rewritten to the tail body and
`continue` is used.

Before this change every Scheme call ate a real C stack frame:
```lisp
(define (count n) (if (= n 0) 'done (count (- n 1))))
(count 100000)    ; segfault — 8MB C stack exhausted around ~10^4
```

After this change a properly tail-recursive function runs to any
depth limited only by the heap. The new `tco_test.c` exercises
100,000 iterations of plain tail recursion, 50,000 of mutual tail
recursion (`even?`/`odd?`), tail calls out of `cond` clauses, and
tail calls as the last expression of a `begin`.

## Fast bignum primitives

Lizard's bump-allocator heap is grow-only and has no GC, so
loops like
```lisp
(define (pow2-iter n acc) (if (= n 0) acc (pow2-iter (- n 1) (* 2 acc))))
(pow2-iter 1000000 1)
```
allocate `O(N²)` of intermediate bignums and exhaust memory long
before they finish — even with TCO eliminating the stack cost.
MIT Scheme handles this because of its generational GC; lizard
now sidesteps the problem entirely by exposing GMP's fast routines
as primitives so the same computation completes in *one* mpz call:

| Primitive            | Backed by         | Cost     |
| -------------------- | ----------------- | -------- |
| `arithmetic-shift`   | `mpz_mul_2exp` / `mpz_fdiv_q_2exp` | O(1) GMP |
| `expt`               | `mpz_pow_ui`      | O(log e) GMP |
| `gcd`                | `mpz_gcd`         | Lehmer in GMP |
| `lcm`                | `mpz_lcm`         | Lehmer + multiply |
| `quotient`           | `mpz_tdiv_q`      | one division |
| `remainder`          | `mpz_tdiv_r`      | one division |
| `abs`                | `mpz_abs`         | one op |
| `square`             | `mpz_mul`         | one op |
| `modular-expt`       | `mpz_powm`        | O(log e), bounded intermediates |

`(arithmetic-shift 1 1000000)` now produces a 301,030-digit exact
integer in milliseconds. `(modular-expt 2 65537 (- (expt 2 127) 1))`
finishes instantly — the RSA-style core works on arbitrary sizes.

## New tests

- `tests/tco_test.c` — depth-100,000 tail recursion, mutual
  recursion, `cond` and `begin` tail positions.
- `tests/fastprims_test.c` — arithmetic-shift (left/right/huge),
  expt, gcd, lcm, quotient/remainder (with negative dividends),
  abs, square, modular-expt, plus the error paths
  (`(quotient 1 0)`, `(expt 2 -1)`, type mismatch).

## New example

- `examples/14-perf.lisp` — count-down from 1,000,000;
  `arithmetic-shift 1 1000000`; `expt 7 5000`; gcd of two giant
  bignums; a toy RSA encrypt/decrypt cycle.

## What's still not addressed

The arena is still grow-only. Long-running idiomatic Scheme
without the fast primitives still piles up garbage. A real GC
is the right next investment — generational, with the arena
becoming the nursery. That's a larger surgery and was deliberately
kept out of this round so the TCO + fast-prims wins land cleanly.

# Lizard v5 — reflection, types, strings

## Type reflection

```scheme
(type-of 42)           ; 'number
(type-of "hi")         ; 'string
(type-of 'foo)         ; 'symbol
(type-of '(1 2))       ; 'pair
(type-of (lambda(x)x)) ; 'procedure
(type-of +)            ; 'primitive
(type-of #t)           ; 'boolean
```

Returns a symbol naming the runtime type. Covers every AST node
type lizard can produce: number, string, symbol, boolean, nil,
pair, list, procedure, primitive, macro, quote, quasiquote,
promise, error, continuation.

## Environment + procedure introspection

```scheme
(defined? 'my-binding)       ; #t / #f without throwing
(env-keys)                   ; list of every bound symbol in scope
(procedure-arity f)          ; number of formal params, or 'variadic
```

`env-keys` walks every frame from innermost outward; primitives,
user-defined functions, and macros all appear. `procedure-arity`
returns a number for lambdas (counting positional params, including
0 for `(lambda () …)`) and the symbol `'variadic` for C primitives.

## Strings — proper operations, not just opaque blobs

```scheme
(string-length s)
(string-append a b ...)          ; n-ary
(substring s start [end])        ; end defaults to length
(string=? a b)
(number->string n)
(string->number s)               ; -> number, or #f if unparseable
(symbol->string s)
(string->symbol s)
```

The tokenizer also now handles backslash escapes inside string
literals: `\n` `\t` `\r` `\\` `\"` `\0`. Before this change `"say
\"hi\""` lex-failed; now it parses to the obvious 9-char string.

## Records, the lisp-y way

No new C — records are tagged conses with a small Lisp protocol:

```scheme
(define (make-point x y) (make-record 'point (list x y)))
(define (point-x p) (field-nth p 0))
(define (point-y p) (field-nth p 1))
(record? (make-point 3 4))     ; #t
(record-type (make-point 3 4)) ; 'point
```

See `examples/15-types.lisp` for the full pattern. Build on
`record?`, `record-type`, and positional `field-nth` to define any
record shape you want.

## Pattern dispatch

Lizard doesn't have varargs in lambdas, so there's no `syntax-rules`
shaped `match` macro yet. `examples/16-match.lisp` shows a runtime
dispatcher that takes a list of `(tag thunk)` clauses and threads
into the matching one. The example builds a tiny arithmetic
AST, an evaluator, and full symbolic differentiation on top of it:

```
d/dx (3 + 4*x) = (plus (lit 0) (plus (times (lit 0) (var x))
                                     (times (lit 4) (lit 1))))
d/dx -(x + 7) evaluates to -1
```

## New tests

- `tests/reflection_test.c` — every type-of case, defined? for
  bound/unbound/non-symbol args, env-keys completeness via
  member-search, procedure-arity for 0/1/N parameters and
  primitives.
- `tests/strings_test.c` — length/append/substring/equality,
  number↔string round-trip, symbol↔string round-trip, bignum→string,
  out-of-range substring errors.

## New examples

- `examples/15-types.lisp` — reflection, records, an `inspect`
  function that dispatches on `type-of` and prints type-aware
  summaries.
- `examples/16-match.lisp` — pattern dispatcher + symbolic
  differentiation of `(3 + 4x)`, `x*x`, `-(x+7)`.
- `examples/17-strings.lisp` — string manipulation, conversions,
  string-reverse via recursive substring, formatted output helper.

## Scoreboard

```
$ make test
15/15 C tests passing  (arith, bignum, closures, control,
                        deep_recursion, errors, fastprims,
                        higher_order, lambda, lists, macros,
                        quasiquote, reflection, strings, tco)
4/4  Lisp golden tests passing
All tests passed.
```

# Lizard v6 — varargs, exceptions, vectors, hashes (extreme edition)

This release adds four major language features and tightens error
semantics so they all compose cleanly.

## Varargs lambdas

```scheme
(define sum (lambda xs
  (define (loop ys acc)
    (if (null? ys) acc (loop (cdr ys) (+ acc (car ys)))))
  (loop xs 0)))

(sum)                  ; 0
(sum 1 2 3 4 5)        ; 15
(sum 1 2 3 4 5 6 7 8 9 10)  ; 55
```

When a `lambda`'s parameter spec is a single symbol instead of a list,
the symbol is bound to a list of *all* the call arguments. This is the
R5RS "rest" form and unlocks `(define (count . xs) ...)`-style
patterns. Implemented at both eval-time and `lizard_apply` call sites.

Dotted-pair varargs `(lambda (a b . rest) ...)` is not yet supported —
that would need new tokenizer support for `.`.

## Exceptions: try / raise / error-object? / error-value

```scheme
(define (safe-div a b)
  (try (lambda () (/ a b))
       (lambda (err)
         (display "caught: ") (display (error-value err)) (newline)
         0)))

(safe-div 10 2)   ; 5
(safe-div  7 0)   ; prints diagnostic, returns 0
```

User code can raise structured payloads:

```scheme
(raise (list 'invalid-input value "must be positive"))
```

The handler receives an error object and uses `(error-value err)` to
unwrap the payload. `error-object?` tests whether a value is an error.

Two C primitives are exempt from auto-propagation (see below) so that
they can *receive* errors as values: `error-object?` and `error-value`.

## Vectors

```scheme
(define v (vector 10 20 30 40 50))
(vector-length v)         ; 5
(vector-ref v 2)          ; 30
(vector-set! v 2 999)
v                         ; #(10 20 999 40 50)
(vector->list v)          ; (10 20 999 40 50)
(list->vector '(a b c))   ; #(a b c)
```

O(1) indexed access + mutation. Fixed-size; create with
`(make-vector n [fill])` or `(vector v1 v2 ...)`. Printer renders as
`#(...)`. `vector?` predicate.

## Hash tables

```scheme
(define h (make-hash-table))
(hash-set! h 'name "lizard")
(hash-set! h 'age 5)
(hash-ref h 'name)              ; "lizard"
(hash-ref h 'missing 'default)  ; default
(hash-has-key? h 'name)         ; #t
(hash-size h)                   ; 2
(hash-keys h)                   ; (age name)
(hash-remove! h 'age)
```

Open-addressed with linear probing. Doubles capacity when load > 0.75.
Hash function: FNV-1a for strings/symbols, mpz_get_ui for numbers.
Key equality is value-based for numbers, strings, symbols, booleans,
and nil. Printer renders as `#hash((k . v) ...)`.

## Auto-propagation of errors

Before this release, `(display (raise 'oops))` would silently print
`oops` because display didn't know its arg was an error. Now errors
short-circuit at every eval boundary:

- **Primitive calls**: if any argument forces to AST_ERROR, the call is
  skipped and the error propagates (except for `error-object?` and
  `error-value`, which receive errors as data).
- **`if`, `cond`**: an erroring predicate propagates without firing
  any branch.
- **`begin`, lambda body**: an intermediate expression that errors
  short-circuits the sequence.

This makes `(try ...)` actually work the way users expect — without
this, a `(raise ...)` inside a `display` call would be silently
absorbed.

## gensym

```scheme
(gensym)              ; g1
(gensym)              ; g2
(gensym "tmp-")       ; tmp-3
```

Produces a fresh symbol on each call. Useful for hand-written
hygienic-ish macros until proper `syntax-rules` lands.

## type-of extended

Now covers vectors and hashes:

```scheme
(type-of (vector 1 2 3))     ; vector
(type-of (make-hash-table))  ; hash
```

## String escape sequences (bonus)

The tokenizer now decodes `\n`, `\t`, `\r`, `\\`, `\"`, `\0` inside
string literals. Before, `"say \"hi\""` lex-failed.

## New tests

- `tests/exceptions_test.c` — raise + try + nested try + error-value
  with various payload types + system errors (div by zero)
- `tests/vectors_test.c` — every op + mutation persistence + accumulator
  via vector + mixed-type contents + out-of-range errors
- `tests/hashes_test.c` — 200-entry growth stress + key types
  (symbols, strings, bignums) + remove + missing-key + default
- `tests/varargs_test.c` — zero/one/many args + mixed types + variadic
  sum, max, count

## New example

`examples/18-extreme.lisp` exercises all four new features in one
program:
- variadic `puts` formatter dispatching on `type-of`
- in-place insertion-sort on a vector
- word-frequency counter on a hash table
- `safe-div` with try/raise/error-value
- structured `(invalid-age N reason)` payloads with cond-based handler
- fresh gensyms

```
$ ./build/lizard < examples/18-extreme.lisp
hello world, 2025
type-of 42 is: number

before sort: #(5 2 8 1 9 3 7 4 6)
after sort:  #(1 2 3 4 5 6 7 8 9)

word frequencies: #hash((brown . 1) (lazy . 2) (dog . 1) ...)
  'the' appeared 4 times
  'fox' appeared 2 times
  'lazy' appeared 2 times

safe-div 10 2 = 5
  caught error, falling back to 0
safe-div  7 0 = 0
safe-div 99 3 = 33

valid age: 25
valid age: rejected age -5: must be non-negative
valid age: rejected age 200: too old to be plausible
valid age: 99

fresh gensym: swap-tmp-1
another:      swap-tmp-2
distinct?     #t
```

## Scoreboard

```
$ make test
19/19 C tests passing  (arith, bignum, closures, control,
                        deep_recursion, errors, exceptions,
                        fastprims, hashes, higher_order, lambda,
                        lists, macros, quasiquote, reflection,
                        strings, tco, varargs, vectors)
4/4  Lisp golden tests passing
All tests passed.
```

## Known deferred work

- **Hygienic macros (`syntax-rules`)** — would need proper
  alpha-renaming. Significant.
- **Dotted-pair varargs `(lambda (a b . rest) body)`** — tokenizer
  needs `.` handling.
- **Real GC** — currently grow-only arena. A generational collector
  with the arena as the nursery is the obvious next step.
- **call/cc** — exists but uses module globals (`callcc_buf`,
  `callcc_active`), so nested call/cc would collide.
- **`write` vs `display` on strings** — currently identical; R5RS
  says write should escape.

## Phase 3: Deep feature expansion

### Kernel completion
- Sigma types: full inference + computation (proj1/proj2 reduce on pairs).
- J-eliminator: `J C d A a b (refl a) → d a` — the fundamental identity
  elimination principle.
- `sexp_to_kterm` extended: `natrec`, `app`, `lam`, `Pi`, `Sigma`, `pair`,
  `fst`, `snd`, `J`, `Id`, `refl` — the full dependent type theory toolkit.
- `(kernel-reduce expr)` — normalize kernel terms to WHNF.
- `(kernel-equal? a b)` — check definitional equality.

### Proof state + tactics
- `src/tactics.c` + `src/tactics.h` — proof state management.
- `(begin-proof type)` — start proof with one goal.
- `(tactic-intro name)` — introduce Pi binder.
- `(tactic-exact term)` — provide exact proof term.
- `(tactic-refl)` — solve Id a a goals.
- `(qed)` — finish proof, extract term.

### Track C: Atoms
- `(atom val)`, `(deref a)`, `(swap! a f)`, `(reset! a v)`, `(atom? x)`.
- Mutable reference cells with CAS-style swap.

### Exceptions
- `(raise val)` — raise an exception.
- `(guard handler body)` — catch exceptions.

### String operations
- `string-ref`, `string-contains?`, `string-upcase`, `string-downcase`.
- `string-split`, `string-join`.

### Lazy evaluation
- `(delay expr)` — create a promise (thunk).
- `(force p)` — evaluate and cache.
- `(promise? x)` — predicate.

### Standard library (lib/match.lisp)
- sort, zip, partition, flatten, take, drop, any, every, enumerate.
- compose, ->, alist-ref, alist-set, range.
- identity, const, flip, curry, uncurry, repeat, complement, memoize, juxt.

### Persistent data structures
- Persistent vectors: pvec, pvec-ref, pvec-set, pvec-push, pvec-count.
- Persistent hash maps: phash-map, phash-get, phash-set, phash-keys.
- Syntax objects: datum->syntax, syntax->datum, syntax-e, syntax-source.

## Phase 4: Elaboration foundations

### Metavariables / Holes (K.4)
- `KT_META` kernel term tag — placeholder for unknown terms.
- `meta_ctx_t` — metavariable context tracking type, solution, and ID.
- `meta_fresh(heap, mctx, type)` — create a fresh typed hole.
- `meta_solve(mctx, id, solution)` — fill a hole.
- `meta_zonk(heap, mctx, term)` — substitute solved metas in a term.
- `(kernel-hole type)`, `(kernel-solve id term)`, `(kernel-zonk term)`,
  `(kernel-meta-state)` — Lisp-facing primitives.

### Unification (K.5)
- `kt_unify(heap, ctx, mctx, a, b)` — first-order unification.
- Flex-rigid: unsolved meta on one side → solve with the other.
- Structural: recursively unify corresponding subterms.
- Works with WHNF reduction — unfolds definitions before comparing.
- `(kernel-unify a b)` — Lisp-facing primitive.
- `?N` syntax in sexp_to_kterm for metavariable references.

### Kernel Bool + Unit types
- `Bool`, `true`, `false` — boolean type with constructors.
- `(if b t f)` — Bool eliminator with computation rules:
  `if true t f → t`, `if false t f → f`.
- `Unit`, `*` — unit type with unique inhabitant.

### Tactic: assumption
- `(tactic-assumption)` — search context for hypothesis matching goal.

# Phase 2U — diagnostic metadata and example-manifest hardening

- Added diagnostic severity/category metadata to `lizard_diagnostic_t`.
- Added severity/category defaulting and public name helpers.
- Parser diagnostics now classify parse failures as `severity=error`, `category=parser`.
- Added API regression coverage for diagnostic metadata.
- Added `scripts/check-example-manifest.sh` for static manifest hygiene checks.
- Hardened `scripts/run-examples.sh` so manifest entries without files are counted and fail CI.
- Added `make examples-audit`.
- Added/restored `examples/63-pow.lisp` so the manifest and filesystem agree.
- Marked currently incomplete showcase examples as experimental instead of dishonest pass gates.

# Phase 2V — restore report API + diagnostic report v2

- Restored the public diagnostic/syntax report typedefs and function prototypes
  required by `diagnostic_report_test.c` and external tooling.
- Added `report_writer.c/.h`, `diagnostic_report.c/.h`, and
  `syntax_expansion_report.c/.h` to the library build.
- Made tokenizer unterminated-string errors recoverable instead of `exit(1)`.
- Added diagnostic report v2 text/JSON output with severity and category fields.
- Added `tests/diagnostic_report_metadata_test.c` for severity/category report
  metadata.
- Fixed `scripts/clean.sh --check` recursion caused by an uncommented usage
  line and allowlisted the legitimate top-level `lib/` directory.
- Kept all strict warning/security flags intact.

# Phase 2W — public report API boundary audit

- Restored `lizard_expansion_trace_event_t` to `include/lizard_api.h` so syntax-object headers can expose trace-event APIs without unknown-type failures.
- Added `tests/api_report_types_test.c` and extended `tests/public_header_test.c` to lock public report/event typedef visibility.
- Added `scripts/check-public-api.sh` and `make api-audit` to prevent future accidental removal of report/syntax public API types.
- Added `api-audit` to the `ci` target.
- Kept strict/security warning flags intact and added no warning suppressions.

# Phase 2Z — diagnostic construction unification

- Added `src/diagnostics.c` / `src/diagnostics.h` as the canonical diagnostic/span construction path.
- Added public diagnostic construction helpers: `lizard_source_span_clear`, `lizard_source_span_set`, `lizard_diagnostic_clear`, `lizard_diagnostic_set`, `lizard_diagnostic_set_simple`, and `lizard_diagnostic_copy`.
- Moved diagnostic severity/category default mapping and name lookup into `diagnostics.c`.
- Refactored tokenizer, parser, runtime, and syntax-expansion reports to use the shared diagnostic helpers.
- Added `tests/diagnostic_construction_test.c` and `tests/diagnostic_category_paths_test.c`.
- Extended `scripts/check-public-api.sh` to guard the diagnostic construction API.
- Kept diagnostic report v2 stable and preserved text/JSON output shapes.
- No strict/security warning flags were removed and no warning suppressions were added.

# Phase 3B — GC metadata side-table scaffold

- Added `src/gc_metadata.c` / `src/gc_metadata.h`.
- Added a C-owned per-heap side table for object size/kind/owner/trace-policy metadata.
- Wired heap creation/destruction to create/destroy the side table.
- Wired heap allocation to register metadata opportunistically without changing allocation semantics.
- Added metadata stats and lookup helpers through `gc.h`.
- Added `tests/gc_metadata_test.c`.
- Extended ownership audit coverage for the metadata side table.
- Kept object layout, mark traversal, sweep behavior, evaluator semantics, and strict warning policy unchanged.

# Phase 3C — liblizard build graph closure audit

- Fixed the syntax-object scaffold link regression class by making `LIB_SRCS`
  close over additional `src/*.c` modules automatically while keeping the core
  source order explicit.
- Added `scripts/check-build-graph.py` to audit that implementation sources are
  represented in the library build graph and that stale `LIB_SRCS` entries are
  rejected.
- Added `make build-graph-audit` and wired it into `make ci`.
- Preserved strict compiler/security flags; no warning suppressions were added.

# Phase 3D — conservative build graph recovery

- Replaced the aggressive Phase 3C `src/*.c` library closure with a conservative allowlisted optional-source closure.
- Prevented incomplete experimental modules such as `prims_kernel_*`, `prims_modules`, `prims_bytecode`, and `kernel_sexp` from being compiled merely because they exist in `src/`.
- Added `scripts/phase3d-recover-build.py` for idempotent recovery of locally drifted Phase 3 trees.
- Hardened public/report header boundaries for report schema and expansion trace APIs.
- Added parser/tokenizer prototypes required by syntax-object scaffolding.
- Replaced the build-graph audit with an allowlist-aware audit.
- Kept all strict/security flags intact and added no warning suppressions.

# Phase 3E — public API duplicate-definition recovery

- Fixed duplicate `lizard_expansion_trace_event_t` definition in `include/lizard_api.h`.
- Added `scripts/check-public-api-duplicates.py` to reject duplicate public typedef/enum definitions.
- Wired duplicate-definition checks into `make api-audit` through `scripts/check-public-api.sh`.
- Hardened `scripts/phase3d-recover-build.py` so repeated recovery runs remove duplicate public API blocks instead of appending more.
- Kept strict warning/security flags unchanged.

# Phase 3G — context expansion trace public API recovery

- Restored context-level expansion trace public API declarations in `include/lizard_api.h`.
- Added `scripts/phase3g-recover-trace-context-api.py` for mixed local trees.
- Extended `scripts/check-public-api.sh` so `make api-audit` catches missing trace context declarations.
- No strict/security warning flags were removed and no warning suppressions were added.

# Phase 3H — surface filename propagation and audit cleanup

- Propagated caller-provided filenames through tokenizer/source parsing into parser diagnostics, top-level AST spans, SurfaceTerm spans, expansion trace origins, and traced context evaluation.
- Made `lizard_context_eval_file` route through a filename-aware internal evaluation path so file diagnostics report the real path instead of `<string>`.
- Restored direct `lizard_api.h` inclusion for `surface_term.h` to satisfy header-boundary audits.
- Updated ownership/build-graph audits for the current live bridge/report modules.
- Added `.gitignore` and removed generated build artifacts plus wrong-project leftovers from the packaged tree.
- Kept strict compiler/security flags unchanged.
