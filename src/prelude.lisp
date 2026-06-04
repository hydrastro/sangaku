; -*- lisp -*-
; src/prelude.lisp -- the Sangaku prelude.
;
; Loading this first puts the Sangaku library on the module search path, so that any
; subsequent (import "cas/poly.lisp") resolves against src/. Every Sangaku program, example,
; and test runs as the prelude followed by the target file, fed to the Lizard interpreter on
; standard input (the launcher script and the Nix wrapper do this for you):
;
;     cat src/prelude.lisp YOUR-FILE.lisp | lizard
;
; The path registrations are bound with `define` so they produce no output of their own (a
; bare top-level expression would be echoed by the interpreter and corrupt golden output);
; the library is silently importable after this file loads. Both "src" (for a checkout, run
; from the repo root) and "." (for a flat install) are registered, so the same prelude works
; in a development checkout and in a Nix store path.

(define _sangaku-path-src (add-module-path! "src"))
(define _sangaku-path-dot (add-module-path! "."))
