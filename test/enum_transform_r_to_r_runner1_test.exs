defmodule PlymioEnumTransformRtoRRunner1Test do

  use PlymioEnumHelpersTest

  test "functions: r to r" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # RANDOM/1

        # duh!
        [1, [random: nil], [1]],
        [1, [random: []], [1]],
        [1, :random, [1]],
        [fn x -> Enum.member?([3,5,7], x) end, :random, [3,5,7]],

        # REDUCE/2

        [6, [reduce: fn v,s -> v + s end], [1,2,3]],
        [6, [reduce: [fn v,s -> v + s end]], [1,2,3]],
        [[c: 3, b: 2, a: 1], [reduce: fn v,s -> v ++ s end], [[a: 1], [b: 2], [c: 3]]],

        # all arity 2
        [3, [reduce: [fn v,s -> v + s end, fn v,s -> v - s end]], [1,2,3]],
        [18, [reduce: [fn v,s -> v + s end, fn v,s -> v * s end]], [1,2,3]],

        # mixed arity. note first element of enum must be a keyword
        [[c: 3, b: 2, a: 1], [reduce: [fn v -> v |> List.wrap end,
                                       fn v,s -> v ++ s end]], [[a: 1], b: 2, c: 3]],

        # REDUCE/3

        [15, [reduce: [9, fn v,s -> v + s end]], [1,2,3]],
        [[3,2,1], [reduce: [[], fn v,s -> [v | s] end]], [1,2,3]],
        [%{a: 1, b: 2, c: 3}, [reduce: [%{}, fn {k,v},s -> s |> Map.put(k,v) end]], [a: 1, b: 2, c: 3]],

        # all arity 2
        [3, [reduce: [9, [fn v,s -> v + s end, fn v,s -> v - s end]]], [1,2,3]],
        [194920, [reduce: [4, [fn v,s -> v + s end, fn v,s -> v * s end]]], [1,2,3]],

        # mixed arity
        [14, [reduce: [0, [fn v -> v * v end, fn v,s -> v + s end]]], [1,2,3]],

        # all arity 1 => effectively just a map with result 3*3*3*3
        [81, [reduce: [:ignored, [fn v -> v * v end, fn v -> v * v end]]], [1,2,3]],

        # a doctest example
        [4375094500, [reduce: [7,
                               [fn v, s ->
                                 v + s
                               end,
                               fn v ->
                                  v - 42
                                end,
                                fn v, s ->
                                  v * s
                                end]]], [1,2,3]],

        # REDUCE_WHILE/3

        [[2,1], [reduce_while: [[],
                                fn
                                  v,s when v > 2 -> {:halt, s}
                                  v,s -> {:cont, [v | s]}
                                end]], [1,2,3]],

        # mixed arity
        [[4,1], [reduce_while: [[],
                                [fn
                                  v,s when v > 2 -> {:halt, s}
                                  v,s -> {:cont, [v | s]}
                                end,
                                fn
                                {:halt, s} -> {:halt, s |> Enum.map(fn v -> v*v end)}
                                  x -> x
                                end]]], [1,2,3]],

        # REJECT/2

        [[3,5], [reject: fn x -> x == 7 end], [3,5,7]],
        [[5], [reject: [fn x -> x == 7 end, fn x -> x < 5 end]], [3,5,7]],

        # REVERSE/1

        [[7,5,3], [reverse: nil], [3,5,7]],
        [[7,5,3], [reverse: []], [3,5,7]],
        [[7,5,3], :reverse, [3,5,7]],
        [[c: 3, b: 2, a: 1], :reverse, [a: 1, b: 2, c: 3]],

        # REVERSE/2

        [[7,5,3,9,11,13], [reverse: [[9,11,13]]], [3,5,7]],
        [[c: 3, b: 2, a: 1, d: 4, e: 5], [reverse: [[d: 4, e: 5]]], [a: 1, b: 2, c: 3]],

        # REVERSE_SLICE/3

        [[3,5,7], [reverse_slice: [0, 1]], [3,5,7]],
        [[5,3,7], [reverse_slice: [0, 2]], [3,5,7]],
        [[7,5,3], [reverse_slice: [0, 3]], [3,5,7]],
        [[7,5,3], [reverse_slice: [0, 99]], [3,5,7]],
        [[3,7,5], [reverse_slice: [1, 2]], [3,5,7]],

        ])

  end

end

