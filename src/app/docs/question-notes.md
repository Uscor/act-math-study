### How a question looks

```python
{
  "template_id": "topic_descriptor_v1",       # snake_case, unique, ends _v1
  "topic": "algebra.linear_equations",        # dotted topic path, see topic list
  "difficulty_tier": "medium",                # easy | medium | hard
  "is_modeling": False,                       # True if math is wrapped in a real-world scenario

  "difficulty_levers": {                      # see "why difficulty is hard"
    # plain-language key: pinned-condition value. Document EVERY lever.
  },

  "cosmetic_slots": {                         # surface-only variation
    # slot_name: [list of interchangeable options]
  },

  "parameters": {                             # math variation, sampled
    # name: {"type": "int"|"float", "range": [lo, hi]}
  },

  "guards": [                                 # reject a sample if any is false
    # python-evaluable boolean strings over the parameters
  ],

  "stem": "...{slot}...{param}...",           # the question text, slots in braces

  "derived": {                                # computed, never sampled
    # name: "python expression over parameters"
  },

  "distractors": [                            # wrong answers AS RULES
    {"value": "<expr>", "trap": "<trap_name>"}
    # exactly 3 distractors -> 4 options total
  ],

  "authoring_notes": "..."                     # see required-notes section
}
```

### Field rules

- **template_id** — unique, snake_case, descriptive, suffixed `_v1`. The version suffix lets a later revision coexist with instances already generated from the old one.
- **topic** — a dotted path from the topic list at the bottom. Stay inside the published list so the app can filter by ACT section.
- **difficulty_tier** — your honest coarse prior. Three buckets only.
- **difficulty_levers** — one entry per thing that determines difficulty, each phrased as a pinned condition. If a lever is "the trap is active," encode it as a guard too. A template with no documented levers is rejected in review — it means you haven't analyzed what makes it hard.
- **cosmetic_slots** — interchangeable surface options. Test: swapping any option for any other must leave the math and difficulty *identical*. If swapping changes the answer, it is a parameter, not a cosmetic slot.
- **parameters** — the sampled numbers. Give a type and an inclusive range. Prefer sampling *roots/solutions* and deriving coefficients, not the reverse, whenever cleanliness of the answer is a difficulty lever.
- **guards** — boolean strings, evaluated against a candidate sample; if any is false the sample is rejected and resampled. Use guards to (a) keep magnitudes reasonable, (b) keep the answer clean, (c) keep traps active, (d) prevent degenerate cases (division by zero, the trap collapsing onto the answer).
- **stem** — the question text. Every `{name}` must resolve to a cosmetic slot, a parameter, or a derived value. Phrase the *ask* precisely — if the gotcha is "they ask for x+2 not x," the stem must unambiguously ask for the expression.
- **derived** — values computed from parameters (the total shown to the student, the correct answer). Never sample these; always compute, so they stay consistent with the parameters.
- **distractors** — exactly three, each a `{value, trap}` pair. `value` is a python expression over parameters/derived; `trap` is a name from the trap taxonomy. The correct answer is `derived["answer"]`; the four presented options are it plus the three distractors, shuffled at serve time.

### The expression language (guards, derived, distractor values)

Every expression string — in `guards`, `derived`, and distractor `value` — is evaluated in a **restricted, deterministic** environment. Author only within this whitelist; anything outside it will be rejected by the validator, not silently run.

**In scope (names available to expressions):**
- All `parameters` by name (e.g. `root`, `coeff`).
- All `derived` values by name, *as long as they are defined earlier in the `derived` block than the expression using them* (derived values may reference earlier derived values, never later ones — no forward references, no cycles).

**Allowed operators:** `+  -  *  /  //  %  **`, comparisons (`< <= > >= == !=`), boolean `and / or / not`, and the ternary `a if cond else b`.

**Allowed function calls (only these):**
```
abs(x)        min(a, b, ...)     max(a, b, ...)
round(x, n)   int(x)             float(x)
math.gcd(a,b) math.sqrt(x)       math.floor(x)   math.ceil(x)
```

**Forbidden:** any other function, attribute access (`.something`), indexing (`x[0]`), comprehensions, lambdas, imports, names not defined as a parameter or earlier-derived value, randomness of any kind, and any I/O. Expressions must be **pure**: same inputs → same output, every time. Determinism is non-negotiable because the pool is generated from fixed seeds and must be reproducible.

If you need a value the whitelist can't express, that is a signal the template is too complex for this system — simplify it or flag it under the failure protocol below, rather than reaching outside the whitelist.

### When a topic resists templating — the failure protocol

Not every ACT question parameterizes cleanly. Some depend on reading a specific diagram, on a one-off conceptual insight, or on a data set that can't be meaningfully randomized. Forcing these into a template produces something worse than no template. If, after honest effort, you cannot satisfy the review bar — most often because a difficulty lever can't be pinned, or no trap can be written as a parameter-relative rule, or the math can't be expressed in the whitelist — then **do not emit a broken template.** Instead emit a short rejection record and stop:

```python
{
  "status": "not_templatable",
  "topic": "<the topic you attempted>",
  "reason": "<one or two sentences: which review-bar item fails and why>",
  "suggestion": "<optional: e.g. 'needs a static diagram bank' or 'better authored as fixed items'>"
}
```

This is a legitimate, valuable outcome — it tells the team which topics need a different approach (a hand-authored fixed-item bank, a diagram library) rather than the generator. A correct rejection is worth more than a template that passes authoring but produces subtly wrong or stale questions at scale.

## The trap taxonomy

ACT wrong answers are not random — they are a small enumerable set of anticipated mistakes. Author distractors as instances of these named traps. Tagging by trap name is what lets the app later track *which* mistake a student repeats. Use these names; propose additions in `authoring_notes` if genuinely needed.

- `solved_for_variable_not_expression` — solved for x but the question asked for x+k (or 2x, etc.). The canonical ACT trap.
- `stopped_at_intermediate` — equals a correct sub-result, tempting if you stop early.
- `sign_error` — the specific sign slip the problem structure invites.
- `units_unconverted` — correct number, wrong/unconverted units.
- `used_wrong_quantity` — solved a real thing, but not the thing asked.
- `extra_operation` — did one operation too many.
- `off_by_constant` — the answer ± a constant that appears in the problem.
- `percent_of_wrong_base` — took the percent of the wrong quantity.
- `swapped_operands` — order-sensitive operation done backwards.

Each distractor must be (a) different from the correct answer for ALL legal parameter samples — enforce with a guard if needed — and (b) different from the other distractors. Two distractors colliding is a defect.

## Required authoring notes

In `authoring_notes`, include:

1. **Difficulty justification** — one or two sentences: why this tier, tied to the levers.
2. **Staleness check** — name two sampled instances that look different on the surface, and confirm in one line that they exercise the same skill at the same difficulty (that's the goal) without being trivially the same numbers.
3. **Trap liveness** — confirm the guards keep every distractor distinct from the answer and from each other across the parameter range.

## Worked example — author to this standard

```python
{
  "template_id": "alg_linear_solve_for_expr_v1",
  "topic": "algebra.linear_equations",
  "difficulty_tier": "medium",
  "is_modeling": True,

  "difficulty_levers": {
    "asks_for_expression_not_variable": "stem asks for variable + ask_offset, not the variable; trap is active by design",
    "integer_solution": "root sampled as int, so the variable always resolves cleanly",
    "coefficient_magnitude": "coeff single-digit; arithmetic stays mental-math-able"
  },

  "cosmetic_slots": {
    "actor": ["a chemist", "a baker", "a contractor", "Saráhi"],
    "object": ["samples", "loaves", "tiles", "pages"],
    "variable": ["x", "n", "t", "k"]
  },

  "parameters": {
    "root":       {"type": "int", "range": [2, 9]},
    "coeff":      {"type": "int", "range": [2, 6]},
    "shift":      {"type": "int", "range": [1, 9]},
    "ask_offset": {"type": "int", "range": [1, 5]}
  },

  "guards": [
    "coeff * root + shift < 100",
    "ask_offset != 0",
    "root != root + ask_offset"          # answer never collides with the 'solved for variable' trap
  ],

  "stem": "{actor} has {coeff} times as many {object} as {variable}, plus {shift} more. If the total is {total}, what is the value of {variable} + {ask_offset}?",

  "derived": {
    "total":  "coeff * root + shift",
    "answer": "root + ask_offset"
  },

  "distractors": [
    {"value": "root",                       "trap": "solved_for_variable_not_expression"},
    {"value": "total - shift",              "trap": "stopped_at_intermediate"},
    {"value": "coeff * root + ask_offset",  "trap": "used_wrong_quantity"}
  ],

  "authoring_notes": "Medium because it is one solve step plus the expression-not-variable trap; no conversions or radicals. Instance 'Saráhi/pages/n+3, total 27' (answer 8) and instance 'a baker/loaves/t+2, total 19' (answer 5) look different and land the trap on different letters/values while testing the same one-step-solve-then-evaluate skill. Guards keep root, root+ask_offset, total-shift, and coeff*root+ask_offset mutually distinct across the range."
}
```

That object generates: *"Saráhi has 4 times as many pages as n, plus 7 more. If the total is 27, what is the value of n + 3?"* → A) 5  B) 8  C) 20  D) 12. Answer B; A is the `solved_for_variable_not_expression` trap, C is `stopped_at_intermediate` (total − shift = 20), D is `used_wrong_quantity`.

### Second worked example — a different category, to show the pattern generalizes

Note how the difficulty levers and parameter design differ from the algebra case. Here the *data set itself* is the parameter, and the difficulty lever is keeping the mean a clean integer — a stats-specific concern that has no analogue in the linear example. Author each topic to *its own* levers; do not copy the algebra shape mechanically.

```python
{
  "template_id": "stats_mean_missing_value_v1",
  "topic": "stats.mean_median_mode",
  "difficulty_tier": "easy",
  "is_modeling": True,

  "difficulty_levers": {
    "clean_target_mean": "values and target_mean chosen so the missing value is a positive integer; no fractions",
    "small_dataset": "exactly 4 known values plus 1 unknown; arithmetic stays light",
    "mean_not_median": "stem asks for mean; the median trap (middle value) is active"
  },

  "cosmetic_slots": {
    "actor": ["a student", "a coach", "a nurse", "Kieran"],
    "quantity": ["test scores", "lap times", "daily readings", "page counts"]
  },

  "parameters": {
    "v1": {"type": "int", "range": [60, 90]},
    "v2": {"type": "int", "range": [60, 90]},
    "v3": {"type": "int", "range": [60, 90]},
    "v4": {"type": "int", "range": [60, 90]},
    "missing": {"type": "int", "range": [60, 95]}     # the value to solve for
  },

  "guards": [
    "min(v1, v2, v3, v4) <= missing",                  # keep 'missing' from being an obvious outlier
    "(v1 + v2 + v3 + v4 + missing) % 5 == 0"           # CLEAN integer mean — the key lever, as a guard
  ],

  "stem": "{actor} recorded five {quantity}: {v1}, {v2}, {v3}, {v4}, and one more. If the mean of all five is {target_mean}, what was the fifth value?",

  "derived": {
    "target_mean": "(v1 + v2 + v3 + v4 + missing) // 5",
    "answer": "missing"
  },

  "distractors": [
    {"value": "target_mean",                              "trap": "used_wrong_quantity"},
    {"value": "sorted_median_of_known",                   "trap": "used_wrong_quantity"},
    {"value": "v1 + v2 + v3 + v4 - target_mean * 4",      "trap": "off_by_constant"}
  ],

  "authoring_notes": "Easy: one mean computation reversed, clean integer answer, no conversions. The guard '(sum) %% 5 == 0' is the load-bearing difficulty lever — without it the answer could be fractional and the question changes character. Instance 'Kieran / page counts / 72,80,68,90 mean 78' (answer 80) and 'a coach / lap times / 61,63,65,67 mean 65' (answer 69) look different and place the answer differently while testing the same reverse-mean skill. NOTE on distractors: 'sorted_median_of_known' is shorthand for a median expression the whitelist cannot write directly (it needs sorting) — see flag below."
}
```

**This example deliberately surfaces a whitelist limit.** The `sorted_median_of_known` distractor can't actually be written in the expression whitelist (no sorting, no indexing). That's intentional, to show the failure mode: faced with this, a correct authoring session does NOT smuggle in a forbidden operation. It either (a) replaces that distractor with a whitelist-expressible trap (e.g. another `off_by_constant` variant), or (b) if the median trap is essential to the template's value, emits a `not_templatable` note explaining that this template needs a median helper the expression language doesn't provide. Either response is correct; reaching outside the whitelist is not.


## What "good" looks like — review bar

These split into **hard gates** (a generated instance is mechanically rejected if violated — these are exactly what the separate validator spec checks) and **soft quality bars** (judgment calls a reviewer enforces). Author to both, but know the difference.

**Hard gates — machine-checkable, instance rejected on failure:**
- Exactly 3 distractors; exactly 4 options total after adding the answer.
- The correct answer is computed via `derived["answer"]`, never sampled.
- Every distractor value is distinct from the answer AND from every other distractor, for the sampled instance.
- Every expression stays inside the expression-language whitelist.
- Every `{name}` in the stem resolves to a cosmetic slot, parameter, or derived value.
- Every parameter sample satisfies all guards.
- Every `trap` is a name from the taxonomy.

**Soft quality bars — reviewer judgment, not machine-checkable:**
- Every difficulty lever is documented AND pinned by parameter design or guard.
- Cosmetic swaps provably don't touch math or difficulty.
- The stem's *ask* is unambiguous, especially when a trap depends on misreading it.
- `authoring_notes` covers difficulty, staleness, and trap-liveness.
- The difficulty tier is honest.

If you cannot satisfy the hard gates, the template is broken — narrow ranges or add guards until you can. If you cannot satisfy the soft bars for a given topic, use the failure protocol and emit a `not_templatable` record instead of forcing it.

## Topic list (extend only with team sign-off)

Topics are organized under the ACT's own five reporting categories (plus a cross-cutting Integrating Essential Skills bucket), so that a topic tag doubles as the analytics axis the official score report uses. The part of the dotted path before the first `.` is the **reporting category** — store it as a derived field so the app can aggregate "student is weak in Functions" without parsing the full path. Trig is split out for authoring granularity even though ACT files it under Geometry; map `trig.*` back to Geometry for score-report display.

```
# === NUMBER & QUANTITY ===
number.integers_factors_multiples
number.fractions_decimals
number.exponents_integer
number.exponents_rational
number.radicals
number.scientific_notation
number.absolute_value
number.complex_numbers
number.matrices
number.vectors
number.sequences_arithmetic
number.sequences_geometric

# === ALGEBRA ===
algebra.linear_equations
algebra.linear_word_problems
algebra.systems_of_equations
algebra.inequalities
algebra.absolute_value_equations
algebra.polynomial_arithmetic
algebra.factoring
algebra.quadratics_solving
algebra.quadratic_formula
algebra.rational_expressions
algebra.radical_equations
algebra.exponential_equations
algebra.logarithms

# === FUNCTIONS ===
functions.notation_evaluation
functions.domain_range
functions.linear
functions.quadratic_parabolas
functions.polynomial
functions.exponential_growth_decay
functions.logarithmic
functions.rational
functions.piecewise
functions.transformations
functions.composition
functions.inverse

# === GEOMETRY ===
geometry.lines_angles
geometry.triangles_properties
geometry.triangles_similarity_congruence
geometry.pythagorean
geometry.special_right_triangles
geometry.polygons
geometry.circles_basic
geometry.circles_equations
geometry.area_perimeter
geometry.surface_area_volume
geometry.coordinate_distance_midpoint
geometry.coordinate_slope_lines
geometry.conic_sections
geometry.transformations_reflections

# === TRIGONOMETRY (maps to Geometry for score-report display) ===
trig.right_triangle_ratios
trig.unit_circle
trig.radians_degrees
trig.law_of_sines_cosines
trig.identities
trig.graphs

# === STATISTICS & PROBABILITY ===
stats.mean_median_mode
stats.weighted_average
stats.range_spread
stats.data_reading_tables
stats.data_reading_graphs
stats.bivariate_scatterplots
stats.probability_basic
stats.probability_compound
stats.counting_combinatorics
stats.expected_value

# === INTEGRATING ESSENTIAL SKILLS (cross-cutting; often modeling) ===
essential.ratios_proportions
essential.rates
essential.percent
essential.percent_change
essential.unit_conversion
essential.multi_step_word_problems
```

### The modeling flag (not a topic)

Modeling is a *cross-cutting label* on the real ACT, not a topic of its own — a single question can be both Algebra and Modeling. So do NOT create a modeling topic. Instead add an optional boolean field to the template:

```python
"is_modeling": True   # the question wraps the math in a real-world scenario / data
```

Default it to `False`. Set it `True` when the template's stem frames the math as a real-world situation (a fundraiser's ticket totals, a scaled recipe, reading a value off a chart). This lets the app report modeling performance separately while keeping topic tags clean.

## Out of scope for this document

This spec covers *authoring one template*. It does NOT cover: the offline generation script that expands templates into the pool, the validator that checks generated instances, the database schema, or serve-time answer-shuffling and presentation transforms. Those are separate documents. Your deliverable is the template object and its notes — nothing executes it yet.
