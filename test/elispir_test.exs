defmodule ElispirTest do
  use ExUnit.Case, async: true

  test "evaluate anonymous function" do
    sum = fn (a, b) -> a + b end
    assert Elispir.eval([sum, 1, 2]) == 3
  end

  test "native addition function" do
    assert Elispir.eval([&+/2, 1, 2]) == 3
  end

  test "two expression arguments" do
    assert Elispir.eval([&+/2, [&+/2, 1, 1], [&+/2, 1, 1]]) == 4
  end

  test "native comparison operator" do
    assert Elispir.eval([&==/2, 1, 1]) == true
  end

  test "if expression" do
    assert Elispir.eval([:if, [&==/2, 1, 1], [&+/2, 1, 1], [&+/2, 2, 2]]) == 2
  end

  test "if expression with 1 literal" do
    assert Elispir.eval([:if, [&==/2, 1, 1], 2, [&+/2, 2, 2]]) == 2
  end

  test "if expression with 2 literals" do
    assert Elispir.eval([:if, [&==/2, 1, 1], 2, 4]) == 2
  end

  test "if expression with 3 literals - false" do
    assert Elispir.eval([:if, false, 2, 4]) == 4
  end

  test "if expression with 3 literals - true" do
    assert Elispir.eval([:if, true, 2, 4]) == 2
  end

  test "do returns literal" do
    assert Elispir.eval([:do, 2]) == 2
  end

  test "do returns last literal" do
    assert Elispir.eval([:do, 2, 3]) == 3
  end

  test "do returns function result" do
    assert Elispir.eval([:do, [&-/2, 4, 2]]) == 2
  end

  test "do returns nil if given nothing to do" do
    assert Elispir.eval([:do]) == nil
  end

  test "define a variable in a do block" do
    assert Elispir.eval([:do, [:def, :a, 5], [&+/2, :a, :a]]) == 10
  end

  test "redefine a variable in a do block" do
    assert Elispir.eval([:do, [:def, :a, 3], [:def, :a, 4], [&+/2, :a, :a]]) == 8
  end

  test "define a variable as the result of an expression" do
    assert Elispir.eval([:do, [:def, :a, [&+/2, 4, 4]]]) == 8
  end

  test "do does not leak scope" do
    assert Elispir.eval(
      [:do,
        [:def, :a, 3],
        [:do, 
          [:def, :a, 5]
        ],
        [&+/2, :a, 2]
      ]
    ) == 5
  end

  test "inner do blocks can reference variables from outer do blocks" do
    assert Elispir.eval(
      [:do,
        [:def, :a, 6],
        [:do, 
          [&*/2, :a, 2]
        ]
      ]
    ) == 12
  end

  test "define a function" do
    assert Elispir.eval(
      [:do,
        [:def, :square,
          [:fn, [:a], [&*/2, :a, :a]]
        ]
      ]
    ) == "&:square/1"
  end

  test "call a function" do
    assert Elispir.eval(
      [:do,
        [:def, :square,
          [:fn, [:a], [&*/2, :a, :a]]
        ],
        [:square, 4]
      ]
    ) == 16
  end

  test "function parameters override existing values from outside the scope" do
    assert Elispir.eval(
      [:do,
        [:def, :a, 2],
        [:def, :square,
          [:fn, [:a], [&*/2, :a, :a]]
        ],
        [:square, 4]
      ]
    ) == 16
  end

  test "undefined functions raise an error" do
    assert_raise UndefinedElispirFunctionError, fn ->
      Elispir.eval([:does_not_exist])
    end
  end

  test "access variables defined outside of function" do
    assert Elispir.eval(
      [:do,
        [:def, :outside, 2],
        [:def, :square,
          [:fn, [], [&*/2, :outside, :outside]]
        ],
        [:square]
      ]
    ) == 4
  end

  test "scope is captured at definition" do
    assert Elispir.eval(
      [:do,
        [:def, :outside, 2],
        [:def, :square,
          [:fn, [], [&*/2, :outside, :outside]]
        ],
        [:def, :outside, 3],
        [:square]
      ]
    ) == 4
  end

  test "logic in a function" do
    assert Elispir.eval(
      [:do,
        [:def, :istwo,
          [:fn, [:a], [:if, [&==/2, :a, 2], true, false]]
        ],
        [:istwo, 2]
      ]
    ) == true
  end

  test "recursion" do
    assert Elispir.eval(
      [:do,
        [:def, :factorial,
          [:fn, [:n], 
            [:if, [&==/2, :n, 0],
              1,
              [&*/2, :n, [:factorial, [&-/2, :n, 1]]]
            ]
          ]
        ],
        [:factorial, 4]
      ]
    ) == 24
  end

  test "fibonacci" do
    assert Elispir.eval(
      [:do,
        [:def, :fib,
          [:fn, [:n],
            [:if, [&>/2, :n, 1],
              [&+/2, 
                [:fib, [&-/2, :n, 1]],
                [:fib, [&-/2, :n, 2]]
              ],
              1
            ]
          ]
        ],
        [:fib, 8]
      ]
    ) == 34
  end
end
