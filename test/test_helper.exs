ExUnit.start()

defmodule PlymioEnumHelpersTest do

  use ExUnit.Case, async: true

  alias Plymio.Enum.Utils, as: PEU
  alias Plymio.Enum.Transform, as: PET
  alias Plymio.Enum.Transform.Dictionary, as: PETD

  def helper_is_enum(value) do
    cond do
      Enumerable.impl_for(value) -> true
      true -> false
    end
  end

  def helper_assert_is_enum(value), do: assert helper_is_enum(value)

  # header
  def helper_is_lazy(value)

  def helper_is_lazy(nil), do: false

  def helper_is_lazy(value) do
    case Enumerable.impl_for(value) do
      x when x != nil ->
        case x do
          Enumerable.Stream -> true
          Enumerable.Function -> true
          _ -> false
        end
      _ -> false
    end
  end

  def helper_assert_is_lazy(value), do: assert helper_is_lazy(value)
  def helper_test_is_lazy(test_value, value), do: assert test_value == helper_is_lazy(value)

  def harnais_assert_equal_enums(test_enum, real_enum) do

    test_value = test_enum |> Enum.map(fn x -> x end)
    real_value = real_enum |> Enum.map(fn x -> x end)

    assert test_value == real_value

  end

  def helper_enum_to_flat_keys(enum) do
    enum
    |> Stream.map(fn {k, v} -> {[k], v} end)
  end

  def helper_realise_enum_to_flat_keys(enum), do: enum |> helper_enum_to_flat_keys |> Enum.to_list

  def helper_enum_to_2lists(enum) do
    enum
    |> Stream.chunk(2,2,[])
  end

  def helper_realise_enum_to_2lists(enum), do: enum |> helper_enum_to_2lists |> Enum.to_list

  def helper_to_2tuples(enum) do
    enum
    |> Stream.chunk(2,2,[])
    |> Stream.map(fn [k,v] -> {k,v} end)
  end

  def helper_realise_to_2tuples(enum) do
    enum
    |> helper_to_2tuples
    |> Enum.to_list
  end

  def helper_enum_to_keyword(enum) do
    enum
    |> Stream.chunk(2,2,[])
    |> Stream.map(fn [k,v] -> {k,v} end)
    |> Enum.into(Keyword.new)
  end

  def helper_realise_enum(enum), do: enum |> Enum.to_list

  def helper_realise_enum_to_keyword(enum), do: enum |> helper_enum_to_keyword

  def helper_assert_stream_value(value, stream) do
    assert value == Enum.to_list(stream)
    stream
  end

  def helper_assert_to_2tuples(result, enum) do
    helper_assert_stream_value(result, PEU.to_2tuples(enum))
  end

  def helper_assert_to_keyword!(result, enum) do
    helper_assert_stream_value(result, PEU.to_keyword!(enum))
  end

  def helper_assert_enum_to_flat_keys(result, enum) do

    helper_assert_stream_value(result, PEU.enum_to_flat_keys(enum))

  end

  def helper_assert_transform_realise(result, enum, edits) do
    assert result == PET.realise(enum, edits)
  end

  def helper_assert_transform_transform(result, enum, edits) do
    assert result == PET.transform(enum, edits)
  end

  def helper_assert_transform_build(edits) do
    result = PET.build(edits)
    assert is_function(result, 1)
    result
  end

  def helper_make_2tuple_reject_key(key) do
    fn
      {^key, _} -> false
      _ -> true
    end
  end

  def helper_assert_transform_dictionary(td) do
    assert %PETD{} = td
    assert td |> PETD.keys  |> Enum.all?(fn v -> is_atom(v) end)
    assert td |> PETD.values |> Enum.all?(fn v -> is_function(v,1) end)
    td
  end

  def helper_transform_dictionary_create(opts \\ []) do
    opts
    |> PETD.build
    |> helper_assert_transform_dictionary
  end

  def helper_transform_dictionary_create_dict1() do
    [
      f1: [filter: [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end]],
      m1: [map: [
            fn
              {k,v} when is_number(v)  -> {k, v * v}
              kv -> kv
            end,
            fn
              {k,v} when is_number(v) -> {k, v + 42}
              kv -> kv
            end
            ]],
      r1: [reject: [fn {_k,v} -> v < 45 end, fn {_k,v} -> v > 50 end]],
    ]
    |> helper_transform_dictionary_create

  end

  def helper_transform_dictionary_keys(td) do
    td
    |> helper_assert_transform_dictionary
    |> PETD.keys
  end

  def helper_transform_dictionary_values(td) do
    td
    |> helper_assert_transform_dictionary
    |> PETD.values
  end

  def helper_transform_build_transform_fun(bild_args \\ []) do

    transform_fun =
      try do

        edit_fun = bild_args
        |> PET.build

        assert is_function(edit_fun),
          "build: failed bild_args #{inspect bild_args}"

        edit_fun

    rescue

      _any ->

        nil

    end

    assert is_function(transform_fun),"transform_fun not a function #{inspect transform_fun}"

    transform_fun

  end

  def helper_transform_build_realise_fun(bild_args \\ []) do

    edit_fun = helper_transform_build_transform_fun(bild_args)

    # now wrap in a realise
    realise_fun = fn enum -> enum |> PET.realise(edit_fun) end

    assert is_function(realise_fun),"realise_fun not a function #{inspect realise_fun}"

    realise_fun

  end

  def helper_run_and_realise_tests_default1(opts \\ []) do

    test_mapper = fn

    {test_flag, bild_args} when is_tuple(test_flag) ->

        [c: helper_transform_build_realise_fun(bild_args), f: test_flag]

     {test_flag, bild_args, test_value} when is_tuple(test_flag) ->

        [c: helper_transform_build_realise_fun(bild_args), v: test_value, f: test_flag]

      {test_flag, test_result, bild_args} ->

        [c: helper_transform_build_realise_fun(bild_args), r: test_result, f: test_flag]

      # {test_flag, bild_args, test_result, test_value} ->

      #   [c: helper_transform_build_realise_fun(bild_args), r: test_result, v: test_value, f: test_flag]

      [test_result, bild_args, test_value] ->

        [c: helper_transform_build_realise_fun(bild_args), r: test_result, v: test_value]

      [test_result, bild_args] ->

      [c: helper_transform_build_realise_fun(bild_args), r: test_result]

      _any ->

        assert false

    end

    [test_mapper: test_mapper] ++ opts
    |> Harnais.run_tests_default_test_value

  end

  def helper_run_tests_default1(opts \\ []) do

    test_mapper = fn

    {test_flag, bild_args} when is_tuple(test_flag) ->

        [c: helper_transform_build_transform_fun(bild_args), f: test_flag]

     {test_flag, bild_args, test_value} when is_tuple(test_flag) ->

        [c: helper_transform_build_transform_fun(bild_args), v: test_value, f: test_flag]

      {test_flag, test_result, bild_args} ->

        [c: helper_transform_build_transform_fun(bild_args), r: test_result, f: test_flag]

      [test_result, bild_args, test_value] ->

        [c: helper_transform_build_transform_fun(bild_args), r: test_result, v: test_value]

      [test_result, {_m,_f,_a} = mfa] ->

      [c: mfa, r: test_result]

      [test_result, bild_args] ->

      [c: helper_transform_build_transform_fun(bild_args), r: test_result]

      _any ->

        assert false

    end

    [test_mapper: test_mapper] ++ opts
    |> Harnais.run_tests_default_test_value

  end

  def helper_stream_run_fun(stream, fun) do

    cond do
      PEU.lazy?(stream) -> fun.(stream)
      true -> false
    end

  end

  def helper_stream_make_fun(verb, expect)

  def helper_stream_make_fun({fun, args}, expect) do

    args = case args do
             x when is_nil(x) -> []
             x -> x |> List.wrap
           end

    make_fun = fn enum ->
      apply(Enum, fun, [enum | args])
    end

    make_fun
    |> helper_stream_make_fun(expect)
  end

  def helper_stream_make_fun(fun, expect) when is_function(fun) do
    fn actual ->
      actual
      |> helper_stream_run_fun(fn a ->

        result = a |> fun.()

        expect == result

      end)
    end
  end

  defp helper_dictionary_create(opts) do
    opts
    |> PETD.build
    |> helper_assert_transform_dictionary
  end

  def helper_dictionary_build_test1() do
    [
      v_f_number: [filter: fn v -> is_number(v) end],
      v_f_gt_0:   [filter: fn v -> v > 0 end],
      v_m_squared:      [map: fn v -> v * v end],
      v_m_plus_42:      [map: fn v -> v + 42 end],
      v_r_lt_45:     [reject: fn v -> v < 45 end],
      v_r_gt_50:     [reject: fn v -> v > 50 end],

      kv_f_v_number:   [filter: fn {_k,v} -> is_number(v) end],
      kv_f_v_gt_0:     [filter: fn {_k,v} -> v > 0 end],
      kv_m_v_squared:  &(Stream.map(&1, fn {k,v} -> {k, v * v} end)),
      kv_m_v_plus_42:  [map: fn {k,v} -> {k, v + 42} end],
      kv_r_v_lt_45:    &(Stream.reject(&1, fn {_k,v} -> v < 45 end)),
      kv_r_v_gt_50:    [reject: fn {_k,v} -> v > 50 end],

      v_f_gt_0_m_cubed:   [&(Stream.reject(&1, fn v -> v > 0 end)),
                           &(Stream.map(&1, fn v -> v * v * v end))],

      v_f_lt_42_m_squared_and_sum: [
                          [filter: fn v -> v < 42 end],
                           &(Stream.map(&1, fn v -> v * v end)),
                          :sum],

      # composed from exiting dictiuonary keys
      v_f_number_gt_0: [:v_f_number, :v_f_gt_0],
      v_f_number_gt_0_lt_10: [:v_f_number_gt_0, [filter: fn v -> v < 10 end]],
      v_m_squared_plus_42: [:v_m_squared, :v_m_plus_42],
      v_f_number_gt_0_m_squared_plus_42: [:v_f_number_gt_0, :v_m_squared_plus_42],
      v_f_number_gt_0_m_squared_plus_42_minus_7: [
        :v_f_number_gt_0_m_squared_plus_42,
        [map: fn v -> v - 7 end]],

      # copy of an existing key
      ensure_only_numbers: :v_f_number,

    ]
    |> helper_dictionary_create
  end

  def helper_enum_dictionary_transform(transforms \\ [], %PETD{} = td)
  when is_list(transforms) do

    transforms
    |> Enum.each(fn

      [transforms, enum] ->

      result_dict = enum |> PETD.transform(td, transforms)

      result_call = transforms
      |> List.wrap
      |> List.flatten
      |> Enum.reject(&is_nil/1)
      |> fn transforms -> td |> PETD.fetch!(transforms) end.()
      |> Enum.reduce(enum, fn f, s -> s |> PET.transform(f) end)

      # same as call?
      assert result_dict == result_call

      # ensure realised results are the same
      realise_dict = PEU.maybe_realise(result_dict)
      realise_call = PEU.maybe_realise(result_call)
      assert realise_dict == realise_call

    end)

  end

  def helper_enum_dictionary_realise(transforms \\ [], %PETD{} = td) do
    helper_enum_dictionary_transform(transforms, %PETD{} = td)
  end

  defmacro __using__(_opts \\ []) do

    quote do

      use ExUnit.Case, async: true
      alias Plymio.Enum.Utils, as: PEU
      alias Plymio.Enum.Transform, as: PET
      alias Plymio.Enum.Transform.Dictionary, as: PETD
      use Harnais.Attributes
      import Harnais.Utils.Utils, only: [harnais_assert_equal: 2]
      import PlymioEnumHelpersTest

      @l_test1 [:a, 1, :b, 2, :c, 3]
      @l_test2 [:x, 10, :y, 11, :z, 12]
      @l_test3 ["p", 100, %{q: 1}, 101, :r, 102]

      @k_test1 helper_realise_enum_to_keyword(@l_test1)
      @t_test1 helper_realise_to_2tuples(@l_test1)
      @l2_test1 helper_realise_enum_to_2lists(@l_test1)
      @m_test1 @t_test1 |> Enum.into(%{})
      @tfk_test1 helper_realise_enum_to_flat_keys(@t_test1)

      @k_test2 helper_realise_enum_to_keyword(@l_test2)
      @t_test2 helper_realise_to_2tuples(@l_test2)
      @l2_test2 helper_realise_enum_to_2lists(@l_test2)
      @m_test2 @t_test2 |> Enum.into(%{})

      @k_test3 helper_realise_enum_to_keyword(@l_test3)
      @t_test3 helper_realise_to_2tuples(@l_test3)
      @l2_test3 helper_realise_enum_to_2lists(@l_test3)
      @m_test3 @t_test3 |> Enum.into(%{})

    end

  end

end

