# 01: A final `| say` stage

Status: ready-for-agent

**Spec:** `rak-plans/features/pipelines.md`, Stages: `name args` is `name(args, input)`,
so `echo hi | say` is `say(input)`.

**Today:** a bare routine name as the last stage fails to compile:

```
echo hi | say
===SORRY!===
Argument to "say" seems to be malformed
------> echo hi | say<HERE><EOL>
```

`ls | get name | say` fails the same way. `echo hi | { say $_ }` works.

**Done when:** a routine name alone, with no arguments, is a valid stage, last or not,
with a test in `t/16-pipelines/rak/`.
