# 08: A bare `<target` loads into the topic

**What to build:** a statement consisting only of `<target` (no statement after it, nothing
before it) loads the decoded content into `$_`, so a following leading dotty subscript
reaches into it (`<a.json` then `.users.0.name`). In irak the loaded value counts as the
submission's value, so it becomes the irak topic.

**Blocked by:** 07

**Status:** ready-for-agent

**Tests:** `t/14-redirection/rak/011-load-topic.rak`

- [ ] `<a.json;` followed by `.name` gives the loaded object's `name`.
- [ ] Dotty chains reach nested data (`.users.0.name`).
- [ ] `<a.json say 1` is still input redirection, not a load.
- [ ] In irak, the next submission's `.name` reaches into the loaded data.
