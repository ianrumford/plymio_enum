defmodule PlymioEnumUtils1Test1 do

  use PlymioEnumHelpersTest

  test "real?: 1" do

    harnais_assert_equal(true, PEU.real?([1,2,3]))
    harnais_assert_equal(true, PEU.real?([a: 1, b: 2, c: 3]))
    harnais_assert_equal(true, PEU.real?(%{a: 1}))

    harnais_assert_equal(false, PEU.real?(nil))
    harnais_assert_equal(false, PEU.real?(5))
    harnais_assert_equal(false, PEU.real?(:atom))
    harnais_assert_equal(false, PEU.real?("string"))

    harnais_assert_equal(false, PEU.real?(Stream.map([1,2,3], fn x -> x end)))

  end

  test "lazy?: 1" do

    harnais_assert_equal(false, PEU.lazy?([1,2,3]))
    harnais_assert_equal(false, PEU.lazy?([a: 1, b: 2, c: 3]))
    harnais_assert_equal(false, PEU.lazy?(%{a: 1}))

    harnais_assert_equal(false, PEU.lazy?(nil))
    harnais_assert_equal(false, PEU.lazy?(5))
    harnais_assert_equal(false, PEU.lazy?(:atom))
    harnais_assert_equal(false, PEU.lazy?("string"))

    harnais_assert_equal(true, PEU.lazy?(Stream.map([1,2,3], fn x -> x end)))

  end

  test "enum?: 1" do

    harnais_assert_equal(true, PEU.enum?([1,2,3]))
    harnais_assert_equal(true, PEU.enum?([a: 1, b: 2, c: 3]))
    harnais_assert_equal(true, PEU.enum?(%{a: 1}))

    harnais_assert_equal(false, PEU.enum?(nil))
    harnais_assert_equal(false, PEU.enum?(5))
    harnais_assert_equal(false, PEU.enum?(:atom))
    harnais_assert_equal(false, PEU.enum?("string"))

    harnais_assert_equal(true, PEU.enum?(Stream.map([1,2,3], fn x -> x end)))

  end

  test "enm_to_enum: assert" do

    helper_assert_is_enum(PEU.to_enum([1,2,3]))
    helper_assert_is_enum(PEU.to_enum([a: 1, b: 2, c: 3]))
    helper_assert_is_enum(PEU.to_enum(%{a: 1}))

    helper_assert_is_enum(PEU.to_enum(nil))
    helper_assert_is_enum(PEU.to_enum(5))
    helper_assert_is_enum(PEU.to_enum(:atom))
    helper_assert_is_enum(PEU.to_enum("string"))

    helper_assert_is_enum(PEU.to_enum(Stream.map([1,2,3], fn x -> x end)))

  end

  test "to_enum: assert and compare" do

    harnais_assert_equal_enums([1,2,3], PEU.to_enum([1,2,3]))
    harnais_assert_equal_enums([a: 1, b: 2, c: 3], PEU.to_enum([a: 1, b: 2, c: 3]))
    harnais_assert_equal_enums(%{a: 1}, PEU.to_enum(%{a: 1}))

    harnais_assert_equal_enums([], PEU.to_enum(nil))
    harnais_assert_equal_enums([5], PEU.to_enum(5))
    harnais_assert_equal_enums([:atom], PEU.to_enum(:atom))
    harnais_assert_equal_enums(["string"], PEU.to_enum("string"))

    harnais_assert_equal_enums([1,2,3], PEU.to_enum(Stream.map([1,2,3], fn x -> x end)))

  end

  test "maybe_realise: 1" do

    [

      [1, 1],
      [:atom, :atom],
      ["string", "string"],
      [Enum.map([1,2,3], &(&1)), [1,2,3]],
      [Enum.flat_map([1,2,3], fn v -> [v,v] end), [1,1,2,2,3,3]],
      [Stream.map([1,2,3], &(&1)), [1,2,3]],
      [Stream.flat_map([1,2,3], fn v -> [v,v] end), [1,1,2,2,3,3]],

      # "simple" fun that is not enumerable
      [&(&1), &(&1)],

      [Stream.transform([1,2,3], nil, fn v,s -> {[v], s} end), [1,2,3]],

    ]
    |> Enum.map(fn [v,r] -> [c: :maybe_realise, v: v, r: r] end)
    |> fn tests ->
      [tests: tests, test_module: PEU]
      |> Harnais.run_tests_default_test_value
    end.()

  end

  test "flatten: assert and compare" do

    harnais_assert_equal_enums([1,2,3], PEU.flatten([1,2,3]))
    harnais_assert_equal_enums([a: 1, b: 2, c: 3], PEU.flatten([a: 1, b: 2, c: 3]))

 assert_raise FunctionClauseError, fn -> PEU.flatten(%{a: 1}) end
    assert_raise FunctionClauseError, fn -> PEU.flatten(42) end
    assert_raise FunctionClauseError, fn -> PEU.flatten(:atom) end
    assert_raise FunctionClauseError, fn -> PEU.flatten("string") end

    harnais_assert_equal_enums([1,2,3], PEU.flatten(Stream.map([1,2,3], fn x -> x end)))

    harnais_assert_equal_enums([1, 21, 22, 3], PEU.flatten([1,[21, 22],3]))

    harnais_assert_equal_enums([1,21,22,3], PEU.flatten(Stream.map([1,[21,22],3], fn x -> x end)))

    harnais_assert_equal_enums([1,7,8,9,3], PEU.flatten(Stream.map([1,Stream.map([7,8,9], &(&1)),3], &(&1))))

  end

  test "flatten: assert lazy" do

    helper_test_is_lazy(false, PEU.flatten([1,2,3]))
    helper_test_is_lazy(false, PEU.flatten([a: 1, b: 2, c: 3]))

    helper_test_is_lazy(true, PEU.flatten(Stream.map([1,2,3], &(&1))))

    helper_test_is_lazy(false, PEU.flatten([1,[21, 22],3]))

    helper_test_is_lazy(true, PEU.flatten(Stream.map([1,[21,22],3], &(&1))))

    helper_test_is_lazy(true, PEU.flatten(Stream.map([1,Stream.map([7,8,9], &(&1)),3], &(&1))))

  end

  test "wrap_flat_just: 1" do

    harnais_assert_equal_enums([1,2,3], PEU.wrap([1,2,3]))
    harnais_assert_equal_enums([1,2,3], PEU.wrap_flat([1,2,3]))
    harnais_assert_equal_enums([1,2,3], PEU.wrap_flat_just([1,2,3]))

    harnais_assert_equal_enums([1], PEU.wrap(1))
    harnais_assert_equal_enums([1,21,22,3], PEU.wrap_flat([1, [21, 22], 3]))

    harnais_assert_equal_enums([1,2,3], PEU.wrap(Stream.map([1,2,3], &(&1))))

    harnais_assert_equal_enums([1,21,22,3], PEU.wrap_flat_just([nil, 1, [21, nil, 22, nil], 3, nil]))

    harnais_assert_equal_enums([1,21,22,3], PEU.wrap_flat_just(Stream.map([nil, 1, [21, nil, 22, nil], 3, nil], &(&1))))

  end

  test "to_2tuples: ok" do

    helper_assert_to_2tuples(@t_test1, @l_test1)
    helper_assert_to_2tuples(@t_test2, @l_test2)
    helper_assert_to_2tuples(@t_test3, @l_test3)

  end

  test "to_2tuples: error" do

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_2tuples(nil, [42])
    end)

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_2tuples(nil, [:a])
    end)

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_2tuples(nil, [:a, 1, :b])
    end)

  end

  test "to_keyword!: ok" do

    helper_assert_to_keyword!(@k_test1, @l_test1)
    helper_assert_to_keyword!(@k_test2, @l_test2)

  end

  test "to_keyword!: error" do

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_keyword!(nil, [42])
    end)

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_keyword!(nil, [:a])
    end)

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_keyword!(nil, [:a, 1, :b])
    end)

    assert_raise(FunctionClauseError, fn ->
      helper_assert_to_keyword!(@k_test3, @l_test3)
    end)

  end

end

