# Sangaku documentation

- [`CAS.md`](CAS.md) — the proof-producing CAS in depth: how each capability works and how it is
  certified, written as a running narrative of the system's development. The most complete account
  of what Sangaku does.
- [`TRAGER_ROADMAP.md`](TRAGER_ROADMAP.md) — the algebraic-case integration (Trager–Bronstein)
  ladder: what is done and certified, and what remains at the frontier.
- [`LIMITATIONS.md`](LIMITATIONS.md) — the precise, honest scope of what works and what does not.

For the public API of individual modules, read the header comment at the top of each file in
[`../src/cas/`](../src/cas/): every module documents its purpose, the mathematics it depends on, its
public functions, and what it verifies.

For runnable demonstrations, see [`../examples/`](../examples/) — every capability has a
self-checking example, and the theorem-proving demonstrations (definite integrals, the Dirichlet/
sinc integral, the axiom mode) are examples 388–391.
