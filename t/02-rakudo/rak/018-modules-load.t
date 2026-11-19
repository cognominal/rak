use Test;

plan 1;

# Run through the rak wrapper: core modules compile under the rak frontend
# with Raku semantics. NativeCall has a `#word` comment, which rak syntax
# would read as a `#`-sigiled variable; Terminal::LineEditor needs it.

lives-ok { EVAL 'use NativeCall; 1', :lang<Raku> }, 'NativeCall loads under the rak frontend';
