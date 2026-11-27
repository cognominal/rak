# 02: A `->meth` stage followed by another stage

Status: done

**Spec:** `rak-plans/features/pipelines.md`, Stages: `->meth args` is
`input.meth(args)`, at any place in the pipeline.

**Today:** `->meth` works as the last stage (`say (echo hi | ->elems)` prints `1`), but
not before another `|`, where it is read as a pointy block's signature:

```
echo hi | ->elems | ^cat
===SORRY!=== Invalid typename 'elems' in parameter declaration.
------> echo hi | -><HERE>elems | ^cat
```

**Done when:** `->meth` is a method stage wherever it starts a stage, with a test in
`t/16-pipelines/rak/`.

**Done:** tested in `t/16-pipelines/rak/011-starts-and-lines.rak`.
