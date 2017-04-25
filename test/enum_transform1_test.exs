defmodule PlymioEnumTransform1Test1 do

  use PlymioEnumHelpersTest

  test "enum_transform: filter" do

    helper_assert_transform_realise(
      @l_test1,
      @l_test1,
      filter: fn x -> x end)

    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:a, :c]),
      @t_test1,
      filter:
      fn
        {:b, _} -> false
        _ -> true
      end)

    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:a, :c]),
      @t_test1,
      filter: helper_make_2tuple_reject_key(:b))

    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:c]),
      @t_test1,
      filter: [
        helper_make_2tuple_reject_key(:b),
        helper_make_2tuple_reject_key(:a)])

    # pre create the transform fun
    transform_fun = helper_assert_transform_build(
      filter: [
        helper_make_2tuple_reject_key(:b),
        helper_make_2tuple_reject_key(:a)])

    # apply the transform fun
    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:c]),
      @t_test1,
      transform_fun)

  end

    test "enum_transform: reject" do

    helper_assert_transform_realise(
      [],
      @l_test1,
      reject: fn x -> x end)

    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:b]),
      @t_test1,
      reject:
      fn
        {:b, _} -> false
        _ -> true
      end)

    helper_assert_transform_realise(
      @t_test1 |> Keyword.take([:b]),
      @t_test1,
      reject: helper_make_2tuple_reject_key(:b))

    helper_assert_transform_realise(
      [],
      @t_test1,
      reject: [
        helper_make_2tuple_reject_key(:b),
        helper_make_2tuple_reject_key(:a)])

    # pre create the transform fun
    transform_fun = helper_assert_transform_build(
      reject: [
        helper_make_2tuple_reject_key(:b),
      helper_make_2tuple_reject_key(:a)])

    # apply the transform fun
    helper_assert_transform_realise(
      [],
      @t_test1,
      transform_fun)

    transform_fun = helper_assert_transform_build(
      reject: [helper_make_2tuple_reject_key(:b)])

    # apply the transform fun
    helper_assert_transform_realise(
       @t_test1 |> Keyword.take([:b]),
      @t_test1,
      transform_fun)

  end

  test "enum_transform: transform" do

    helper_assert_transform_realise(
      @l_test1,
      @l_test1,
      map: fn x -> x end)

    helper_assert_transform_realise(
      @t_test1 |> List.keyreplace(:b, 0, {:b, 42}),
      @t_test1,
      map:
      fn
        {:b, _} -> {:b, 42}
        x -> x
      end)

    helper_assert_transform_realise(
      @t_test1 |> List.keyreplace(:b, 0, {:b, 42}) |> List.keyreplace(:a, 0, {:a, 99}),
      @t_test1,
      map: [
      fn
        {:b, _} -> {:b, 42}
        x -> x
      end,
      fn
        {:a, _} -> {:a, 99}
        x -> x
      end,
      ])

    helper_assert_transform_realise(
      @t_test1 |> List.keyreplace(:b, 0, {:b, 123}) |> List.keyreplace(:a, 0, {:a, 99}),
      @t_test1,
      map: [
      fn
        {:b, _} -> {:b, 42}
        x -> x
      end,
      fn
        {:a, _} -> {:a, 99}
        x -> x
      end,
      fn
        {:b, _} -> {:b, 123}
        x -> x
      end,
      ])

    transform_fun = helper_assert_transform_build(
      map: [
      fn
        {:b, _} -> {:b, 42}
        x -> x
      end,
      fn
        {:a, _} -> {:a, 99}
        x -> x
      end,
      fn
        {:b, _} -> {:b, 123}
        x -> x
      end,
      ])

    # apply the transform fun
    helper_assert_transform_realise(
      @t_test1 |> List.keyreplace(:b, 0, {:b, 123}) |> List.keyreplace(:a, 0, {:a, 99}),
      @t_test1,
      transform_fun)

    end

  test "enum_transform: group_by" do

    helper_assert_transform_realise(
      %{{:a, 1} => [a: 1], {:b, 2} => [b: 2], {:c, 3} => [c: 3]},
      @k_test1,
      group_by: fn x -> x end)

    helper_assert_transform_realise(
      %{a: [a: 1], b: [b: 2], c: [c: 3]},
      @k_test1,
      group_by: fn {k,_v} -> k end)

    helper_assert_transform_realise(
      %{1 => [a: 1], 2 => [b: 2], 3 => [c: 3]},
      @k_test1,
      group_by: fn {_k,v} -> v end)

    helper_assert_transform_realise(
      %{a: [a: 1, a: 1], b: [b: 2, b: 2], c: [c: 3, c: 3]},
      @k_test1 ++ @k_test1,
      group_by: fn {k,_v} -> k end)

    # miltiple group by funs just a Enum.reduce on the original {k,v}
    helper_assert_transform_realise(
      %{"a" => [a: 1, a: 1], "b" => [b: 2, b: 2], "c" => [c: 3, c: 3]},
      @k_test1 ++ @k_test1,
      group_by: [fn {k,_v} -> k end, fn k -> k |> to_string end])

  end

end

