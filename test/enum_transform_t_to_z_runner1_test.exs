defmodule PlymioEnumTransformTtoZRunner1Test do

  use PlymioEnumHelpersTest

  # Some tests lifted from Elixir doctests

  test "functions: t to z" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

       # TAKE/2

        [[1,2], [take: 2], [1,2,3]],
        [[], [take: 0], [1,2,3]],
        [[1,2,3], [take: 99], [1,2,3]],
        [[3], [take: -1], [1,2,3]],
        [[2,3], [take: -2], [1,2,3]],
        [[1,2,3], [take: -99], [1,2,3]],

        # TAKE_EVERY/2

        [[], [take_every: 0], [1,2,3,4,5,6,7]],
        [[1,2,3,4,5,6,7], [take_every: 1], [1,2,3,4,5,6,7]],
        # 1st is always included
        [[1,3,5,7], [take_every: 2], [1,2,3,4,5,6,7]],
        [[1], [take_every: 99], [1,2,3,4,5,6,7]],
        {{:e, FunctionClauseError}, [take_every: -99], [1,2,3,4,5,6,7]},

        # TAKE_RANDOM/2

        [fn e -> e |> Enum.all?(fn v -> Enum.member?([1,2,3,4,5,6,7], v) end) end, [take_random: 3], [1,2,3,4,5,6,7]],
        [fn e -> e |> Enum.all?(fn v -> Enum.member?([1,2,3,4,5,6,7], v) end) end, [take_random: 0], [1,2,3,4,5,6,7]],
        [fn e -> e |> Enum.all?(fn v -> Enum.member?([1,2,3,4,5,6,7], v) end) end, [take_random: 99], [1,2,3,4,5,6,7]],
        {{:e, FunctionClauseError}, [take_random: -99], [1,2,3,4,5,6,7]},

        # TAKE_WHILE/2

        [[1,2,3,4,5,6,7], [take_while: fn _v -> true end], [1,2,3,4,5,6,7]],
        [[1,2], [take_while: fn v -> v < 3 end], [1,2,3,4,5,6,7]],
        [[7,6,5], [take_while: fn v -> v > 4 end], [7,6,5,4,3,2,1]],

        # multiple funs are AND-ed
        [[7,6], [take_while: [fn v -> v > 4 end, fn v -> is_integer(v) end]], [7,6,:a,5,4,3,2,1]],

        # TO_LIST/1

        [[1,2,3], :to_list, [1,2,3]],
        [[a: 1, b: 2, c: 3], :to_list, [a: 1, b: 2, c: 3]],
        [[a: 1, b: 2, c: 3], :to_list, %{a: 1, b: 2, c: 3}],
        [[a: 1, b: 2, c: 3], :to_list, %{a: 1, b: 2, c: 3} |> Stream.map(&(&1))],

        # UNIQ/1

        [[1,2,3], :uniq, [1,2,3]],
        [[3,2,1], :uniq, [3,2,1]],
        [[3,2,1], :uniq, [3,2,1,3,2,1,3,2,1]],
        [[c: 3, b: 2, a: 1, c: 33, b: 22, a: 11], :uniq, [c: 3, b: 2, a: 1, c: 3, b: 2, a: 1, c: 33, b: 22, a: 11]],

        # UNIQ_BY/2

        [[1], [uniq_by: fn _v -> 42 end], [1,2,3]],
        [[3], [uniq_by: fn _v -> 42 end], [3,2,1]],
        [[c: 3, b: 2, a: 1], [uniq_by: fn {k,_v} -> k end], [c: 3, b: 2, a: 1, c: 3, b: 2, a: 1, c: 33, b: 22, a: 11]],

        # multiple funs are reduced mappers
        [[7,6,4,2], [uniq_by: [fn v -> v end, fn v -> v + rem(v,2) end]], [7,6,5,4,3,2,1]],
        [[7,5,3,1], [uniq_by: [fn v -> v end, fn v -> v - rem(v,2)end]], [7,6,5,4,3,2,1]],

        # UNZIP/1

        [{[:a,:b,:c],[1,2,3]}, :unzip, [a: 1, b: 2, c: 3]],
        [{[:a,:b,:c],[1,2,3]}, :unzip, %{a: 1, b: 2, c: 3}],
        [{[:a,:b,:c],[1,2,3]}, :unzip, %{a: 1, b: 2, c: 3} |> Stream.map(&(&1))],

        # WITH_INDEX/1

        [[{1,0}, {2, 1}, {3, 2}], :with_index, [1,2,3]],
        [[{{:a,1},0}, {{:b,2}, 1}, {{:c,3}, 2}], :with_index, [a: 1, b: 2, c: 3]],

        # WITH_INDEX/2

        [[{1,42}, {2, 43}, {3, 44}], [with_index: 42], [1,2,3]],
        [[{1,-1}, {2, 0}, {3, 1}], [with_index: -1], [1,2,3]],
        [[{1,42}, {2, 43}, {3, 44}], [with_index: 42], [1,2,3]],
        [[{{:a,1},42}, {{:b,2}, 43}, {{:c,3}, 44}], [with_index: 42], [a: 1, b: 2, c: 3]],

        # ZIP/1

        [[{1, :a, "foo"}, {2, :b, "bar"}, {3, :c, "baz"}], :zip, [[1, 2, 3], [:a, :b, :c], ["foo", "bar", "baz"]]],
        # stops when first enum is exhausted
        [[{1, :a, "foo"}, {2, :b, "bar"}], :zip, [[1, 2], [:a, :b, :c], ["foo", "bar", "baz"]]],

        # ZIP/2

        [[{1, :a}, {2, :b}, {3, :c}], [zip: [[:a,:b,:c]]], [1,2,3]],

        # stops when either enum is exhausted
        [[{1, :a}, {2, :b}], [zip: [[:a,:b,:c]]], [1,2]],
        [[{1, :a}, {2, :b}], [zip: [[:a,:b]]], [1,2,3]],

        ])

  end

end

