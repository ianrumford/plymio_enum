defmodule PlymioEnumTransformDefenumtransform1ModuleTest do

  use PlymioEnumHelpersTest

  import PET, only: [defenumtransform: 1,]

  #use Plymio.Enum.Transform

  defenumtransform composite1(

    filter: fn x -> x end,

    group_by: [fn {k,_v} -> k end, fn k -> k |> to_string end],

    map: fn {_k, v} -> v end,

  )

  defenumtransform composite2(

    filter: fn x -> x end,

    group_by: [fn {k,_v} -> k end, fn k -> k |> to_string end],

    reject: fn
      {"x", _} -> true
      _ -> false
    end,

    map: fn {_k, v} -> v end,

  )

  defenumtransform composite3(

    filter: fn v -> is_number(v) end,
    filter: fn v -> v > 0 end,
    map: fn v -> v * v end,
    map: fn v -> v + 42 end,
    reject: fn v -> v < 45 end,
    reject: fn v -> v > 50 end

  )

  defenumtransform composite4(

    {:filter, [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end]},
    {:map, [fn {k,v} -> {k, v * v} end, fn {k,v} -> {k, v + 42} end]},
    {:reject, [fn {_k,v} -> v < 45 end, fn {_k,v} -> v > 50 end]},
    :to_list,
    {List, :insert_at, [2, {:e, "five"}]}

  )

end

defmodule PlymioEnumTransformDefenumtransform1Test do

  use PlymioEnumHelpersTest

  require PlymioEnumTransformDefenumtransform1ModuleTest, as: DTM1

  test "enum_transform: composite 1" do

    transform_fun = &DTM1.composite1/1

    # apply the transform fun
    helper_assert_transform_realise(
      [[a: 1], [b: 2], [c: 3]],
      @t_test1,
      transform_fun)

  end

  test "enum_transform: composite 2" do

    transform_fun = &DTM1.composite2/1

    # apply the transform fun
    helper_assert_transform_realise(
      [[y: 11], [z: 12]],
      @t_test2,
      transform_fun)

  end

  test "enum_transform: composite 3" do

    transform_fun = &DTM1.composite3/1

    # apply the transform fun
    helper_assert_transform_realise(
      [46],
      [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)],
      transform_fun)

  end

  test "enum_transform: composite 4" do

    transform_fun = &DTM1.composite4/1

    # apply the transform fun
    helper_assert_transform_realise(
      [b: 46, e: "five"],
      [a: 1, b: 2, c: 3, d: :atom],
      transform_fun)

  end

end
