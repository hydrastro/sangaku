; FLOOR 3 of lizard's foundations: CONTEXTUAL MODAL TYPE THEORY over the interaction net, anchored to lizard's
; trusted dual-context S4 modal checker (tt_check_modal.c, via infer-modal).  The modal axis: necessity (Box) with
; the valid/truth context distinction of contextual modal type theory -- Delta (valid) survives box-entry, Gamma
; (truth) is dropped, and Delta's preservation across nested boxes is the S4 4-axiom (Box A -> Box Box A).
;
; The discipline is unchanged from Floors 1-2: the net CARRIES the modal derivation and DELEGATES the check to the
; trusted kernel.  FULL AGREEMENT, including the rejection (the S4 soundness heart): lizard's modal checker rejects
; by RETURNING an error node, and lizard installs the guard-free predicate error-object? that tests exactly that.
; So a modal verdict is read guard-free -- accepted terms infer a Box type (error-object? #f, Box? #t), rejected
; terms return an error node (error-object? #t) -- and this floor asserts acceptance-AND-rejection agreement with the
; trusted S4 kernel, including the 4-axiom on the accept side and the truth-vs-valid discrimination on the reject
; side.  (An earlier iteration wrongly reported the rejection as uncapturable; it had reached for `guard`, which is
; unreliable in this build, instead of error-object?.  The wall is removed; the rejection is demonstrated, not faked.)
(import "cas/inetmodal.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Contextual modal type theory: the net carries box-derivations; the trusted S4 kernel checks them, and") (newline)
(display "accepts the valid cases (incl. the 4-axiom) while REJECTING a truth-only variable inside a box.") (newline) (newline)

; readback faithfulness
(must "(itm-box (itm-sort 0)) reads back to (box (U 0))"
  (itm-readback-is? (itm-box (itm-sort 0)) (quote (box (U 0)))))
(must "(itm-box (itm-box (itm-var x))) reads back to (box (box x))"
  (itm-readback-is? (itm-box (itm-box (itm-var (quote x)))) (quote (box (box x)))))

(define delta_x (itm-delta (list (list (quote x) 0))))   ; Delta = [x : U0]  (x VALID)
(define gamma_y (itm-gamma (list (list (quote y) 0))))   ; Gamma = [y : U0]  (y TRUTH)

; ---- ACCEPT side ----
(define r-a1 (infer-modal (context) (context) (box (U 0))))
(must "ACCEPT: (box (U 0)) infers a Box type" (itm-accepts-type? r-a1))
(must "ACCEPT verdict via error-object?: (box (U 0)) is not an error" (itm-accepted? r-a1))

(define r-a2 (infer-modal delta_x (context) (box (quote x))))
(must "ACCEPT: a valid hypothesis survives a box -- (box x) under Delta=[x]" (itm-accepted? r-a2))

(define r-a3 (infer-modal delta_x (context) (box (box (quote x)))))
(must "ACCEPT (4-axiom): (box (box x)) under Delta=[x]" (itm-accepted? r-a3))
(define r-a3b (infer-modal delta_x (context) (box (box (box (quote x))))))
(must "ACCEPT (4-axiom depth 3): (box (box (box x)))" (itm-accepted? r-a3b))

; ---- REJECT side: the S4 soundness heart, now demonstrated guard-free ----
(define r-r1 (infer-modal (context) gamma_y (box (quote y))))
(must "REJECT: a TRUTH-only variable inside a box is rejected -- (box y) under Gamma=[y]" (itm-rejected? r-r1))
(must "the rejection is an error node, not an accepted result" (not (itm-accepted? r-r1)))

; ---- FULL AGREEMENT: the verdict matches the expected verdict on BOTH sides ----
(must "AGREEMENT accept: (box x|valid) verdict is accept" (itm-verdict-is? r-a2 #t))
(must "AGREEMENT reject: (box y|truth) verdict is reject" (itm-verdict-is? r-r1 #f))
(must "the valid/truth DISCRIMINATION: same shape (box v), opposite verdicts by context"
  (cond ((and (itm-accepted? r-a2) (itm-rejected? r-r1)) #t) (else #f)))

(newline)
(display "The truth-vs-valid discrimination -- (box x) accepted when x is valid, (box y) REJECTED when y is only") (newline)
(display "true -- is the soundness heart of strict S4, and it is now demonstrated guard-free via error-object?.  The") (newline)
(display "net carries the derivation; the trusted kernel both accepts the valid cases (including the 4-axiom) and") (newline)
(display "rejects the unsound one; the verdicts agree on both sides (itm-caveat).") (newline)
