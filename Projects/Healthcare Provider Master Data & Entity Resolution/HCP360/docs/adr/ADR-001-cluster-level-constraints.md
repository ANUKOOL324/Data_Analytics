# ADR-001: Chain-merge protection lives at the cluster level, not the edge

## Status

Accepted

## Context

Connected-components clustering over accepted match pairs has a famous
failure: transitive chain merges. The seeded trap in this repo is the
real-world shape: two distinct providers at one group practice (same
address, same practice phone, same surname) plus an initials-only
record ("J. Smith") that legitimately resembles both. Three designs
were measured against 15-20 seeded traps per run.

## Options considered (all measured)

1. Edge guard, name-similarity floor: accepted edges must carry name
   evidence. Measured useless: 1/15 traps merged with it on OR off;
   the classifier already rejected direct cross-provider pairs, and
   the floor cannot distinguish a bridge from an honest variant.
2. Edge guard, first-name conflict: drop accepted edges whose FULL
   first names disagree. Measured WORSE than nothing once bridges
   exist: 15/15 traps merged, because no direct James-John edge is
   needed; the bridge welds them transitively and every individual
   edge looks fine.
3. Cluster-level constraint (chosen): agglomerate accepted edges in
   descending score order and REFUSE any union that would place two
   conflicting full first names in one entity, unless a matching NPI
   proves identity (legal name changes are real). The ambiguous bridge
   record joins its best-scoring side.

## Decision

Option 3. Measured: 0/15-0/20 traps merged across demo and benchmark
runs, with pairwise precision 0.95-0.99 retained.

## Consequences

- The invariant is entity-level and survives transitivity, which no
  edge rule can.
- The genuinely ambiguous bridge record lands on one side; that
  assignment is honest uncertainty, surfaced in accepted_pairs.csv
  rather than hidden.
- Constraint checks add O(names^2) per union attempt; names per
  entity are few, measured runtime is dominated by pair features.
