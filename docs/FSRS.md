# FSRS implementation notes

Moyashi Recall V0.2 uses the canonical **FSRS-6 core memory-state equations** with the published 21 default parameters.

## Configuration

- Algorithm family: FSRS-6
- Default desired retention: 0.90
- Default maximum interval: 36,500 days
- Ratings: Again (1), Hard (2), Good (3), Easy (4)
- Memory state: difficulty, stability, retrievability
- Default parameter vector:
  `[0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542]`

## Current V0.2 scheduling policy

The scheduler implements FSRS-6's published formulas for:

- initial stability
- initial difficulty
- difficulty updates with linear damping and mean reversion
- trainable forgetting curve
- same-day/short-term stability
- post-recall stability
- post-forgetting stability
- interval calculation from desired retention

V0.2 intentionally uses **day-level scheduling**. It does not yet add sub-day learning/relearning steps or random interval fuzzing. Those are scheduling-policy layers around the FSRS memory model and can be added without changing stored review history.

## Sources

Implementation is cross-checked against the Open Spaced Repetition project's FSRS-6 algorithm documentation and the maintained `py-fsrs` reference implementation.
