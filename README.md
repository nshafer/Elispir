Elispir
=======

Lisp-like parser/evaluator in Elixir.  Supports variables, conditionals, functions, closures, recursion.

Inspired by [this blog post](http://itsbarakyo.com/projects/2015/09/17/elisper-lisp-in-elixir.html) by barakyo

### Anonymous functions

    iex> sum = fn (a, b) -> a + b end
    #Function<12.54118792/2 in :erl_eval.expr/5>
    iex> Elispir.eval([sum, 1, 2])
    3


### Function capture

Use any function available with Elixir's capture operator `&`

    iex> Elispir.eval([&+/2, 1, 1])
    2

    iex> Elispir.eval([&+/2, [&+/2, 2, 2], [&+/2, 2, 3]])
    9

## Do clauses

Evaluate multiple expressions with a `:do` clause.  The value of the last expression is returned

    iex> Elispir.eval([:do, [&IO.puts/1, "Hello"], [&IO.puts/1, "World"]])
    Hello
    World
    :ok

### If statements

    iex> Elispir.eval([:if, [&==/2, 1, 1], [&+/2, 1, 1], [&+/2, 2, 2]])
    2

### Define variables inside a `:do` block

    iex> Elispir.eval([:do, [:def, :a, 5]])
    5

    iex> Elispir.eval([:do,
    ...>   [:def, :a, 5],
    ...>   [&+/2, :a, :a]
    ...> ])
    10

### Define a named function

    iex> Elispir.eval(
    ...>   [:do,
    ...>     [:def, :square,
    ...>       [:fn, [:x],
    ...>         [&*/2, :x, :x]
    ...>       ]
    ...>     ]
    ...>   ]
    ...> )
    "&:square/1"

### Call the function (within the same `:do` block)

    iex> Elispir.eval(
    ...>   [:do,
    ...>     [:def, :square,
    ...>       [:fn, [:x], [&*/2, :x, :x]]
    ...>     ],
    ...>     [:square, 5],
    ...>   ]
    ...> )
    25

### The value of variables is captured at the time that the function is defined (closures)

    iex> Elispir.eval(
    ...>   [:do,
    ...>     [:def, :outside, 2],
    ...>     [:def, :square,
    ...>       [:fn, [], [&*/2, :outside, :outside]]
    ...>     ],
    ...>     [:def, :outside, 3],
    ...>     [:square]
    ...>   ]
    ...> )
    4


### Call a function recursively

    iex> Elispir.eval(
    ...>   [:do,
    ...>     [:def, :factorial,
    ...>       [:fn, [:n], 
    ...>         [:if, [&==/2, :n, 0],
    ...>           1,
    ...>           [&*/2, :n, [:factorial, [&-/2, :n, 1]]]
    ...>         ]
    ...>       ]
    ...>     ],
    ...>     [:factorial, 4]
    ...>   ]
    ...> )
    24


See [tests](test/elispir_test.exs) for more examples.
