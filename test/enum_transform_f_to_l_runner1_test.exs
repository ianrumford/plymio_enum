defmodule PlymioEnumTransformFtoLRunner1Test do

  use PlymioEnumHelpersTest

  test "functions: f to l" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # FETCH/2

        [{:ok, {:a, 1}}, [fetch: 0]],
        [{:ok, {:b, 2}}, [fetch: 1]],
        [{:ok, {:c, 3}}, [fetch: 2]],
        [:error, [fetch: 4]],
        [{:ok, {:c, 3}}, [fetch: -1]],
        [{:ok, {:b, 2}}, [fetch: -2]],
        [{:ok, {:a, 1}}, [fetch: -3]],
        [:error, [fetch: -4]],

        # FETCH!/2

        {:r, {:a, 1}, [fetch!: 0]},
        {:r, {:b, 2}, [fetch!: 1]},
        {:r, {:c, 3}, [fetch!: 2]},
        {{:e, Enum.OutOfBoundsError}, [fetch!: 4]},
        {:r, {:a, 1}, [fetch!: -3]},
        {:r, {:b, 2}, [fetch!: -2]},
        {:r, {:c, 3}, [fetch!: -1]},
        {{:e, Enum.OutOfBoundsError}, [fetch!: -4]},

        # FILTER/2

        [[b: 2], [filter: fn {k,_v} -> k == :b end]],
        [[b: 2, c: 3], [filter: fn {_k,v} -> v > 1 end]],
        [[c: 3], [filter: [fn {_k,v} -> v > 1 end, fn {k,_v} -> k == :c end]]],

        # FILTER_MAP/3

        [[b: 4, c: 9], [filter_map: [fn {_k,v} -> v > 1 end, fn {k,v} -> {k, v * v} end]]],
        [[9], [filter_map: [[fn {_k,v} -> v > 1 end, fn {k,_v} -> k == :c end],
                            [fn {k,v} -> {k, v * v} end, fn {_k,v} -> v end]]]],

        [{:c, 3}, [find: fn {k,_v} -> k == :c end]],
        [nil, [find: fn {k,_v} -> k == :d end]],
        [42, [find: [42, fn {k,_v} -> k == :d end]]],

        # note: if the default is a fun, a single filter fun must be in a list
        [{:c, 3}, [find: [&(&1), [fn {k,_v} -> k == :c end]]]],
        [&(&1), [find: [&(&1), [fn {k,_v} -> k == :d end]]]],
        [{:c, 3}, [find: [&(&1), [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 3 end]]]],

        [2, [find_index: fn {k,_v} -> k == :c end]],
        [2, [find_index: [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 3 end]]],
        [nil, [find_index: [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 99 end]]],

        [true, [find_value: fn {k,_v} -> k == :c end]],
        [true, [find_value: [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 3 end]]],
        [nil, [find_value: [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 99 end]]],

        [true, [find_value: [42, fn {k,_v} -> k == :c end]]],
        [42, [find_value: [42, fn {k,_v} -> k == :d end]]],
        [true, [find_value: [42, [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 3 end]]]],
        [42, [find_value: [42, [fn {k,_v} -> k == :c end, fn {_k,v} -> v == 99 end]]]],

        # FLAT_MAP/2

        [[1,2,3], [flat_map: fn v -> [v] end], [1,2,3]],
        [[1,1,2,2,3,3], [flat_map: fn v -> [v,v] end], [1,2,3]],
        [[1,1,4,4,9,9], [flat_map: [fn v -> v * v end, fn v -> [v,v] end]], [1,2,3]],

        # FLAT_MAP_REDUCE/3

        [{[1,2,3], 6}, [flat_map_reduce: [0, fn i, s -> {[i], s + i} end]], [1,2,3]],
        [{[[1],[2],[3]], 6}, [flat_map_reduce: [0, fn i, s -> {[[i]], s + i} end]], [1,2,3]],
        [{[1,1,2,2,3,3], 14}, [flat_map_reduce: [0, fn i, s -> {[i,i], s + (i * i)} end]], [1,2,3]],

        # GROUP_BY/3

        [%{1 => [1], 2 => [2], 3 => [3]}, [group_by: fn v -> v end], [1,2,3]],
        [%{4 => [1,2,3]}, [group_by: [fn v -> v end, fn _v -> 4 end]], [1,2,3]],
        [%{a: [a: 1], b: [b: 2], c: [c: 3]}, group_by: fn {k,_v} -> k end],
        [%{a: [a: 1, b: 2, c: 3]}, group_by: [fn {k,_v} -> k end, fn _k -> :a end]],

        # INTERSPERSE/2

        [[1,42,2,42,3], [intersperse: 42], [1,2,3]],
        [[a: 1, d: 4, b: 2, d: 4, c: 3], [intersperse: {:d, 4}]],

        # INTO/2

        # note: into is Enum by default
        [%{a: 1, b: 2, c: 3}, [into: %{}]],
        [[a: 1, b: 2, c: 3], [into: [[]]]],
        [[a: 1, b: 2, c: 3], [into: []]],
        [[d: 4, a: 1, b: 2, c: 3], [into: [[d: 4]]]],
        [[d: 4, a: 1, b: 2, c: 3], [into: [d: 4]]],

        # Stream.into is a noop (identity transformation) for the enum
        [[a: 1, b: 2, c: 3], [{{Stream,:into}, %{d: 4}}]],
        [[a: 1, b: 2, c: 3], [{{Stream,:into}, [d: 4]}]],

        # INTO/3

        [[d: 4, e: 5, f: 6, a: 1, b: 2, c: 3], [into: [[d: 4, e: 5, f: 6], fn x -> x end]]],
        [%{d: 4, e: 5, f: 6, a: 1, b: 2, c: 3}, [into: [%{d: 4, e: 5, f: 6}, fn x -> x end]]],
        [%{a: 1, b: 4, c: 9}, [into: [%{}, fn {k,v} -> {k, v*v} end]]],

        # Stream.into is a noop (identity transformation) for the enum
        [[a: 1, b: 2, c: 3], [{{Stream,:into}, [[d: 4], fn {k,v} -> {k, v*v} end]}]],

        # JOIN/2

        ["123", [join: nil], [1,2,3]],
        ["1_2_3", [join: "_"], [1,2,3]],
        ["abc", [join: nil], [:a,:b,:c]],
        ["a_1_b_2_c_3", [join: "_"], [:a,1,:b,2,:c,3]],

        ])

  end

end

