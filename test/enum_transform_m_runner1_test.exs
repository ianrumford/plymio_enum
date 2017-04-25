defmodule PlymioEnumTransformRunner1Test do

  use PlymioEnumHelpersTest

  test "functions: m" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # MAP/2

        [[1,2,3], [map: fn v -> v end], [1,2,3]],
        [[a: 1, b: 2, c: 3], [map: fn x -> x end]],
        [[a: 1, b: 2, c: 3], [map: [fn x -> x end]]],
        [[true, true, true], [map: [fn {_k,v} -> v end, fn v -> is_number(v) end]]],
        [[1,4,9], [map: [fn {_k,v} -> v end, fn v -> v*v end]]],
        [[a: 1, b: 2, c: 3], [map: fn v -> v end], %{a: 1, b: 2, c: 3}],
        [[a: 1, b: 2, c: 3], [map: fn v -> v end], %{a: 1, b: 2, c: 3} |> Stream.map(&(&1))],
        [[1,4,9], [map: [fn v -> v end, fn v -> v * v end]], [1,2,3]],

        # MAP/EVERY/3

        # first value is always mapped
        [[a: 1, b: 2, c: 3], [map_every: [1, &(&1)]]],
        [[a: 1, b: 2, c: 3], [map_every: [2, &(&1)]]],
        [[a: 1, b: 2, c: 3], [map_every: [99, &(&1)]]],
        [[a: 1, b: 4, c: 9], [map_every: [1, fn {k,v} -> {k,v*v} end]]],
        [[a: 1, b: 2, c: 9], [map_every: [2, fn {k,v} -> {k,v*v} end]]],
        [[a: 2, b: 2, c: 3], [map_every: [99, fn {k,v} -> {k,v+1} end]]],

        # MAP_JOIN/3

        ["123", [map_join: fn x -> x end], [1,2,3]],
        ["1_2_3", [map_join: ["_", fn x -> x end]], [1,2,3]],
        ["abc", [map_join: nil], [:a,:b,:c]],
        ["a_1_b_2_c_3", [map_join: ["_", &(&1)]], [:a,1,:b,2,:c,3]],

        # MAP_REDUCE/3

        [{[1,2,3],6}, [map_reduce: [0, fn v,s -> {v, s + v} end]], [1,2,3]],
        [{[a: 1, b: 2, c: 3],6}, [map_reduce: [0, fn {k,v},s -> {{k,v}, s + v} end]], [a: 1, b: 2, c: 3]],

        # mixed
        [{[1,4,9],14}, [map_reduce: [0, [fn v -> v*v end, fn v,s -> {v, s + v} end]]], [1,2,3]],

        # MAX/2

        [3, [max: nil], [1,2,3]],
        [3, [max: []], [1,2,3]],
        [:c, :max, [:a,:b,:c]],

        # MAX_BY/3

        [-3, [max_by: fn x -> x |> abs end], [-1,-2,-3]],
        ["little", [max_by: fn x -> x |> String.length end], ["mary", "had", "a", "little", "lamb"]],
        ["mary", [max_by: fn x -> x |> String.length end], ["mary", "had", "a", "huge", "lamb"]],

        [-1, [max_by: [fn x -> x |> abs end, fn _ -> 42 end]], [-1,-2,-3]],
        ["mary" , [max_by: [fn x -> x |> String.length end, fn _ -> 42 end]], ["mary", "had", "a", "little", "lamb"]],
        ["a", [max_by: [fn x -> x |> String.length end,
                        fn
                          1 -> 99
                          x -> x
                         end]], ["mary", "had", "a", "huge", "lamb"]],

        # MEMBER?/2

        [true, [member?: 2], [1,2,3]],
        [false, [member?: :a], [1,2,3]],
        [true, [member?: {:c, 3}], %{a: 1, b: 2, c: 3}],

        # MIN/2

        [1, [min: nil], [1,2,3]],
        [1, [min: []], [1,2,3]],
        [:a, :min, [:a,:b,:c]],

        # MIN_BY/3

        [-1, [min_by: fn x -> x |> abs end], [-1,-2,-3]],
        ["a", [min_by: fn x -> x |> String.length end], ["mary", "had", "a", "little", "lamb"]],
        ["had", [min_by: fn x -> x |> String.length end], ["mary", "had", "few", "lambs"]],

        [-3, [min_by: [fn x -> x |> abs end, fn _ -> 42 end]], [-3, -2, -1]],
        ["mary", [min_by: [fn x -> x |> String.length end, fn _ -> 42 end]], ["mary", "had", "a", "little", "lamb"]],

        # MIN_MAX/2

        [{1, 3}, [min_max: nil], [1,2,3]],
        [{1, 3}, [min_max: []], [1,2,3]],
        [{:a, :c}, :min_max, [:a,:b,:c]],

        # MIN_MAX_BY/3

        [{-1, -3}, [min_max_by: fn x -> x |> abs end], [-1,-2,-3]],
        [{"a", "little"}, [min_max_by: fn x -> x |> String.length end], ["mary", "had", "a", "little", "lamb"]],
        [{"had", "lambs"}, [min_max_by: fn x -> x |> String.length end], ["mary", "had", "few", "lambs"]],

        [{-1, -1} , [min_max_by: [fn x -> x |> abs end, fn _ -> 42 end]], [-1,-2,-3]],
        [{-3, -3} , [min_max_by: [fn x -> x |> abs end, fn _ -> 42 end]], [-3, -2, -1]],
        ])

  end

end

