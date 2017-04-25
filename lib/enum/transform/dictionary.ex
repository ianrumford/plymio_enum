defmodule Plymio.Enum.Transform.Dictionary do

  @moduledoc ~S"""
  Managing a Dictionary of `Transform Functions` for Enumerables.

  This module support the creation and use of a dictionary of named `transform functions`.

  It also supports the **composition** of higher level transforms from transforms in the dictionary tother and/or new pipelines. **Composed** transforms can themselves be saved in the dictionary.

  It uses `Plymio.Enum.Transform` for support having peer functions `build/2`,
  `transform/3` and `realise/3` that layer dictionary management.

  ## Building a Transform Dictionary

  A `transform dictionary` can be built using `build/1`, and updated using `build/2`, from either a `Map` or `Keyword` where the keys are the `transform function` name.

  Each value must be one or more elements that are  *either* supported by `Plymio.Enum.Transform.build/1` *or* an existing dictionary key.  See the examplea for the range of options.

  > The returned `transform dictionary` is a struct i.e. `%Plymio.Enum.Transform.Dictionary{}`

      iex> td_test1 = [
      ...>
      ...>   # v transforms
      ...>   v_f_number:  [filter: fn v -> is_number(v) end],
      ...>   v_f_gt_0:    [filter: fn v -> v > 0 end],
      ...>   v_m_squared: [map: fn v -> v * v end],
      ...>   v_m_plus_42: [map: fn v -> v + 42 end],
      ...>   v_r_lt_45:   [reject: fn v -> v < 45 end],
      ...>   v_r_gt_50:   [reject: fn v -> v > 50 end],
      ...>
      ...>   # {k,v} 2tuple transforms
      ...>   kv_f_v_number:   [filter: fn {_k,v} -> is_number(v) end],
      ...>   kv_f_v_gt_0:     [filter: fn {_k,v} -> v > 0 end],
      ...>   kv_m_v_squared:  &(Stream.map(&1, fn {k,v} -> {k, v * v} end)),
      ...>   kv_m_v_plus_42:  [map: fn {k,v} -> {k, v + 42} end],
      ...>   kv_r_v_lt_45:    &(Stream.reject(&1, fn {_k,v} -> v < 45 end)),
      ...>   kv_r_v_gt_50:    [reject: fn {_k,v} -> v > 50 end],
      ...>
      ...>   v_f_gt_0_m_cubed: [&(Stream.reject(&1, fn v -> v > 0 end)),
      ...>                      &(Stream.map(&1, fn v -> v * v * v end))],
      ...>
      ...>   v_f_lt_42_m_squared_and_sum: [
      ...>     [filter: fn v -> v < 42 end],
      ...>     &(Stream.map(&1, fn v -> v * v end)),
      ...>     :sum],
      ...>
      ...>   # composed from existing dictionary keys (transforms) and pipelines
      ...>   v_f_number_gt_0: [:v_f_number, :v_f_gt_0],
      ...>   v_f_number_gt_0_lt_10: [:v_f_number_gt_0, [filter: fn v -> v < 10 end]],
      ...>   v_m_squared_plus_42: [:v_m_squared, :v_m_plus_42],
      ...>   v_f_number_gt_0_m_squared_plus_42: [:v_f_number_gt_0, :v_m_squared_plus_42],
      ...>   v_f_number_gt_0_m_squared_plus_42_minus_7: [
      ...>     :v_f_number_gt_0_m_squared_plus_42,
      ...>     [map: fn v -> v - 7 end]],
      ...>
      ...>   # copy of an existing key
      ...>   ensure_only_numbers: :v_f_number,
      ...> ]
      ...> |> build
      iex> match?(%Plymio.Enum.Transform.Dictionary{}, td_test1)
      true

  Notes:

    1. Each value can be one or more (`List`) of:

      * transform function (e.g. `&(Stream.map(&1, fn {k,v} -> {k, v * v} end))`)
      * transform pipeline (e.g. `[filter: fn v -> is_number(v) end]`)
      * discrete transform (e.g. `:sum`),
      * existing dictionary transform (key) (e.g. `: v_f_number`)

    1. `:v_m_squared` and `:v_r_lt_45` values are explicit `transform functions`.

    1. `:v_f_gt_0_m_cubed` is a list of `transform_functions`.

    1. `:v_f_lt_42_m_squared_and_sum` is a mix (pipeline) of valid values.

    1. `:v_f_number_gt_0` is composed from existing transforms in the dictionary.

    1. `:v_ensure_only_numbers` is a copy of `:v_f_number`

    1. When the value is an `Atom` it could be a discrete transform (e.g. `:sum`) or an existing transform (e.g. `:v_f_number`) in the dictionary.  Preference is given to existing dictionary transform.

    1. Transforms composed from other dictionary keys are "frozen" and do *not* track changes to the  keys used to compose them.

    1. The dictionary is built one key at a time so "later" keys (e.g. `:v_m_squared_plus_42`) can be composed from "earlier" keys (`:v_m_squared` and `:v_m_plus_42`).

  > To make the following tests less cluttered, the above dictionary has been extracted into the helper function `helper_dictionary_build_test1`.

   The two functions `transform/3` and `realise/3`  complement `Plymio.Enum.Transform.transform/2` and `Plymio.Enum.Transform.realise/2`.

  ## Using a Transform Dictionary

  This example selects (filters) just the numbers in the enumerable, returning a *lazy* enumerable.
  Normally `transform` returns a *lazy* enumerable (as does its peer `Plymio.Enum.Transform.transform/2`).

       iex> td_test1 = helper_dictionary_build_test1()
       ...> result = [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1), 4.25]
       ...> |> transform(td_test1, :v_f_number)
       ...> match?(%Stream{}, result)
       true

  Calling `realise/3` will return the actual result:

       iex> td_test1 = helper_dictionary_build_test1()
       ...> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1), 4.25]
       ...> |> realise(td_test1, :v_f_number)
       [-1, 1, 2, 3, 4.25]

  This example uses one of the **composed** transforms (`:v_f_number_gt_0_m_squared_plus_42_minus_7`) to filter just the numbers, square them, add 42 and subtract 7:

       iex> td_test1 = helper_dictionary_build_test1()
       ...> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1), 4.25]
       ...> |> realise(td_test1, :v_f_number_gt_0_m_squared_plus_42_minus_7)
       [36, 39, 44, 53.0625]

  Multiple transforms can be given as a list.  (The last transform -- :sum -- always returns a *real* value)

       iex> td_test1 = helper_dictionary_build_test1()
       ...> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)]
       ...> |> transform(td_test1, [:v_f_number, :v_f_lt_42_m_squared_and_sum])
       15

  A mix of transform forms (keys, functions, pipeline, discrete) can be given.

       iex> td_test1 = helper_dictionary_build_test1()
       ...> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)]
       ...> |> transform(td_test1, [:v_f_number, :v_f_gt_0, [map: fn v -> v*v*v end], :sum])
       36

  Note a single pipeline must be inside another list

       iex> td_test1 = helper_dictionary_build_test1()
       ...> [1,2,3] |> realise(td_test1, [[map: fn v -> v*v end]])
       [1,4,9]
  """

  alias Plymio.Enum.Utils, as: PEU
  require Plymio.Enum.Transform, as: PET
  alias __MODULE__, as: PETD
  require Logger

  @type transform_name :: atom
  @type transform_names :: transform_name | [transform_name]
  @type transform_function :: PET.transform_function
  @type transform_pipeline :: PET.transform_pipeline
  @type transform_functions :: [transform_function]
  @type transform_dictionary :: %Plymio.Enum.Transform.Dictionary{}

  @type transform_build_key :: transform_name
  @type transform_build_value :: transform_function | transform_pipeline

  @type transform_build_opt :: {transform_build_key, transform_build_value}
  @type transform_build_opts :: [transform_build_opt]

  @type transform_build_map :: %{required(transform_build_key) => transform_build_value}

  @type transform_build_args :: transform_build_map | transform_build_opts

  defstruct transforms: %{}

  defp build_verb(td, verb, opts)

  defp build_verb(%PETD{} = td, _verb, []) do
    td
  end

  defp build_verb(%PETD{} = td, :build, opts) do

    opts
    # make the values lists
    |> Stream.map(fn {transform_name, transform_value} ->
      {transform_name, transform_value |> List.wrap}
    end)
    |> Enum.reduce(td, fn

     # could be a transform pipeline or mix (list) of transforms
     {transform_name, transform_value}, td ->

      cond do

        # if a Keyword must be a pipeline
        Keyword.keyword?(transform_value) ->

          td |> put(transform_name, transform_value |> PET.build)

        # Mix of transform functions, transform pipelines or discrete transforms
        true ->

          transform_funs = transform_value
          |> Enum.map(fn
            # transform function
            fun when is_function(fun,1) -> fun
            # atom: discrete transform OR existing transform_name in dictionary?
            value when is_atom(value) ->

              case td |> has_key?(value) do

                # prefer existing transform
                true -> td |> fetch!(value)

                # must be a discrete transform
                _ -> PET.build([value])

              end

            # discrete transform: tuple?
            value when is_tuple(value) -> PET.build([value])
            # transform pipeline
            pipeline when is_list(pipeline) -> pipeline |> PET.build
          end)

          td |> put(transform_name, transform_funs)

      end

    end)

  end

  @doc ~S"""
  `build/1` builds a `transform dictionary` and `build/2` will update it.

  See the main example at the top.

  ## Examples

  To create a `transform_dictionary`, call `build/` with a `Map` or `Keyword`:

      iex> td = [
      ...>   f1: [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]],
      ...>   m1: [map: [fn v -> v * v end, fn v -> v + 42 end]],
      ...>   r1: [reject: [fn v -> v < 45 end, fn v -> v > 50 end]],
      ...> ]
      ...> |> build
      iex> match?(%Plymio.Enum.Transform.Dictionary{}, td)
      true

 To update a `transform_dictionary`, call `build/2` with the `transform_dictionary` and a `Map` or `Keyword`:

      iex> opts1 = [
      ...>   f1: [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]],
      ...>   m1: [map: [fn v -> v * v end, fn v -> v + 42 end]],
      ...>   r1: [reject: [fn v -> v < 45 end, fn v -> v > 50 end]],
      ...> ]
      ...> td1 = opts1 |> build
      ...>
      ...> # build new transform dictionary updating :f1 and adding three new transforms.
      ...> opts2 = [
      ...>   f1: [filter: [fn v -> is_atom(v) end]],
      ...>   m2: [map: [fn v -> v * v * v end, fn v -> v - 99 end]],
      ...>   r2: &(Stream.reject(&1, fn v -> v < 0 end)),
      ...>   s1: :sum
      ...> ]
      ...> td2 = td1 |> build(opts2)
      ...> td2 |> keys
      [:f1, :m1, :m2, :r1, :r2, :s1]
  """

  @spec build(transform_dictionary | nil, transform_build_args) :: transform_dictionary

  def build(td \\ nil, opts \\ [])

  def build(%PETD{} = td, []) do
    td
  end

  def build(nil, []) do
    %PETD{}
  end

  def build(nil, opts) do
    %PETD{} |> build(opts)
  end

  def build(%PETD{} = td, opts) do
    build_verb(td, :build, opts)
  end

  def build(td, opts) when is_list(td) and is_list(opts) and length(opts) == 0 do
    %PETD{} |> build(td)
  end

  @doc ~S"""
  `transform/3` applies `transform functions` from the `transform dictionary` to an enumerable.

  The `transforms` are first converted to a list if necessary, flattened and any nils deleted.

  The result may be anything including a lazy enumerable (e.g. `Stream`).

  See the examples at the top.
  """

  def transform(enum, td, transforms \\ [])

  def transform(enum, %PETD{} = _td, []) do
    enum
  end

  def transform(enum, %PETD{} = td, transforms) do

    cond do

      # a pipeline?
      Keyword.keyword?(transforms) -> [transforms]

      true ->

        transforms
        |> List.wrap
        |> List.flatten
        |> Stream.reject(&is_nil/1)

    end
    |> Stream.map(fn

      # key in the dictionary or a discrete transform?
      transform when is_atom(transform) ->

        case td |> has_key?(transform) do
          true -> td |> fetch!(transform)
          _ -> [transform] |> PET.build
        end

      # explicit trasnform function?
      transform when is_function(transform) -> transform

      # anything else must be a pipeline to be built on the fly
      transform -> transform |> PET.build

    end)
    |> Enum.reduce(enum, fn transform_fun, s -> s |> transform_fun.() end)

  end

  @doc ~S"""
  `realise/3` applies `transforms` from the `tranform dictionary` to an enumerable.

  It calls `transform/2` to apply the transforms.

  If the result is a lazy enumerable (e.g. `Stream`), it is realised
  (e.g. `Enum.to_list/1`).

  """

  def realise(enum, td, transforms \\ [])

  def realise(enum, %PETD{} = _td, []) do
    enum |> Enum.to_list
  end

  def realise(enum, %PETD{} = td, transforms) do
    enum
    |> transform(td, transforms)
    |> PEU.maybe_realise
  end

  defp field_transform(td, field, transform_fun)

  defp field_transform(%PETD{} = td, :transforms = field, transform_fun) when is_function(transform_fun) do

    field_value = td
    |> Map.fetch!(field)
    |> fn value -> transform_fun.(value) end.()

    td |> Map.put(field, field_value)

  end

  @doc ~S"""

  The `get` function takes one or more keys, returning a `transform_function` or list of `transform_functions`.

  The default must be nil or a `transform_function`.

      iex> helper_dictionary_build_test1()
      ...> |> get(:v_f_gt_0)
      ...> |> is_function(1)
      true

      iex> helper_dictionary_build_test1()
      ...> |> get(
      ...>      [:v_f_gt_0, :missing_x, :v_m_plus_42, nil],
      ...>      nil)
      ...> |> Enum.all?(fn
      ...>      value when is_function(value, 1) -> true
      ...>      value when is_nil(value) -> true
      ...>      _ -> false
      ...>    end)
      true
  """

  @spec get(transform_dictionary, transform_names, transform_function) :: transform_functions
  def get(td, keys, default \\ nil)

  def get(%PETD{} = td, keys, default)
  when is_list(keys) and (is_function(default,1) or is_nil(default)) do
    transforms = td |> Map.fetch!(:transforms)
    keys |> Enum.map(fn key -> transforms |> Map.get(key, default) end)
  end

  def get(%PETD{} = td, key, default)
  when is_function(default,1) or is_nil(default) do
    td |> Map.fetch!(:transforms) |> Map.get(key, default)
  end

  @doc ~S"""

  The `fetch!` accessor can take one or more keys, returning one or more
  (`List`) `transform_functions`. Unknown keys raise a `KeyError`.

      iex> helper_dictionary_build_test1()
      ...> |> fetch!(:v_f_gt_0)
      ...> |> is_function(1)
      true

      iex> helper_dictionary_build_test1()
      ...> |> fetch!([:v_f_gt_0, :v_m_plus_42])
      ...> |> Enum.all?(fn value -> is_function(value, 1) end)
      true
  """
  @spec get(transform_dictionary, transform_names) :: transform_functions
  def fetch!(%PETD{} = td, keys) when is_list(keys) do
    transforms = td |> Map.fetch!(:transforms)
    keys |> Enum.map(fn key -> transforms |> Map.fetch!(key) end)
  end

  def fetch!(%PETD{} = td, key) do
    # td
    #   :transforms, fn transforms -> transforms |>Map.fetch!(key) end)
    td |> Map.fetch!(:transforms) |> Map.fetch!(key)
  end

  @doc ~S"""

  The `put` function supports either a `transform_function` or a pipeline of discrete transforms.

      iex> helper_dictionary_build_test1()
      ...> |> put(:key_x, fn x -> x end)
      ...> |> has_key?(:key_x)
      true

      iex> helper_dictionary_build_test1()
      ...> |> put(:map_v_cubed, [map: fn x -> x * x * x end])
      ...> |> get(:map_v_cubed)
      ...> |> is_function(1)
      true
  """

  @spec put(transform_dictionary, transform_name, transform_function) :: transform_dictionary
  def put(%PETD{} = td, key, value) when is_function(value, 1) do
    td
    |> field_transform(
      :transforms, fn transforms -> transforms |> Map.put(key, value) end)
  end

  def put(%PETD{} = td, key, transform_pipeline)
  when is_list(transform_pipeline) do
    transform_fun = transform_pipeline |> PET.build
    td
    |> field_transform(
      :transforms, fn transforms -> transforms |> Map.put(key, transform_fun) end)
  end

  @doc ~S"""
  The `has_key?` function works as expected:

      iex> helper_dictionary_build_test1()
      ...> |> has_key?(:v_r_gt_50)
      true

  """

  @spec has_key?(transform_dictionary, transform_name) :: boolean
  def has_key?(%PETD{} = td, key) do
    td |> Map.fetch!(:transforms) |> Map.has_key?(key)
  end

  @doc ~S"""
  The `keys` accessor works as expected:

       iex> helper_dictionary_build_test1() |> keys
       [:ensure_only_numbers, :kv_f_v_gt_0, :kv_f_v_number, :kv_m_v_plus_42,
        :kv_m_v_squared, :kv_r_v_gt_50, :kv_r_v_lt_45, :v_f_gt_0,
        :v_f_gt_0_m_cubed, :v_f_lt_42_m_squared_and_sum, :v_f_number,
        :v_f_number_gt_0, :v_f_number_gt_0_lt_10,
        :v_f_number_gt_0_m_squared_plus_42,
        :v_f_number_gt_0_m_squared_plus_42_minus_7, :v_m_plus_42,
        :v_m_squared, :v_m_squared_plus_42, :v_r_gt_50, :v_r_lt_45]
  """

  @spec keys(transform_dictionary) :: transform_names
  def keys(%PETD{} = td) do
    td |> Map.fetch!(:transforms) |> Map.keys
  end

  @doc ~S"""
  The `values` function works as expected:

       iex> values = helper_dictionary_build_test1() |> values
       ...> values |> Enum.all?(fn fun -> is_function(fun,1) end)
       true
  """

  @spec values(transform_dictionary) :: transform_functions
  def values(%PETD{} = td) do
    td |> Map.fetch!(:transforms) |> Map.values
  end

  @doc ~S"""
  The `count` function works as expected:

       iex> helper_dictionary_build_test1() |> count
       20
  """

  @spec count(transform_dictionary) :: integer
  def count(%PETD{} = td) do
    td |> Map.fetch!(:transforms) |> map_size
  end

  @doc ~S"""
  The `delete` function works as expected:

       iex> helper_dictionary_build_test1()
       ...> |> delete(:v_r_gt_50)
       ...> |> has_key?(:v_r_gt_50)
       false

  """

  @spec delete(transform_dictionary, transform_name) :: transform_dictionary
  def delete(%PETD{} = td, key) do
    td
    |> field_transform(
      :transforms, fn transforms -> transforms |> Map.delete(key) end)
  end

end

