defmodule PlymioEnumTransformStoSRunner1Test do

  use PlymioEnumHelpersTest

  test "functions: s to s" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # SCAN/2

        [[1,3,6], [scan: fn v,s -> v + s end], [1,2,3]],
        [[1,3,6], [scan: fn v,s -> v + s end], [1,2,3]],

        # SCAN/3

        [[1,9,144], [scan: [fn v,s -> v + s end, fn x -> x * x end]], [1,2,3]],

        # SHUFFLE/1

        [[1], [shuffle: nil], [1]],
        [[1], [shuffle: []], [1]],
        [[1], :shuffle, [1]],
        [fn enum -> enum |> Enum.all?(fn x -> Enum.member?([3,5,7], x) end) end, :shuffle, [3,5,7]],

        # SLICE/2

        [[3,5,7], [slice: 0 .. 2], [3,5,7]],
        [[7], [slice: -1 .. 2], [3,5,7]],
        [[5,7], [slice: -2 .. 2], [3,5,7]],
        [[3,5,7], [slice: 0 .. 999], [3,5,7]],
        [[7], [slice: 2 .. 999], [3,5,7]],
        [[], [slice: 3 .. 9999], [3,5,7]],
        [[], [slice: 3 .. 2], [3,5,7]],
        [[3,5,7], [slice: 0 .. -1], [3,5,7]],
        [[5,7], [slice: 1 .. -1], [3,5,7]],

        # SLICE/3

        [[3,5,7], [slice: [0, 3]], [3,5,7]],
        [[7], [slice: [2, 1]], [3,5,7]],
        [[5,7], [slice: [1, 3]], [3,5,7]],
        [[7], [slice: [-1, 3]], [3,5,7]],
        [[5,7], [slice: [-2, 3]], [3,5,7]],

        # SORT/1

        [[1,2,3], :sort, [1,2,3]],
        [[1,2,3], :sort, [3,2,1]],
        [[:a,:b,:c], :sort, [:c, :a, :b]],
        [[a: 1, b: 2, c: 3], :sort, %{a: 1, b: 2, c: 3}],
        [[a: 1, b: 2, c: 3], :sort, %{c: 3, a: 1, b: 2}],

        # SORT/2

        [[1,2,3], [sort: &<=/2], [1,2,3]],
        [[3,2,1], [sort: &>=/2], [1,2,3]],
        [[a: 1, b: 2, c: 3], [sort: fn {_k1,v1}, {_k2,v2} -> v1 <= v2 end], [a: 1, b: 2, c: 3]],
        [[c: 3, b: 2, a: 1], [sort: fn {_k1,v1}, {_k2,v2} -> v1 >= v2 end], [a: 1, b: 2, c: 3]],

        # SORT_BY/2

        [[1,2,3], [sort_by: fn x ->  x end], [1,2,3]],
        [[3,2,1], [sort_by: fn x ->  x * (-1)  end], [1,2,3]],
        [[b: 2, c: 3, a: 1], [sort_by: fn
                               {:a, 1} -> 99
                               _x -> 1
                             end], %{c: 3, a: 1, b: 2}],

        # SORT_BY/3

        [[1,2,3], [sort_by: [fn x ->  x end, &<=/2]], [1,2,3]],
        [[3,2,1], [sort_by: [fn x ->  x end, &>=/2]], [1,2,3]],
        [[c: 3, b: 2, a: 1], [sort_by: [fn x ->  x end, &>=/2]], [a: 1, b: 2, c: 3]],
        [[c: 3, b: 2, a: 1], [sort_by: [fn x ->  x end, fn {_k1,v1}, {_k2,v2} -> v1 >= v2 end]], [a: 1, b: 2, c: 3]],

        # SPLIT/2

        [{[1],[2,3]}, [split: 1], [1,2,3]],
        [{[1,2],[3]}, [split: 2], [1,2,3]],
        [{[1,2,3],[]}, [split: 99], [1,2,3]],
        [{[],[1,2,3]}, [split: -99], [1,2,3]],

        # SPLIT_WHILE/2

        [{[1],[2,3]}, [split_while: fn x -> x <= 1 end], [1,2,3]],
        [{[1,2],[3]}, [split_while: fn x -> x != 3 end], [1,2,3]],

        # multiple funs are OR-ed
        [{[1,2],[3]}, [split_while: [fn x -> x < 3 end, fn x -> x == 1 end]], [1,2,3]],
        [{[1],[2,3]}, [split_while: [fn x -> x == 1 end, fn x -> x > 2 end]], [1,2,3]],
        # always false
        [{[1,2,3], []}, [split_while: [fn x -> x <= 2 end, fn x -> x == 3 end]], [1,2,3]],

        # SPLIT_WITH/2

        [{[1],[2,3]}, [split_with: fn x -> x <= 1 end], [1,2,3]],
        [{[1,3],[2]}, [split_with: fn x -> x != 2 end], [1,2,3]],

        # multiple funs are AND-ed
        [{[3],[1,2]}, [split_with: [fn x -> x > 1 end, fn x -> x > 2 end]], [1,2,3]],

        # SUM/1

        [6, :sum, [1,2,3]],
        {{:e, ArithmeticError}, :sum, [:a,1,2,3]},

        ])

  end

end

