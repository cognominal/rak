# 04: Redirection targets accept the documented spellings

**What to build:** every target spelling the documentation promises works as a target:
naked strings including the path forms `./out.txt`, `../out.txt` and `~/out.txt`; quoted
strings including spaces and escapes; scalar variables; array and hash subscripts; and the
dotty subscript (`>.conf<output>`, `>@files[0]`). Today the naked-target rule contradicts
its own comment: it accepts a leading `/` and a leading letter or underscore, but not a
leading `.` or `~`, so script-relative and home-relative targets do not parse. Nothing here
changes where a redirection may appear.

**Blocked by:** None (can start immediately; independent of the binding model)

**Status:** ready-for-agent

- [ ] `./`, `../` and `~/` targets parse and write to the intended file.
- [ ] The naked-target rule and its comment agree on the accepted spellings.
- [ ] A target with spaces works when quoted, and a quoted target's escapes are honoured.
- [ ] A scalar variable target and a subscripted target (array and hash) each resolve at
      run time to the file actually written.
- [ ] A dotty-subscript target works in a `.rak` file, and a target spelling that is not in
      the documented set fails at compile time rather than writing somewhere unexpected.
