# Tree Expressions — Detailed Specification

**Version:** 0.1 (proposal for Rak shell/language)  
**Status:** Draft  
**Applies to:** `.rak` files and interactive Rak shell sessions

---

## 1. Motivation

A **tree expression** (tree expr) is a multi-line form whose visual layout mirrors the shape of its AST. The indentation and alignment of operators directly encode the tree structure, replacing the need for explicit parentheses, operator-precedence tables, or manual grouping.

Tree expressions solve two problems simultaneously:

1. **No precedence rules.** Within a single line, all binary operators have equal precedence and are left-associative — **except** `=` (assignment) and `:=` (binding assignment), which are right-associative even within a line and in tree expressions (see §5.7). The **column position** of an operator — not its lexical identity — determines its binding strength relative to operators on adjacent lines. This eliminates the need to memorise precedence tables (is `&` above `|`? Is `<<` above `&`?) and makes the parse tree visually obvious.

2. **Readable multi-line arithmetic/logic.** Deeply nested expressions that would require many parentheses in C, or many `$()` or `[...]` wrappers in shell, are written as a compact tree whose outline is the same as the AST it produces.

### Running example

```rak
  1 + 2
* 3 + 4
- 5 + 6
```

This is a single tree expression spanning three lines. It means exactly:

```rak
((1 + 2) * (3 + 4)) - (5 + 6)
```

No explicit parentheses are needed — the indentation and column alignment supply them.

---

## 2. Core concepts

### 2.1 The fundamental insight

**The column number (character offset from the left margin) of each binary operator defines its depth in the AST:**

- **Smaller column = closer to the root** (looser binding, evaluated later).
- **Larger column = deeper in the tree** (tighter binding, evaluated first).

Operators at the same column are at the same depth (siblings in the tree). Within one line, operators at different columns layer the expression: a leftward operator is the parent of a rightward one.

### 2.2 Relation to conventional trees

A conventional parenthesised expression `((1 + 2) * (3 + 4)) - (5 + 6)` has this AST:

```
           -
          / \
         /   \
        /     \
       /       \
      *         +
     / \       / \
    +   +     5   6
   / \ / \
  1   2 3 4
```

In a tree expression, **the visual layout is this tree rotated 90° counterclockwise** — the root is at the left margin, children are indented to the right:

```
  1 + 2
* 3 + 4
- 5 + 6
```

Reading the tree from the outermost column (column 0: `*`, `-`) inward (column 4: `+`, `+`, `+`) traces the same hierarchy as reading the AST top-down.

### 2.3 Two notation forms

Tree expressions support two equivalent notations, which are **syntactic sugar for the same underlying tree**. The parser may normalise one to the other, and authors may mix them.

| Form | Characteristic | When to use |
|------|---------------|-------------|
| **Compact** | Each line is a full infix subexpression. Alignment of operators across lines encodes the tree. | Short expressions, inlining |
| **Explicit** (also called "overdone") | Each line contains at most one operator and its immediate right operand. Leaf operands are on their own lines. The tree depth is explicit in the indentation. | Complex or deeply nested expressions, generated code |

Both forms produce identical ASTs.

---

## 3. Lexical conventions

### 3.1 Lines

A tree expression is a sequence of one or more lines, each terminated by a newline. The tree expression ends when one of the following is encountered:

- A blank line (empty or whitespace-only)
- A line whose first non-whitespace column is **less than or equal to** the column of the first token of the tree expression's first line, AND that is not a continuation of the tree expr (see §5)
- End of file / end of statement scope

### 3.2 Tokens

Within a tree-expression line, tokens are separated by runs of whitespace. The significant tokens are:

| Token type | Examples | Notes |
|------------|----------|-------|
| Binary operator | `+`, `-`, `*`, `/`, `==`, `&&`, `\|\|`, `<<`, `>>`, `//`, `%%`, `eq`, `ne` | Must be surrounded by at least one space on both sides (see §4.3) |
| Unary prefix operator | `not`, `!`, `-` (negation), `~` | Must NOT have a space between the operator and its operand. A spaced unary token is treated as binary. |
| Parenthesised expression | `(1 + 2)`, `(x)` | Parsed as a single operand; its internal structure is conventional |
| Literal/nested expression that continues on the next line | (See §5) | |

### 3.3 `tree-expr` boundary markers (optional)

A tree expression may be delimited explicitly with `{` and `}` to bypass normal newline-termination rules:

```rak
my $result = {
    1 + 2
  * 3 + 4
  - 5 + 6
}
```

When braces are used, the enclosed lines are always parsed as a single tree expression regardless of blank lines or indentation changes.

> **Open question:** Should the opening brace be on its own line, or could it be `= {` on the same line as the assignment? The conservative answer is "on its own line" for MVP.

---

## 4. The two forms in detail

### 4.1 Compact form

In the compact form, each line is a full infix expression. It may contain multiple binary operators at potentially different column positions. The operator that determines the line's role in the overall tree is the one at the **smallest column on that line** (the leftmost operator). That operator defines the "level" of the line.

**Rule:** The leftmost binary operator on each line defines that line's tree depth from its column. If a line has no binary operator (only unary operators or a bare operand), the line is a leaf or subexpression consumed by the preceding operator.

**Example:**

```rak
  1 + 2
* 3 + 4
- 5 + 6
```

| Line | Tokens | Leftmost binop | Column of leftmost binop | Role |
|------|--------|----------------|--------------------------|------|
| 1 | `1 + 2` | `+` | 4 | Subexpression `(1+2)`, left operand of next level |
| 2 | `* 3 + 4` | `*` | 0 | Outer `*`, right operand is `(3+4)` |
| 3 | `- 5 + 6` | `-` | 0 | Outer `-`, right operand is `(5+6)` |

The indentation of line 1 (two spaces before `1`) signals that its entire infix expression `1 + 2` is a subcomponent of the outer level. Lines 2 and 3, whose operators start at column 0, are the outermost operators.

### 4.2 Explicit ("overdone") form

In the explicit form, each line is limited to at most one binary operator. The operator appears at its designated column, with any operands to the right. Leaf operands (values with no operator) occupy their own lines at a deeper indentation.

**Rule:** The indentation of each line directly encodes the AST depth of its token.

**Example:**

```rak
    1
  + 2
*   3
  + 4
-   5
  + 6
```

| Line | Column | Token | Role in tree |
|------|--------|-------|-------------|
| 1 | 4 | `1` | Deepest leaf, left operand of `+` on line 2 |
| 2 | 2 | `+` | Mid-level `+`, right operand `2` at column 4 |
| 3 | 0 | `*` | Root-level `*`, right operand `3` at column 4 (forming subexpression `3+4` with next line) |
| 4 | 2 | `+` | Mid-level `+`, right operand `4` at column 4 |
| 5 | 0 | `-` | Root-level `-`, right operand `5` at column 4 |
| 6 | 2 | `+` | Mid-level `+`, right operand `6` at column 4 |

### 4.3 Equivalence of the two forms

The two forms produce **identical ASTs** and may be mixed within the same scope at the author's discretion. The compact form is more concise; the explicit form makes the tree structure unambiguous at a glance.

The parser should normalise both to a common internal representation.

---

## 5. Parsing algorithm

This section defines a deterministic algorithm that accepts either form and produces a single AST node.

### 5.1 Definitions

- **Column** of a token: the 0-based character offset from the start of the line to the first character of the token.
- **Line class**:
  - *Operator line*: a line whose first non-whitespace token is a binary operator.
  - *Operand line*: a line whose first non-whitespace token is an operand (value, variable, parenthesised expression, function call, etc.). It may contain operators to the right.
  - *Blank line*: a line that is empty or consists only of whitespace. Blank lines terminate the current tree expression unless it is delimited by braces.

### 5.2 Overall structure

The parser processes lines top to bottom, maintaining a **stack of `(column, AST_node)` pairs**. The stack invariant: column values are strictly increasing from bottom to top (the top of the stack has the deepest/rightmost column).

### 5.3 Step-by-step algorithm

```
Input:   list of lines L = [l1, l2, ..., ln]
         (whitespace-trimmed on the right, but leading whitespace preserved)
Output:  a single AST node

1. Initialise an empty stack.

2. For each line li in L:

   a. Determine the column col of the first non-whitespace character.
      If the line is empty/blank, break (end of tree expression).

   b. Parse the line into its tokens:
      - If the first token is a binary operator BINOP:
           This is an operator line.
           Let R = rest-of-line expression (right side of BINOP).
           Parse R as a traditional infix expression (left-associative,
           no precedence — all binops at the same level on this line
           are evaluated left-to-right).
      - If the first token is NOT a binary operator:
           This is an operand line.
           Let R = the entire line parsed as a traditional expression.
           (The line contributes a value but no operator at this column.)

   c. Pop entries from the stack where stack_column > col.
      The popped entries form an ordered list S = [s1, s2, ..., sk]
      (where s1 was deepest, sk is shallowest among the popped).
      All entries in S are at strictly greater columns than col.

   d. If the line is an operand line:
        - Push (col, R) onto the stack.
        - (R may be a complex infix expression parsed from the line.)

   e. If the line is an operator line with operator BINOP:
        - Determine the left operand LHS:
            - If S is non-empty, combine its entries using the
              "region combiner" (§5.4) to form a single expression LHS.
            - If S is empty, LHS is undefined. This is an error
              unless BINOP is unary (treated as prefix operator on R).
        - The right operand RHS is R (the expression parsed from
          the right side of BINOP).
        - If there are additional lines at indentation > col that
          were NOT consumed as operands on this line (i.e., they form
          a block indented under this operator), then RHS is extended
          to include them (see §5.5 "indented block as right operand").
        - Form the node N = BINOP(LHS, RHS).
        - Push (col, N) onto the stack.

3. After all lines are processed, collapse the stack:
   Pop all entries from the stack; the result of the last pop (the most
   deeply nested remaining entry) is the root of the tree expression,
   with all other entries composed as determined by the region combiner.
```

### 5.4 The region combiner

When multiple sibling subtrees at different depths are popped from the stack (step 2c), they form a **region** — a sequence of one or more AST nodes ordered from deepest to shallowest. How are they combined?

**Rule:** Within a region, sibling subtrees are combined left-to-right using the binary operator that is the parent of the region. Concretely:

- If the region has exactly one node, that node is the left operand.
- If the region has multiple nodes `[N1, N2, ..., Nk]` (where N1 is deepest), they were pushed by operator lines at the same parent column or operand lines nested within. They are combined as if by the repeated application of the operator that caused the pop.

**Important:** In the explicit form, a region between two operator lines at the same column typically contains subexpressions at every line between them. The parser determines these groupings automatically from the column stack.

### 5.5 Indented block as right operand

When an operator line at column C has an explicit right operand R on the same line, but the next lines are at columns > C, those lines form an **indented block** that extends R into a larger subexpression.

**Rule:** After forming `BINOP(LHS, R)` from an operator line, the parser examines subsequent lines. If the next line's first token is at column > C, it recursively parses those lines as a subexpression whose result becomes the **right operand** of BINOP, replacing `R`. The original `R` is treated as the first operand (left side) of this deeper subexpression.

In practice:

```
*   3
  + 4
```

Here `*` at column 0 has immediate right operand `3`. The next line `  + 4` starts at column 2 > 0. So the parser recurses: the block `  + 4` forms `(+ 3 4)`, and the result becomes the right operand of `*`. Thus `*` has RHS `(3 + 4)`, not `3`.

### 5.6 Recursive structure of tree expressions

A tree expression can be defined recursively as:

```
tree-expr       := line-block

line-block      := single-line
                  | single-line NEWLINE line-block

single-line     := indent? infix-expr

indent          := SPACE+

infix-expr      := term (BINOP term)*

term            := operand
                  | operand line-block    (indented continuation)

operand         := value | parenthesized | function-call
```

The presence of an indented continuation after an operand converts that operand into the left side of a deeper subexpression whose operator appears on the next line.

### 5.7 Right-associative operators: `=` and `:=`

The binary operators `=` (assignment) and `:=` (binding assignment) are **right-associative** in all contexts, including within a line and across lines in a tree expression. This is the single exception to the left-associative default.

**Within a line:**

```rak
a = b = c + d
```

Parses as `a = (b = (c + d))` — right-associative, regardless of column.

**In a tree expression:** The right-associative operators bypass the standard column-stack logic. When the parser encounters `=` or `:=` at column C, it:
1. Pops deeper entries as usual to form the left operand.
2. **Does not** combine the operator with the accumulated same-column entry as a left operand (as §5.3 step 2e would for left-assoc ops). Instead, the expression right of the operator is parsed first (recursively, including further `=`/`:=` chains), and the result is combined right-to-left.
3. The indented-block extension (§5.5) still applies — a `=` at column 0 with an indented block underneath extends its right side.

**Example with indented block:**

```rak
  x = a + b
=   y = c + d
= z = 0
```

This parses as `x = (a + b)` assigned into `y = (c + d)` assigned into `z = 0` — effectively `z = (y = (x = (a + b) + (c + d)))` *if* the columns are 0 for `=` and > 0 for the `+` lines. (The exact tree depends on column positions; the key point is that `=` chains are right-associative, not left-associative like all other binops.)

**Contrast with left-associative operators:**

```rak
  a + b
+ c + d
```

With left-associative `+`, this is `((a + b) + c) + d`. With `=`, the same alignment would be `a = (b = (c = d))` — right-to-left.

### 5.8 Worked example

Let's trace the algorithm on the compact form:

```
  1 + 2
* 3 + 4
- 5 + 6
```

**Line 1: `  1 + 2`**
- col = 2 (two spaces before `1`)
- First token: `1` (operand) → operand line
- Parse R: `1 + 2` → infix expression `(+ 1 2)`
- Pop stack entries where col > 2: none (stack is empty)
- Push `(col=2, (+ 1 2))` → Stack: `[(2, (+ 1 2))]`

**Line 2: `* 3 + 4`**
- col = 0
- First token: `*` (binary operator) → operator line
- Parse R: `3 + 4` → infix expression `(+ 3 4)`
- Pop stack entries where col > 0: pop `(2, (+ 1 2))` → S = `[(+ 1 2)]`
- S has one entry: LHS = `(+ 1 2)`
- Right operand R = `(+ 3 4)` (from parsing the rest of line 2)
- Check next lines: line 3 starts at col 0, which is NOT > 0, so no indented block.
- Form `(* (+ 1 2) (+ 3 4))`
- Push `(col=0, (* (+ 1 2) (+ 3 4)))` → Stack: `[(0, (* (+ 1 2) (+ 3 4)))]`

**Line 3: `- 5 + 6`**
- col = 0
- First token: `-` (binary operator) → operator line
- Parse R: `5 + 6` → infix expression `(+ 5 6)`
- Pop stack entries where col > 0: pop `(0, (* (+ 1 2) (+ 3 4)))` → S = `[(* (+ 1 2) (+ 3 4))]`
  (Note: col is 0, and stack top col is 0, which is NOT > 0, so nothing is popped.
   But the stack has an entry at col=0, which is the *same* level.)

Hmm — this reveals a subtlety. The stack entry at col=0 is at the *same* level as the new line, not a *deeper* level. The rule "pop where stack_column > col" would not pop it. We need to refine:

**Refined rule for same-column operators:** When a new line at column C has a binary operator, and there is already an entry at column C on the stack, that entry becomes the left operand. Specifically, the new operator at column C combines with the *previous* expression at column C (or the accumulated region above).

Let me re-trace with the refined rule:

**Line 2: `* 3 + 4`** (after line 1 processed)
- col = 0, operator = `*`
- Right operand R = `(+ 3 4)` 
- Stack currently: `[(2, (+ 1 2))]`
- Pop entries where col > 0: pop `(2, (+ 1 2))` → S = `[(+ 1 2)]`
- LHS = `(+ 1 2)` (the only entry in S)
- Form `(* (+ 1 2) (+ 3 4))`, push at col=0
- Stack: `[(0, (* (+ 1 2) (+ 3 4)))]`

**Line 3: `- 5 + 6`**
- col = 0, operator = `-`
- Right operand R = `(+ 5 6)`
- Stack: `[(0, (* (+ 1 2) (+ 3 4)))]`
- Pop entries where col > 0: none (stack top is at col=0, not > 0)
- Popped S is empty → no accumulated left operand from deeper levels.
- Since we have an entry at the *same* column (col=0), and binary `-` needs a left operand:
  - Pop the entry at col=0 (the accumulated result from the same level)
  - LHS = `(* (+ 1 2) (+ 3 4))`
- Form `(- (* (+ 1 2) (+ 3 4)) (+ 5 6))`, push at col=0
- Stack: `[(0, (- (* (+ 1 2) (+ 3 4)) (+ 5 6)))]`

**End of lines.** Collapse stack: final result is `(- (* (+ 1 2) (+ 3 4)) (+ 5 6))`.

This gives `((1+2)*(3+4)) - (5+6)`. Correct!

Now let me trace the explicit form:

```
    1
  + 2
*   3
  + 4
-   5
  + 6
```

**Line 1: `    1`**
- col = 4
- First token: `1` (operand) → operand line
- Pop where col > 4: none
- Push `(col=4, 1)` → Stack: `[(4, 1)]`

**Line 2: `  + 2`**
- col = 2
- First token: `+` (binary operator) → operator line
- Right operand R = `2` (rest of line, just the literal `2`)
- Pop where col > 2: pop `(4, 1)` → S = `[1]`
- LHS = `1`
- Form `(+ 1 2)`, push at col=2
- Stack: `[(2, (+ 1 2))]`

**Line 3: `*   3`**
- col = 0
- First token: `*` (binary operator) → operator line
- Right operand R = `3`
- Pop where col > 0: pop `(2, (+ 1 2))` → S = `[(+ 1 2)]`
- LHS = `(+ 1 2)`
- **Check indented block:** next line (line 4) starts at col=2 > col=0. So R is extended:
  - The indented block is: `  + 4` (line 4).
  - Parse block as subexpression with left operand = current R = `3`:
    - `+` at col=2, right operand = `4`
    - Accumulated from deeper: none
    - Form `(+ 3 4)`
  - RHS = `(+ 3 4)` (not just `3`)
- Form `(* (+ 1 2) (+ 3 4))`, push at col=0
- Stack: `[(0, (* (+ 1 2) (+ 3 4)))]`

**Line 4: `  + 4`** — already consumed as indented block of line 3. Skip.

**Line 5: `-   5`**
- col = 0
- First token: `-` (binary operator) → operator line
- Right operand R = `5`
- Pop where col > 0: stack top is `(0, ...)`, col=0 is not > 0. Nothing popped.
- Stack has entry at col=0 → it's the LHS.
- LHS = `(* (+ 1 2) (+ 3 4))` (pop the col=0 entry)
- **Check indented block:** next unprocessed line (line 6) starts at col=2 > col=0. R is extended:
  - Indented block: `  + 6`
  - Parse: `+` at col=2, right=6, left (from accumulated/deeper) = 5 (our R).
  - Form `(+ 5 6)`
  - RHS = `(+ 5 6)` (not just `5`)
- Form `(- (* (+ 1 2) (+ 3 4)) (+ 5 6))`, push at col=0
- Stack: `[(0, (- (* (+ 1 2) (+ 3 4)) (+ 5 6)))]`

**Line 6:** consumed as indented block. Skip.

**End.** Collapse: result = `(- (* (+ 1 2) (+ 3 4)) (+ 5 6))`. Correct!

The algorithm works for both forms.

---

## 6. Formal algorithm

We now give the algorithm in a pseudocode form that can serve as a reference implementation.

```
function parseTreeExpr(lines):
    stack = []  // list of (column, ASTNode) pairs
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        // Determine column of first non-whitespace character
        col = leadingWhitespaceCount(line)
        
        // Parse the line's tokens
        tokens = tokenize(line)
        if len(tokens) == 0:
            break  // blank line terminates
        
        // Classify first token
        if isBinaryOperator(tokens[0]):
            op = tokens[0]
            restTokens = tokens[1..]  // right side of operator
            rightExpr = parseInfix(restTokens)  // left-assoc, no precedence
            (stack, consumed) = processOperatorLine(stack, line, i, col, op, rightExpr, lines)
            i += consumed
        else:
            // Operand line – parse full line as an infix expression
            expr = parseInfix(tokens)
            (stack, consumed) = processOperandLine(stack, line, i, col, expr, lines)
            i += consumed
    
    // Collapse remaining stack
    return collapseStack(stack)


function processOperatorLine(stack, line, lineIdx, col, op, rightExpr, allLines):
    // Step 1: Pop deeper entries
    deeper = []
    while len(stack) > 0 and stack[-1].column > col:
        deeper.push(stack.pop())
    
    // Step 2: Determine left operand
    if len(deeper) > 0:
        leftExpr = combine(deeper)  // see combine()
    elif len(stack) > 0 and stack[-1].column == col:
        // Same-column operator – previous result at this column is left operand
        leftExpr = stack.pop().node
    else:
        error("No left operand for binary operator at column", col)
    
    // Step 3: Check for indented block on subsequent lines
    rhs = rightExpr
    nextLineIdx = lineIdx + 1
    if nextLineIdx < len(allLines):
        nextCol = leadingWhitespaceCount(allLines[nextLineIdx])
        if nextCol > col:
            // There is an indented block. Extend RHS.
            // The block starts with the next line and continues while col > current col.
            blockLines = []
            j = nextLineIdx
            while j < len(allLines):
                c = leadingWhitespaceCount(allLines[j])
                if c <= col:
                    break
                blockLines.push(allLines[j])
                j += 1
            
            if len(blockLines) > 0:
                // The current rightExpr's value becomes the left side
                // of the first operator in the block.
                // Prepend a synthetic operand line with the rightExpr
                // at the block's depth.
                rhs = parseBlock(rightExpr, blockLines)
    
    // Step 4: Form node
    node = ASTNode(op, leftExpr, rhs)
    stack.push((col, node))
    
    return (stack, 1 + countConsumedLines(lineIdx, col, allLines))


function processOperandLine(stack, line, lineIdx, col, expr, allLines):
    // Check if this operand is followed by an indented operator line
    nextLineIdx = lineIdx + 1
    if nextLineIdx < len(allLines):
        nextCol = leadingWhitespaceCount(allLines[nextLineIdx])
        if nextCol > col:
            // The operand is the left side of a subexpression starting
            // on the next line. Pop deeper entries (though they might
            // be at the operand's own depth) and then let the next
            // operator line handle the rest.
            // For now, just push the operand and let the next
            // iteration handle the operator line.
            stack.push((col, expr))
            return (stack, 1)
    
    // Pop deeper entries and push
    while len(stack) > 0 and stack[-1].column > col:
        stack.pop()  // deeper operands are consumed by current level
    stack.push((col, expr))
    return (stack, 1)


function parseBlock(leftExpr, blockLines):
    // Recursively parse blockLines as a tree expression,
    // using leftExpr as the starting left operand.
    // This is equivalent to prepending a synthetic line
    // with leftExpr at the block's base column.
    
    // Find the base column of the block
    baseCol = leadingWhitespaceCount(blockLines[0])
    
    // Create a synthetic stack with leftExpr at baseCol depth
    blockStack = [(baseCol, leftExpr)]
    
    // Process each line in blockLines as a regular tree expression
    // relative to blockStack
    i = 0
    while i < len(blockLines):
        line = blockLines[i]
        col = leadingWhitespaceCount(line)
        tokens = tokenize(line)
        
        if len(tokens) == 0:
            break
        
        if isBinaryOperator(tokens[0]):
            op = tokens[0]
            rest = tokens[1..]
            right = parseInfix(rest)
            
            // Pop deeper from blockStack
            deeper = []
            while len(blockStack) > 0 and blockStack[-1].column > col:
                deeper.push(blockStack.pop())
            
            // Left operand
            if len(deeper) > 0:
                lhs = combine(deeper)
            elif len(blockStack) > 0 and blockStack[-1].column == col:
                lhs = blockStack.pop().node
            else:
                lhs = leftExpr  // the synthetic left operand
            
            // Check for further indented block...
            // (recursive)
            
            node = ASTNode(op, lhs, right)
            blockStack.push((col, node))
        
        i += 1
    
    // Collapse blockStack
    return collapseStack(blockStack)


function combine(nodes):
    // nodes is a list of ASTNode from deepest to shallowest.
    // Combine them left-to-right using the operator of the deepest
    // node's parent (if available), or sequentially.
    //
    // For MVP: if there's exactly one node, return it.
    // If there are multiple nodes, they are siblings at the same level
    // and should be combined according to the parent context.
    if len(nodes) == 1:
        return nodes[0]
    
    // Multiple nodes in a region form a left-associative chain:
    result = nodes[0]
    for each n in nodes[1..]:
        result = ASTNode(someOperator, result, n)
    return result


function collapseStack(stack):
    // Return the single root node from a stack,
    // combining any remaining entries.
    if len(stack) == 0:
        return null
    result = stack[0].node
    for i = 1..len(stack)-1:
        result = stack[i].node  // shallower entries override deeper?
    return result
```

This algorithm is a reference design; a real implementation would optimise the parse tree construction and error reporting.

---

## 7. Edge cases and special situations

### 7.1 Single-line tree expression

A tree expression with only one line is equivalent to a normal infix expression:

```rak
1 + 2 * 3
```

Since there is no column alignment across lines, there is no tree. The expression is parsed with standard Rak infix semantics (left-associative within the line, no precedence).

### 7.2 Unary operators in tree expressions

Unary prefix operators (e.g. `not`, `!`, negation `-`) **must not** be separated from their operand by whitespace. This distinguishes them from binary operators:

```rak
!flag && cond          # ! is unary prefix (no space before flag)
- 5 + 3                # - at column 0 is binary subtraction? or unary negation?
```

**Disambiguation rule:** A token is a unary operator if it appears at the start of a line (or after another operator) without intervening whitespace before its operand. A token surrounded by spaces on both sides is a binary operator. If a `-` or `+` token has a space on its left but not on its right, it is unary (negation/identity). If it has spaces on both sides, it is binary.

The following is recommended for clarity:

```rak
  -3 + 5
* -2 + 4
```

Here `-3` and `-2` are unary negations, and `+ 5` and `+ 4` are binary additions.

### 7.3 Functions calls and parenthesised subexpressions

Parenthesised expressions and function calls are treated as single operands. Their internal structure is conventional and does not participate in the tree-expr indentation rules:

```rak
  f(1) + g(2)
* h(3) + arr[4]
- max(5, 6) + sqrt(7)
```

This parses as `((f(1) + g(2)) * (h(3) + arr[4])) - (max(5,6) + sqrt(7))`.

### 7.4 Arrays, hashes, and bracketed subexpressions

Square brackets `[...]` and curly braces `{...}` are also treated as single operands. They do not create tree-expression contexts unless explicitly used as the tree-expr delimiter (§3.3).

### 7.5 Non-binary operators (chained comparisons)

Languages with chained comparisons (e.g. `0 < x < 10`) introduce a ternary relation. In a tree expression, chained comparisons should be written as binary conjunctions:

```rak
  0 < x
&& x < 10
```

This is explicit and avoids ambiguity.

### 7.6 Mixing indentation widths

The column number is absolute (character offset from position 0 of the line). **Tabs are forbidden** in tree expressions — a tab anywhere in a tree expression is a syntax error. Only spaces may be used for indentation and alignment.

**Indent unit:** 2 spaces per depth level is the convention.

### 7.7 Comments and blank lines within a tree expression

- **Blank lines** terminate the tree expression (unless inside `{...}` delimiters).
- **Inline comments** (`# ...`) inside a tree expression are not allowed — `#` is a sigil prefix in Rak. Use `/* ... */` for block comments instead, but note that even these may interact with parsing. For MVP, simply require tree expressions to be comment-free.

### 7.8 Nested tree expressions

A tree expression can itself contain operands that are tree expressions, if the operand is a block delimited by `{...}`:

```rak
  a + b
* {
      1 + 2
    * 3 + 4
  }
- c + d
```

Here the `*` takes as its right operand the entire inner tree expression `((1+2)*(3+4))`. The indentation of the inner braces is relative to the inner expression; the outer tree expression sees the inner `{...}` as a single operand.

### 7.9 Ternary operators are forbidden

The ternary conditional operator (`cond ? a : b`) **must not** appear inside a tree expression. It is forbidden because:
- `?` and `:` do not have a single-column position that maps cleanly to a tree depth.
- The ternary is a three-argument shape, not a binary tree, and would require special-case parsing that undermines the uniform column-based model.

If a conditional is needed, factor it out into a separate statement or use a parenthesised conventional expression outside the tree expression:

```rak
# Good: conditional outside the tree expression
my $tmp = cond ? a : b
  $tmp + c
* d + e

# Good: traditional parens inside a leaf operand
  (cond ? a : b) + c
* d + e

# BAD: ternary inside tree expression
  cond ? a : b     # SYNTAX ERROR in tree expr
+ c + d
```

---

## 8. Relationship to the Rak language grammar

### 8.1 Statement context

In Rak, a newline normally terminates a statement. A tree expression overrides this by requiring the parser to check whether a line is a continuation of a preceding tree expression.

**How the parser detects a tree expression:**

When a line starts with content at some column C, and the previous line also had content at a column (any column), the parser checks:

1. Does the current line start at a column **greater** than or equal to the first line's first token column?
2. Does the current line's first token create a continuation (is it an operator at a non-zero column, or an operand at a deeper indentation)?

If yes, the newline is consumed, and parsing continues as a tree expression.

**Simpler rule for MVP:** A tree expression is explicitly opted into by one of:
- A line whose first token is at column > 0 (indented relative to normal statement start), AND the line is not a standalone statement (i.e., it's preceded by a line that has a binary operator or is itself part of a tree expression).
- The `{...}` delimiter.

For the initial implementation, requiring `{...}` delimiters for tree expressions may be simpler:

```rak
my $result = {
    1 + 2
  * 3 + 4
  - 5 + 6
}
```

### 8.2 Grammar snippet (for the Rak parser)

The following is an informal grammar fragment showing how tree expressions might integrate with the Rak grammar:

```
statement        : simple-stmt
                 | tree-expr-stmt
                 ;

tree-expr-stmt   : tree-expr
                 | assignment '=' tree-expr
                 | 'return' tree-expr
                 ;

tree-expr        : '{' tree-expr-lines '}'
                 | tree-expr-first-line tree-expr-continuation*
                 ;

tree-expr-first-line : INDENT? infix-expr NEWLINE
                     ;

tree-expr-continuation : INDENT infix-expr NEWLINE
                       | INDENT BINOP SPACE+ operand NEWLINE
                       ;

infix-expr       : operand (SPACE+ BINOP SPACE+ operand)*
                 ;

**Right-associative exception:** Operators `=` and `:=` do not participate in the left-associative `infix-expr` rule above. Instead, they are parsed specially:

```
assign-expr      : operand SPACE+ (':=' | '=') SPACE+ assign-expr
                 | infix-expr
                 ;
```

Within a tree expression, `=` and `:=` follow the column-stack algorithm of §5.3 but with right-associative semantics as described in §5.7.

operand          : value
                 | '(' expr ')'
                 | '[' expr ']'
                 | '{' tree-expr-lines '}'
                 ;
```

### 8.3 Interaction with Rak sigils (`~`, `#`)

The native-type sigils `~` (str) and `#` (int) are legal operands in tree expressions. They participate in column counting like any other token. Since a sigil character touches its identifier with no space, it does not create an operator ambiguity:

```rak
  #i + #j
* ~key ~ "value"
- #k + ~name
```

Parses as `((#i + #j) * (~key ~ "value")) - (#k + ~name)`, where `~` in `~key ~ "value"` is both sigil and string-concatenation operator (disambiguated by context: sigil when touching an identifier, infix operator when spaced on both sides).

### 8.4 Interaction with pipe and redirection

When Rak acts as a shell, pipes `|` and redirections `>`, `<`, `>>` are operators. In a tree expression within a shell context, they follow the same column-alignment rules (but remember `=` and `:=` are right-associative; see §5.7):

```rak
  cmd1 | cmd2
| cmd3 | cmd4
> output.txt
```

This would represent a pipeline tree: `(cmd1 | cmd2) | (cmd3 | cmd4) > output.txt`.

However, **pipes and redirections are recommended to be kept at column 0** (the outermost level) for clarity, and tree expressions should be used primarily for data expressions rather than shell pipelines in MVP.

---

## 9. Comparison with other approaches

| Approach | Example | How precedence works |
|----------|---------|---------------------|
| **Traditional infix** | `((1+2)*(3+4))-(5+6)` | Explicit parentheses |
| **Standard precedence** | `1+2*3+4-5+6` | Built-in precedence table (`*` before `+`, left-assoc) |
| **Forth/RPN** | `1 2+3 4+*5 6+-` | Stack-based postfix |
| **Lisp prefix** | `(- (* (+ 1 2) (+ 3 4)) (+ 5 6))` | Nested prefix |
| **Tree expr (this spec)** | Visual alignment | Column-based, visual AST |

The tree-expr approach occupies a unique point in this space: it removes the need for either precedence tables or explicit parentheses, replacing them with a visual convention that mirrors the program's actual tree structure.

### Limitations

- Cannot represent non-tree graphs (DAGs, shared subexpressions) — but for common arithmetic, logic, and data-pipeline expressions, trees are the right abstraction.
- Wide expressions may exceed terminal width — the explicit form mitigates this by stacking operators vertically.
- Visually ambiguous layouts may mislead the reader — see §10 for style guidelines.

---

## 10. Style guide (recommended conventions)

1. **Indentation unit:** 2 spaces per depth level. (4 spaces for the explicit form if more clarity is desired.)
   
2. **Compact form:** Prefer for short (2–4 line) expressions where each subexpression fits on one line.

3. **Explicit form:** Prefer when any subexpression spans multiple lines, or when the tree depth exceeds 2.

4. **Alignment of operators:** Within a column, all operators should be at the same character offset. Misalignment (e.g. `+` at col 2 in one line, col 3 in another) is a syntax error or will create unintended tree structure.

5. **Spacing around operators:** A binary operator **must** have at least one space on each side. Use consistent spacing — if a `+` at column 4 has one space on each side on line 1, the same `+` at column 4 on line 2 should also have one space on each side.

6. **Unary operators:** Always write unary operators without a space to their operand (`-x`, `!flag`, `not flag`). Binary operators always have spaces on both sides.

7. **Operator richness:** Avoid using tree expressions with more than 3–4 distinct column levels. Beyond that, extract subexpressions into named variables.

8. **Braces for disambiguation:** When a tree expression appears in an ambiguous context (e.g. inside a larger expression where newline termination is unclear), wrap it in `{...}`.

---

## 11. Edge cases not yet resolved

The following areas are intentionally left for implementation experience:

| Issue | Open question |
|-------|---------------|
| Error recovery | If a line's operator column doesn't match any expected level, how does the parser produce a useful error? |
| Pipeline trees | When `\|` is an operator, does `cmd1 \| cmd2 \| cmd3` parse as `(\| cmd1 (\| cmd2 cmd3))` (right-associative) or `(\| (\| cmd1 cmd2) cmd3)` (left-associative)? |
| Performance | The recursive block parser may re-scan lines. A production implementation should use an iterative stack, not recursion. |

---

## 12. Change log

| Date | Version | Change |
|------|---------|--------|
| (draft) | 0.1 | Initial specification |

---

*This document is a detailed expansion of the tree-expr concept handwaved in `shell.md`. The column-based precedence idea is inspired by languages that use indentation as syntax (Haskell's off-side rule, Python, Nim's `=` alignment) but adapted to operators rather than block structure.*
