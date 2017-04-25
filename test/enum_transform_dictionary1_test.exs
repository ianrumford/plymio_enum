defmodule PlymioEnumTransformDictionary1Test1 do

  use PlymioEnumHelpersTest

  test "dictionary: accessors" do

    td = %PETD{}

    assert [:fun1] = td
    |> PETD.put(:fun1, &(&1))
    |> helper_transform_dictionary_keys

    assert [:fun1, :fun2, :fun3] = td
    |> PETD.put(:fun1, &(&1))
    |> PETD.put(:fun2, &(&1))
    |> PETD.put(:fun3, &(&1))
    |> PETD.put(:fun1, &(&1))
    |> PETD.keys

    assert [42] = td
    |> PETD.put(:fun1, &(&1))
    |> PETD.put(:fun2, &(&1))
    |> PETD.put(:fun3, &(&1))
    |> PETD.put(:fun1, &(&1))
    |> PETD.values
    |> Enum.map(fn fun -> fun.(42) end)
    |> Enum.uniq

    td = td
    |> PETD.put(:fun1, &(&1))
    |> PETD.put(:fun2, &(&1))
    |> PETD.put(:fun3, &(&1))
    |> PETD.put(:funx, &(&1))

    assert td |> PETD.has_key?(:funx)
    refute td |> PETD.has_key?(:funp)

    assert 4 = td |> PETD.count

    td = td |> PETD.delete(:funx)
    |> helper_assert_transform_dictionary

    refute td |> PETD.has_key?(:funx)

    assert 3 = td |> PETD.count
    assert [:fun1, :fun2, :fun3] = td |> PETD.keys

  end

  test "build: no td, no opts" do
    PETD.build()
    |> helper_assert_transform_dictionary
  end

  test "build: td, no opts" do
    %PETD{}
    |> PETD.build()
    |> helper_assert_transform_dictionary
  end

  test "build: create td, opts 1" do

    opts = [
      f1: [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]],
      m1: [map: [fn v -> v * v end, fn v -> v + 42 end]],
      r1: [reject: [fn v -> v < 45 end, fn v -> v > 50 end]],
    ]

    td = opts |> PETD.build
    |> helper_assert_transform_dictionary

    assert [:f1, :m1, :r1] == td |> PETD.keys

  end

  test "build: update td, opts 1" do

    opts1 = [
      f1: [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]],
      m1: [map: [fn v -> v * v end, fn v -> v + 42 end]],
      r1: [reject: [fn v -> v < 45 end, fn v -> v > 50 end]],
    ]

    td1 = opts1 |> PETD.build
    |> helper_assert_transform_dictionary

    td1_keys_actual = td1 |> PETD.keys |> Enum.sort
    td1_keys_expect = [:f1, :m1, :r1] |> Enum.sort

    assert td1_keys_expect == td1_keys_actual

    opts2 = [
      f1: [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]],
      m2: [map: [fn v -> v * v end, fn v -> v + 42 end]],
      r2: [reject: [fn v -> v < 45 end, fn v -> v > 50 end]],
    ]

    td2 = td1 |> PETD.build(opts2)
    |> helper_assert_transform_dictionary

    td2_keys_actual = td2 |> PETD.keys |> Enum.sort
    td2_keys_expect = [:f1, :m1, :r1, :m2, :r2] |> Enum.sort

    assert td2_keys_expect == td2_keys_actual

  end

  test "build: pipelines" do

    opts = [

      v_f_number: [filter: fn v -> is_number(v) end],
      v_f_gt_0:   [filter: fn v -> v > 0 end],
      v_m_squared:      [map: fn v -> v * v end],
      v_m_plus_42:      [map: fn v -> v + 42 end],
      v_r_lt_45:     [reject: fn v -> v < 45 end],
      v_r_gt_50:     [reject: fn v -> v > 50 end]

    ]

    opts_keys = Keyword.keys(opts) |> Enum.uniq |> Enum.sort

    td = opts
    |> PETD.build
    |> helper_assert_transform_dictionary

    assert opts_keys == td |> PETD.keys |> Enum.sort

  end

  test "build: functions" do

    opts = [
      v_m_squared: &(Stream.map(&1, fn v -> v * v end)),
      v_r_lt_45:   &(Stream.reject(&1, fn v -> v < 45 end)),

      v_f_gt_0_m_cubed: [&(Stream.reject(&1, fn v -> v > 0 end)),
                         &(Stream.map(&1, fn v -> v * v * v end))],
    ]

    opts_keys = Keyword.keys(opts) |> Enum.uniq |> Enum.sort

    td = opts
    |> PETD.build
    |> helper_assert_transform_dictionary

    assert opts_keys == td |> PETD.keys |> Enum.sort

  end

  test "build: piplines, functions and discrete transforms" do

    opts = [
      v_f_number: [filter: fn v -> is_number(v) end],
      v_f_gt_0:   [filter: fn v -> v > 0 end],
      v_m_squared:      &(Stream.map(&1, fn v -> v * v end)),
      v_m_plus_42:      [map: fn v -> v + 42 end],
      v_r_lt_45:     &(Stream.reject(&1, fn v -> v < 45 end)),
      v_r_gt_50:     [reject: fn v -> v > 50 end],

      v_f_gt_0_m_cubed:   [&(Stream.reject(&1, fn v -> v > 0 end)),
                           &(Stream.map(&1, fn v -> v * v * v end))],

      v_f_lt_42_m_squared_and_sum: [
        [filter: fn v -> v < 42 end],
        &(Stream.map(&1, fn v -> v * v end)),
        :sum],

    ]

    opts_keys = Keyword.keys(opts) |> Enum.uniq |> Enum.sort

    td = opts
    |> PETD.build
    |> helper_assert_transform_dictionary

    assert opts_keys == td |> PETD.keys |> Enum.sort

  end

  test "transform: no transforms" do

    td = helper_dictionary_build_test1()
    enum1 = [a: 1, b: 2, c: 3, d: :atom, e: "string", f: make_ref(), g: &(&1)]

    enum2 = enum1 |> PETD.transform(td)

    assert enum1 == enum2

  end

  test "transform: one or many" do

    td = helper_dictionary_build_test1()

    enum1 = [a: 1, b: 2, c: 3, d: :atom, e: "string", f: make_ref(), g: &(&1)]

    enum2 = [1,2,3]

     [
      [:kv_f_v_number, enum1],
      [:v_m_squared, enum2],
      [:kv_r_v_gt_50, enum1],

      [[:kv_f_v_number], enum1],
      [[:v_m_squared], enum2],
      [[:kv_r_v_gt_50], enum1],

      [[:kv_f_v_number, nil, :kv_m_v_squared, nil, nil, :kv_r_v_gt_50], enum1],

      [[[:kv_f_v_number, nil, :kv_m_v_squared], nil], enum1],

    ]
    |> helper_enum_dictionary_transform(td)

  end

end

