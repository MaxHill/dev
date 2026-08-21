# Review Principles

These principles adapt ideas from TigerBeetle's TigerStyle. They are not a
copy of TigerStyle and they are not Zig-specific rules.

Use this priority when goals conflict:

1. Safety
2. Performance
3. Developer experience

Good design advances all three goals. Look for the simpler design that
removes the conflict instead of accepting a weak compromise.

## Apply the principles in context

The repository's documented standards take precedence. Adapt each principle
to the language, runtime, workload, and failure model.

Do not apply a systems-language rule literally when its purpose has a
different form in another language. Preserve the purpose.

Examples:

- In Zig, allocation review can focus on explicit allocator calls and
  lifetime control.
- In JavaScript, it can focus on arrays, objects, closures, promises,
  strings, and spreads created inside hot loops.
- In a garbage-collected language, allocation is still work. It adds
  garbage collection pressure and can increase latency.
- In Rust, ownership removes some memory errors but does not remove leaks,
  unbounded growth, copies, or contention.
- In shell code, bounded execution includes command retries, pipelines,
  subprocesses, and input size.
- A 70-line function is a useful pressure, not a universal defect. Judge
  whether the function still fits one mental model.
- A dependency can be justified in an application but unacceptable in a
  small library or critical foundation.

Treat exact TigerStyle limits as review prompts unless the repository
adopts them as rules. Report a finding only when the diff creates a
concrete risk or cost.

## Safety

### Keep control flow explicit and bounded

Prefer direct control flow that a reviewer can trace. Avoid hidden
recursion, callback chains, and abstractions that obscure termination.

Put a bound on work and resource use when the system expects a bound. Check
loops, recursion, queues, retries, batches, buffers, caches, pagination,
and concurrency.

An event loop can run forever by design. Each unit of work within it must
still have a clear bound.

Use fail-fast behavior when an invariant fails. Do not let corrupt state
travel through the system.

### State and check invariants

Distinguish programmer errors from expected operating errors.

- Handle expected errors through the normal error model.
- Stop on broken internal invariants when continued execution can corrupt
  state.
- Check function inputs, outputs, preconditions, postconditions, and state
  transitions where they matter.
- State invariants positively when possible.
- Split compound checks when separate checks give clearer diagnostics.
- Check both valid and invalid space at boundaries.
- Add paired checks on different sides of an important boundary when
  practical.

Assertions must encode a real mental model. They do not replace one.

### Minimize state lifetime

Declare state close to its use. Keep the number of live variables small.

Avoid duplicate state and aliases that can diverge. Keep validation close
to use to reduce place-of-check to place-of-use errors.

Centralize state transitions when scattered mutation makes the lifecycle
difficult to verify. Prefer pure leaf functions when they make state
changes easier to reason about.

### Handle boundaries and errors

Treat all external data as untrusted until checked. This includes files,
networks, environment variables, users, databases, subprocesses, and
dependencies.

Handle every error path. Review cleanup, cancellation, timeouts, partial
writes, retries, and rollback behavior.

Pass important options explicitly at call sites. Do not rely on a library
default when a future default change could alter correctness.

### Review memory and resources

Check bounds, ownership, lifetime, cleanup, and maximum growth.

Look for:

- out-of-bounds access and off-by-one errors
- use after release or use after logical invalidation
- leaks of memory, files, sockets, locks, processes, and subscriptions
- buffers that can expose stale or uninitialized data
- accidental copies of large values
- resources held across suspension or unrelated work
- unbounded caches, collections, streams, and queues

Static allocation after startup is a strong systems design when fixed
capacity is valid. In other environments, seek the same goals through
bounded pools, reuse, preallocation, and clear ownership.

### Make tests explore failure space

Test invalid input, boundary values, state transitions, partial failure,
cancellation, and recovery. Do not test only the expected path.

Use fuzzing, simulation, property tests, or fault injection where the risk
warrants them. These tools can find bugs, but they cannot replace a precise
model.

## Performance

### Design for performance before measurement

Do not defer every performance concern until profiling. Architecture fixes
can produce larger gains than local optimization.

Use measurement to validate a concern and compare solutions. Use mechanical
reasoning when the design already has a clear scaling or resource problem.

### Sketch resource costs

Estimate network, disk, memory, and CPU costs. Consider both latency and
bandwidth.

Account for frequency. A cheap operation can dominate when it runs often.

State the expected input size, concurrency, throughput, and worst case. Ask
whether the design stays within those bounds.

### Prefer predictable performance

Review worst-case and tail behavior, not only averages.

Flag:

- unbounded or accidental quadratic work
- latency spikes from growth, cleanup, or garbage collection
- lock contention and serialized work
- retries without backoff or limits
- synchronous I/O on latency-sensitive paths
- work that scales with historical state instead of current input

Predictable performance is often more useful than the highest peak
throughput.

### Batch and amortize work

Batch network, disk, memory, and CPU work where batching preserves
correctness and latency goals.

Separate control-plane work from data-plane work when this enables batching
and clearer bounds. Avoid reacting to every external event with a full unit
of expensive work.

### Review allocation in every language

Allocation includes more than explicit `malloc` calls.

Look for values created repeatedly in hot paths:

- arrays, objects, maps, sets, and strings
- closures, promises, tasks, and callbacks
- iterator adapters and intermediate collections
- spreads, concatenation, serialization, and copying
- boxed values and temporary buffers

For example, a new JavaScript array on each loop iteration creates
allocation and garbage collection work. Consider reuse, mutation within a
clear owner, preallocation, or a fused operation.

Do not recommend reuse when it creates unsafe aliasing or confusing
lifetime rules. Safety remains first.

### Help the machine execute predictable work

Keep hot loops direct. Remove repeated computation and avoid unnecessary
indirection.

Use data layouts and access patterns that fit the workload. Consider cache
locality, branch predictability, copying, and vectorization where relevant.

Do not assume the compiler or runtime will remove avoidable work. Verify
important assumptions with a benchmark, profile, trace, or generated-code
inspection.

## Developer experience

### Use precise names

Choose nouns and verbs that express the domain model. Do not use one name
for multiple concepts.

Avoid abbreviations unless the domain uses them clearly. Add units and
qualifiers to names when values can be confused.

Treat index, count, size, offset, duration, timestamp, and identifier as
different concepts even when they share a primitive type.

Follow the repository and language naming conventions. TigerStyle's
`snake_case` rule is not portable to every language.

### Keep code within one mental model

TigerStyle uses a hard 70-line function limit. Use that number as pressure
to inspect a large function, not as an automatic cross-language violation.

Ask:

- Does the function fit on a screen or in one mental model?
- Does it mix unrelated responsibilities?
- Can a reviewer see all control-flow paths and state changes?
- Would extraction clarify the domain, or only hide logic behind weak
  helpers?

Keep central control flow visible. Move cohesive, non-branching work into
well-named helpers. Avoid fragmented call chains that force the reader to
jump between files.

### Reduce dimensionality

Prefer small, clear interfaces. Avoid parameters that callers can swap or
combine incorrectly.

Use option objects, parameter objects, or domain types when several
primitive arguments are ambiguous. Prefer the simplest return type that
represents the real outcome.

Make ownership, mutation, suspension, and error behavior visible at the
interface.

### Explain why and how

Comments and documentation must explain constraints, reasons, and
non-obvious methods. Do not restate the code.

Document surprising performance choices, safety checks, limits, and
trade-offs. Write commit messages that preserve the reason for the change.

### Keep resources and lifecycle visible

Group acquisition with cleanup. Make subscriptions, locks, files,
processes, and temporary state easy to track.

Avoid creating state before it is needed. Release it as soon as its purpose
ends.

### Limit dependencies and tools

Every dependency adds supply-chain, update, compatibility, startup, and
learning costs.

TigerBeetle uses a zero-dependency policy because it is foundational
infrastructure. Adapt this rule to the repository.

For each new dependency, ask:

- Is the capability central enough to justify the cost?
- Could a small local implementation be safer and clearer?
- Is the dependency maintained, pinned, and reviewed?
- What code and transitive dependencies will execute?
- Does it increase build time, binary size, startup time, or operational
  complexity?
- Does the project already have a tool that can do the job?

Do not reject a dependency only because it exists. Report the concrete cost
or risk in the current project.

### Keep style rules purposeful

Use formatting, line length, function size, and file order to make code
easier to inspect. Follow automated repository formatting first.

Do not report personal taste as a defect. Connect each finding to safety,
performance, or developer cost.
