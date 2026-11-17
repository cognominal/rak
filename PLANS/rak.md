# Rak 

Rak provides  a mix of standard and shell modes
sometimes withing a single statement.
It improves raku expressivity, supports interactivity, introduces pattern matching on data structures, and performance.
Rak is a fork and extension of raku.
Interactive use of rak at the command line is a good way
to learn it.

While the ancestor of Raku, Perl shined at matching pattern in strings,
rak, in addition, strives to be good at matching patterns in complex data 
structures.

Shell mode is new to raku ecosystem  but will be familiar to most unix users. 
Within shell mode one can  launch commands without forking or spawning, and can pipe data.
emitted by o ine command to the next.
Piped data are not necesarily a string, 

Redirections, naked strings and globbing are supported in both modes, 
standard and shell.

Redirections avoid the explicit use of file descriptors. 

```rak
echo              # launch command `echo` to print a newline
alias echo=nl     # aliases are supported 
say hello world   # call `say` builtin with 2 naked strings

say(1 + 3)

# a naked string not immediately followed by a '(' enter shell mode
# in shell mode stuff in parentheses 
say (1 + 3) things    # prints "4 things"
say \(1 + 3) things   # print "(1 + 3) things"
say \\( 1 + 3 ) things # print "\(1 + 3) things"

say world()
say i for 1..100 # one letter vars have a predefined type

# new sigils 

#foo = 1 

# i walking data structures 
a.1      # sigil can be omitted when inferred
a.1.name # no vification, a,1 is not created if missing execpt in interactive mode
say a.1.name.#i.~s
say a.1.name#1~s
say( 1 + 3 )

my #i = 1
my ~s = foo 

```
Rak is enabled by launching the `rak` 
executable or using the `.rak` file extension.


## Building onn Larry Wall ideas

Rak builds on Larry Wall's idea of concepts adapted from
natural languages mechanisms in an admitedly very 
different environment.

When possible, concision is preferred to regularity
at the cost of a language more complex to learn without 
sacrificing expressivity.
Interactive shell mode mechanisms a good way to learn.

Concision is obtained by huffing, designing short 
variants of common constructs.
Natural language have different registers often depending 
if is spoken or written. Written language is usually 
more formal. The equivalents in rak are the standard mode 
and the shell mode. The interactivity encouraged by shell mode
is a parallel to  spoken language.

## Minimizing visual noise

Braces and other parenthetic chars are heavy on the eye.


## New sigils and sigiless variable 

### sigiless variables names 

Conformant to the concision and noise reduction
principles, one character variables can be used 
without their sigil.

#### Scalar sigiless variables 

i...n integer 
I..N  varaiable lenghth of integer.

r..z

s     string 



Rak supports leaner default thanks to new sigils for 
scalars 

Rak support standard mode and shell mode. 
Shell mode is convenient for interactive use
ai:nd launching external command without bothering 
with `fork`, `exect`, `spawn` and the like,
conformant to cla ssic unix shells usage.

Naked strings and redirects are supported in both mode.
One can redirect to and from the web using URL.

With new sigils `#`, `` scalars fit in a register. 


Rak knows data language like yaml and json and 
can pattern match data structure using myaml an extension
of yaml. In myaml, single primary sigil variables are interpolated.





n

Rak can use shellish mode and standard mode in a single 
statement.

## Shellish
ya
After alias expansion, the first word is searched 

ls foo.yaml 



Pull data structures from the web, 


A shell that 

-redirects from the web and to the web using

## http requests GET and POST



