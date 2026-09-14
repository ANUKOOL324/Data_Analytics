# ADR-002: Blocking strategies are measured, never assumed

## Status

Accepted

## Context

Record linkage at n records is n(n-1)/2 comparisons; 19k records is
177M pairs, unworkable. Blocking compares only within candidate groups,
and every blocking choice silently caps recall: a true pair split
across blocks can never be recovered downstream.

## Options considered

1. One "obvious" key (postcode). Simple, and moved providers (15% of
   variants here, by design) change postcode: their pairs are lost
   before matching begins.
2. Union of three keys (chosen): normalized postcode, surname+city,
   phone last-4, each catching pairs the others miss, with per-key
   contribution counted and two metrics reported on every run:
   pair-completeness (share of true pairs surviving blocking, 0.92 on
   the demo) and reduction ratio (share of n^2 avoided, 0.984-0.995).
3. Sorted-neighborhood / embedding blocking. Heavier machinery for the
   same measurement discipline; candidates once the measured
   completeness of option 2 becomes the binding constraint.

## Decision

Option 2, with both metrics in every metrics.json. The 0.92 measured
completeness IS the honest recall ceiling, stated rather than
discovered: moved providers with no shared key are unreachable, and
fixing that means a new key (NPI when present, name-initial+specialty),
not a better classifier.

## Consequences

- Every quality conversation starts from "blocking kept 92% of true
  pairs"; nobody debugs the classifier for pairs it never saw.
- Degenerate blocks (over 200 records) are skipped with the guard
  visible in code; postcode blocks in dense cities are the known case.
- The per-key contribution stats make adding/removing keys an
  evidence-based change.
