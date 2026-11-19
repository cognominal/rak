# Used by 019-module-eval.t: EVALs whose meaning differs between Raku and rak.
unit module RakEvalProbe;

sub tilde-method() is export { EVAL '(1, 2).map({ ~.succ }).join(",")' }

sub dotty-call() is export {
    my $s = Supplier.new;
    EVAL '$s.Supply.^name'
}
