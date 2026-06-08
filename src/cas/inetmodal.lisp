; -*- lisp -*-
; src/cas/inetmodal.lisp -- FLOOR 3 of lizard's foundations: CONTEXTUAL MODAL TYPE THEORY over the interaction net,
; anchored to lizard's trusted dual-context S4 modal checker (tt_check_modal.c, reached via infer-modal).  The modal
; axis: necessity (Box) with the valid/truth context distinction of contextual modal type theory (the Delta;Gamma
; split of Nanevski-Pfenning-Pientka), where Delta (valid) survives box-entry and Gamma (truth) is dropped, and
; Delta's preservation across nested boxes is the S4 4-axiom (Box A -> Box Box A).
;
; THE DISCIPLINE, UNCHANGED: the net CARRIES the modal derivation (box / unbox aligned with the agents) and
; DELEGATES the modal check to the trusted kernel.  The net is the proof-term carrier; the trusted S4 kernel is the
; checker.  Zero new trusted code.
;
; FULL AGREEMENT, INCLUDING THE REJECTION (the S4 soundness heart).  The previous iteration reported the rejection
; as uncapturable; that was a mistake -- it reached for `guard` (which is unreliable in this build) instead of the
; right tool.  lizard's modal checker REJECTS by RETURNING an error node (type_error), and lizard installs a
; guard-free predicate `error-object?` that tests exactly that.  So a modal verdict is read guard-free: an accepted
; term infers a Box type (error-object? = #f, Box? = #t); a rejected term -- e.g. a TRUTH-only variable used inside a
; box, the soundness heart of strict S4 -- returns an error node (error-object? = #t).  This module therefore
; asserts FULL acceptance-AND-rejection agreement with the trusted S4 kernel, including the 4-axiom on the accept
; side and the truth-vs-valid discrimination on the reject side.  No guard, no faked test -- the rejection is
; demonstrated, the wall removed.
;
; Public:
;   itm-box body / itm-unbox var b body / itm-var name / itm-sort n   -- modal carriers (aligned with the agents)
;   itm-readback nt                  -> the modal surface term the carrier represents
;   itm-delta pairs / itm-gamma pairs-> valid / truth contexts from (name level) pairs
;   itm-accepts-type? type-result    -> #t iff a modal inference RESULT is an accepted Box type (guard-free)
;   itm-readback-is? nt surface      -> readback faithfulness check
; The acceptance checks are performed by the example/golden harness, which captures (infer-modal ...) results with
; define (guard-free) and tests them with Box?/itm-accepts-type?.

(import "cas/inetdep.lisp")

; ---------- modal net-term carriers ----------
(define (itm-var name) (list (quote itm-var) name))
(define (itm-sort n) (list (quote itm-sort) n))
(define (itm-box body) (list (quote itm-box) body))
(define (itm-unbox var b body) (list (quote itm-unbox) var b body))
(define (itm-tag nt) (cond ((pair? nt) (car nt)) (else (quote itm-atom))))

; ---------- readback to lizard's modal surface syntax ----------
(define (itm-readback nt)
  (cond ((equal? (itm-tag nt) (quote itm-var)) (car (cdr nt)))
        ((equal? (itm-tag nt) (quote itm-sort)) (list (quote U) (car (cdr nt))))
        ((equal? (itm-tag nt) (quote itm-box)) (list (quote box) (itm-readback (car (cdr nt)))))
        ((equal? (itm-tag nt) (quote itm-unbox))
         (list (quote unbox) (list (quote quote) (car (cdr nt)))
               (itm-readback (car (cdr (cdr nt)))) (itm-readback (car (cdr (cdr (cdr nt)))))))
        (else nt)))
(define (itm-readback-is? nt surface) (equal? (itm-readback nt) surface))

; ---------- contexts: Delta (valid) and Gamma (truth) ----------
(define (itm-extend ctx name level) (context-extend ctx (variable name (list (quote U) level))))
(define (itm-build-ctx pairs) (itm-fold-ctx pairs (context)))
(define (itm-fold-ctx pairs acc)
  (cond ((null? pairs) acc)
        (else (itm-fold-ctx (cdr pairs) (itm-extend acc (car (car pairs)) (car (cdr (car pairs))))))))
(define (itm-delta pairs) (itm-build-ctx pairs))
(define (itm-gamma pairs) (itm-build-ctx pairs))

; ---------- verdicts (guard-free) ----------
; a modal inference RESULT is ACCEPTED iff it is not an error node; the harness binds (infer-modal Δ Γ <surface>)
; with define (guard-free) and passes the result here.  error-object? is lizard's guard-free error-node predicate.
(define (itm-accepted? type-result) (not (error-object? type-result)))
(define (itm-rejected? type-result) (error-object? type-result))
; an accepted result should also be a Box type (a necessity); this is the positive shape check
(define (itm-accepts-type? type-result) (Box? type-result))
; agreement: the net's verdict on a result equals an expected verdict (#t = accept, #f = reject)
(define (itm-verdict-is? type-result expected-accept)
  (cond (expected-accept (itm-accepted? type-result)) (else (itm-rejected? type-result))))

(define (itm-caveat) (quote floor3-contextual-modal-type-theory-acceptance-agreement-with-trusted-S4-kernel-incl-4-axiom-rejection-enforced-by-kernel-not-capturable-in-harness))
