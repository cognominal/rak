# irak for absolute beginners

A tutorial on irak, the interactive rak shell, for people who have never programmed and
have never used a terminal. By the end you will move around a computer's files, run
programs, build and walk nested data, move data between files, programs and web
services, and know why each of those things works the way it does.

rak is a language and a shell at the same time. irak (pronounced "eye-rak") is rak used
interactively: you type, it answers. Everything in this tutorial happens in irak.

## Contents

- [Preface](#preface)
- **Part I: The machine**
  - [1. Terminal, shell and irak](#1-terminal-shell-and-irak)
  - [2. Files and directories](#2-files-and-directories)
  - [3. Processes](#3-processes)
- **Part II: Talking to irak**
  - [4. Values, words and strings](#4-values-words-and-strings)
  - [5. Commands](#5-commands)
  - [6. The topic and history](#6-the-topic-and-history)
- **Part III: Data**
  - [7. Variables and sigils](#7-variables-and-sigils)
  - [8. Complex data structures](#8-complex-data-structures)
  - [9. Walking data structures](#9-walking-data-structures)
  - [10. Referring to data: names, containers, sharing](#10-referring-to-data-names-containers-sharing)
- **Part IV: Moving data**
  - [11. Redirection and formats](#11-redirection-and-formats)
  - [12. Pipelines](#12-pipelines)
  - [13. The web as a file: URL targets](#13-the-web-as-a-file-url-targets)
- **Part V: Putting it together**
  - [14. A complete session](#14-a-complete-session)
  - [15. From irak to a `.rak` script](#15-from-irak-to-a-rak-script)
  - [16. Where to go next](#16-where-to-go-next)
- **Appendices**
  - [A. rak and Raku, chapter by chapter](#appendix-a-rak-and-raku-chapter-by-chapter)
  - [B. Gotchas](#appendix-b-gotchas)
  - [C. Mini glossary](#appendix-c-mini-glossary)

---

## Preface

### Who this is for

You need to know how to type and how to open an application on your computer. That is
all. You do not need to know what a "terminal", a "file system" or a "variable" is: each
word is explained the first time it is used, and collected in the
[mini glossary](#appendix-c-mini-glossary) at the end.

If you already program, skim Part I and read [Appendix A](#appendix-a-rak-and-raku-chapter-by-chapter)
alongside the rest: it gives the Raku spelling of every rak construct.

### Why learn in a shell

Most programming tutorials have you write a file, run it, read the result, change the
file, and run it again. irak shortens that loop to one line: you type something, press
ENTER, and see what it means right away. That makes it a good place to *ask the
computer questions*: what is in this directory, what is in this file, what does this
web service answer, what is the third element of that list. Programming starts as a
conversation, and turns into a program once the conversation is worth keeping
([chapter 15](#15-from-irak-to-a-rak-script)).

### How to read this tutorial

Read it in order, at the keyboard. Every example is meant to be typed. The chapters
build on one another, and from [chapter 8](#8-complex-data-structures) on they reuse the
same small data file, `team.json`, which you will build yourself.

Each chapter ends with a **Recap** and a few **Exercises**. The answers are folded
under each exercise: try first, then unfold.

### Work in progress

rak and irak are young, and this tutorial runs slightly ahead of them. It describes rak
as it is designed, which is mostly, but not entirely, how it behaves today. Where the two
differ, a red box like this one says so:

> [!CAUTION]
> 🔴 **Not implemented yet.** The feature described here does not exist yet: the
> examples will fail with an error.

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** The feature exists, but today it gives a
> different result, or an error, in the case shown.

The biggest gaps are in the web chapter ([chapter 13](#13-the-web-as-a-file-url-targets)):
loading from and posting to URLs work, but the `http` routine for the other kinds of
request, following pages, and binary answers are designed, not implemented.
Everything without a red box was checked against the current rak.

### Conventions

An irak session is shown like this:

```
[0] > say hello
hello
[1] > 1 + 2
3
```

- `[0] >` is irak's **prompt**: irak is waiting for you. The number counts what you have
  typed so far. You type what follows the prompt, then press ENTER.
- The lines without a prompt are irak's answer. You do not type them.
- Text after `#` and a space is a **comment**: a note for the human reader, ignored by
  irak. You don't need to type comments.

```
[2] > 10 * 3          # this note is ignored
30
```

When the numbers in the prompt don't matter, the examples show `>` alone.

Sometimes a command is meant for your usual terminal, before irak starts. Those
lines start with `$`:

```
$ ./rak
```

Keys are written in capitals: ENTER, TAB, Ctrl-C (hold Ctrl, press C), Ctrl-D, ↑ and ↓.

---

# Part I: The machine

Before you can talk to a computer usefully, you need a picture of what is inside it:
files kept on disk, and programs running in memory. Part I gives you that picture.

## 1. Terminal, shell and irak

### 1.1 A terminal is a window, a shell is a program

On a modern computer you mostly *point*: you click icons, drag windows, choose from
menus. A **terminal** is a window in which you *type* instead. It shows lines of text,
and at the bottom, a place where what you type appears.

A terminal does nothing by itself. It shows text, and sends what you type to a program
running inside it. That program is a **shell**: it reads a line you type, does what the
line says, prints the result, and waits for the next line. The usual shells are called
bash, zsh or fish. irak is a shell too, with a difference: it is also a full programming
language, so the same line can list files, compute a sum, or reshape data fetched from
the web. A traditional shell needs helper programs, such as `jq` for JSON data and `curl`
for the web, to do what irak does by itself;
[13.11](#1311-what-a-traditional-shell-would-need) compares the two side by side, once you
know enough to appreciate the difference.

The loop a shell runs has a name: **read, evaluate, print, loop**, or **REPL**. irak is
rak's REPL.

### 1.2 Starting irak

Open a terminal. On Linux, it is usually called "Terminal"; on macOS it is
Terminal.app, in Applications → Utilities. You see a line ending with `$` or `%`: your
usual shell's prompt.

If rak is installed, start irak with:

```
$ rak
```

If you built rak from its source code, go to the directory where you built it and type:

```
$ ./rak
```

(The `./` means "the program called `rak` *right here*". [Chapter 2](#2-files-and-directories)
explains why it is needed.)

irak greets you and shows its prompt:

```
Welcome to irak, the rak shell.
[0] >
```

The `[0]` counts your **submissions**: each time you press ENTER, what you typed is
submitted to irak, which evaluates it, and the count goes up by one.

### 1.3 Your first submission

Type this, then press ENTER:

```
[0] > say hello
hello
```

`say` is a **routine**: a named piece of behaviour that is built into rak. `say` prints
what follows it, then goes to the next line. `hello` is what it prints.

Try a few more:

```
[1] > say 'hello world'
hello world
[2] > say 42
42
[3] > 6 * 7
42
```

The last one has no `say`, and irak still shows `42`. irak shows the **value** of every
submission: the result of what you typed. `6 * 7` has the value `42`, so irak shows it.
`say hello` *prints* `hello` itself, so irak does not show anything more.
[Chapter 4](#4-values-words-and-strings) comes back to this difference.

Why the quotes around `'hello world'`? Without them, `say` receives two separate words,
`hello` and `world`, and prints them one after the other, with nothing in between:

```
[4] > say hello world
helloworld
```

The quotes make `hello world` a single piece of text, space included.
[Chapter 4](#43-strings-naked-and-quoted) explains when quotes are needed.

### 1.4 Leaving, interrupting, and getting unstuck

- **Ctrl-D** at an empty prompt leaves irak. You are back in your usual shell.
- **Ctrl-C** stops whatever is running and gives you the prompt back. At the prompt
  itself, it clears the line you were typing. It never makes irak quit.
- If irak shows a different prompt, made of dots, it thinks your submission is not
  finished: you have opened a bracket or a quote and not closed it. Close it and press
  ENTER, or press Ctrl-C to start over.

```
[5] > say (1 + 2
...   )
3
```

### 1.5 Mistakes are cheap

You cannot break irak by typing something wrong. When it does not understand a
submission, or understands it but cannot do it, it prints an **error message** and
waits for the next submission. Nothing else happens.

```
[6] > 1 +
===SORRY!=== Error while compiling
Missing required term after infix
------> 1 +⏏<EOL>
```

An error message looks scary, but it is written for you. Read it in three steps:

1. **What kind of error**: `===SORRY!=== Error while compiling` means irak could not
   even understand the line. Other errors come later, while the line is running (for
   example, a file that does not exist).
2. **What went wrong**: `Missing required term after infix`. An *infix* is an operator
   written between two things, like `+`. irak saw `1 +` and expected a second number.
3. **Where**: the `⏏` sign marks the spot. Here it is at the end of the line (`<EOL>`
   means "end of line").

Then fix the line and try again. Typing ↑ brings back your previous submission, so you
can correct it instead of typing it all again.

### Recap

- A terminal is a text window. A shell is a program in it that reads and runs your lines.
- irak is rak's shell. Start it with `rak` or `./rak`, leave with Ctrl-D.
- Each line you submit has a value, which irak shows unless the line printed something.
- Error messages say what kind of error, what went wrong, and where (`⏏`).

### Exercises

1. Start irak and compute how many seconds there are in a day.
   <details><summary>Answer</summary>

   ```
   > 24 * 60 * 60
   86400
   ```
   </details>

2. Print `good morning` with `say`. How many words did `say` receive?
   <details><summary>Answer</summary>

   `say 'good morning'` prints `good morning`: `say` received one piece of text.
   `say good morning` prints `goodmorning`: `say` received two words, `good` and
   `morning`, and printed them one after the other.
   </details>

3. Type `say (2 + 3` and press ENTER. What does irak do? How do you get out of it?
   <details><summary>Answer</summary>

   irak shows its continuation prompt (`...`), because the bracket is still open. Type
   `)` and ENTER to finish the submission, or Ctrl-C to abandon it.
   </details>

---

## 2. Files and directories

### 2.1 The tree

Everything a computer keeps when it is switched off is stored in **files**: your
photos, your documents, and the programs themselves. A file is a named sequence of
bytes. A **byte** is a number between 0 and 255; text, images and programs are all
made of bytes, interpreted differently.

Files are kept in **directories** (also called folders). A directory holds files and
other directories, which hold more files and directories, and so on. The result is a
**tree**, drawn upside down: its root is at the top.

```
/                       the root directory
├── home
│   └── ada             your home directory
│       ├── notes.txt
│       ├── photos
│       │   └── cat.jpg
│       └── projects
│           └── rak
├── tmp
└── usr
    └── bin             where many programs live
        ├── ls
        └── git
```

On Linux and macOS, the root of the tree is written `/`. (Windows writes it differently;
this tutorial follows Linux and macOS.)

Your **home directory** is the part of the tree that belongs to you. Its name is your
user name, and it is usually `/home/yourname` on Linux or `/Users/yourname` on macOS.
In this tutorial, the user is called `ada`.

### 2.2 Paths

A **path** names a place in the tree by listing the directories on the way to it,
separated by `/`:

```
/home/ada/photos/cat.jpg
```

reads as: from the root `/`, go into `home`, then into `ada`, then into `photos`, and
there take the file `cat.jpg`.

A path that starts with `/` is **absolute**: it starts at the root, so it means the same
thing wherever you are. A path that does not start with `/` is **relative**: it starts
from the **current directory**, the place in the tree where you are now. Every shell,
and every running program, has a current directory.

If your current directory is `/home/ada`, then:

| Relative path | Means |
|---|---|
| `notes.txt` | `/home/ada/notes.txt` |
| `photos/cat.jpg` | `/home/ada/photos/cat.jpg` |
| `.` | the current directory itself, `/home/ada` |
| `..` | the directory above, `/home` |
| `../..` | two levels up, `/` |
| `./notes.txt` | the same as `notes.txt` |

Two more shortcuts:

- `~` means your home directory. `~/photos` is `/home/ada/photos`, wherever you are.
- `-`, in `cd -`, means "the directory I was in before" (see below).

That is why you started irak with `./rak` in [chapter 1](#12-starting-irak): when you
type a program name alone, the shell looks for it in a list of special directories
([chapter 3](#33-how-a-program-is-found-path)), not in the current directory. `./rak`
says "the `rak` right here".

**Names with spaces.** A file can be called `my notes.txt`. But a shell separates words
with spaces, so `my notes.txt` looks like two names. Put such a name in quotes:
`'my notes.txt'`. Many people avoid spaces in file names and use `-` or `_` instead:
`my-notes.txt`.

### 2.3 Moving around

Start irak and ask where you are:

```
> pwd
/home/ada
```

`pwd` stands for "print working directory" (*working directory* is another name for the
current directory). irak starts in the directory you started it from.

List what is here:

```
> ls
notes.txt  photos  projects
```

Move into a directory with `cd` ("change directory"):

```
> cd photos
> pwd
/home/ada/photos
> ls
cat.jpg
```

Go back up, using `..`:

```
> cd ..
> pwd
/home/ada
```

Three short forms are worth remembering:

```
> cd /usr/bin       # an absolute path: go there directly
> cd -              # go back to where you were: /home/ada
> cd                # no argument: go home
```

`cd -` is handy when you jump between two places: it swaps them each time.

You can also ask rak for the current directory as a value, instead of a printed line.
`$*CWD` holds it:

```
> $*CWD
"/home/ada".IO
```

Ignore the `.IO` for now: it says the value is a path, not just any text.

### 2.4 Looking closer: `ls -l` and `ls -a`

`ls` accepts **options**: words starting with `-` that change what it does. `-l` asks
for the long listing:

```
> ls -l
-rw-r--r-- 1 ada ada  1204 Nov 18 10:02 notes.txt
drwxr-xr-x 2 ada ada  4096 Nov 17 21:40 photos
drwxr-xr-x 3 ada ada  4096 Nov 19 09:15 projects
```

Each line describes one entry. From the right: the name, the date it was last changed,
its size in bytes, its group and owner (here both `ada`), a count you can ignore, and
ten characters of **permissions**.

The first character says what kind of entry it is: `-` for a file, `d` for a directory.
The nine others come in three groups of three, for three kinds of people:

```
- rw- r-- r--
  │   │   └── everybody else
  │   └────── the file's group
  └────────── the file's owner
```

In each group, `r` means *may read*, `w` *may write* (change), and `x` *may execute*
(run it as a program, or, for a directory, enter it). A `-` means the permission is
missing. So `-rw-r--r--` is a file that its owner can read and change, and everyone
else can only read.

`-a` shows **hidden** entries too, whose names start with a dot:

```
> ls -a
.  ..  .config  notes.txt  photos  projects
```

There are `.` and `..` again, and `.config`, a directory where programs keep their
settings. Options can be combined: `ls -la`.

### 2.5 Making and removing things

| Command | Does |
|---|---|
| `mkdir dir` | make a directory |
| `touch file` | create an empty file (or update the date of an existing one) |
| `cp from to` | copy a file |
| `mv from to` | move or rename a file or directory |
| `rm file` | remove a file |
| `rmdir dir` | remove an empty directory |
| `cat file` | print a file's contents |

Make a playground for this tutorial, so your experiments stay in one place:

```
> cd
> mkdir irak-tutorial
> cd irak-tutorial
> touch empty.txt
> ls
empty.txt
> mv empty.txt still-empty.txt
> ls
still-empty.txt
> rm still-empty.txt
> ls
>
```

The last `ls` printed nothing: the directory is empty.

> **Warning.** `rm` does not move a file to a trash can. The file is gone, and there is
> no undo. Before you remove something, `ls` it, and read the name twice.

From now on, the tutorial assumes you are in `~/irak-tutorial`. If you leave irak and
come back, start with `cd ~/irak-tutorial`.

### 2.6 Text, binary, and extensions

Some files hold **text**: letters, digits, punctuation, line breaks. You can read them
with `cat`, and edit them with a text editor. Others are **binary**: images, sound,
compiled programs. Their bytes are not meant to be read as text, and `cat` on them
prints garbage.

A file name usually ends with an **extension**: a dot and a few letters, as in
`notes.txt`, `cat.jpg`, `team.json`. The extension is only part of the name. It does
not change what is inside the file, but it tells people and programs what to expect:
`.txt` for plain text, `.jpg` for an image, `.json` for data in the JSON format.

rak takes extensions seriously. When you save data into `team.json`, rak writes it as
JSON *because* the name ends in `.json`; when you save into `team.txt`, it writes plain
text. [Chapter 11](#11-redirection-and-formats) is all about this.

### Recap

- Files hold bytes. Directories hold files and directories, forming a tree rooted at `/`.
- A path names a place in the tree. Absolute paths start with `/`; relative ones start
  from the current directory. `.` is here, `..` is up, `~` is home.
- `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm`, `cat` cover everyday file work.
- `ls -l` shows permissions: read, write, execute, for owner, group and others.
- `rm` is permanent.
- An extension is part of the name; rak uses it to choose a format.

### Exercises

1. From `~/irak-tutorial`, what absolute path does `../irak-tutorial/./x.txt` name?
   <details><summary>Answer</summary>

   `/home/ada/irak-tutorial/x.txt`: `..` goes up to `/home/ada`, then back into
   `irak-tutorial`, and `.` stays where it is.
   </details>

2. Create the directories `a`, then `a/b`, and a file `a/b/c.txt`. Then go into `a/b`
   and back to `~/irak-tutorial` in one `cd`.
   <details><summary>Answer</summary>

   ```
   > mkdir a
   > mkdir a/b
   > touch a/b/c.txt
   > cd a/b
   > cd ../..
   ```
   `cd -` would also work, since you came from there.
   </details>

3. In `ls -l`, a line starts with `-rwx------`. Who can do what?
   <details><summary>Answer</summary>

   It is a file (`-`). Its owner can read, change and run it. Nobody else can do
   anything with it.
   </details>

---

## 3. Processes

### 3.1 Programs and processes

A **program** is a file: a list of instructions, sitting on disk. `ls` is a program, in
the file `/usr/bin/ls`. A program does nothing while it sits there.

A **process** is a program *running*: the computer has loaded the instructions into
memory and is carrying them out. The same program can run as many processes at once.
Three terminals running irak are three irak processes, made from one program file.

Each process gets a number when it starts, its **process ID**, or **PID**. rak shows
its own:

```
> $*PID
48213
```

Your number will differ. `ps` lists processes. With `-f`, it shows more columns:

```
> ps -f
UID        PID  PPID  C STIME TTY      TIME     CMD
ada      47990 47985  0 09:12 pts/3    00:00:00 -zsh
ada      48213 47990  1 09:20 pts/3    00:00:02 rakudo-m …
ada      48377 48213  0 09:31 pts/3    00:00:00 ps -f
```

`PPID` is the **parent** PID: the process that started this one. Read the table from the
bottom: `ps` (48377) was started by irak (48213, shown as `rakudo-m`, the program that
runs rak), which was started by your usual shell `zsh` (47990). Every process except
the very first one has a parent, so processes form a tree, like files do. `pstree -p`
draws it, if it is installed:

```
> pstree -p $*PID
rakudo-m(48213)───pstree(48391)
```

When irak runs `ls`, it starts a **child process**, waits for it to end, and shows you
the prompt again. The child's output goes straight to your terminal.

### 3.2 What every process carries

Every process has, among other things:

1. **A current directory.** Relative paths start there ([2.2](#22-paths)).
2. **An environment**: a set of named text values, called **environment variables**,
   that it received from its parent. They hold settings such as your home directory or
   your language.
3. **Three standard streams**, numbered 0, 1 and 2:

   | Number | Name | Usually connected to | Used for |
   |---|---|---|---|
   | 0 | standard input | the keyboard | what the process reads |
   | 1 | standard output | the terminal | its normal results |
   | 2 | standard error | the terminal | error messages and warnings |

   A process does not know or care where its streams go. That is what makes
   [redirection](#11-redirection-and-formats) and [pipelines](#12-pipelines) possible:
   the shell connects the streams to files, or to other processes, and the program works
   the same.
4. **An exit status**, which it leaves behind when it ends ([3.5](#35-how-a-process-ends)).

rak shows its environment in `%*ENV`. The `%` says it is a collection of named entries
([chapter 7](#7-variables-and-sigils)). Ask for one entry with a dot and its name:

```
> %*ENV.HOME
/home/ada
> %*ENV.USER
ada
> %*ENV.LANG
en_US.UTF-8
```

The `.HOME` after `%*ENV` means "the entry named `HOME`". This dot is called a
**dotty subscript**, and [chapter 9](#9-walking-data-structures) is all about it.

The three standard streams are also visible from rak, as `$*IN`, `$*OUT` and `$*ERR`.
`say` writes to `$*OUT`. `note` writes to `$*ERR`:

```
> note 'something is odd'
something is odd
```

On the terminal, both look the same. The difference appears when you send one of them
to a file: the other one still reaches the screen. [Chapter 5](#56-command-redirections)
shows this.

### 3.3 How a program is found: `$PATH`

When you type `ls`, irak needs the file holding the `ls` program. It does not search the
whole disk. It looks at the environment variable `PATH`:

```
> %*ENV.PATH
/home/ada/.local/bin:/usr/local/bin:/usr/bin:/bin
```

`PATH` is a list of directories separated by `:`. irak looks for a file called `ls` in
each of them, in order, and runs the first one it finds. Programs found this way are
called **external commands**, because they live outside irak.

The `type` builtin tells you what a name means:

```
> type ls
ls is /usr/bin/ls
> type cd
cd is a shell builtin
> type say
say is a rak routine
```

`type` answers from rak's point of view, and a name can mean several things.
[Chapter 5](#53-who-wins-a-name) explains how irak chooses.

This is why `./rak` needed its `./`: the directory where you built rak is not in `PATH`,
so the bare name `rak` would not be found there.

### 3.4 Starting a child

A command that runs for a while shows that irak waits for its child:

```
> sleep 3
>
```

`sleep 3` is an external command that does nothing for three seconds, then ends. For
those three seconds, irak shows no prompt: it is waiting. When the child ends, the
prompt comes back.

A child **inherits** from its parent: it gets a copy of irak's environment, starts in
irak's current directory, and its three streams are connected to the same terminal.
That is why a full-screen program works from irak:

```
> less ~/irak-tutorial/a/b/c.txt
```

`less` takes over the terminal to show the file one screen at a time (press `q` to
quit). Editors such as `nano` or `vim` work the same way.

### 3.5 How a process ends

A process ends in one of two ways:

- It **exits**: it finishes and hands back a small number, its **exit code**. By
  convention, `0` means success, and anything else means some kind of failure. Each
  program documents what its codes mean.
- It is **killed by a signal**: something outside it tells it to stop
  ([3.7](#37-stopping-a-process)).

Either way, the process leaves an **exit status**: its exit code, or the signal that
killed it. irak keeps the last one in `$?`.

```
> ls nothing-here
ls: cannot access 'nothing-here': No such file or directory
exit 2
> $?->exitcode
2
> ls
a
> $?->exitcode
0
```

When a command fails, irak prints a dimmed `exit N` line, so you notice. Otherwise it
says nothing. `$?` can also be compared to a number directly: `$? == 0` is true after
a success.

`true` and `false` are two tiny programs that do nothing except succeed and fail. They
are useful for experiments:

```
> false
exit 1
> $? == 0
False
> true
> $? == 0
True
```

### 3.6 Why `cd` must be a builtin

A child gets a *copy* of its parent's current directory and environment. Whatever the
child does to its copy, the parent's stays unchanged. So a `cd` program, run as a child,
would change only its own directory, then exit: irak would not move.

That is why `cd` is a **builtin**: a command that irak carries out itself, inside its
own process, without starting a child. `type cd` says so. Every shell has `cd` built in
for the same reason.

The same goes for the environment. Changing `%*ENV` in irak changes it for irak and for
every child started afterwards, but not for the shell that started irak:

```
> %*ENV.GREETING = 'hi'
hi
> printenv GREETING
hi
```

`printenv` is a child that prints an environment variable it inherited.

### 3.7 Stopping a process

A **signal** is a short message the system sends to a process, usually to tell it to
stop. Each signal has a name and a number:

| Signal | Number | Sent when | Usual effect |
|---|---|---|---|
| `SIGINT` | 2 | you press Ctrl-C | stop |
| `SIGTERM` | 15 | `kill PID` | stop, cleanly |
| `SIGKILL` | 9 | `kill -9 PID` | stop at once, no cleanup possible |
| `SIGPIPE` | 13 | the reader of its output went away | stop ([chapter 12](#127-laziness-and-sigpipe)) |

Try Ctrl-C on a long sleep:

```
> sleep 100
^C
killed by SIGINT
> $?->signal
2
```

The child got `SIGINT` and stopped. irak did not: a shell ignores Ctrl-C while a child
runs, so that only the child stops.

To stop a process that is not in front of you, find its PID with `ps`, then send it a
signal with `kill`. Open a second terminal, start `sleep 1000` in it, and from irak:

```
> ps -u ada -f
…
ada      48502 48499  0 09:47 pts/4    00:00:00 sleep 1000
> kill 48502
```

In the other terminal, the `sleep` ends. Try plain `kill` first: `SIGTERM` lets a
program clean up after itself. Use `kill -9` only when a program ignores `SIGTERM`.

### Recap

- A program is a file. A process is a program running, with a PID and a parent.
- A process has a current directory, an environment (`%*ENV`), three standard streams
  (input 0, output 1, error 2), and leaves an exit status (`$?`).
- External commands are found by searching the directories in `PATH`. `type` tells you
  what a name means.
- irak waits for its children. Children inherit copies of the environment and current
  directory, which is why `cd` is a builtin.
- Exit code `0` is success. Signals (`SIGINT`, `SIGTERM`, `SIGKILL`) stop processes.

### Exercises

1. Run `ls /` and check that it succeeded, using `$?`.
   <details><summary>Answer</summary>

   ```
   > ls /
   bin  boot  dev  etc  home  …
   > $? == 0
   True
   ```
   </details>

2. Find where the `git` program lives. If `git` is not installed, try `cat`.
   <details><summary>Answer</summary>

   `type git` prints something like `git is /usr/bin/git`.
   </details>

3. Explain why `printenv GREETING` printed nothing in your usual shell after you set
   `%*ENV.GREETING` in irak and quit.
   <details><summary>Answer</summary>

   irak changed its own copy of the environment. Its parent, your usual shell, has its
   own copy, which irak cannot touch. When irak exited, its copy disappeared with it.
   </details>

4. Run `sleep 5`, press Ctrl-C, and print the number of the signal that stopped it.
   <details><summary>Answer</summary>

   `$?->signal` gives `2`, which is `SIGINT`.
   </details>

---

# Part II: Talking to irak

Part I showed irak as a shell: a place to run programs. Part II shows irak as a
language: values, words, strings, and the rules that decide whether a word is text,
a routine, or a program to run.

## 4. Values, words and strings

### 4.1 Every submission has a value

Each time you submit a line, irak **evaluates** it: it works out what the line means
and does it. The result is the line's **value**, and irak shows it:

```
[0] > 2 + 2
4
[1] > 'hello'
hello
```

A value is a piece of data: a number, a piece of text, a list, a date, a file path.
Every value has a **type**, which says what kind of value it is. You can ask a value for
its type by writing `->WHAT` after it:

```
[2] > 42->WHAT
(Int)
[3] > 'hello'->WHAT
(Str)
[4] > 2.5->WHAT
(Rat)
```

`Int` is short for *integer*, a whole number. `Str` is short for *string*, the
programmer's word for a piece of text (a *string* of characters). `Rat` is short for
*rational number*, a fraction; more on it below.

The arrow `->` asks a value a question, or tells it to do something. The word after the
arrow is a **method**: something a value of that type knows how to do. Strings know
their length, numbers know whether they are even:

```
[5] > 'hello'->chars
5
[6] > 'hello'->uc
HELLO
[7] > 'hello'->flip
olleh
[8] > 7->is-prime
True
```

When a method needs more information, give it in parentheses after a dot:

```
[9] > 'a-b-c'.split('-')
(a b c)
[10] > 'hello'.substr(1, 3)
ell
```

So: `->name` calls a method with nothing more to say, and `.name(…)` calls one with
something in the parentheses. Remember that the dot alone, without parentheses, means
something else in rak; [chapter 9](#9-walking-data-structures) is about it.

### 4.2 Numbers

rak does arithmetic the way you learned it at school:

| Operator | Means | Example | Value |
|---|---|---|---|
| `+` | add | `3 + 4` | `7` |
| `-` | subtract | `3 - 4` | `-1` |
| `*` | multiply | `3 * 4` | `12` |
| `/` | divide | `10 / 4` | `2.5` |
| `div` | divide, whole part only | `7 div 2` | `3` |
| `%` | remainder of a division | `7 % 2` | `1` |
| `**` | power | `2 ** 10` | `1024` |

Multiplication goes before addition, and parentheses change the order:

```
> 3 + 2 * 4
11
> (3 + 2) * 4
20
```

Integers have no size limit:

```
> 2 ** 100
1267650600228229401496703205376
```

Division gives an exact fraction, a `Rat`, and not an approximation. That is why rak
gets a famous sum right, which many languages get wrong:

```
> 0.1 + 0.2 == 0.3
True
> 1 / 3
0.333333
```

irak shows only a few digits of `1 / 3`, but it keeps the exact fraction inside.

**Spaces around operators.** Always write a space on each side of an operator: `3 + 4`,
not `3+4`. rak relies on spacing: in [chapter 11](#117-spacing-is-syntax), `>file`
written without a space means "send this to a file", while `$a > $b`, spaced, compares
two numbers. Spacing every operator keeps you on the safe side.

**Write `0.5`, not `.5`.** In rak, a dot followed by a number means "the element at
that position" ([chapter 9](#9-walking-data-structures)). `.5` is the sixth element of
something, not one half. Write the zero.

### 4.3 Strings: naked and quoted

You have already typed strings without quotes: in `say hello`, `hello` is a string.
A word typed without quotes that rak takes as text is a **naked string**. Most shells
work this way, and it saves a lot of typing:

```
> say hello
hello
> 'hello' eq hello
True
```

(`eq` compares two strings; see [4.5](#45-true-false-and-comparisons).)

A word is a naked string when it starts with a letter or `_`, contains no space, and is
not a word that rak already knows. "Already knows" covers three cases:

1. **Keywords**, the words that structure the language: `if`, `else`, `for`, `my`,
   `sub`, `return`, and a few dozen more. They never become strings.
2. **Routines and variables** that rak knows at that point: `say`, `uc`, the routines
   you write yourself ([4.4](#44-words-that-call-routines)).
3. A word **directly followed by `(`**: that is always a call.

When you want text that a naked string cannot express, use quotes:

- text with spaces: `'hello world'`;
- text that starts with a digit or a symbol: `'42nd street'`, `'#hashtag'`;
- text that is also a routine's name: `'say'`.

There are two kinds of quotes, and they differ in one way:

```
> my $name = 'Ada'
Ada
> say "hello $name"
hello Ada
> say 'hello $name'
hello $name
```

Double quotes **interpolate**: they replace `$name` with the value it holds. Single
quotes keep the text exactly as written. (`my $name = 'Ada'` creates a variable called
`$name` and puts `Ada` in it; [chapter 7](#7-variables-and-sigils) covers variables.)
Double quotes also run any code between braces:

```
> say "two and two make {2 + 2}"
two and two make 4
```

Two strings are joined with `~`, spaced like any operator:

```
> 'rak' ~ ' ' ~ 'rocks'
rak rocks
```

Inside quotes, a few **escapes** stand for characters that are awkward to type: `\n` for
a line break, `\t` for a tab, `\"` for a double quote inside double quotes. They work in
double quotes only.

```
> say "one\ntwo"
one
two
```

### 4.4 Words that call routines

A **routine** is a named piece of behaviour. `say`, `uc` (upper case) and `lc` (lower
case) are routines that rak provides. When a word names a routine, the words after it
are its **arguments**: the values it works on. No parentheses are needed:

```
> say uc hello
HELLO
```

Read it from the right: `hello` is a naked string; `uc hello` calls `uc` with it, giving
`HELLO`; `say` prints that.

You can write your own routines with `sub` (for *subroutine*):

```
> sub double($x) { $x * 2 }
&double
> double 21
42
```

`sub double($x) { $x * 2 }` declares a routine called `double` that takes one value,
calls it `$x`, and gives back `$x * 2`. irak shows `&double`: the routine itself is a
value too ([chapter 10](#107-referring-to-code)).

**Position matters.** rak reads your text from left to right, and a word only becomes a
routine call once rak has seen the routine's `sub`. Before that, it is a naked string:

```
> say triple; sub triple { 3 }
triple
> say triple
3
```

On the first line, `triple` is printed as text, because the `sub` comes later on the
line. On the second, `triple` is known, so it is called. In irak, where you usually
declare a routine on one line and use it on the next, this rarely matters. In a script
it does: declare routines before you call them without parentheses, or call them with
parentheses, `triple()`, which always works.

### 4.5 True, false, and comparisons

Comparisons give one of two values, `True` or `False`. Numbers and strings use different
operators:

| Numbers | Strings | Means |
|---|---|---|
| `==` | `eq` | equal |
| `!=` | `ne` | not equal |
| `<` | `lt` | less than (for strings: before, in alphabetical order) |
| `>` | `gt` | greater than |
| `<=` | `le` | less or equal |
| `>=` | `ge` | greater or equal |

```
> 3 == 3.0
True
> 'apple' lt 'banana'
True
> 10 < 9
False
```

Why two sets? Because `'10'` and `'9'` compare differently as numbers and as text:

```
> '10' < '9'
False
> '10' lt '9'
True
```

As numbers, 10 is bigger. As text, `1` comes before `9`, like `apple` before `banana`.
The operator tells rak which comparison you mean.

`if` runs a block of code only when a condition is true. A **block** is code between
braces `{ }`:

```
> if 3 > 2 { say yes } else { say no }
yes
```

`and`, `or` and `not` combine conditions:

```
> 3 > 2 and 'a' lt 'b'
True
> not 3 > 2
False
```

### 4.6 Several words in a row

When words follow a routine, each word is a separate argument, as in a shell. Here is a
routine that counts its arguments (`*@a` collects them all; `->elems` counts them):

```
> sub count(*@a) { @a->elems }
&count
> count apples pears plums
3
```

Commas work as well, and mix in:

```
> count apples, pears plums
3
> count (1 + 3) things
2
```

The parenthesised `(1 + 3)` is computed first and passed as one argument, `4`.

This also explains what you saw in [chapter 1](#13-your-first-submission):
`say hello world` gives `say` two arguments, and `say` prints its arguments one after
the other, without spaces. To print a space, it must be part of a string:
`say 'hello world'`, or `say hello, ' ', world`.

### Recap

- Every submission has a value, and every value a type: `Int`, `Str`, `Rat`, …
- `->name` calls a method with no arguments. `.name(…)` calls one with arguments.
- Arithmetic is exact. Space your operators. Write `0.5`, not `.5`.
- A naked string is an unquoted word that rak does not already know. Quote text with
  spaces or symbols. Double quotes interpolate `$name` and `{code}`; single quotes don't.
- A word that names a routine calls it; the words after it are its arguments.
- Numbers compare with `==` `<` `>`, strings with `eq` `lt` `gt`.

### Exercises

1. What are the values of `17 div 5`, `17 % 5` and `17 / 5`?
   <details><summary>Answer</summary>

   `3`, `2` and `3.4`.
   </details>

2. Print `I am 36 years old` using a variable `$age` holding `36`.
   <details><summary>Answer</summary>

   ```
   > my $age = 36
   36
   > say "I am $age years old"
   I am 36 years old
   ```
   </details>

3. Write a routine `shout` that turns its argument to capitals and adds `!`. Then call it
   with the naked string `hey`.
   <details><summary>Answer</summary>

   ```
   > sub shout($s) { uc($s) ~ '!' }
   &shout
   > shout hey
   HEY!
   ```
   </details>

4. Why does `'Zebra' lt 'apple'` give `True`?
   <details><summary>Answer</summary>

   Strings compare character by character, by their code in the character table, where
   all capitals come before all small letters. `Z` comes before `a`. Compare
   `'Zebra'->lc lt 'apple'` to ignore case.
   </details>

---

## 5. Commands

### 5.1 Lines that run programs

[Chapter 3](#3-processes) showed irak running external programs: `ls`, `sleep`, `ps`.
[Chapter 4](#4-values-words-and-strings) showed irak computing values: `2 + 2`,
`uc hello`. Both are the same thing to irak: a **command**. A command is a line whose
first word names something to run, followed by its arguments:

```
> echo hello world
hello world
> say hello world
helloworld
```

`echo` is an external command, a program on disk, found through `PATH`. It prints its
arguments separated by spaces. `say` is a rak routine, run inside irak with no new
process. They look alike on the line, and irak treats them alike: the first word chooses
what runs, and the following words are its arguments.

A single word on a line also runs a command, if that word names a program on `PATH`:

```
> ls
a  in.txt
> date
Fri Nov 20 10:14:02 CET 2026
```

This only applies to a word alone on its line. Elsewhere, `ls` is a naked string:

```
> my $x = ls
ls
```

### 5.2 Arguments

Arguments are separated by spaces, as in any shell. Quotes group words with spaces into
one argument:

```
> touch 'my file.txt'
> ls -l 'my file.txt'
-rw-r--r-- 1 ada ada 0 Nov 20 10:15 my file.txt
```

Variables are replaced by their value, and stay one argument even when the value
contains spaces:

```
> my $f = 'my file.txt'
my file.txt
> ls $f
my file.txt
```

A list variable gives one argument per element (lists are the subject of
[chapter 8](#8-complex-data-structures)):

```
> my @files = 'a.txt', 'b.txt'
[a.txt b.txt]
> touch @files
> ls @files
a.txt  b.txt
```

Code in braces runs, and its value becomes an argument:

```
> echo {6 * 7} answers
42 answers
```

A word that starts with `/` is a path, even when it looks odd: `ls /usr/bin`,
`cat /etc/hostname`. A word that starts with `m/` is a pattern (a *regex*, which this
tutorial does not cover), so a relative path whose first directory is `m` is written
`./m/…`.

Options are just arguments that start with `-`. Each program decides what its options
mean, and documents them in its **manual page**, which `man` shows:

```
> man ls
```

(`q` quits `man`, as it quits `less`.)

### 5.3 Who wins a name

A name can mean several things at once. `sort` is a rak routine *and* a program in
`/usr/bin`. `type` lists every meaning, in order:

```
> type sort
sort is a rak routine
sort is /usr/bin/sort
```

The first line is the one that wins. The rule is: **rak names win over external
commands**. Your own routines, rak's routines and irak's builtins all come before any
program on `PATH`.

To get the external program anyway, put `^` in front of its name:

```
> ^sort names.txt
```

`^sort` always runs `/usr/bin/sort`, whatever rak calls `sort`.

`type` can also tell you about builtins and your own routines:

```
> type cd
cd is a shell builtin
> sub greet { say hi }
&greet
> type greet
greet is a rak routine
```

### 5.4 Using a command's output as a value

At the start of a line, an external command writes straight to your terminal. When you
use its result instead, as part of something bigger, irak captures what it would have
printed and gives it to you as a string. Put the command in parentheses:

```
> my $listing = (ls)
a.txt
b.txt
my file.txt
> $listing->lines->elems
3
```

`->lines` splits a string into lines, and `->elems` counts them: there are three files.
The same idea, written in one go:

```
> (ls)->lines->elems
3
```

A `~` in front of the parentheses asks for the string explicitly:

```
> say "I am in " ~ ~(pwd)
I am in /home/ada/irak-tutorial
```

(The captured output ends with a line break, as `pwd` printed one. `->trim` removes
spaces and line breaks at both ends when they get in the way.)

### 5.5 Exit status, in practice

[Chapter 3](#35-how-a-process-ends) introduced exit statuses. irak shows a dimmed
`exit N` after any external command that fails, and keeps the status in `$?`:

```
> grep zebra a.txt
exit 1
> $? == 0
False
> $?->exitcode
1
```

`grep` searches files for a word. Like many programs, it uses its exit code to answer a
question: `0` for "found", `1` for "not found", `2` for "something went wrong". So you
can use it in an `if`:

```
> grep -q hello notes.txt; if $? == 0 { say found } else { say 'not found' }
found
```

(`-q` makes `grep` quiet: it prints nothing and only sets its exit status. The `;`
separates two statements on one line.)

A rak routine run as a command does not change `$?`; only external commands do.

### 5.6 Command redirections

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** Redirecting an *external command* (`ls >listing.txt`,
> `^sort <fruit.txt`, `ls nothing 2>err.txt`) currently stops with an error such as
> `Type check failed in assignment to $out`. Redirecting rak statements, as in
> [chapter 11](#11-redirection-and-formats), works.

Every external command has the three standard streams of [chapter 3](#32-what-every-process-carries).
By default, all three are connected to your terminal. A **redirection** connects one of
them to a file instead. It is written as an arrow *touching* the file name:

| Written | Does |
|---|---|
| `cmd >file` | standard output goes to `file`, which is emptied first |
| `cmd >>file` | standard output is added to the end of `file` |
| `cmd <file` | standard input is read from `file` |
| `cmd 2>file` | standard error goes to `file` |
| `cmd 2>&1` | standard error goes wherever standard output goes |

```
> ls >listing.txt
> cat listing.txt
a.txt
b.txt
listing.txt
my file.txt
> date >>listing.txt
> date >>listing.txt
> cat listing.txt
a.txt
b.txt
listing.txt
my file.txt
Fri Nov 20 10:21:40 CET 2026
Fri Nov 20 10:21:43 CET 2026
```

`ls` itself shows up in the listing: irak created `listing.txt` before running `ls`.

Standard error is kept apart from standard output for a reason: so that error messages
stay visible when the results go to a file.

```
> ls a.txt nothing >out.txt
ls: cannot access 'nothing': No such file or directory
exit 2
> cat out.txt
a.txt
```

The result went into the file, the error came to your screen. Now send the errors to
their own file:

```
> ls a.txt nothing >out.txt 2>err.txt
exit 2
> cat err.txt
ls: cannot access 'nothing': No such file or directory
```

And to keep everything together, send errors where the output goes. Order matters: first
send output to the file, then errors to where output now goes:

```
> ls a.txt nothing >all.txt 2>&1
exit 2
> cat all.txt
ls: cannot access 'nothing': No such file or directory
a.txt
```

Input redirection feeds a file to a program that reads its standard input. `sort` (the
external one) sorts the lines it reads:

```
> printf "pear\napple\nplum\n" >fruit.txt
> ^sort <fruit.txt
apple
pear
plum
```

**The arrow must touch the file name.** `>out.txt` is a redirection. `> out.txt`, with a
space, is the "greater than" comparison of [chapter 4](#45-true-false-and-comparisons),
which makes no sense after a command, so irak refuses it and tells you how to fix it:

```
> ls > out.txt
===SORRY!=== Error while compiling
A redirection is written touching its target: use >target
```

The same arrows also work on rak statements, not just external commands, and on rak
values, not just text. [Chapter 11](#11-redirection-and-formats) shows what that adds.

### Recap

- A command is a line whose first word names what to run: a rak routine, a builtin, or
  an external program. A lone word that names a program on `PATH` runs it.
- Arguments are separated by spaces. Quotes group. `$var` is one argument, `@list` one
  per element, `{code}` its value.
- rak names win over programs. `type name` lists all meanings, winner first. `^name`
  forces the program.
- `(cmd)` captures a command's output as a string.
- `$?` holds the last exit status; irak shows `exit N` on failure.
- `>file`, `>>file`, `<file`, `2>file`, `2>&1` redirect the streams. The arrow touches
  the name.

### Exercises

1. Save the list of files in `/usr/bin` into `bin.txt`, then count them with rak.
   <details><summary>Answer</summary>

   ```
   > ls /usr/bin >bin.txt
   > (cat bin.txt)->lines->elems
   2417
   ```
   Your number will differ. `(ls /usr/bin)->lines->elems` gives the same count without
   a file.
   </details>

2. What does `type echo` print on your machine? Which `echo` runs when you type
   `echo hi`?
   <details><summary>Answer</summary>

   Something like `echo is /usr/bin/echo`. If rak defines no `echo`, that program runs.
   If one day you write `sub echo { … }`, `type echo` lists your routine first, and
   it wins; `^echo hi` would still run the program.
   </details>

3. Run `ls nothing`, sending the error message to `oops.txt`. Is anything shown on your
   screen?
   <details><summary>Answer</summary>

   ```
   > ls nothing 2>oops.txt
   exit 2
   ```
   Only irak's `exit 2` note. The message itself is in `oops.txt`.
   </details>

4. Why does `my $x = ls` not list files?
   <details><summary>Answer</summary>

   A word runs a program only when it is a command: the first word of a line. After
   `my $x =`, `ls` is a naked string. Write `my $x = (ls)` to capture the listing.
   </details>

---

## 6. The topic and history

### 6.1 The topic: each answer feeds the next

A conversation builds on what was just said. irak does the same: the value of each
submission is kept in a special variable called `$_`, the **topic**, and the next
submission can use it.

```
[0] > 6 * 7
42
[1] > $_ + 1
43
[2] > $_ * 2
86
```

Line 1 used the 42 from line 0. Line 2 used the 43 from line 1. The topic is also used
when you call a method with nothing in front of the arrow:

```
[3] > 'irak'
irak
[4] > ->uc
IRAK
[5] > ->chars
4
```

`->uc` alone means "`->uc` on the topic". This is how you explore something step by
step: produce a value, look at it, take the next step from there. You will use this a
lot when walking data in [chapter 9](#93-walking-from-the-topic).

The name `$_` is pronounced "the topic", or "dollar underscore". It is called the topic
because, as in a conversation, it is what you are talking about right now.

### 6.2 What leaves the topic alone

Not every submission has a value worth keeping. Three kinds leave `$_` as it was:

1. **A submission that fails.** A typing mistake does not wipe out your work.
2. **A submission whose value is `Nil`**, rak's "nothing here" value.
3. **A submission that prints something.** `say`, or an external command writing to the
   terminal, has already shown you its result; its value is not interesting.

```
[6] > 100
100
[7] > say 'just a remark'
just a remark
[8] > ls
a.txt  b.txt
[9] > 1 +
===SORRY!=== Error while compiling
Missing required term after infix
------> 1 +⏏<EOL>
[10] > $_
100
```

The topic is still the `100` of submission 6. In practice: printing, listing files and
making mistakes never lose the value you were working on.

### 6.3 Recalling earlier submissions

irak numbers your submissions and remembers the last 1000. Four ways bring one back:

| You type | irak does |
|---|---|
| ↑ and ↓ | step back and forth through earlier submissions, one at a time |
| `!n` then ENTER | runs submission number `n` again |
| `!n` then TAB | puts the text of submission `n` on the line, for you to edit |
| `!!n` then ENTER | sets the topic `$_` back to the *value* of submission `n`, without running it again |

`!n` and `!!n` only work when they are the whole line.

```
[11] > 2 ** 16
65536
[12] > 'something else'
something else
[13] > !!11
65536
[14] > $_ - 1
65535
```

`!!11` brought back the value of submission 11, so submission 14 could continue from
it. The difference between `!11` and `!!11` matters when the submission did something:
`!11` would do it again (create the file again, fetch the web page again), while `!!11`
reuses the value it produced the first time.

The arrow keys stop at the oldest and newest submissions. To change a long submission,
recall it with `!n` TAB, edit it, and press ENTER: it runs as a new submission, with a
new number.

### Recap

- The topic `$_` holds the value of the previous submission.
- A leading `->method` (and, in [chapter 9](#93-walking-from-the-topic), a leading
  `.`) works on the topic.
- Failures, `Nil`, and printing submissions leave the topic unchanged.
- ↑ ↓, `!n` (run again), `!n` TAB (edit), `!!n` (reuse the value) recall submissions.

### Exercises

1. Starting from `'banana'`, use the topic to get its length, then that length
   doubled, in three submissions.
   <details><summary>Answer</summary>

   ```
   > 'banana'
   banana
   > ->chars
   6
   > $_ * 2
   12
   ```
   </details>

2. You computed a value in submission 3, then ran `ls` and `say hi`. What is `$_` now?
   <details><summary>Answer</summary>

   Still the value of submission 3: `ls` and `say` printed output, so they left the
   topic alone.
   </details>

3. Submission 5 was `date >>log.txt`. What is the difference between typing `!5` and
   `!!5`?
   <details><summary>Answer</summary>

   `!5` runs `date >>log.txt` again and adds a second line to `log.txt`. `!!5` sets the
   topic to the value submission 5 had, and does not touch `log.txt`.
   </details>

---

# Part III: Data

So far, values have been single things: a number, a word. Real data comes in
collections: a list of files, a person with a name and an age, a team of people each
with their projects. Part III shows how rak holds such data, how you find your way
around inside it, and how two names can refer to the same piece of it.

## 7. Variables and sigils

### 7.1 Naming a value

The topic `$_` keeps your last value, but only the last one. To keep a value around for
longer, give it a name. A named place that holds a value is a **variable**:

```
> my $city = 'Lyon'
Lyon
> say "I live in $city"
I live in Lyon
```

`my` **declares** the variable: it tells rak that from now on, `$city` is a name you
use. `=` **assigns** a value to it: it puts `'Lyon'` in. You can assign a new value
later, without `my`:

```
> $city = 'Nantes'
Nantes
> $city
Nantes
```

Declare a variable once, with `my`, then use it as often as you like. Using a variable
you never declared is an error, which protects you from typos:

```
> say $ctiy
===SORRY!=== Error while compiling
Variable '$ctiy' is not declared.  Did you mean '$city'?
```

A variable name starts with a symbol, here `$`, followed by letters, digits, `_` or
`-`: `$city`, `$file-count`, `$max_size`, `$x2`.

### 7.2 Sigils: the label on the box

The symbol at the start of a variable's name is its **sigil**. Think of a variable as a
box with a name written on it. The sigil is a picture on the label, telling you what
kind of box it is before you open it.

rak has four sigils that it shares with Raku, the language it is built on:

| Sigil | Reads as | Holds | Example |
|---|---|---|---|
| `$` | "the" | **one thing** (a scalar) | `$city`, `$count` |
| `@` | "these" | **an ordered list** of things (an array) | `@files`, `@scores` |
| `%` | "this table" | **named entries**: keys and their values (a hash) | `%person`, `%*ENV` |
| `&` | "do" | **a piece of code** (a routine) | `&double`, `&say` |

The `$` looks like the S of "scalar" (single). The `@` looks like the a of "array". The
`%` shows two little circles with a slash between them, like a key and its value. You
will meet `@` and `%` properly in [chapter 8](#8-complex-data-structures).

```
> my @fruit = 'apple', 'pear', 'plum'
[apple pear plum]
> my %person = name => 'Ada', age => 36
{age => 36, name => Ada}
```

The sigil also changes what assignment does. Assigning several values to an `@`
variable keeps them all. Assigning them to a `$` variable stores them as one thing, a
single list; [chapter 10](#105-boxes-inside-boxes-itemization) explains the difference.

You have also seen variables with a second symbol after the sigil: `$*CWD`, `%*ENV`,
`$*PID`. The `*` marks a **dynamic variable**, one that rak provides and that describes
the situation you are running in: the current directory, the environment, the process
ID. You read them like any variable.

### 7.3 rak's own sigils: `~` and `#`

rak adds two sigils of its own, for the two kinds of value people use most often:

| Sigil | Holds | Default | Example |
|---|---|---|---|
| `~` | one piece of text (a native string) | `""` (empty) | `~name`, `~path` |
| `#` | one whole number (a native integer) | `0` | `#count`, `#i` |

The `~` echoes the `~` that joins strings. The `#` is the "number sign".

```
> my ~greeting = 'hello'
hello
> my #count = 3
3
> #count = #count + 1
4
> say "~greeting, I counted #count"
hello, I counted 4
```

They interpolate in double quotes like `$` variables.

What does **native** mean? A `$` variable is a box that can hold anything: a number now,
a string later, a list after that. To make that possible, rak keeps, behind the scenes,
a small container that points to the value. Each read follows the pointer, and each new
number is a new object in memory. That is flexible, and slow when you repeat it a
million times.

A `~` or `#` variable holds the raw value directly, the way the processor itself stores
text and numbers. There is no container to follow and nothing extra to create. That makes
them faster, and it makes them strict:

```
> my #n = 2.7
===SORRY!=== Error while compiling
Cannot assign a literal of type Rat (2.7) to a native variable (#n) of type int.
> my #n = 'abc'
This type cannot unbox to a native integer: P6opaque, Str
```

A `#` variable holds whole numbers, and nothing else. A `~` variable holds text, and
nothing else. The sigil *is* the type, so you cannot add another type to it:
`my Str ~s` is an error.

Their other purpose, the reason they were added, is to make walking data short to
write. You will see why in [chapter 9](#94-steps-held-in-variables).

### 7.4 Choosing a sigil

| You want to keep… | Use |
|---|---|
| a word, a name, a line of text | `~` |
| a count, a position, an index | `#` |
| a fraction, a date, a path, or "anything" | `$` |
| a value that may be missing (undefined) | `$` |
| several values in order | `@` |
| values looked up by name | `%` |
| a routine, to pass around | `&` |

When unsure, `$` always works. Use `~` and `#` when you know the value is text or a
whole number, which is most of the time.

### 7.5 Missing values

A `$` variable declared without a value is **undefined**: the box is empty.

```
> my $later
(Any)
> $later->defined
False
```

`(Any)` is how irak shows an empty `$` box. `->defined` asks whether there is a value.
The operator `//` ("defined-or") gives a replacement when there is none:

```
> $later // 'nothing yet'
nothing yet
> $later = 5
5
> $later // 'nothing yet'
5
```

You will use `//` a lot when data may be incomplete ([9.9](#99-missing-paths)).

A related value is `Nil`, which means "no value here". A routine that finds nothing
returns `Nil`, and assigning `Nil` to a `$` variable empties it.

`~` and `#` variables are never undefined. Without a value, they hold their default:

```
> my ~empty
> my #zero
0
```

(`my ~empty` shows an empty line: the empty string.) Empty lists and hashes are shown as
`[]` and `{}`.

### 7.6 Types and comments

Every variable's value has a type, and `->WHAT` shows it:

```
> $city->WHAT
(Str)
> @fruit->WHAT
(Array)
> %person->WHAT
(Hash)
> $*CWD->WHAT
(Path)
```

A word about `#`. Before rak, `#` only started comments. It still does, as long as a
space or a symbol follows it:

```
> 1 + 1   # this is a comment
2
> say #count    # this is the variable #count, then a comment
4
```

`#count`, with a letter right after the `#`, is the variable. To start a comment, put a
space after the `#`. An undeclared `#oops` is an error, so a missing space is noticed at
once.

### 7.7 Scope: where a name is valid

A **block**, code between braces `{ }`, is a little world of its own. A variable
declared inside a block only exists inside it:

```
> my $y = 3
3
> { my $y = 4; say $y }
4
> $y
3
```

The inner `$y` is a different variable that hides the outer one until the block ends.
The part of the code where a name is valid is its **scope**. In irak, each submission
sees the variables declared by the earlier ones, at the top level.

### Recap

- `my` declares a variable. `=` assigns a value.
- The sigil says what kind of box: `$` one thing, `@` a list, `%` named entries, `&`
  code. `*` after the sigil marks a variable rak provides (`$*CWD`, `%*ENV`).
- rak's `~` (text) and `#` (whole number) are native: fast, strict, never undefined.
- `->defined` and `//` deal with missing values.
- `#name` is a variable; `# ` with a space starts a comment.
- A variable declared in a block exists only in that block.

### Exercises

1. Declare `#width` as 12 and `#height` as 5, and print `area: 60` using them.
   <details><summary>Answer</summary>

   ```
   > my #width = 12
   12
   > my #height = 5
   5
   > say "area: {#width * #height}"
   area: 60
   ```
   </details>

2. Which sigil would you use for: a file name; the number of lines in a file; the
   price of a coffee; the list of your friends; your friends' phone numbers?
   <details><summary>Answer</summary>

   `~` for the file name, `#` for the line count, `$` for the price (it has a fractional
   part), `@` for the list of friends, `%` for the phone numbers, looked up by name.
   </details>

3. What does `my $x; say $x // 'empty'` print? And `my #x; say #x // 'empty'`?
   <details><summary>Answer</summary>

   `empty`, then `0`: `#x` is never undefined, so `//` keeps its value.
   </details>

---

## 8. Complex data structures

### 8.1 Arrays

An **array** is an ordered list of values. Write the values separated by commas:

```
> my @scores = 12, 7, 30
[12 7 30]
```

The values are **elements**. Each one has a **position**, also called its **index**,
counted from **0**: `12` is at position 0, `7` at 1, `30` at 2. Counting from zero
feels odd at first; think of the index as "how many steps from the start".

Arrays know things about themselves:

```
> @scores->elems        # how many elements
3
> @scores->end          # the last index
2
> @scores->sum
49
> @scores->sort
(7 12 30)
> @scores->max
30
```

They can grow and shrink at the end:

```
> @scores.push(25)
[12 7 30 25]
> @scores->pop
25
> @scores
[12 7 30]
```

`push` adds an element at the end (it needs to know *what* to add, so it takes
parentheses). `pop` removes the last element and gives it back. `unshift` and `shift`
do the same at the start.

For a list of words, `<…>` saves the commas and quotes:

```
> my @days = <mon tue wed thu fri>
[mon tue wed thu fri]
```

Square brackets also make an array, as a value of its own, without a variable:

```
> [1, 2, 3]->elems
3
```

### 8.2 Hashes

A **hash** is a table of **keys** and **values**. Each key is a name, and leads to one
value. Write each entry as `key => value`:

```
> my %phone = Ada => '555-0101', Bo => '555-0123'
{Ada => 555-0101, Bo => 555-0123}
```

A hash has no order of its own. irak shows its keys in alphabetical order, to make them
easy to find, but rak may hand them to you in any order. When the order matters, sort
the keys:

```
> %phone->keys->sort
(Ada Bo)
> %phone->values
(555-0101 555-0123)
> %phone->elems
2
```

Each key appears once. Assigning to an existing key replaces its value; assigning to a
new key adds an entry:

```
> %phone.Cy = '555-0199'
555-0199
> %phone->elems
3
```

(`%phone.Cy` means "the entry `Cy` of `%phone`"; [chapter 9](#9-walking-data-structures)
is about this dot.)

Braces make a hash as a value of its own:

```
> { a => 1, b => 2 }->keys->sort
(a b)
```

### 8.3 Nesting

Here is the powerful part: an element of an array, or a value in a hash, can itself be
an array or a hash. Data that fits the real world is usually **nested**:

- a person is a hash: name, age, role;
- a person's projects are an array of hashes: each project has a name and tags;
- a project's tags are an array of strings;
- a team is a hash with a name and an array of people.

Draw it as a tree, like the file tree of [chapter 2](#21-the-tree):

```
team (hash)
├── name: "Orbit"
└── people (array)
    ├── 0 (hash)
    │   ├── name: "Ada"
    │   ├── age: 36
    │   ├── role: "lead"
    │   └── projects (array)
    │       ├── 0 (hash)
    │       │   ├── name: "rak"
    │       │   ├── stars: 120
    │       │   └── tags (array): "lang", "shell"
    │       └── 1 (hash)
    │           ├── name: "irak"
    │           ├── stars: 45
    │           └── tags (array): "repl", "shell"
    ├── 1 (hash)
    │   ├── name: "Bo"  …
    └── 2 (hash)
        ├── name: "Cy"  …
```

Keys in hashes, positions in arrays: each step down the tree is either a name or a
number. Keep this picture in mind; the next chapter is about moving around in it.

### 8.4 Building `team.json`

Type this in irak. It is long, but irak waits as long as a bracket is open, so you can
spread it over several lines, as shown. The `...` continuation prompt appears by itself.

```
> my %team =
...     name   => 'Orbit',
...     people => [
...         { name => 'Ada', age => 36, role => 'lead',
...           projects => [ { name => 'rak',  tags => ['lang', 'shell'], stars => 120 },
...                         { name => 'irak', tags => ['repl', 'shell'], stars => 45 } ] },
...         { name => 'Bo', age => 29, role => 'dev', manager => 'Ada',
...           projects => [ { name => 'myaml', tags => ['data', 'yaml'], stars => 12 }, ] },
...         { name => 'Cy', age => 41, role => 'ops', manager => 'Ada', projects => [] },
...     ];
```

irak shows the result on one long line. Before reading it, two details of what you
typed.

**The trailing comma in Bo's projects.** Look at `[ { name => 'myaml', … }, ]`. The comma
before `]` is not a typo. When square brackets contain exactly one thing and no comma,
rak *opens* that thing and puts its contents in the array: a single hash becomes a list
of its entries, and you get an array of key-value pairs instead of an array holding one
hash. The comma says "this is a list of one element". The rule: **an array with a single
hash inside needs a trailing comma.** Ada's projects have two hashes separated by a
comma, so they don't need one. Cy's projects are `[]`, empty.

**Word lists inside brackets.** `<lang shell>` would be shorter than `['lang', 'shell']`,
but rak does not accept `<…>` word lists inside brackets. Use quotes there.

### 8.5 Reading irak's printout

irak shows `%team` like this (wrapped here to fit):

```
{name => Orbit, people => [{age => 36, name => Ada, projects => [{name => rak,
stars => 120, tags => [lang shell]} {name => irak, stars => 45, tags => [repl
shell]}], role => lead} {age => 29, manager => Ada, name => Bo, projects =>
[{name => myaml, stars => 12, tags => [data yaml]}], role => dev} {age => 41,
manager => Ada, name => Cy, projects => [], role => ops}]}
```

To read it, match the brackets: `{ }` around a hash, `[ ]` around an array. Inside a
hash, `key => value`; inside an array, the elements, separated by spaces. Strings are
shown without quotes.

That is hard to read for anything bigger. Saving the data as JSON
([8.6](#86-saving-and-loading-a-teaser)) and looking at the file gives a much clearer
picture, one value per line, indented by depth. The [next chapter](#9-walking-data-structures)
shows how to look at one part at a time, which is what you will usually do.

### 8.6 Saving and loading: a teaser

Save the team to a file:

```
> %team >team.json
> cat team.json
{
  "name": "Orbit",
  "people": [
    {
      "age": 36,
      "name": "Ada",
      "projects": [
        {
          "name": "rak",
          "stars": 120,
          "tags": [
            "lang",
            "shell"
          ]
        },
…
```

`>team.json` sends the value of `%team` into the file `team.json`. Because the name
ends in `.json`, rak writes the value in the **JSON** format. Load it back, into a new
variable:

```
> my %copy <team.json
> %copy.people.1.name
Bo
```

`<team.json` reads the file and decodes it back into hashes and arrays. You now have a
data file to experiment with: if you break `%team`, reload it. From now on, the tutorial
assumes `%team` is loaded:

```
> my %team <team.json
```

[Chapter 11](#11-redirection-and-formats) explains `>` and `<` in full.

### 8.7 JSON, the common language of data

**JSON** (JavaScript Object Notation, pronounced "Jason") is a text format for nested
data. Nearly every program, language and web service can read and write it, which is why
rak chose it as its first data format. It has:

| JSON | rak |
|---|---|
| `{ "key": value, … }` (an object) | a hash |
| `[ value, … ]` (an array) | an array |
| `"text"` | a string |
| `42`, `3.14` | a number |
| `true`, `false` | `True`, `False` |
| `null` | an undefined value |

That is all. Some rak values have no JSON form: a set, infinity (`Inf`), a date, a
routine. Saving one of them fails with an error that names the culprit, and leaves the
file untouched ([11.6](#116-when-a-format-fails)). Turn such values into strings or
numbers first.

### Recap

- An array (`@`) is an ordered list. Positions count from 0. `->elems`, `.push(…)`,
  `->pop`, `->sort`, `->sum`.
- A hash (`%`) maps keys to values. It has no order; sort its keys when order matters.
- Arrays and hashes nest. Draw the tree: each step down is a key or a position.
- `[ { … }, ]`: one hash alone in brackets needs a trailing comma.
- `%team >team.json` saves as JSON; `my %team <team.json` loads.

### Exercises

1. Make an array of the first five square numbers (1, 4, 9, 16, 25), then compute their
   sum and their largest value.
   <details><summary>Answer</summary>

   ```
   > my @sq = 1, 4, 9, 16, 25
   [1 4 9 16 25]
   > @sq->sum
   55
   > @sq->max
   25
   ```
   </details>

2. Make a hash `%capital` from three countries to their capitals, and add a fourth.
   <details><summary>Answer</summary>

   ```
   > my %capital = France => 'Paris', Japan => 'Tokyo', Peru => 'Lima'
   {France => Paris, Japan => Tokyo, Peru => Lima}
   > %capital.Kenya = 'Nairobi'
   Nairobi
   ```
   </details>

3. What goes wrong with `my @a = [ { x => 1, y => 2 } ]`? Check with `@a->elems`.
   <details><summary>Answer</summary>

   Without a trailing comma, the single hash is opened: `@a` holds two pairs,
   `x => 1` and `y => 2`, so `@a->elems` is 2. With `[ { x => 1, y => 2 }, ]` it holds
   one hash, and `->elems` is 1.
   </details>

4. Draw the tree of `{ title => 'Notes', pages => [ { n => 1 }, { n => 2 } ] }`.
   <details><summary>Answer</summary>

   ```
   (hash)
   ├── title: "Notes"
   └── pages (array)
       ├── 0 (hash)
       │   └── n: 1
       └── 1 (hash)
           └── n: 2
   ```
   </details>

---

## 9. Walking data structures

### 9.1 One step at a time

To reach inside a hash or an array, write a dot followed by the step: a key for a hash,
a position for an array. This is a **dotty subscript**. ("Subscript" is the
programmer's word for "the thing that says which element".)

```
> %team.name
Orbit
> %team.people
[{age => 36, …} {age => 29, …} {age => 41, …}]
> my @people = %team.people->list
> @people.0
{age => 36, name => Ada, projects => [...], role => lead}
```

(Long values are shortened with `…` in this tutorial. The `->list` makes `@people` hold the
three people, rather than one array of three people; [9.6](#96-visiting-every-element)
says more.)

`%team.name` is the value under the key `name`. `@people.0` is the element at position
0. A step that is a word is a key; a step that is a number is a position.

When a key is not a plain word, quote it:

```
> my %odd = 'first name' => 'Ada', '2024' => 'leap'
{2024 => leap, first name => Ada}
> %odd.'first name'
Ada
> %odd.'2024'
leap
```

Without the quotes, `%odd.2024` would ask for *position* 2024, and `%odd` is a hash, not
an array: rak answers `Index out of range`. Double quotes interpolate, so a key held in a `$` variable works too:

```
> my $which = 'first name'
first name
> %odd."$which"
Ada
```

### 9.2 Paths

Steps chain. Each one starts from where the previous one arrived:

```
> %team.people.0.name
Ada
> %team.people.0.projects.1.name
irak
> %team.people.0.projects.1.tags.0
repl
```

Read `%team.people.0.projects.1.tags.0` from left to right, following the tree of
[8.3](#83-nesting): start at the team; take its people; take the first person; take her
projects; take the second project; take its tags; take the first tag. Such a chain of
steps is a **path**, just as `/home/ada/photos` is a path in the file tree, with `.`
instead of `/`.

If you know the program **jq**, a popular tool for JSON, this will look familiar: jq
writes the same path `.people[0].projects[1].tags[0]`.

Paths work for changing data too. Assign to a path to change the value at its end:

```
> %team.people.0.age = 36
37
> %team.people.0.age
37
```

Assigning to a key that does not exist yet adds it:

```
> %team.people.2.projects.0 = { name => 'deploy', stars => 3, tags => ['ops'] }
{name => deploy, stars => 3, tags => [ops]}
```

Cy has a project now. To undo your experiments, reload the file. Do it now, so that the
rest of the chapter shows the same results as your screen:

```
> my %team <team.json
```

### 9.3 Walking from the topic

In irak, you rarely type a whole path at once. You take one step, look at the result,
and take the next step from there. A dotty subscript with nothing in front of it starts
from the topic `$_`, the value of the previous submission ([chapter 6](#6-the-topic-and-history)):

```
[0] > %team
{name => Orbit, people => […]}
[1] > .people
[{…} {…} {…}]
[2] > .1
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
[3] > .projects
[{name => myaml, stars => 12, tags => [data yaml]}]
[4] > .0.tags
[data yaml]
[5] > ->elems
2
```

This is exploring data by conversation: each answer shows you what the next question
can be. When you take a wrong turn, `!!n` ([6.3](#63-recalling-earlier-submissions))
brings back the value of an earlier step:

```
[6] > !!2
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
[7] > .age
29
```

You can also load a file straight into the topic: `<team.json` alone, with nothing on
its left, reads the file and makes it the topic.

```
[8] > <team.json
[9] > .people.2.role
ops
```

> **This is why `.5` is not one half.** A dot followed by a number subscripts the topic:
> `.5` is position 5 of `$_`. Write `0.5` for the number.

### 9.4 Steps held in variables

Often the step itself is in a variable: you loop over positions, or the user typed a
key. With `$` variables, you would write `."$key"`, with quotes, as in 9.1. With rak's
own sigils, it is simpler: a dot followed by a `~` variable uses its text as a key, and
a dot followed by a `#` variable uses its number as a position.

```
> my ~field = 'role'
role
> my #who = 2
2
> %team.people.#who.~field
ops
```

This is the main reason the `~` and `#` sigils exist: the sigil tells rak, as it reads
your line, whether a step is a key or a position, without brackets or quotes.

A `$` variable directly after the dot is an error, because rak would not know which kind
of step it is:

```
> %team.$key
===SORRY!=== Error while compiling
In rak, '.$key' is not an indirect method call: use '->$key' to call it, or '."$key"' to subscript by it
```

### 9.5 Subscripts and methods

You have now seen three things that follow a value:

| Written | Means | Example |
|---|---|---|
| `.word` | the entry named `word` (a subscript) | `%team.name` |
| `->word` | ask the value to do `word` (a method, no arguments) | `%team->elems` |
| `.word(…)` | ask the value to do `word` with arguments | `@scores.push(25)` |

The difference between the first two matters as soon as a key and a method share a
name. A hash knows how to give its `keys`, but it may also *have* an entry called
`keys`:

```
> my %h = keys => 'under the mat', door => 'red'
{door => red, keys => under the mat}
> %h.keys
under the mat
> %h->keys
(door keys)
```

`.keys` reads the data; `->keys` asks the hash. The rule is simple: **a dot reads
data, an arrow asks the value.** Empty parentheses also call a method: `%h.keys()` is the
same as `%h->keys`.

Methods and subscripts chain freely:

```
> %team.people.0.projects->elems
2
> %team.people->elems
3
> %team.people.0->keys->sort
(age name projects role)
```

### 9.6 Visiting every element

A **loop** repeats a block for each element of a list. `for` sets the topic `$_` to each
element in turn, so the dot inside the block reads from the current element:

```
> for %team.people->list { say .name }
Ada
Bo
Cy
```

Why `->list`? Because the array of people sits *inside* the hash `%team`, in a box of
its own, and `for` would otherwise loop once, over the box. `->list` opens the box and
gives the elements. [Chapter 10](#105-boxes-inside-boxes-itemization) explains these
boxes. For now, remember: **to loop over an array taken from inside a structure, add
`->list`.** An `@` variable does not need it: `for @people { say .name }` works.

To name the element instead of using the topic, write `->` and a variable after the
list. This is a **pointy block**:

```
> for %team.people->list -> %person { say %person.name, ': ', %person.age }
Ada: 36
Bo: 29
Cy: 41
```

A hash can be walked by its keys, by its values, or by both. `->kv` gives keys and
values alternately, and a pointy block can take two at a time:

```
> my %p = %team.people.1
> for %p->keys->sort -> ~k { say ~k }
age
manager
name
projects
role
> for %p->kv -> $k, $v { say "$k: $v" if $v ~~ Str }
role: dev
manager: Ada
name: Bo
```

The lines may come in another order on your screen: a hash has no order of its own.

(`$v ~~ Str` asks "is `$v` a string?"; `~~` is the **smartmatch** operator, which
tests a value against a type, a pattern or another value.)

Arrays can be walked by position with `->keys` too, which gives `0, 1, 2…`:

```
> for @people->keys -> #i { say "#i: {@people.#i.name}" }
0: Ada
1: Bo
2: Cy
```

### 9.7 Transforming lists

Loops that build a new list are so common that they have short forms.

**`map`** makes a new list by applying something to each element:

```
> %team.people.map(*.name)
(Ada Bo Cy)
> %team.people.map(*.age)->sum
106
```

`*.name` is a **whatever expression**: the `*` stands for "the element, whichever it
is". `*.name` means "the `name` of the element", `*.age * 2` means "twice its age". For
anything longer, use a block, with the topic as the element:

```
> %team.people.map({ .projects.map(*.stars)->sum })
(165 12 0)
```

That is the total number of stars of each person's projects.

**`grep`** keeps the elements for which a test is true. The name comes from the Unix
`grep` program, which keeps the lines that match:

```
> %team.people.grep(*.role eq 'dev').map(*.name)
(Bo)
> %team.people.grep(*.age > 30).map(*.name)
(Ada Cy)
```

**`first`** gives the first element that passes the test, and stops looking:

```
> %team.people.first(*.name eq 'Bo').manager
Ada
```

**`sort`** sorts, by the element itself or by what you choose. A minus sorts in
reverse:

```
> %team.people->list.sort(*.age).map(*.name)
(Bo Ada Cy)
> %team.people->list.sort(-*.age).map(*.name)
(Cy Ada Bo)
```

**`unique`**, **`elems`**, **`sum`**, **`max`**, **`min`**, **`join`** finish the job:

```
> my @projects = %team.people->list.map(*.projects->list)->flat
> @projects.map(*.name)
(rak irak myaml)
> @projects.map(*.tags->list)->flat->unique->sort
(data lang repl shell yaml)
> @projects.map(*.name)->join(', ')
rak, irak, myaml
```

`->flat` turns a list of lists into one long list: each person gives a list of
projects, and `->flat` lines them all up.

Each of these returns a new list and leaves the original untouched, so you can chain
them, and you can always go back one step with `!!n`.

### 9.8 Unknown depth: walking everything

`map` and `for` walk one level. To walk *everything*, at any depth, you need a routine
that calls itself when it meets something nested: a **recursive** routine. Here is one
that prints every path in a structure, with its value:

```
> sub walk($data, $path = '') {
...     given $data {
...         when Associative { for $data->keys->sort -> ~k { walk $data.~k, "$path.~k" } }
...         when Positional  { for $data->keys -> #i { walk $data.#i, "$path.#i" } }
...         default          { say "$path = $data" }
...     }
... }
> walk %team
.name = Orbit
.people.0.age = 36
.people.0.name = Ada
.people.0.projects.0.name = rak
.people.0.projects.0.stars = 120
.people.0.projects.0.tags.0 = lang
.people.0.projects.0.tags.1 = shell
.people.0.projects.1.name = irak
…
.people.2.role = ops
```

How it works, line by line:

- `sub walk($data, $path = '')` takes the data and the path so far, which starts empty.
- `given $data` makes `$data` the topic for the `when` lines.
- `when Associative` matches hashes (things you look up by key). For each key, sorted,
  it calls `walk` again on the value under that key, with the key added to the path.
- `when Positional` matches arrays (things you look up by position). Same, with
  positions.
- `default` matches everything else: a string, a number. There is nothing inside to
  walk, so it prints the path and the value.

Each call handles one level and hands the levels below to new calls of itself. That is
the whole trick of recursion: a routine that solves a small part of the problem, and
trusts itself for the rest. It works for any depth, because it never needed to know the
depth.

Notice that the printed paths are valid rak: copy `.people.0.projects.1.name` after
`%team` and you get `irak`. Notice also that Bo's empty `projects` array prints nothing:
there is nothing in it to print.

For the common case "apply something to every leaf", rak has a ready-made method,
`deepmap`, which keeps the structure and changes only the leaves:

```
> %team->deepmap(*->uc).people.1.name
BO
```

### 9.9 Missing paths

A step that leads nowhere gives an undefined value, not an error:

```
> %team.budget
(Any)
> %team.budget.total
(Any)
> %team.people.7.name
(Any)
```

That is convenient when you explore, and dangerous when you compute: an undefined value
used as a number is treated as 0, with a warning. Guard with `//`:

```
> %team.people.7.name // 'nobody'
nobody
```

To ask whether a key is present, without reading it, add `:exists`:

```
> %team.people.1.manager:exists
True
> %team.people.0.manager:exists
False
```

Ada has no manager. `:delete` removes an entry and gives back its value:

```
> %team.people.1.manager:delete
Ada
```

Reading a missing path never creates it: `%team.budget.total` above left `%team`
unchanged. Only assigning creates what is missing.

### Recap

- `.key` and `.position` take one step into a hash or an array. `.'key'` and `."$key"`
  for keys that are not plain words.
- Steps chain into paths: `%team.people.0.projects.1.name`. Paths can be assigned to.
- A leading dot walks from the topic, one submission at a time. `<file` alone loads
  into the topic.
- `.~k` and `.#i` take a step held in a `~` or `#` variable. `.$k` is an error.
- A dot reads data; an arrow asks the value (`.keys` vs `->keys`).
- `for … ->list { }`, `->kv`, pointy blocks `-> $x { }` visit elements.
- `map`, `grep`, `first`, `sort`, `unique`, `flat`, `join`, `sum` transform lists.
- A recursive routine walks any depth; `deepmap` changes every leaf.
- A missing path is undefined: use `//`, `:exists`, `:delete`.

### Exercises

1. Using the topic, go from `%team` to the number of tags of Ada's first project, one
   step per submission.
   <details><summary>Answer</summary>

   ```
   > %team
   > .people
   > .0
   > .projects
   > .0
   > .tags
   > ->elems
   2
   ```
   Or in one submission: `%team.people.0.projects.0.tags->elems`.
   </details>

2. List the names of the people who have at least one project.
   <details><summary>Answer</summary>

   ```
   > %team.people.grep(*.projects->elems > 0).map(*.name)
   (Ada Bo)
   ```
   </details>

3. Which projects have the tag `shell`?
   <details><summary>Answer</summary>

   ```
   > @projects.grep({ 'shell' (elem) .tags }).map(*.name)
   (rak irak)
   ```
   `(elem)` asks "is this an element of that list?".
   </details>

4. Change `walk` so that it prints only the paths that end in `name`.
   <details><summary>Answer</summary>

   Change the `default` line to:
   ```
   default { say "$path = $data" if $path.ends-with('.name') }
   ```
   </details>

5. Compute the total stars of the whole team.
   <details><summary>Answer</summary>

   ```
   > @projects.map(*.stars)->sum
   177
   ```
   </details>

---

## 10. Referring to data: names, containers, sharing

Two names can lead to the same data, or to two copies of it. Change the data through
one name, and depending on which case you are in, the other name sees the change or
doesn't. This chapter is about telling the two cases apart. Many confusing bugs, in
every programming language, come from getting this wrong.

### 10.1 Assignment copies

Assigning one array to another copies its elements:

```
> my @a = 1, 2, 3
[1 2 3]
> my @b = @a
[1 2 3]
> @b.0 = 99
99
> @a
[1 2 3]
> @b
[99 2 3]
```

`@a` and `@b` are two separate arrays. Changing one leaves the other alone. Hashes
behave the same: `my %copy = %team` makes a second hash. So far, so intuitive.

### 10.2 Binding: a second name for the same thing

Sometimes you *want* two names for one thing: a short name for something deep inside a
structure, say. That is **binding**, written `:=` instead of `=`:

```
> my @c := @a
[1 2 3]
> @c.0 = 42
42
> @a
[42 2 3]
```

`@c` is not a copy. It is another name for the very same array, so a change through
`@c` is a change to `@a`. Assignment (`=`) puts a value *into* a box; binding (`:=`)
makes a name *refer to* an existing box.

Binding is most useful for reaching into nested data. Instead of typing
`%team.people.0` again and again:

```
> my %ada := %team.people.0
{age => 36, name => Ada, projects => […], role => lead}
> %ada.role = 'architect'
architect
> %team.people.0.role
architect
```

`%ada` is a **reference** to Ada's entry inside `%team`: a name that leads to data
stored elsewhere. Changing `%ada` changes the team.

Compare with assignment:

```
> my %bo = %team.people.1
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
> %bo.role = 'lead'
lead
> %team.people.1.role
dev
```

`%bo` is a copy, so the team is unchanged.

### 10.3 The surprise: copies are shallow

Here is the case that catches everybody. Copy the whole team, then change a person in
the copy:

```
> my %copy = %team
> %copy.name = 'Orbit II'
Orbit II
> %team.name
Orbit
> %copy.people.2.age = 99
99
> %team.people.2.age
99
```

Changing the name in the copy left the original alone. Changing Cy's age in the copy
*also changed it in the original*. Why?

Because `my %copy = %team` copies only the first level: the keys `name` and `people`,
and their values. The value of `people` is an array, and what is copied is a reference
to that array, not the array itself. Both hashes now point to the same array of people:

```
 %team ──┬── name ── "Orbit"
         └── people ─────────┐
                             ▼
                      [ Ada, Bo, Cy ]    ← one array, shared
                             ▲
 %copy ──┬── name ── "Orbit II"
         └── people ─────────┘
```

`%copy.name = …` replaced a value at the first level, which belongs to `%copy` alone.
`%copy.people.2.age = …` went down into the shared array and changed it there, so both
hashes see the change.

This kind of copy is called **shallow**: it copies one level and shares the rest. It is
fast, and it is what assignment always does. Reload before going on:

```
> my %team <team.json
```

### 10.4 Copying on purpose

To copy the levels below as well, you need a **deep** copy, one that copies every
nested array and hash. rak's `deepmap`, which you met in
[9.8](#98-unknown-depth-walking-everything), rebuilds every level of a structure. Asked
to keep each leaf as it is (`*->self`), it produces a deep copy:

```
> my %deep = %team->deepmap(*->self)
> %deep.people.2.age = 99
99
> %team.people.2.age
41
```

Make it a routine, since you will want it again:

```
> sub deep-copy($x) { $x->deepmap(*->self) }
&deep-copy
```

Another deep copy you already know: save to a file and load it back. Encoding and
decoding JSON rebuilds everything:

```
> %team >backup.json
> my %fresh <backup.json
```

`->clone` gives a shallow copy, the same as assignment, when you need one as a value:
`%team->clone`.

When to use which:

| You want… | Write |
|---|---|
| a second name for the same data | `my %x := …` (binding) |
| an independent top level, sharing what's below | `my %x = …` (assignment) |
| a fully independent copy | `my %x = deep-copy …`, or a JSON round trip |

### 10.5 Boxes inside boxes: itemization

Back in [9.6](#96-visiting-every-element), looping over `%team.people` needed `->list`.
Here is why.

An `@` variable holds *several* things. A `$` variable holds *one* thing. But you can
put an array into a `$` variable: it is then one thing, an array, sitting in a box:

```
> my @a = 1, 2, 3
[1 2 3]
> my $s = @a
[1 2 3]
> for @a { print "<$_> " }
<1> <2> <3>
> for $s { print "<$_> " }
<1 2 3>
```

Looping over `@a` gives three elements. Looping over `$s` gives *one*: the array, as a
whole, in its box. Putting a list into a single box is called **itemizing** it.

Every value stored inside an array or a hash sits in such a box. So `%team.people`
gives you a box holding an array: one item. That is why `for %team.people` would loop
once, and why `my @people = %team.people` would give an array with one element, the
whole array of people. `->list` takes the array out of its box:

```
> (my @wrong = %team.people)->elems
1
> (my @right = %team.people->list)->elems
3
```

Methods like `map` and `grep` don't care: `%team.people.map(*.name)` works, because a
method call reaches through the box to the array.

The opposite also exists. A `|` in front of a list **slips** its elements into the
surrounding list, instead of putting the list in as one element:

```
> my @x = 1, 2
[1 2]
> my @y = 3, 4
[3 4]
> (my @nested = @x, @y)->elems
2
> (my @slipped = |@x, |@y)->elems
4
```

`@x, @y` makes a list of two arrays. `|@x, |@y` makes a list of four numbers.

The rule of thumb: **`->list` to open a box, `|` to spill a list into another list.**

### 10.6 Passing data to routines

When you call a routine, its parameters are bound to your arguments: the routine sees
your data, not a copy. To stop accidents, rak makes parameters **read-only** by default:

```
> sub birthday($person) { $person = 'changed' }
&birthday
> birthday %team.people.0
Cannot assign to a readonly variable or a value
```

Two **traits** change that, written after the parameter:

- `is copy`: the routine gets its own copy, which it may change. Your data is safe.
- `is rw`: "read-write". The routine may change your variable, and you see the change.

```
> sub bump($n is rw) { $n = $n + 1 }
&bump
> my $v = 1
1
> bump $v
2
> $v
2
> sub local-bump($n is copy) { $n = $n + 1; $n }
&local-bump
> local-bump $v
3
> $v
2
```

Note that read-only protects the *parameter*, not what is inside it. A routine that
receives a hash can still change the hash's entries, since the hash itself is shared:

```
> sub promote(%person) { %person.role = 'lead' }
&promote
> promote %team.people.1
lead
> %team.people.1.role
lead
```

If a routine should not change your data, give it a deep copy.

### 10.7 Referring to code

Routines are values too. The `&` sigil names a routine *without calling it*:

```
> &uc
&uc
> my &shout = &uc
&uc
> shout 'hey'
HEY
```

This lets you pass behaviour around, as you passed `*.name` to `map`:

```
> sub twice(&f, $x) { f f $x }
&twice
> twice &flip, 'abc'
abc
> sub add-one($n) { $n + 1 }
&add-one
> twice &add-one, 5
7
```

`->&f` calls a routine as if it were a method of a value:

```
> 'abc'->&flip
cba
```

A block, too, is a piece of code you can keep in a variable. A pointy block with
parameters is an anonymous routine:

```
> my &area = -> $w, $h { $w * $h }
-> $w, $h { #`(Block|…) ... }
> area 3, 4
12
```

### 10.8 Native variables cannot be shared

`~` and `#` variables hold their value directly, without a box. With no box, there is
nothing for a second name to point at, so they cannot be bound:

```
> my ~s = 'a'
a
> my ~t := ~s
===SORRY!===
Can only compile an assign initializer on a native
```

Assigning copies them, always. This is part of what makes them fast, and it is rarely a
limitation: a text or a number is something you copy, not something you share.

### 10.9 Same thing, or equal things?

Two kinds of question:

- *Do these two have the same value?* `==` for numbers, `eq` for strings, and `eqv`
  for whole structures, compared level by level.
- *Are these two the same object?* `===`, which asks for identity, not likeness.

```
> my @p = 1, 2
[1 2]
> my @q = 1, 2
[1 2]
> my @r := @p
[1 2]
> @p eqv @q
True
> @p === @q
False
> @p === @r
True
```

`@p` and `@q` are equal but distinct, like two copies of the same book. `@p` and `@r`
are one array with two names. Use `eqv` to compare data, and `===` to check whether two
names share it.

### Recap

- `=` copies into a box; `:=` makes a name refer to an existing box.
- Copies are shallow: nested arrays and hashes are shared. Use `deep-copy` (via
  `deepmap`) or a JSON round trip for a full copy.
- Values inside structures are itemized: `->list` opens the box, `|` slips a list into
  another one.
- Parameters are read-only; `is copy` and `is rw` change that. Shared contents can still
  be changed.
- `&name` refers to a routine without calling it; `->&f` calls one as a method.
- `~` and `#` variables cannot be bound.
- `eqv` compares values; `===` checks identity.

### Exercises

1. After `my @a = 1, 2; my @b := @a; @b.push(3)`, what is `@a`?
   <details><summary>Answer</summary>

   `[1 2 3]`: `@b` is another name for `@a`.
   </details>

2. After `my %c = %team; %c.people.0.name = 'Zed'`, what is `%team.people.0.name`?
   Why?
   <details><summary>Answer</summary>

   `Zed`. The copy is shallow: `%c` and `%team` share the same array of people, and the
   change was made inside it.
   </details>

3. Write `sub rename-all(%t)` that returns a copy of a team with every name in capitals,
   without changing the original.
   <details><summary>Answer</summary>

   ```
   > sub rename-all(%t) { my %c = deep-copy %t; %c.people.map({ .name = .name->uc }); %c }
   &rename-all
   > rename-all(%team).people.map(*.name)
   (ADA BO CY)
   > %team.people.map(*.name)
   (Ada Bo Cy)
   ```
   </details>

4. How many elements has `my @z = [1, 2], [3, 4]`? And `my @z = |[1, 2], |[3, 4]`?
   <details><summary>Answer</summary>

   2, then 4.
   </details>

---

# Part IV: Moving data

Data is rarely born in irak. It comes from files, from other programs, from the web,
and it goes back there when you are done. Part IV is about moving data in and out:
redirection to and from files, pipelines between programs and rak, and the web treated
as one more place to read and write.

## 11. Redirection and formats

You met redirection on external commands in [5.6](#56-command-redirections). In rak,
the same arrows work on any statement, and they understand data, not just text.

### 11.1 Output redirection

`STMT >file` runs the statement with its output going to `file` instead of the screen.
The file is emptied first, or created if it does not exist. `>>file` adds to the end
instead:

```
> say hello >greeting.txt
> say world >>greeting.txt
> cat greeting.txt
hello
world
```

The redirection lasts for that one statement only. The next statement prints to the
screen again. The file is closed when the statement ends, even if the statement fails
halfway.

A statement can do a lot of printing, and all of it goes to the file:

```
> for 1..5 { say $_ * $_ } >squares.txt
> cat squares.txt
1
4
9
16
25
```

`1..5` is a **range**: the numbers from 1 to 5.

Only standard output is redirected. `note` writes to standard error, which still
reaches your screen:

```
> note 'this is a warning' >log.txt
this is a warning
> cat log.txt
>
```

`log.txt` is empty.

### 11.2 Input redirection

`<file STMT`, with the arrow *before* the statement, connects the statement's standard
input to the file. In rak, standard input is `$*IN`:

```
> <greeting.txt say $*IN->lines->elems
2
> my $first
(Any)
> <greeting.txt $first = $*IN->get
hello
```

`->lines` reads all the lines; `->get` reads one.

Both directions can be combined, input before and output after:

```
> <greeting.txt say $*IN->lines->reverse >reversed.txt
> cat reversed.txt
(world hello)
```

### 11.3 Load: a file into a variable

The form you will use most is the **load**: `VARIABLE <file`, with the variable on the
*left* of the arrow. It reads the whole file, decodes it, and assigns the result:

```
> my @lines <greeting.txt
[hello world]
> my $text <greeting.txt
hello
world
```

With an `@` variable, a text file loads as a list of lines. With a `$` variable, it
loads as one string.

Any place you can assign to works on the left, including a path into a structure:

```
> %team.notes <greeting.txt
hello
world
```

And with nothing on the left, a load goes into the topic. You have used this already:

```
> <team.json
> .people.0.name
Ada
```

Notice the difference between `<file STMT`, which connects standard input and lets the
statement read it, and `VARIABLE <file`, which reads and decodes the file for you.

### 11.4 Formats

The extension of the file name decides its **format**: how values are turned into bytes
when writing, and back into values when reading. Upper or lower case does not matter.

| Extension | Format | Writes | Reads |
|---|---|---|---|
| `.json` | JSON | any value, pretty-printed: indented, keys sorted | one value |
| `.jsonl` | JSON Lines | one compact JSON value per line | a list of values |
| anything else | plain text | text | lines (`@`) or a string (`$`) |

**JSON** you know from [8.7](#87-json-the-common-language-of-data). It writes one value,
on as many lines as needed.

**JSON Lines** writes one value per line, each on a single line. It suits records: one
line per person, per event, per log entry. You can add a record with `>>`, which JSON
cannot do:

```
> %team.people >people.jsonl
> cat people.jsonl
{"age":36,"name":"Ada","projects":[…],"role":"lead"}
{"age":29,"manager":"Ada","name":"Bo","projects":[…],"role":"dev"}
{"age":41,"manager":"Ada","name":"Cy","projects":[],"role":"ops"}
> { name => 'Di', age => 24, role => 'intern', projects => [] } >>people.jsonl
> my @everyone <people.jsonl
> @everyone->elems
4
```

The sigil on the left of a load must fit the content:

```
> my @list <team.json       # needs a JSON array
> my %h <team.json          # needs a JSON object: works
> my $x <team.json          # takes anything
> my @r <people.jsonl       # a list of records
```

With a variable as the target, `>$file`, the format is chosen when the statement runs,
from the variable's value:

```
> my $out = 'ada.json'
ada.json
> %team.people.0 >$out
```

### 11.5 Value mode and text mode

How does `%team >team.json` know to write the *value* of `%team`, while
`say hello >greeting.txt` writes the *printed text*? By looking at what the statement
did:

```
                  did the statement print anything?
                 ┌──────────────┴──────────────┐
                yes                            no
                 │                             │
            TEXT MODE                     VALUE MODE
  the printed text is written.     the statement's value is encoded
  if the target has a format,      in the target's format and written.
  the text must already be in      (with no format: the file is left
  that format; rak checks it       empty.)
  and rewrites it neatly.
```

Value mode is what you want for data:

```
> %team >team.json            # the hash, as JSON
> 1/3 >third.json             # 0.3333333333333333
> 'hi' >hi.json               # "hi"
```

Text mode is what you want for text, and it still checks JSON targets. Printed text
that is almost-JSON is accepted and cleaned up, which is handy for typing JSON by hand:

```
> print q[{ a: 'a', }] >t.json
> cat t.json
{
  "a": "a"
}
```

The keys had no quotes, the strings had single quotes, and there was a trailing comma:
none of that is strict JSON, all of it is fixed. (`q[…]` is another way to write a
single-quoted string, useful when the text itself contains quotes.)

Printed text that is not JSON at all is refused:

```
> say (1, 2) >t2.json
t2.json: invalid JSON at line 1, column 1: unexpected '('
```

`say` printed `(1 2)`, which is rak's way of showing a list, not JSON. Drop the `say`
to write the value instead: `(1, 2) >t2.json`.

### 11.6 When a format fails

Every format error names the file and says what went wrong. The target is left
untouched: a failed save never leaves a half-written file.

| Message | Cause | Fix |
|---|---|---|
| `cannot encode as json: a value of type Set has no JSON form` | the value has no JSON form | convert it first: `->list`, `->Str` |
| `invalid JSON at line 2, column 1: unexpected end of input` | the file to load is not valid JSON | look at that line of the file |
| `expected a JSON object for %h, found an array` | wrong sigil for the content | use `@` for arrays, `%` for objects, `$` for anything |
| `cannot append to a .json target, use .jsonl for one record per line` | `>>` on a `.json` file | use `.jsonl`, or rewrite the whole file |

A missing file, or one you may not write, gives an error that names it too.

### 11.7 Spacing is syntax

A redirection arrow **touches** its file name. A comparison has **spaces** on both
sides. That is how rak tells them apart:

```
> my $a = 3
3
> $a > 2           # comparison: is $a greater than 2?
True
> say $a >two      # redirection: print 3 into the file "two"
> say $a > 2       # comparison, printed
True
```

A file name that starts with a digit is not a target: `say $a >2` would be ambiguous,
and rak refuses to guess. Write `>'2'` if you really want a file called `2`. The load
`<5` is the exception, and rak warns about it:

```
> $a <5
Potential difficulties:
    `<5` loads the file '5'; put a space after `<` to compare
```

Hyperoperators, which you have not met, are spaced too, so `@a >>+<< @b` stays what it
is. When in doubt, follow the rule: **operators spaced, redirections touching.**

### Recap

- `STMT >file` and `STMT >>file` send output to a file; `<file STMT` reads input from
  one. One statement only.
- `VARIABLE <file` loads and decodes a file; `<file` alone loads into the topic.
- The extension picks the format: `.json`, `.jsonl`, or plain text.
- Value mode writes the statement's value when it printed nothing; text mode writes
  the printed text, checked against the format.
- Format errors name the file and leave it untouched.
- Spaced `>` compares; `>` touching a name redirects.

### Exercises

1. Save the names of the team, one per line, into `names.txt`, then load them back into
   an array.
   <details><summary>Answer</summary>

   ```
   > for %team.people->list { say .name } >names.txt
   > my @names <names.txt
   [Ada Bo Cy]
   ```
   </details>

2. Save the same names as a JSON array into `names.json`. Which mode is used?
   <details><summary>Answer</summary>

   `%team.people.map(*.name) >names.json`. Nothing is printed, so value mode: the list
   is encoded as a JSON array.
   </details>

3. Why does `my %h <names.json` fail? What would work?
   <details><summary>Answer</summary>

   `names.json` holds an array, and `%h` expects an object. `my @h <names.json` or
   `my $h <names.json` works.
   </details>

4. Append a log record with the current time to `log.jsonl` each time you run a
   submission. (`DateTime->now->Str` gives the time as text.)
   <details><summary>Answer</summary>

   ```
   > { when => DateTime->now->Str, what => 'tested' } >>log.jsonl
   ```
   Recall it with `!n` to add more records. A `DateTime` itself has no JSON form,
   hence `->Str`.
   </details>

---

## 12. Pipelines

### 12.1 The Unix idea

In the 1970s, the people who built Unix had an idea that still shapes how computers are
used: write small programs that each do one thing well, and connect them so that the
output of one is the input of the next. The connection is a **pipe**, written `|`. A
chain of programs joined by pipes is a **pipeline**.

```
> cat fruit.txt
pear
apple
plum
apple
> cat fruit.txt | ^sort | ^uniq -c
      2 apple
      1 pear
      1 plum
```

`cat` prints the file. Its standard output, instead of going to the screen, goes into
the standard input of `sort`, which sorts the lines. That output goes into `uniq -c`,
which collapses repeated lines and counts them. Only the last program's output reaches
your screen. The three programs run at the same time, each processing what the previous
one produces, as on an assembly line.

(The `^` forces the external `sort` and `uniq`, as rak has routines with those names;
see [5.3](#53-who-wins-a-name).)

Each stage in the pipeline is a **stage**. Pipes connect stages, while redirections,
from [chapter 11](#11-redirection-and-formats), connect one statement to a file.

### 12.2 rak stages

In a Unix shell, every stage is a program, and everything passed between them is text.
In rak, a stage can also be a piece of rak: a method, a dotty path, a block, or a
routine. Those stages pass **values**, not text, and run inside irak, without starting
any process.

```
> cat fruit.txt | ->unique
(pear apple plum)
```

`cat` is a program. `->unique` is a rak method. Between them, rak turns `cat`'s output
into a list of lines, and calls `->unique` on that list.

Each kind of rak stage receives the *whole* value coming from the left, the
**upstream** value:

| Stage | Means | Example |
|---|---|---|
| `->meth` or `.meth(…)` | call a method on the upstream value | `->unique`, `.head(3)` |
| `.path` | take a dotty path from it | `.people`, `.0.name` |
| `{ block }` | run the block with the topic `$_` set to it | `{ .map(*.age)->sum }` |
| `name args` | call a routine, with the upstream value as the last argument | `map *.name`, `grep *.age > 30` |
| `from-json` | decode it as one JSON document | `cat x.json \| from-json` |
| `from-jsonl` | decode it as JSON Lines: one value per line | `cat x.jsonl \| from-jsonl` |

### 12.3 Pipelines with no process at all

Since a load is a stage, a pipeline can start from a file and stay in rak all the way,
much like the program `jq`:

```
> <team.json | .people | map *.name
(Ada Bo Cy)
> <team.json | .people | map *.age | ->sum
106
> <team.json | .people | grep *.projects->elems > 0 | map *.name
(Ada Bo)
```

Read it left to right, as a sentence: load the team, take its people, keep those with
projects, take their names. Compare with the same thing written as one expression:

```
> (my %t <team.json).people.grep(*.projects->elems > 0).map(*.name)
(Ada Bo)
```

Both are correct. The pipeline reads in the order you think, one step after another,
and you can grow it one stage at a time: run the first two stages, look, add a third.

A pipeline can start in three ways: with a command (`cat fruit.txt | …`), with a load
(`<team.json | …`), or with a leading dotty path, which starts from the topic:

```
> <team.json
> .people | map *.role
(lead dev ops)
```

### 12.4 Where bytes meet values

When a program and a rak stage meet, rak converts between bytes and values:

**Program → rak stage.** The program's output becomes a list of lines, without their
line breaks. The list is **lazy**: lines are read as the rak stage asks for them, not
all at once ([12.7](#127-laziness-and-sigpipe)). To decode the output as data instead,
add a `from-json` or `from-jsonl` stage:

```
> cat team.json | from-json | .people.1.name
Bo
> cat people.jsonl | from-jsonl | map *.name
(Ada Bo Cy Di)
```

**rak stage → program.** The value is written as text on the program's standard input:

| The value is | Written as |
|---|---|
| a string or a number | one line |
| a list | one line per element |
| a hash, or a list of hashes or lists | JSON Lines: one compact record per line |

```
> <team.json | .people | map *.name | ^sort -r
Cy
Bo
Ada
> <team.json | .people | ^grep Bo
{"age":29,"manager":"Ada","name":"Bo","projects":[…],"role":"dev"}
```

In the second example, each person became one line of JSON, and the external `grep`
kept the line containing `Bo`.

**Program → program.** A real pipe, as in any Unix shell. The bytes pass through
untouched, and rak is not involved.

### 12.5 When `|` is a pipe

`|` has other meanings in rak, inherited from Raku: `1 | 2` is a **junction**, a value
meaning "1 or 2", and `|@a` slips a list ([10.5](#105-boxes-inside-boxes-itemization)).
To keep these meanings, `|` is a pipe only when:

1. the line *starts* like a pipeline: with a command, a load (`<file`), or a leading
   dotty path (`.people`); and
2. the `|` is spaced, with a space on both sides.

Everywhere else it is a junction. In particular, a variable does not start a pipeline:

```
> my @names = 'Bo', 'Ada'
[Bo Ada]
> @names | ^sort
Must specify something to sort
```

`@names | ^sort` is a junction of `@names` and a call to `sort` with no arguments, which
fails.

Set the topic and start from it with `.[]`, "all the elements of the topic":

```
> $_ = @names
[Bo Ada]
> .[] | ^sort
Ada
Bo
```

### 12.6 Pipelines as values

At the start of a line, a pipeline shows its result: a program's output goes to the
screen, and a rak stage's value is shown by irak. Inside parentheses, the pipeline is a
value you can store or pass on:

```
> my @people = (<team.json | .people)
> @people->elems
3
> my $count = (cat fruit.txt | ->elems)
4
```

If the last stage is a program, the value is its output, as a string, as for a single
command in [5.4](#54-using-a-commands-output-as-a-value):

```
> my $sorted = (cat fruit.txt | ^sort)
apple
apple
pear
plum
```

### 12.7 Laziness and SIGPIPE

The program `yes` prints `y` forever. It never stops by itself. Yet this ends at once:

```
> ^yes | ->head(2)
(y y)
```

Two things make it work.

First, **laziness**: the rak stage `->head(2)` asks for two lines, and only two are
read. Nothing in rak waits for "all" of `yes`'s output.

Second, **SIGPIPE**: once `->head(2)` has what it needs, it stops reading. The next time
`yes` writes, nobody is listening, and the system sends it the signal `SIGPIPE`
([3.7](#37-stopping-a-process)), which stops it. The same happens between two programs,
as in any shell:

```
> yes | head -2
y
y
```

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** `^yes | ->head(2)` works, but the program-to-program
> pipeline `yes | head -2` currently prints nothing, and `@?` then holds one status instead
> of two.

A stage stopped by `SIGPIPE` is not counted as a failure: it was told to stop, not
broken.

Laziness is why a pipeline over a huge file starts producing results at once, and why it
does not need to fit the whole file in memory.

### 12.8 Exit status of a pipeline

A pipeline has several programs, so several exit statuses. rak keeps all of them in
`@?`, in order, and puts the most useful one in `$?`: **the first program that failed,
or the last one if none failed**. (Shell users know this as `pipefail`.)

```
> false | true
exit 1
> $?->exitcode
1
> @?.map(*->exitcode)
(1 0)
```

`false` failed, so `$?` is its status, even though `true`, at the end, succeeded. A
pipeline made only of rak stages changes neither `$?` nor `@?`.

### 12.9 Redirecting a pipeline

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** Today, a pipeline ending in a rak stage and redirected to a
> `.json` file writes `[]`, and to a `.jsonl` file stops with `Type Str does not support
> associative indexing`. A pipeline ending in a program stops with the error of
> [5.6](#56-command-redirections). Save the pipeline's value instead:
> `my @names = (<team.json | .people | map *.name); @names >names.json`.

A pipeline is a statement, so it can end with a redirection. With a rak stage at the
end, the value is saved in the target's format:

```
> <team.json | .people | map *.name | ->sort >names.json
> cat names.json
[
  "Ada",
  "Bo",
  "Cy"
]
> cat fruit.txt | ->unique >fruit.jsonl
> cat fruit.jsonl
"pear"
"apple"
"plum"
```

With a program at the end, its output is redirected, as for any command:

```
> cat fruit.txt | ^sort | ^uniq >fruit-set.txt
```

### Recap

- A pipeline joins stages with a spaced `|`: the output of each is the input of the next.
- Stages are programs (bytes) or rak stages (values): `->meth`, `.path`, `{ block }`,
  `name args`, `from-json`, `from-jsonl`.
- A pipeline starts with a command, a load or a leading dotty path. Otherwise `|` is a
  junction.
- Program output becomes lazy lines; rak values become lines or JSON Lines.
- In parentheses, a pipeline is a value.
- Laziness and `SIGPIPE` let pipelines stop early.
- `$?` is the first failure (or the last status); `@?` holds them all.

### Exercises

1. List the distinct tags used by the team, sorted, with a pipeline.
   <details><summary>Answer</summary>

   ```
   > <team.json | .people | { .map(*.projects->list)->flat.map(*.tags->list)->flat } | ->unique | ->sort
   (data lang repl shell yaml)
   ```
   </details>

2. Count how many lines of `/etc/passwd` mention `bash`, with a program then a rak stage.
   <details><summary>Answer</summary>

   ```
   > cat /etc/passwd | grep *.contains('bash') | ->elems
   ```
   The number depends on your system.
   Or entirely with programs: `grep -c bash /etc/passwd`.
   </details>

3. Why does `@names | ^sort` not sort?
   <details><summary>Answer</summary>

   A pipeline must start with a command, a load, or a leading dotty path. A variable
   does not start one, so `|` is the junction operator. Write `$_ = @names; .[] | ^sort`.
   </details>

4. Save the team's people as JSON Lines, using a pipeline, and count the records with
   `wc -l`.
   <details><summary>Answer</summary>

   ```
   > <team.json | .people >people.jsonl
   > wc -l people.jsonl
   3 people.jsonl
   ```
   </details>

---

## 13. The web as a file: URL targets

Loading from a URL, posting to one, credentials and errors work today. A few parts of
the chapter are still designs, and say so in a red box: the `http` routine
([13.5](#135-other-kinds-of-request-http)), pages ([13.8](#138-pages)), and the
JSON Lines and binary answers of [13.3](#133-what-comes-back).

### 13.1 Clients, servers and URLs

When your browser shows a web page, it runs a conversation with another computer, often
on the other side of the planet. Your browser is the **client**: it asks. The other
computer runs a **server**, a process ([chapter 3](#3-processes)) that waits for
questions and answers them. The language of that conversation is **HTTP** (HyperText
Transfer Protocol), and its secure form, encrypted on the way, is **HTTPS**.

Each question names what it is about with a **URL** (Uniform Resource Locator), an
address for something on the web:

```
https://api.github.com/repos/rakudo/rakudo/issues?state=open
└─┬─┘   └─────┬──────┘└────────────┬─────────────┘└───┬────┘
scheme       host                 path               query
```

- the **scheme** says how to talk: `https`;
- the **host** says which computer: `api.github.com`;
- the **path** says what, on that computer, much like a file path;
- the **query**, after `?`, adds options: `key=value` pairs separated by `&`.

Many servers answer with data rather than with web pages: JSON, most of the time. Such a
server is an **API** (Application Programming Interface), a service made for programs
rather than for people. GitHub, weather services, package registries and most of the
tools you use at work have one.

For rak, a URL is a place where data lives, like a file. So the same arrows work.

### 13.2 Reading: `<url`

A load from a URL fetches it:

```
> <https://api.github.com/repos/rakudo/rakudo
> .full_name
rakudo/rakudo
> .stargazers_count
1734
> .license.name
Artistic License 2.0
```

Exactly as with `<team.json`, the answer became the topic, and you walk it with dots.
Load into a variable to keep it:

```
> my %repo <https://api.github.com/repos/rakudo/rakudo
> %repo.open_issues_count
1203
```

(Your numbers will differ: these are live.)

Behind the scenes, rak sent an HTTP **GET** request, the kind your browser sends when you
open a page: "give me what is at this URL". The server's answer is a **response**: a
**status code** that says how it went, a few **headers** (labelled facts about the
answer), and a **body**, the content itself.

### 13.3 What comes back

A file's format comes from its extension. A response's format comes from its
`Content-Type` header, which the server sets to say what the body is:

| `Content-Type` | You get |
|---|---|
| `application/json` (or anything ending in `+json`) | data: hashes, arrays, strings, numbers |
| `application/x-ndjson` (JSON Lines) | a list of records, read lazily |
| `text/…` (`text/plain`, `text/html`, …) | a string |
| anything else (images, archives, …) | raw bytes, a `Blob` |

A string loads as a text file does: whole into `$` or `~`, line by line into `@`.

```
> my ~license <https://raw.githubusercontent.com/rakudo/rakudo/main/LICENSE
> ~license->lines->head(1)
(		       The Artistic License 2.0)
> my @lines <https://raw.githubusercontent.com/rakudo/rakudo/main/LICENSE
> @lines->elems
201
```

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** JSON Lines and binary answers are not decoded
> yet: today, any `Content-Type` that is not JSON gives a string. The `$logo` example
> below will not work.

```
> my $logo <https://raku.org/camelia-logo.png
> $logo->elems
14562
```

The `->elems` of a `Blob` is its size in bytes. To keep the bytes, save them:
`$logo >camelia.png`. A file whose extension is not a data format receives bytes as they
are.

### 13.4 Writing: `STMT >url`

Writing to a URL **sends** something to the server. rak sends an HTTP **POST** request,
the kind a web form sends: "here is something new, take it". What is sent follows the
value and text modes of [11.5](#115-value-mode-and-text-mode):

- if the statement printed nothing, its **value** is sent as JSON;
- if it printed, the **printed text** is sent. As for a `.json` file, it must be JSON,
  and is checked before anything leaves your computer.

Most APIs expect JSON, so you mostly send values:

```
> { title => 'Docs: typo in chapter 3', body => 'Missing word.' } >https://api.github.com/repos/me/notes/issues
{number => 42, state => open, title => Docs: typo in chapter 3, url => https://…, …}
```

The server answered with the issue it created, and irak shows that answer: with a URL
target, the decoded response is the statement's value, and so it becomes the topic. Walk
it:

```
> .number
42
> .html_url
https://github.com/me/notes/issues/42
```

When the server answers with nothing (the status `204 No Content`), the value is `Nil`.

The output of a program can be sent the same way: `cat draft.json >https://…` posts what
`cat` printed, which must be JSON too.

`>>url` has no meaning (you cannot "append" to a web service) and is an error, as are
`<url STMT` and `2>url`. rak refuses them before running anything.

### 13.5 Other kinds of request: `http`

GET and POST are the most common requests, and the arrows give them to you. HTTP has a
few more **methods**, each a different verb:

| Method | Means | Typical use |
|---|---|---|
| GET | give me | read something |
| POST | take this new thing | create something |
| PUT | replace with this | overwrite something entirely |
| PATCH | change these fields | update part of something |
| DELETE | remove | delete something |

> [!CAUTION]
> 🔴 **Not implemented yet.** The `http` routine does not exist yet. Until it does, a
> program does the job: `curl -s -X PATCH -H 'Content-Type: application/json' -d '…' URL`.

The `http` routine gives you all of them, with the method as its first word. A body, when
there is one, is sent as JSON:

```
> http patch https://api.github.com/repos/me/notes/issues/42 { state => 'closed' }
{number => 42, state => closed, …}
> http delete https://api.example.com/drafts/7
> http get https://api.github.com/repos/rakudo/rakudo
{full_name => rakudo/rakudo, …}
```

As with `STMT >url`, the decoded answer is the value, and becomes the topic.
`http get URL` is the same as `<URL`; it exists so that every method has the same
spelling.

### 13.6 Writing URLs

A URL target starts with `http://` or `https://`. It runs until a space, a `;`, a `#`, a
brace or a parenthesis. Variables with the `$` sigil interpolate in it:

```
> my $owner = 'rakudo'
rakudo
> <https://api.github.com/repos/$owner/rakudo
> .full_name
rakudo/rakudo
```

Only `$` variables do. A `~` is common in URLs (`https://example.com/~ada/`), so `~`
stays a plain character, and a `#` would start a comment. For a `~` or `#` variable, or
any other code, quote the URL: in a double-quoted string, everything interpolates
([4.3](#43-strings-naked-and-quoted)):

```
> my ~repo = 'rakudo'
rakudo
> my #n = 5
5
> <"https://api.github.com/repos/$owner/{~repo}/issues?per_page={#n * 2}"
> ->elems
10
```

A variable's name ends where a Raku name does, and `-` may be part of a name:
`<https://example.com/$owner-fork` reads the variable `$owner-fork`. Quote and use
braces: `<"https://example.com/{$owner}-fork"`. A URL that contains a space must be
quoted too: `<"https://example.com/my file.txt"`. (Inside a URL, a space is usually
written `%20`, which needs no quotes.)

### 13.7 Credentials: headers from a config file

Most APIs want to know who you are before they let you write, and many before they let
you read. You prove it with a **token**, a long secret string the service gives you,
sent in a header with each request.

Typing a secret into your commands would leave it in your history, and in your scripts.
So rak reads headers from a configuration file, `~/.config/rak/http-headers.json`, and
adds them to every request sent to the matching host:

```
// ~/.config/rak/http-headers.json
{
  'api.github.com': {
    auth: '$GITHUB_TOKEN',
    Accept: 'application/vnd.github+json',
  },
  'api.example.com': { 'X-Api-Key': '$EXAMPLE_KEY' },
}
```

The file is read as relaxed JSON ([11.5](#115-value-mode-and-text-mode)): comments,
single quotes, keys without quotes, trailing commas. Quote a key that contains a `.` or
a `-`.

- Each top-level key is a host (or `host:port`). Its entries are the headers to send
  there.
- `'$NAME'` is replaced by the environment variable `NAME`
  ([3.2](#32-what-every-process-carries)), so the secret itself can stay out of the file.
  When `NAME` is not set, the header is not sent.
- `auth: TOKEN` is short for the header `Authorization: Bearer TOKEN`, the most common
  way to send a token.

For `api.github.com`, if no `auth` is configured, rak asks the GitHub command-line tool
for one (`gh auth token`), so if you use `gh`, GitHub works with no setup at all.

rak never writes this file: create it yourself, with the directory
(`mkdir -p ~/.config/rak`). If the variable `XDG_CONFIG_HOME` is set, rak looks in
`$XDG_CONFIG_HOME/rak/` instead.

### 13.8 Pages

> [!CAUTION]
> 🔴 **Not implemented yet.** rak does not follow pages yet: a load gives the first page
> only. Ask for bigger pages with a query option, such as `?per_page=100` on GitHub.

An API with many results sends them in **pages**: the first 30 issues, say, and a
header named `Link` saying where the next page is. rak follows those links for you, and
it does so lazily:

```
> my $issues <https://api.github.com/repos/rakudo/rakudo/issues
> $issues.head(5).map(*.title)
(…five titles…)
```

With a `$` variable, rak fetches a page only when you need its contents: here, only the
first. With an `@` variable, rak fetches every page at once, since an array holds all
its elements:

```
> my @all <https://api.github.com/repos/rakudo/rakudo/issues
> @all->elems
1203
```

That can be many requests. Use `$` and `->head` while exploring; use `@` when you really
want everything. A query option often reduces the work: `?state=open&labels=docs`.

### 13.9 When the server says no

Each response carries a status code. In the 200s, all went well. In the 400s, the
problem is your request: `404` "not found", `401` "who are you?", `403` "not allowed",
`422` "I don't understand what you sent". In the 500s, the problem is the server's.

For a 4xx or 5xx status, rak throws an error, an `X::Rak::HTTP`, with the URL, the
status and the server's own message:

```
> <https://api.github.com/repos/rakudo/no-such-repo
https://api.github.com/repos/rakudo/no-such-repo: HTTP 404: Not Found
```

The message is the `message` field of a JSON answer, which is what most APIs send, or
else the first line of the answer. When no answer comes back at all (no network, a
wrong host name), the error is an `X::Rak::HTTP` too, without a status.

A failure changes nothing: `my %repo <url` that fails leaves `%repo` as it was, and a
POST whose printed text is not JSON sends nothing.

You will learn to catch errors in [15.5](#155-when-things-go-wrong).

### 13.10 Files and URLs together

> [!CAUTION]
> 🔴 **Does not (yet) behave as said.** A load followed by an output redirection, as in
> `<url >file` or `<file >url`, is refused today, for files as for URLs. Use two
> statements: `<url; $_ >rakudo.json`, and `my %d <draft.json; %d >url`.

Since files and URLs are both targets, you can move data between them in a single
statement:

```
> <https://api.github.com/repos/rakudo/rakudo >rakudo.json
> my %r <rakudo.json
```

Saving an answer to a file and working from the file is a good habit: it is faster, it
works offline, and it doesn't count against the API's limits. Sending data from a file is
as short:

```
> <draft.json >https://api.github.com/repos/me/notes/issues
```

`<draft.json` loads the file; the statement's value is that data, which `>url` sends.

### 13.11 What a traditional shell would need

You have now seen the three things that set irak apart from bash, zsh or fish: it
**understands data** (JSON, JSON Lines), it **walks structures** with dotty paths, and it
treats **the web as a file**. A traditional shell knows only text: a variable holds a
string, a pipe carries bytes, a redirection targets a file. Everything else is done by
helper programs, chiefly **`jq`**, which reads and reshapes JSON, and **`curl`**, which
talks HTTP. Both are excellent; the cost is that each has its own little language, and
the shell's quoting rules sit on top of both.

Here are the same tasks in irak and in bash. Each bash line is the usual way to do it.

> [!CAUTION]
> 🔴 **Not implemented yet.** Following pages and the `http` routine are not there yet.
> The other examples work today.

**Read a field from a JSON file.**

```
> <team.json | .people.0.name                    # irak
$ jq -r '.people[0].name' team.json              # bash + jq
```

The path is nearly the same: jq inspired rak's dotty paths. But in bash, the file is
read and decoded again by every `jq` call, and the result is text again afterwards.

**Keep the data, ask several questions.**

```
> my %team <team.json                             # irak: decoded once
> %team.people->elems
3
> %team.people.grep(*.age > 30).map(*.name)
(Ada Cy)
```

```
$ jq '.people | length' team.json                                  # bash + jq
3
$ jq -r '.people[] | select(.age > 30) | .name' team.json
Ada
Cy
```

A bash variable can only hold a string, so there is nowhere to keep `%team` as data: each
question goes back to the file. jq's `select`, `.[]` and `length` are a second language
to learn next to the shell's.

**Change a value and save.**

```
> %team.people.0.age = 37; %team >team.json       # irak
```

```
$ jq '.people[0].age = 37' team.json > team.tmp && mv team.tmp team.json   # bash + jq
```

The temporary file is not decoration. `jq … team.json > team.json` would empty
`team.json` *before* jq reads it, because the shell opens the target first: a classic way
to lose a file. rak writes the target only once the value is ready
([11.6](#116-when-a-format-fails)).

**Load from the web.**

```
> <https://api.github.com/repos/rakudo/rakudo      # irak
> .stargazers_count
```

```
$ curl -s https://api.github.com/repos/rakudo/rakudo | jq .stargazers_count   # bash
```

**Send a token.** irak takes it from `~/.config/rak/http-headers.json`
([13.7](#137-credentials-headers-from-a-config-file)), once. curl needs it on every line:

```
$ curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user | jq -r .login
```

**Post JSON.**

```
> my $title = 'Docs: typo in chapter 3'            # irak
> { title => $title, body => 'Missing word.' } >https://api.github.com/repos/me/notes/issues
> .number
42
```

```
$ title='Docs: typo in chapter 3'                  # bash + jq + curl
$ jq -n --arg t "$title" --arg b 'Missing word.' '{title: $t, body: $b}' |
    curl -s -X POST \
         -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H 'Content-Type: application/json' \
         --data @- https://api.github.com/repos/me/notes/issues |
    jq .number
42
```

Why `jq -n --arg`? Because building the JSON by pasting `$title` into a string breaks as
soon as the title contains a quote. In irak, the hash *is* the data, and rak encodes it.

**Follow pages.** irak follows `Link: rel="next"` by itself
([13.8](#138-pages)). With curl, you write a loop that reads the response headers,
extracts the next URL, and concatenates the pages with `jq -s 'add'`; or you use a
service-specific tool such as `gh api --paginate`.

**Know which stage of a pipeline failed.**

```
> false | true; $?->exitcode                       # irak: pipefail by default
1
```

```
$ set -o pipefail; false | true; echo $?           # bash: opt in
1
$ false | true; echo "${PIPESTATUS[@]}"            # all statuses, until the next command
1 0
```

To sum up:

| Task | bash | irak |
|---|---|---|
| decode JSON | `jq` on each call | `<file.json`, once |
| keep structured data in a variable | not possible: strings only | `%`, `@`, `$` |
| walk a structure | jq's language | dotty paths, `map`, `grep` |
| save JSON in place | temporary file and `mv` | `%data >file.json` |
| HTTP GET, POST, PATCH | `curl` with flags | `<url`, `>url`, `http` |
| auth headers | `-H` on every call | a config file |
| pagination | a hand-written loop | automatic, lazy |
| pipeline failures | `set -o pipefail`, `PIPESTATUS` | `$?`, `@?` |

None of this makes jq or curl obsolete: they are still there, and irak runs them like any
program ([16](#16-where-to-go-next)). irak simply makes the common cases one line long,
in one language.

### Recap

- A URL names something on the web. A server answers HTTP requests about it.
- `<url` sends a GET; `STMT >url` sends a POST of JSON (the value, or printed text that
  must be JSON); `>>url` is an error.
- `http patch|put|delete|get URL [BODY]` will send the other methods (not yet).
- The answer's `Content-Type` picks its form: data for JSON, a string otherwise (records
  and bytes are planned). The answer to a POST becomes the statement's value and the
  topic.
- `$var` interpolates in a naked URL. For `~var`, `#var` and `{expr}`, and for spaces,
  quote the URL with double quotes.
- Headers and tokens live in `~/.config/rak/http-headers.json`; `auth:` is a bearer
  token; GitHub falls back to `gh auth token`.
- Pages will be followed lazily into `$`, eagerly into `@` (not yet).
- A 4xx or 5xx status, or no answer, throws `X::Rak::HTTP`, and the target is left as it
  was.

### Exercises

1. Load the GitHub data of a repository you like, and print its description and its
   number of stars.
   <details><summary>Answer</summary>

   ```
   > <https://api.github.com/repos/rakudo/rakudo
   > say .description, ' — ', .stargazers_count
   ```
   </details>

2. Save the open issues of that repository with the label `docs` to `docs-issues.json`,
   then list their titles from the file.
   <details><summary>Answer</summary>

   ```
   > <https://api.github.com/repos/rakudo/rakudo/issues?labels=docs&per_page=100; $_ >docs-issues.json
   > <docs-issues.json | map *.title
   ```
   Until rak follows pages, only the first page is saved: `&per_page=100` makes it as
   big as GitHub allows.
   </details>

3. What does `say 'hello' >https://httpbin.org/post` send, and how?
   <details><summary>Answer</summary>

   Nothing: `say` printed, so text mode, and the printed `hello` is not JSON. rak throws
   an `X::Rak::Format::Decode` before sending anything. Without `say`,
   `'hello' >https://httpbin.org/post` sends the JSON string `"hello"`, and so does
   `say '"hello"' >https://httpbin.org/post`.
   </details>

---

# Part V: Putting it together

## 14. A complete session

This chapter is one irak session from start to end, as you might really work. Nothing in
it is new; it shows how the pieces from all the earlier chapters fit. The task: you
maintain a small project on GitHub, and you want a weekly report of the issues that have
been waiting longest for an answer, saved as a file and posted as a comment on your
project's tracking issue.

### 14.1 Where am I?

```
[0] > pwd
/home/ada
[1] > mkdir -p reports; cd reports
[2] > ls
[3] >
```

An empty directory to work in ([chapter 2](#2-files-and-directories)). Since `ls` showed
nothing, it is empty.

### 14.2 Fetching

```
[3] > my $owner = 'ada'; my $repo = 'orbit'
orbit
[4] > my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100; @open >open.json
[5] > ls -l
-rw-r--r-- 1 ada ada 184211 Nov 20 09:12 open.json
```

One request, loaded into `@open` and saved to a file ([13.10](#1310-files-and-urls-together)). From now on, you
work from the file, and the API is not bothered again.

### 14.3 Looking around

```
[6] > <open.json
[7] > ->elems
37
[8] > .0->keys->sort
(assignee body comments created_at html_url labels number pull_request state title updated_at user …)
[9] > .0.title
Crash when the config file is empty
[10] > .0.user.login
yuki
[11] > .0.comments
0
```

Thirty-seven open issues. Each one is a hash, with a `title`, a `user` (itself a hash,
with a `login`), a count of `comments`, a `created_at` date, and many more.

Some of these "issues" are pull requests: GitHub returns both from the same URL. A pull
request has a `pull_request` key. Filter them out:

```
[12] > !!6
[13] > .grep(!*.pull_request) >issues.json
[14] > <issues.json | ->elems
29
```

`!!6` brought back the full list ([6.3](#63-recalling-earlier-submissions)), and the
`grep` kept those *without* a `pull_request` entry: `!` means "not".

### 14.4 Answering a question

Which issues have no comments at all, oldest first?

```
[15] > <issues.json | grep *.comments == 0 | ->sort(*.created_at) | map { .number, .title }
((12 Crash when the config file is empty) (19 Docs: install on Windows) (23 Support YAML anchors) …)
```

The dates are text in the format `2026-03-14T08:21:05Z`, which sorts in time order as
text, so sorting by `created_at` sorts by age.

How long has each waited? Turn the text into a date, and subtract:

```
[16] > sub age-in-days(~stamp) { (DateTime->now - DateTime.new(~stamp))->Int div 86400 }
&age-in-days
[17] > age-in-days '2026-03-14T08:21:05Z'
251
```

`DateTime.new` reads a date and `DateTime->now` is the current time. Subtracting two
dates gives a duration in seconds, `->Int` drops its fractional part, and `div 86400`
turns seconds into whole days (`div` is division without a fractional part).

### 14.5 Shaping the report

Build one small hash per issue, with only what the report needs:

```
[18] > my @issues <issues.json
[19] > my @waiting = @issues
...      .grep(*.comments == 0)
...      .sort(*.created_at)
...      .map({ %( number => .number, title => .title, days => age-in-days(.created_at),
...                url => .html_url ) });
[20] > @waiting->elems
11
[21] > @waiting.0
{days => 251, number => 12, title => Crash when the config file is empty, url => https://github.com/ada/orbit/issues/12}
```

The same steps as the pipeline of submission 15, written as a **method chain**: each line starts
with a dot and continues the previous one, which lets a long expression spread over
several lines. `%( … )` makes a hash from a list of pairs. Inside a block, it makes the intention clear:
a bare `{ number => … }` inside braces would also work, but `%(…)` cannot be mistaken
for a block.

Save the data, for next week's comparison:

```
[22] > @waiting >waiting-2026-11-20.json
```

### 14.6 Writing the text

The report is Markdown, the same text format this tutorial is written in:

```
[23] > sub report(@items) {
...        say "## Issues waiting for a first answer";
...        say '';
...        for @items -> %i {
...            say "- [#{%i.number}]({%i.url}) {%i.title} — {%i.days} days";
...        }
...    }
&report
[24] > report @waiting
## Issues waiting for a first answer

- [#12](https://github.com/ada/orbit/issues/12) Crash when the config file is empty — 251 days
- [#19](https://github.com/ada/orbit/issues/19) Docs: install on Windows — 198 days
…
[25] > report @waiting >report.md
```

`report @waiting` printed to the screen, to check. `!!` would have repeated it; adding a
redirection sent the same output to a file ([11.1](#111-output-redirection)).

### 14.7 Posting

GitHub's API creates a comment on issue 1 when you POST `{ body => … }` to
`/repos/OWNER/REPO/issues/1/comments`:

```
[26] > my $text <report.md
[27] > { body => $text } >https://api.github.com/repos/$owner/$repo/issues/1/comments
{body => ## Issues waiting…, html_url => https://github.com/ada/orbit/issues/1#issuecomment-…, …}
[28] > .html_url
https://github.com/ada/orbit/issues/1#issuecomment-2483119
```

The token came from `gh` ([13.7](#137-credentials-headers-from-a-config-file)). The
response is the new comment, which became the topic, and its `html_url` is a link to
open in your browser.

### 14.8 What happened

In 28 submissions, you used:

- the file system: `pwd`, `mkdir`, `cd`, `ls` (chapters 2 and 5);
- a URL load saved to a file, then loads from the file (chapters 11 and 13);
- walking from the topic, `!!n` (chapters 6 and 9);
- `grep`, `sort`, `map` as pipeline stages (chapters 9 and 12);
- a routine with a `~` parameter, and a `DateTime` (chapters 7 and 10);
- a hash per record, saved as JSON (chapter 8);
- a routine that prints, redirected to a file (chapter 11);
- a POST to an API, its answer as the topic (chapter 13).

Next week you will want the same report. Typing 28 lines again is no way to live: the
next chapter turns this session into a script.

---

## 15. From irak to a `.rak` script

### 15.1 Scripts

A **script** is a file of rak code that runs from start to end, without you typing each
line. It is how a session becomes a tool. A rak script has a name ending in `.rak`, and
runs with the `rak` command:

```
$ cat hello.rak
say 'hello from a script';
$ rak hello.rak
hello from a script
```

(The `$` at the start of these lines is the prompt of the system shell, not of irak:
you run scripts from a terminal, or from irak itself with `rak hello.rak` as a command.)

What is the same as in irak: everything you learned. Naked strings, sigils, dotty paths,
redirections, URL targets, pipelines.

What is different:

| irak | script |
|---|---|
| each submission's value is shown | nothing is shown unless you `say` it |
| `$_` holds the previous value | `$_` is only set by `for`, `given`, blocks |
| `!!n`, `!n` | no history |
| statements are separated by pressing Enter | statements end with `;` |

The first two matter most. In a script, write `say` where irak would have shown a value,
and use variables where you used the topic.

### 15.2 Turning the session into a script

Take the useful lines of [chapter 14](#14-a-complete-session), drop the exploration, and
name things:

```
# waiting.rak — list issues waiting for a first answer, oldest first.

my $owner = 'ada';
my $repo  = 'orbit';

sub age-in-days(~stamp) { (DateTime->now - DateTime.new(~stamp))->Int div 86400 }

sub report(@items) {
    say "## Issues waiting for a first answer";
    say '';
    for @items -> %i {
        say "- [#{%i.number}]({%i.url}) {%i.title} — {%i.days} days";
    }
}

my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100;

my @waiting = @open
    .grep({ !.pull_request && .comments == 0 })
    .sort(*.created_at)
    .map({ %( number => .number, title => .title,
              days => age-in-days(.created_at), url => .html_url ) });

report @waiting >report.md;
say "{@waiting->elems} issues written to report.md";
```

Lines starting with `#` and a space are comments: for the human reader, ignored by rak.
The first comment says what the script is for. Write one at the top of every script;
you will thank yourself in six months.

The chain of `.grep`, `.sort`, `.map` replaces the pipeline: in a script, method chains
spread over lines read well too. Each line starts with a dot, and continues the previous
one.

### 15.3 Arguments: `MAIN`

The owner and the repository are written into the script. To use it for any project,
take them from the command line. Name a routine `MAIN`, and rak calls it with the
script's arguments ([3.5](#35-how-a-process-ends)):

```
sub MAIN($owner, $repo, #min-days = 0) {
    my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100;
    my @waiting = @open
        .grep({ !.pull_request && .comments == 0 })
        .map({ %( number => .number, title => .title,
                  days => age-in-days(.created_at), url => .html_url ) })
        .grep(*.days >= #min-days)
        .sort(-*.days);
    report @waiting >report.md;
    say "{@waiting->elems} issues written to report.md";
}
```

```
$ rak waiting.rak ada orbit 30
11 issues written to report.md
$ rak waiting.rak
Usage:
  waiting.rak <owner> <repo> [<#min-days>]
```

rak reads the parameters of `MAIN` and does the rest: it checks the arguments, converts
`30` to a number for `#min-days`, and prints a **usage** message when they don't fit. A
parameter with a default, like `#min-days = 0`, is optional.

Arguments are also available as a plain list, in `@*ARGS`.

### 15.4 Making a script a command

Two steps make a script runnable by its name alone, like `ls`.

1. A first line that says which program runs it, the **shebang** (from the `#!`
   characters, "hash-bang"):

   ```
   #!/usr/bin/env rak
   ```

   `/usr/bin/env rak` means "the `rak` found in my `$PATH`" ([3.3](#33-how-a-program-is-found-path)).

2. Permission to execute it ([2.4](#24-looking-closer-ls--l-and-ls--a)):

   ```
   $ chmod +x waiting.rak
   $ ./waiting.rak ada orbit
   ```

To run it from anywhere, put it in a directory listed in your `$PATH`, such as
`~/.local/bin`, and drop the `./`.

### 15.5 When things go wrong

A script runs without you watching. When something fails, it should say what, and stop
cleanly. By default, an error stops the script with a message and the exit status 1,
which is often enough. To handle an error yourself, wrap the risky part in `try`, and
look at the error in a `CATCH` block:

```
my @open = try {
    CATCH {
        when X::Rak::HTTP {
            note "GitHub said {$_->status} for {$_->url}";
            exit 2;
        }
    }
    my @o <https://api.github.com/repos/$owner/$repo/issues?state=open;
    @o
}
```

Inside `CATCH`, the error is the topic. `when X::Rak::HTTP` picks HTTP errors
([13.9](#139-when-the-server-says-no)); `->status` and `->url` ask it for two of its
parts.
`note` writes to standard error, so the message is not mixed with the report if the
output is redirected. `exit 2` stops the script with the status 2, which a caller can
test with `$?->exitcode`.

`die 'message'` raises an error of your own, when your script detects a problem:

```
die "no issues found for $owner/$repo" unless @open;
```

### 15.6 Running it every week

Once a script runs with no questions asked, the system can run it for you. On Linux, the
classic tool is `cron`: one line in your crontab (`crontab -e`) runs a command at fixed
times:

```
# minute hour day-of-month month day-of-week   command
  0      8    *            *     1             cd ~/reports && ~/.local/bin/waiting.rak ada orbit
```

Every Monday at 8:00. The output of a cron job is mailed to you, or lost, depending on
the system, so scripts run by cron should write their results to files, as this one
does.

### 15.7 A second example: `stars.rak`

A short script over the team file of [chapter 8](#8-complex-data-structures), to see
the main pieces once more:

```
#!/usr/bin/env rak
# stars.rak — total stars per person, at least MIN.

sub MAIN($file = 'team.json', #min = 0) {
    my %team <$file;
    for %team.people->list -> %p {
        my #s = %p.projects.map(*.stars)->sum;
        say "{%p.name}: #s" if #s >= #min;
    }
}
```

```
$ ./stars.rak
Ada: 165
Bo: 12
Cy: 0
$ ./stars.rak team.json 20
Ada: 165
```

Note `"{%p.name}"` in the string. Inside double quotes, write a dotty path in braces:
a bare `%p.name` would not be read as a path.

### Recap

- A `.rak` script runs from start to end. Nothing is shown unless you print it; there is
  no history and no topic carried between lines.
- `sub MAIN(…)` receives the command-line arguments, checks them, and writes a usage
  message.
- `#!/usr/bin/env rak` and `chmod +x` make a script a command.
- `try` with `CATCH`/`when` handles errors; `note` and `exit` report them; `die`
  raises one.
- `cron` runs scripts on a schedule.

### Exercises

1. Write `count.rak`, which takes a file name and prints how many lines it has, using a
   load.
   <details><summary>Answer</summary>

   ```
   sub MAIN($file) {
       my @lines <$file;
       say @lines->elems;
   }
   ```
   </details>

2. Add an optional `--json` flag to `stars.rak` that saves the result as JSON instead of
   printing it. (A parameter written `Bool :$json` is a flag: `--json` sets it to
   `True`.)
   <details><summary>Answer</summary>

   ```
   sub MAIN($file = 'team.json', $min = 0, Bool :$json) {
       my %team <$file;
       my %stars = %team.people->list.map({ .name => .projects.map(*.stars)->sum })
                                      .grep(*->value >= $min);
       if $json { %stars >stars.json } else { for %stars->sort { say "{$_->key}: {$_->value}" } }
   }
   ```
   A pair's `key` and `value` are methods, hence the arrows. (`#min` would be nicer, but
   a `#` parameter next to a named flag currently confuses `MAIN`.)
   </details>

3. What happens if `waiting.rak` runs in a directory you may not write to?
   <details><summary>Answer</summary>

   The fetch works, but `>report.md` fails with an error naming `report.md`. The script
   stops with a message and the exit status 1.
   </details>

---

## 16. Where to go next

You have come a long way: from what a file and a process are, through variables, nested
data and references, to pipelines, the web, and scripts. A few directions from here.

**Practice on your own data.** The best way to learn is to use irak for something you
already need: the JSON export of an app, your shell history, a log file at work. Load it,
walk it, ask questions.

**Keep the cheat sheet close.** `CHEATSHEET.md`, at the root of the rak repository, lists
every rak-specific syntax on a few pages.

**Read the glossary.** `GLOSSARY.md` defines the terms rak uses, with the exact meaning
each one has in the project.

**Learn more Raku.** rak is Raku with additions, so every Raku book, tutorial and answer
online applies, once you know the few differences. [Appendix A](#appendix-a-rak-and-raku-chapter-by-chapter)
maps them, chapter by chapter. The official documentation is at <https://docs.raku.org>;
"Think Raku" and "Raku Fundamentals" are friendly books for beginners. Raku has much that
this tutorial did not touch: classes and objects, grammars to parse any text, concurrency
with promises and supplies, and a large module ecosystem.

**Learn the shell itself.** rak runs your system's programs, and the more of them you
know, the more you can do. `man` followed by a command name shows its manual:
`man sort`, `man find`. "The Linux Command Line", by William Shotts, is free online and
excellent.

**Learn jq.** If you work with JSON from the web, `jq` is the standard tool. Its paths
look like rak's dotty paths, and you can call it from irak as any program:
`<data.json | ^jq '.items[] | .name'`.

**Know the limits.** rak is young. Some decisions are still open, and listed in the
repository under `PLANS/`. When something surprises you, check [Appendix B](#appendix-b-gotchas),
then the issue tracker, and report what you found: a surprise for you is a surprise for
the next beginner too.

Happy hacking.

---

# Appendices

## Appendix A: rak and Raku, chapter by chapter

rak is a frontend for Raku: the same language, with additions, active only in files ending
in `.rak` and in irak. Everything in Raku works in rak, with the exceptions listed here.
This appendix is for readers who know Raku, or who will read Raku material later.

### Chapters 1–3: the REPL and processes

| rak | Raku |
|---|---|
| irak, started with `rak` | the Raku REPL, started with `raku` |
| a submission's value becomes `$_` | the REPL does not set the topic |
| `!!n`, `!n` history recall | not in the Raku REPL |
| a bare command name runs a program: `ls -l` | `run 'ls', '-l'`, or `shell 'ls -l'` |
| `$?` (last status), `@?` (all, for a pipeline) | `$?` is unused; `run` returns a `Proc` |
| `$?->exitcode`, `$?->signal` | `$proc.exitcode`, `$proc.signal` |

### Chapter 4: values

| rak | Raku |
|---|---|
| naked strings: `say hello` | `say 'hello'` (a bare `hello` is a routine call) |
| juxtaposition passes several arguments: `f foo bar` | `f 'foo', 'bar'` |
| `->meth` calls a method with no arguments | `.meth` |
| `.word` is a subscript | `.word` is a method call; subscripts are `{'word'}` or `<word>` |

The last two rows are the biggest change. In rak, `.` reads data and `->` asks the value.
In Raku, `.` asks the value, and data is read with `{ }`, `< >` or `[ ]`. `->` keeps its
Raku meaning, a pointy block, wherever a term is expected: `for @a -> $x { }`.

### Chapter 5: commands

| rak | Raku |
|---|---|
| `type NAME` shows what a name means | no equivalent |
| a rak routine wins over a program of the same name; `^name` forces the program | no programs by name |
| `cd` is a builtin that changes `$*CWD` | `chdir`, or assigning to `$*CWD` |
| a command's output in parentheses is a string: `(git branch)` | `run(…, :out).out.slurp` |
| unknown commands are a compile-time error, checked against `$PATH` | — |

### Chapter 7: sigils

| rak | Raku |
|---|---|
| `my ~s` | `my str $s` |
| `my #n` | `my int $n` |
| `.~k`, `.#i` subscript with a native variable | `{$k}`, `[$i]` |
| `-> ~k`, `-> #i` in signatures | `-> str $k`, `-> int $i` |
| `#name` is a variable; `# ` with a space is a comment | `#` always starts a comment |

### Chapter 9: dotty subscripts

| rak | Raku |
|---|---|
| `%h.name` | `%h<name>` or `%h{'name'}` |
| `@a.1` | `@a[1]` |
| `%h.'two words'` | `%h{'two words'}` |
| `%h."$k"` | `%h{$k}` |
| `%h.~k` | `%h{$k}` (with `str $k`) |
| `@a.#i` | `@a[$i]` (with `int $i`) |
| `.people.0.name` (from the topic) | `.<people>[0]<name>` |
| `%h.k:exists`, `%h.k:delete` | `%h<k>:exists`, `%h<k>:delete` |
| `%h.$k` is an error | `%h.$k` calls the method in `$k` |
| `.5` is position 5 of the topic | `.5` is the number 0.5 |

The bracket forms still work in rak: `%h<name>`, `@a[1]` and `%h{$k}` are all accepted.

### Chapter 10: references

Nothing changes: binding, containers, itemization, `is rw`, `is copy`, `eqv` and `===`
are Raku's. `->list` is `.list`, `->clone` is `.clone`, `->deepmap(…)` is `.deepmap(…)`.

### Chapter 11: redirection

| rak | Raku |
|---|---|
| `STMT >file`, `STMT >>file` | `{ temp $*OUT = open('file', :w); STMT }` |
| `<file STMT` | `{ temp $*IN = open('file'); STMT }` |
| `my %h <file.json` | `my %h = from-json slurp 'file.json'` |
| `%h >file.json` (value mode) | `spurt 'file.json', to-json %h, :sorted-keys` |
| `.jsonl` targets | no builtin |
| spacing decides: `$a > 2` vs `$a >two` | `>` is always the comparison |

### Chapter 12: pipelines

| rak | Raku |
|---|---|
| `cmd | ^sort` | `run 'cmd', :out` then `run 'sort', :in($p.out)` |
| `… | ->meth`, `… | .path`, `… | name args` | `==>` feeds are the closest: `@a ==> map(…) ==> my @b` |
| `$?` pipefail, `@?` per stage | — |

In Raku, `|` at the start of a pipeline would be a junction. rak keeps the junction
meaning everywhere a pipeline does not start ([12.5](#125-when--is-a-pipe)).

### Chapter 13: URL targets

| rak | Raku |
|---|---|
| `<url` | a module such as `Cro::HTTP::Client` or `HTTP::Tiny` |
| `STMT >url`, `http METHOD URL BODY` | the same modules |
| `~/.config/rak/http-headers.json` | — |

### Chapter 15: scripts

`.rak` scripts are Raku scripts with rak syntax. `MAIN`, `@*ARGS`, `try`/`CATCH`, `die`,
`exit` and `note` are all Raku's. A file ending in `.raku` or `.rakumod` is plain Raku,
even when run by `rak`, so rak and Raku code can live side by side in one project.

---

## Appendix B: Gotchas

The surprises most beginners hit, each with the fix and where it is explained.

**`say hello world` prints `helloworld`.**
Juxtaposed naked strings are separate arguments, and `say` joins them with nothing.
Write `say 'hello world'`, or `say hello, ' ', world`.
([4.3](#43-strings-naked-and-quoted))

**`$x.exitcode`, `@a.end`, `%h.keys` don't call the method.**
A dot followed by a word is a subscript. Use the arrow for a method with no arguments:
`$?->exitcode`, `@a->end`, `%h->keys`. With arguments, the dot calls: `.split(',')`.
([9.5](#95-subscripts-and-methods))

**`.5` is not one half.**
A dot followed by a number subscripts the topic. Write `0.5`.
([9.3](#93-walking-from-the-topic))

**`%h.$k` is an error.**
rak cannot tell whether `$k` holds a key or a method name. Write `%h."$k"`, `%h.~k`, or
`%h->$k` for a method. ([9.4](#94-steps-held-in-variables))

**`%h.2024` says "Index out of range".**
A number after a dot is a position. For a key made of digits, quote it: `%h.'2024'`.
([9.1](#91-one-step-at-a-time))

**`[ { a => 1 } ]` is not an array holding one hash.**
A single hash alone in brackets is flattened into its pairs. Add a trailing comma:
`[ { a => 1 }, ]`. ([8.4](#84-building-teamjson))

**`<a b>` inside brackets misparses.**
Write `['a', 'b']`. ([8.4](#84-building-teamjson))

**`for %team.people { … }` loops once.**
Values inside structures are itemized. Write `for %team.people->list { … }`. The same
for `my @p = %team.people->list`. ([10.5](#105-boxes-inside-boxes-itemization))

**Changing a copy changes the original.**
Assignment copies one level. Nested arrays and hashes stay shared. Use `deep-copy` or a
JSON round trip. ([10.3](#103-the-surprise-copies-are-shallow))

**`my ~t := ~s` fails.**
Native variables cannot be bound. Assign instead. ([10.8](#108-native-variables-cannot-be-shared))

**`my #n = 2.7` and `my #n = 'abc'` fail.**
A `#` variable holds whole numbers only. Use `$` for fractions, `->Int` to drop the
fractional part. ([7.3](#73-raks-own-sigils--and-))

**`#count` became a variable when you meant a comment.**
A comment starts with `#` and a space. ([7.6](#76-types-and-comments))

**`$a >2` or `$a <5` does not compare.**
A redirection touches its target; a comparison is spaced. Write `$a > 2`, `$a < 5`.
([11.7](#117-spacing-is-syntax))

**`say … >file.json` fails with "invalid JSON".**
Text mode: the printed text must be JSON. Drop the `say` to save the value.
([11.5](#115-value-mode-and-text-mode))

**`>>file.json` is refused.**
JSON holds one value. Use a `.jsonl` file to append records.
([11.4](#114-formats))

**`my %h <list.json` fails.**
The sigil must fit the content: `@` for an array, `%` for an object, `$` for anything.
([11.4](#114-formats))

**`@names | ^sort` doesn't pipe.**
A pipeline starts with a command, a load or a leading dotty path. Set the topic and
write `.[] | ^sort`. ([12.5](#125-when--is-a-pipe))

**`$?` says the pipeline failed though the last command succeeded.**
`$?` is the first failure in the pipeline. `@?` has every stage's status.
([12.8](#128-exit-status-of-a-pipeline))

**`"%p.name"` doesn't interpolate the name.**
In double quotes, put a dotty path in braces: `"{%p.name}"`. ([15.7](#157-a-second-example-starsrak))

**A routine and a program share a name; the routine runs.**
`type NAME` shows both. Use `^name` for the program. ([5.3](#53-who-wins-a-name))

**`my @all <url` takes forever.**
`@` fetches every page. Use `$` and `->head` while exploring.
([13.8](#138-pages))

**A value prints in irak but not in your script.**
Scripts show nothing on their own. Add `say`. ([15.1](#151-scripts))

**Using a value that may be missing gives a warning about "uninitialized value".**
A missing path is undefined. Guard with `//`, or test with `:exists`.
([9.9](#99-missing-paths))

---

## Appendix C: Mini glossary

**API**: a service made for programs, usually answering HTTP requests with JSON.
([13.1](#131-clients-servers-and-urls))

**argument**: a value given to a routine or a program when calling it.

**array**: an ordered list of values, held in an `@` variable. ([8.1](#81-arrays))

**binding** (`:=`): making a name refer to an existing container, instead of copying a
value into a new one. ([10.2](#102-binding-a-second-name-for-the-same-thing))

**block**: code between braces `{ }`. It has its own scope.

**body** (of an HTTP request or response): the content, as opposed to the headers.

**container**: the box that holds a value in a `$`, `@` or `%` variable, or inside a
structure. Native variables have none.

**current directory**: the directory relative paths start from; `$*CWD`, `pwd`.

**deep copy**: a copy of every level of a nested structure. Compare **shallow copy**.
([10.4](#104-copying-on-purpose))

**dotty subscript**: `.key` or `.position` after a value, reading one step into it.
([9.1](#91-one-step-at-a-time))

**dynamic variable**: a variable with `*` after its sigil, provided by rak:
`$*CWD`, `%*ENV`, `@*ARGS`.

**element**: one value of an array or list.

**environment variable**: a named string a process inherits from its parent: `HOME`,
`PATH`. Read with `%*ENV`. ([3.2](#32-what-every-process-carries))

**exit status**: the number a process returns when it ends; 0 for success. In `$?`.

**format**: how values are turned into bytes and back: JSON, JSON Lines, text. Chosen by
extension or by `Content-Type`. ([11.4](#114-formats))

**hash**: a table of keys and values, held in a `%` variable. ([8.2](#82-hashes))

**header** (HTTP): a labelled fact sent with a request or response, such as
`Content-Type`.

**index**: the position of an element in an array, counted from 0.

**irak**: rak's interactive prompt, the REPL.

**itemization**: putting a list in a single box so that it counts as one item.
([10.5](#105-boxes-inside-boxes-itemization))

**JSON**, **JSON Lines**: text formats for data. ([8.7](#87-json-the-common-language-of-data))

**juxtaposition**: writing naked strings side by side, as separate arguments:
`f foo bar`.

**key**: the name that leads to a value in a hash.

**lazy**: computed only when needed. Pipelines and paged URL loads are lazy.

**load**: `TARGET <source`: reading and decoding a file or URL into a variable or the
topic. ([11.3](#113-load-a-file-into-a-variable))

**method**: something a value can do, called with `->name` or `.name(…)`.

**naked string**: a word written without quotes, used as a string. ([4.3](#43-strings-naked-and-quoted))

**native**: a value stored directly, without a container: `~` and `#` variables.
([7.3](#73-raks-own-sigils--and-))

**path** (data): a chain of dotty subscripts: `.people.0.name`.
**path** (file): a chain of directory names: `/home/ada/notes.txt`.

**pipeline**: stages joined by `|`, each feeding the next. ([chapter 12](#12-pipelines))

**pointy block**: a block with parameters: `-> $x { … }`.

**process**: a running program, with its own memory, ID and standard streams.
([chapter 3](#3-processes))

**range**: `1..5`, the numbers from 1 to 5.

**recursion**: a routine that calls itself on the smaller parts of a problem.
([9.8](#98-unknown-depth-walking-everything))

**redirection**: sending a statement's input or output to a file or URL instead of the
terminal. ([chapter 11](#11-redirection-and-formats))

**REPL**: Read-Eval-Print Loop, an interactive prompt such as irak.

**routine**: a named piece of code, declared with `sub`, called with arguments.

**scope**: the part of the code where a name is valid.

**script**: a file of rak code run from start to end. ([chapter 15](#15-from-irak-to-a-rak-script))

**shallow copy**: a copy of the first level of a structure; nested parts are shared.
([10.3](#103-the-surprise-copies-are-shallow))

**shebang**: the `#!` first line of a script, naming the program that runs it.

**sigil**: the symbol at the start of a variable's name: `$ @ % & ~ #`.
([chapter 7](#7-variables-and-sigils))

**signal**: a message the system sends to a process, such as `SIGINT` (Ctrl-C) or
`SIGPIPE`. ([3.7](#37-stopping-a-process))

**slip** (`|`): spilling a list's elements into a surrounding list.

**smartmatch** (`~~`): testing a value against a type, pattern or value.

**stage**: one part of a pipeline: a program, or a rak method, path, block or routine.

**standard input, output, error**: the three streams every process starts with.
In rak: `$*IN`, `$*OUT`, `$*ERR`.

**status code** (HTTP): the number that says how a request went: 200, 404, 500.

**submission**: what you type at the irak prompt and send with Enter.

**topic** (`$_`): the current value: in irak, the previous submission's value; in a
loop, the current element. ([chapter 6](#6-the-topic-and-history))

**undefined**: an empty `$` container, shown as `(Any)`. ([7.5](#75-missing-values))

**URL**: the address of something on the web. ([13.1](#131-clients-servers-and-urls))

**value mode**, **text mode**: whether a redirection writes the statement's value or
its printed text. ([11.5](#115-value-mode-and-text-mode))

**whatever expression**: `*.name`, `* + 1`: a short anonymous routine, `*` standing for
its argument. ([9.7](#97-transforming-lists))
