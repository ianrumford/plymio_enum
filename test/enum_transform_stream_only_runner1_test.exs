defmodule PlymioEnumTransformStreamOnlyRunner1Test do

  use PlymioEnumHelpersTest

  # Some tests lifted from Elixir doctests

  test "functions: stream only" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_tests_default1(
      test_value: test_value,
      test_specs: [

        # CYCLE/1

        [helper_stream_make_fun({:take, 3}, [1,2,3]), :cycle, [1,2,3]],
        [helper_stream_make_fun({:take, 0}, []), :cycle, [1,2,3]],
        [helper_stream_make_fun({:take, 6}, [1,2,3,1,2,3]), :cycle, [1,2,3]],
        # LOOPS! [helper_stream_make_fun({:map, fn v -> v * v end}, [1,4,9]), :cycle, [1,2,3]],

        # INTERVAL/1

        [helper_stream_make_fun({:take, 3}, [0,1,2]), :interval,  10],
        [helper_stream_make_fun({:take, 0}, []), :interval,  5],

        # ITERATE/2
        [helper_stream_make_fun({:take, 3}, [100,142,184]), [iterate: fn v -> 42 + v end],  100],
        [helper_stream_make_fun({:take, 3}, [1,1,1]), [iterate: fn v -> v * v end],  1],
        [helper_stream_make_fun({:take, 3}, [1,4,25]), [iterate: fn v -> (v + 1)  * (v + 1) end],  1],

        # REPEATEDLY

        # this uses Harnais mfa-like form (args are a tuple => ignore test value)
        [helper_stream_make_fun({:take, 3}, [42,42,42]), {Stream, :repeatedly, {fn -> 42 end}}],

        # RESOURCE/3

        [helper_stream_make_fun({:to_list, nil}, [1,2,2,4,4,4,4]),

         {Stream, :resource,

          # this is a Harnais thing - args is tuple => ignore test_value
          {

          # initializer
          fn ->
            1
           end,

           # next
           fn

             v when v <= 5 -> {List.duplicate(v,v), v + v}

             v  -> {:halt, v}

           end,

           # finalizer - receives the accumulator but result not used
           fn s ->
             s
          end

          }}],

        # RUN

        [:ok, :run, [1,2,3]],
        [:ok, :run, [a: 1, b: 2, c: 3]],
        [:ok, :run, [1,2,3] |> Stream.map(&(&1))],

        # TIMER

        # time returns a stream that when realised (:to_list) gives [0]
        [helper_stream_make_fun({:take, 1}, [0]), {Stream, :timer, {10}}],
        [helper_stream_make_fun({:take, 3}, [0]), {Stream, :timer, {10}}],

        # TRANSFORM/3

        # example derived from one in the Elixir docs
        [helper_stream_make_fun({:take, 5}, [42,42,42,42,42]),
         [transform: [0,
                      fn v, s -> if s < 5, do: {[v], s + 1}, else: {:halt, s} end]],
         Stream.repeatedly(fn -> 42 end)],

        # TRANSFORM/4

        # busking it
        [helper_stream_make_fun({:to_list, nil}, [1,2,2,3,3,3,4,4,4,4,5,5,5,5,5]),
         [transform: [

           # initializer
           fn ->
             0
           end,

           # reducer
           fn

             v, s when v <= 5 -> {List.duplicate(v,v), s + v}

             _v, s -> {:halt, s}

           end,

           # finalizer - receives the accumulator but result not used
           fn s -> s end]],

         # enum
         1 .. 100],

        # UNFOLD/2

        # example from Elixir docs
        [helper_stream_make_fun({:take, 999}, [5,4,3,2,1]),
         # args ars tuple is a Harnais thing => ignore test_value
         {Stream, :unfold, {5, fn 0 -> nil; n -> {n, n-1} end}}],

      ])

  end

end

