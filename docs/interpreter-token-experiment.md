# Interpreter token experiment

Run:

```sh
tools/measure_interpreter_tokens.py
```

The script compares the same seam-carving workload in three modes:

- `one_big_file`: write and run one generated Forth file.
- `current_verbose_interactive`: keep one interpreter alive, but expose the full
  echoed pForth transcript to the agent.
- `proposed_compact_interactive`: keep one interpreter alive and expose only
  compact observations such as `agent-stack` markers, `OK`, and errors.

Token counts are estimated as:

```text
ceil((input_bytes + visible_output_bytes) / 4)
```

This is not tokenizer-exact, but it is stable enough for comparing workflows.
The result is also saved to:

```text
output/interpreter-token-measurement.json
```

The important distinction is that verbose interactivity is expensive.  The
interpreter only starts acting like external working memory when the transcript
returned to the model is compact and old definitions are not replayed.
