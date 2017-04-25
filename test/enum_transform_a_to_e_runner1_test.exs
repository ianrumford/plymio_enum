defmodule PlymioEnumTransformAtoERunner1Test do

  use PlymioEnumHelpersTest

  test "functions: a to e" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # ALL?/2

        [true, ["all?": &(&1)]],
        [true, ["all?": fn {_k,v} -> is_number(v) end]],
        [false, ["all?": fn {_k,v} -> is_float(v) end]],
        [true, ["all?": [fn {_k,v} -> is_integer(v) end, fn {k,_v} -> k in [:a, :b, :c] end]]],

        # ANY?/2

        [true, ["any?": fn {_k,v} -> v == 2 end]],
        [false, ["any?": fn {k,_v} -> is_binary(k) end]],
        [true, ["any?": [fn {_k,v} -> v > 1 end, fn {k,_v} -> k == :c end]]],
        [false, ["any?": [fn {_k,v} -> v == 1 end, fn {k,_v} -> k == :c end]]],

        # AT/3

        [{:c, 3}, [at: 2]],
        [{:c, 3}, [at: [2]]],
        [42, [at: [99, 42]]],
        [{:b, 2}, [at: [1, 42]]],
        [{:a, 1}, [at: [-3, 42]]],

        # CHUNK/2

        [[[a: 1], [b: 2], [c: 3]], [chunk: 1]],
        [[[a: 1, b: 2]], [chunk: 2]],
        [[[a: 1, b: 2, c: 3]], [chunk: 3]],
        [[], [chunk: 4]],

        # CHUNK/3

        [[[a: 1], [b: 2], [c: 3]], [chunk: [1, 1]]],
        [[[a: 1], [c: 3]], [chunk: [1, 2]]],
        [[[a: 1]], [chunk: [1, 3]]],
        [[[a: 1]], [chunk: [1, 4]]],
        [[[a: 1, b: 2], [b: 2, c: 3]], [chunk: [2, 1]]],
        [[[a: 1, b: 2]], [chunk: [2, 2]]],
        [[[a: 1, b: 2]], [chunk: [2, 3]]],
        [[[a: 1, b: 2, c: 3]], [chunk: [3, 1]]],
        [[[a: 1, b: 2, c: 3]], [chunk: [3, 2]]],
        [[[a: 1, b: 2, c: 3]], [chunk: [3, 3]]],

        # CHUNK/4

        [[[a: 1], [b: 2], [c: 3]], [chunk: [1, 1, [:fill]]]],
        # this makes no sense but its what chunk does
        [[[a: 1], [c: 3], [c: 3]], [chunk: [1, 2, [:fill]]]],
        [[[a: 1]], [chunk: [1, 3, [:fill]]]],

        # CHUNK_BY/2

        [[[a: 1], [b: 2], [c: 3]], [chunk_by: fn v -> v end]],
        [[[a: 1], [b: 2], [c: 3]], [chunk_by: fn {_k,v} -> v end]],
        [[[a: 1], [b: 2], [c: 3]], [chunk_by: fn {k,_v} -> k end]],
        [[[a: 1], [b: 2], [c: 3]], [chunk_by: fn {_k,v} -> rem(v, 2) == 1 end]],
        [[[a: 1], [b: 2, c: 3]], [chunk_by: fn {_k,v} -> v < 2 end]],
        [[[a: 1, b: 2], [c: 3]], [chunk_by: fn {_k,v} -> v < 3 end]],

        # CONCAT/1

        # list of enums signature
        [test_value ++ [d: 4], [concat: [[d: 4]]]],
        [test_value ++ [d: 4, e: 5], [concat: [[d: 4], [e: 5]]]],
        [test_value ++ [d: 4, e: 5, f: 6], [concat: [[d: 4], [e: 5], %{f: 6}]]],

        # CONCAT/2
        # left,right signature
        [test_value ++ [d: 4], [concat: [d: 4]]],
        [test_value ++ [d: 4, e: 5, f: 6], [concat: [d: 4, e: 5, f: 6]]],

        # COUNT/1

        [3, :count],
        [3, [count: []]],
        [3, [count: nil]],

        # COUNT/2

        [3, [count: fn x -> x end]],
        [1, [count: fn {k,_v} -> k == :a end]],
        [2, [count: fn {_k,v} -> v > 1 end]],
        [1, [count: [fn {_k,v} -> v > 1 end, fn {k,_v} -> k == :c end]]],
        [0, [count: [fn {_k,v} -> v > 1 end, fn {k,_v} -> k == :a end]]],

        # DEDUP/1

        # dedup *consecutive* values
        [[a: 1, b: 2, c: 3, c: 42], [dedup: nil], [a: 1, a: 1, b: 2, c: 3, c: 3, c: 42]],
        [[1, 2, 3], [dedup: nil], [1, 2, 2, 3, 3, 3]],

        # DEDUP_BY/2

        [[a: 1], [dedup_by: fn {_k, v} -> v end], [a: 1, b: 1, c: 1]],
        [[a: 11, b: 2], [dedup_by: fn {k, _v} -> k end], [a: 11, a: 12, b: 2]],

        # DROP/2

        [[b: 2, c: 3], [drop: 1]],
        [[c: 3], [drop: 2]],
        [[], [drop: 3]],
        [[], [drop: 4]],
        [[a: 1, b: 2], [drop: -1]],
        [[a: 1], [drop: -2]],
        [[], [drop: -3]],
        [[], [drop: -4]],

        # DROP_EVERY/2

        # zeroth element is always dropped, unless n == 0
        [[a: 1, b: 2, c: 3], [drop_every: 0]],
        [[], [drop_every: 1]],
        [[b: 2], [drop_every: 2]],
        [[b: 2, c: 3], [drop_every: 3]],
        [[2,4,6,8,10], [drop_every: 2], [1,2,3,4,5,6,7,8,9,10]],
        [[2,3,5,6,8,9], [drop_every: 3], [1,2,3,4,5,6,7,8,9,10]],

        # DROP_WHILE/2

        [[1,2,3,4,5,6,7,8,9,10], [drop_while: fn x -> x > 5 end], [1,2,3,4,5,6,7,8,9,10]],
        [[6,7,8,9,10], [drop_while: fn x -> x <= 5 end], [1,2,3,4,5,6,7,8,9,10]],
        [[3,2,1], [drop_while: fn x -> x < 3 end], [1,2,3,2,1]],
        [[3,2,1], [drop_while: [fn x -> x == 1 end, fn x -> x < 3 end]], [1,2,3,2,1]],

        # EACH/2

        [[1,2,3], [each: fn x -> x * x end], [1,2,3]],
        [[1,2,3], [each: fn _x -> :ignored end], [1,2,3]],

        # EMPTY?/1

        [false, [empty?: nil]],
        [false, [empty?: []]],
        [false, :empty?],
        [false, :empty?, [1,2,3]],
        [false, [empty?: nil], [1,2,3]],
        [false, [empty?: []], [1,2,3]],

        ])

  end

end

