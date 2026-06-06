; A COMPLETE real decision procedure for general n by genuine recursive cylindrical sampling: it finds witnesses on
; cells of EVERY dimension by sampling the outermost variable at the TRUE breakpoints of the family -- a rational
; point in each open sector AND each real projection root as a section -- substituting, and recursing on the
; lower-dimensional family, bottoming out in the complete two-variable decider (docs/CAS.md).
;
; This goes past the earlier n >= 3 section search, which recognized only the DIAGONAL case (all coordinates forced
; equal to one base number).  Here the section structure is whatever the projection dictates, so NON-diagonal
; sections and POSITIVE-DIMENSIONAL sections (curves and surfaces inside R^3) are reached: the open equatorial arc
; of the unit sphere, the meridian circles, and the poles are all decided -- not just the body diagonal.
(import "cas/cadcomplete.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))

(display "A general n-variable decider that lifts through true breakpoints, reaching sections of every dimension.") (newline) (newline)

(define sph (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))   ; x^2 + y^2 + z^2 - 1
(define zz (list (list (list 0 1))))                                          ; z
(define xx (list (list) (list (list 1))))                                     ; x
(define yy (list (list (list) (list 1))))                                     ; y
(define xpos xx)
(define ypos yy)

(display "the projection of the sphere onto its first axis has the breakpoints x = -1 and x = +1:") (newline)
(must "outer breakpoints of the unit sphere are two intervals isolating -1 and +1" (= (length (cadcomplete-outer-breakpoints (list sph) 3)) 2))

(display "a full-dimensional witness (the open ball) and an empty shifted ball:") (newline)
(must "exists x, y, z. x^2 + y^2 + z^2 < 1 (open ball) TRUE" (cadcomplete-exists (cons (quote neg) sph) 3))
(must "exists x, y, z. x^2 + y^2 + z^2 + 1 < 0 FALSE" (if (cadcomplete-exists (cons (quote neg) (list (list (list 1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2))) 3) #f #t))

(display "a ONE-dimensional section -- the open equatorial arc in the z = 0 plane (irrational witness):") (newline)
(must "exists x, y, z. sphere = 0 and z = 0 and x > 0 and y > 0 (1-dim arc) TRUE"
  (cadcomplete-exists (list (quote and) (cons (quote zero) sph) (cons (quote zero) zz) (cons (quote pos) xpos) (cons (quote pos) ypos)) 3))

(display "a ZERO-dimensional section off the equator -- the north pole (0, 0, 1):") (newline)
(must "exists x, y, z. sphere = 0 and x = 0 and y = 0 and z > 0 (the pole z = 1) TRUE"
  (cadcomplete-exists (list (quote and) (cons (quote zero) sph) (cons (quote zero) xx) (cons (quote zero) yy) (cons (quote pos) zz)) 3))

(display "controls -- impossible sign demands on those sections are rejected:") (newline)
(must "exists x, y, z. sphere = 0 and z = 0 and x - 2 > 0 (impossible on the unit circle) FALSE"
  (if (cadcomplete-exists (list (quote and) (cons (quote zero) sph) (cons (quote zero) zz) (cons (quote pos) (list (list (list -2)) (list (list 1))))) 3) #f #t))

(newline)
(display "The decider samples the outer axis at genuine projection breakpoints, substitutes, and recurses, so a") (newline)
(display "witness on a section of any dimension -- a face, an edge, or a vertex of the solved variety -- is found,") (newline)
(display "not only the body-diagonal points the earlier recognizer was limited to.") (newline)
