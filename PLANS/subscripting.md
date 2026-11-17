
New primary sigils are introduced to denote integer and strings.
They don't undergo the overhead of boxing or Scalar proxy and the 
integer fits in a 64 bits register, in raku parlance it is an `int`.

With the use of `.` as subscripter operator and thse new sigils,
subscripting is less noisy in many common cases.

in rak and unambiguous like in raku. The `.[]`  postcircumfix is not
overloaded to access hashes.
In simple case `.` is used when the subscript is simple.


When a subscript can be interpreted as `int` literal
it is an array subscript, when it matches the sigiless rule 
it is a hash subscript.

@a.1.foo.#int-var.~string.

```rak
@a[1]<foo>[#int]{~string}
```


`->` is used for parenthesis-less method call.
