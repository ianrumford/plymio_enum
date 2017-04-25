defmodule PlymioEnumTransformComposite1Test1 do

  use PlymioEnumHelpersTest

  test "enum_transform: composite 1" do

    transform_fun = helper_assert_transform_build(

      filter: fn x -> x end,

      group_by: [fn {k,_v} -> k end, fn k -> k |> to_string end],

      map: fn {_k, v} -> v end,

    )

    # apply the transform fun
    helper_assert_transform_realise(
      [[a: 1], [b: 2], [c: 3]],
      @t_test1,
      transform_fun)

  end

  test "enum_transform: composite 2" do

    transform_fun = helper_assert_transform_build(

      filter: fn x -> x end,

      group_by: [fn {k,_v} -> k end, fn k -> k |> to_string end],

      reject: fn
        {"x", _} -> true
        _ -> false
      end,

      map: fn {_k, v} -> v end,

    )

    # apply the transform fun
    helper_assert_transform_realise(
      [[y: 11], [z: 12]],
      @t_test2,
      transform_fun)

  end

  test "enum_transform: composite 3" do

    transform_fun = helper_assert_transform_build(
      filter: fn v -> is_number(v) end,
      filter: fn v -> v > 0 end,
      map: fn v -> v * v end,
      map: fn v -> v + 42 end,
      reject: fn v -> v < 45 end,
      reject: fn v -> v > 50 end)

    # apply the transform fun
    helper_assert_transform_realise(
      [46],
      [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)],
      transform_fun)

  end

  test "enum_transform: composite 4" do

    transform_fun = helper_assert_transform_build(
      [
        {:filter, [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end]},
        {:map, [fn {k,v} -> {k, v * v} end, fn {k,v} -> {k, v + 42} end]},
      {:reject, [fn {_k,v} -> v < 45 end, fn {_k,v} -> v > 50 end]},
        :to_list,
        {List, :insert_at, [2, {:e, "five"}]}
      ])

    # apply the transform fun
    helper_assert_transform_realise(
      [b: 46, e: "five"],
      [a: 1, b: 2, c: 3, d: :atom],
      transform_fun)

  end

  test "enum_transform: composite 5" do

    filter_fun = [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]]
    |> helper_assert_transform_build

    mapper_fun = [map: [fn v -> v * v end, fn v -> v + 42 end]]
    |> helper_assert_transform_build

    reject_fun = [reject: [fn v -> v < 45 end, fn v -> v > 50 end]]
    |> helper_assert_transform_build

    transform_fun = [filter_fun, mapper_fun, reject_fun]
    |> helper_assert_transform_build

    # apply the transform fun
    helper_assert_transform_realise(
      [46],
      [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)],
      transform_fun)

  end

  test "enum_transform: composite 6" do

    transform_pipeline = [
      filter: fn {_k,v} -> is_number(v) end,
      map: fn {k,v} -> {k,v*v} end,
      group_by: fn {k,_v} -> k |> to_string end
    ]

    # apply the transform fun
    helper_assert_transform_realise(
      %{"a" => [a: 1], "b" => [b: 4], "c" => [c: 9]},
      [a: 1, b: 2, c: 3, d: :atom],
      transform_pipeline)

  end

end
