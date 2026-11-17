# indentation as syntax

in rak we want to remove braces in  braced blocks that spans multiple lines.
Blocks with bracees that span multiple lines are not allowed 
Indentation will be the syntax of blocks in that case.
But block that don't span lines  will stay the same.


The code that does the parse is currently the is the token blockoid method.

## how to implement it ?

We assune no tabs.
We need a scheme to detect indentation of each line so that would
affect the matching of spaces.

## how to present it as a grammar convention.

Under the hood, after a newline the \s rule tracks indentation and deindent but I 
dont't want  indent and deindent rule. Also I want the same rule to 
define multiline a indented block and a braced unline block.

I want a method rule trait `is block that is equivalent to a method trait `is indent<{}>`.
The indent trait has an opening character and a closing character for the rule when it is 
an uniline rule. Otherwise it is indented.
