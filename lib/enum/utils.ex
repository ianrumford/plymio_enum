defmodule Plymio.Enum.Utils do

  @moduledoc ~S"""
  Utility Functions for Eumerables.

  Below, a *real* enumerable means a concrete collection i.e. a
  `List`, `Map`, or `Keyword`, while a *lazy* enumerable is (usually)
  a `Stream`.

  The functions try to be as *lazy* as possible, often returning a `Stream`.
  """

  require Logger

  @type enum :: Enumerable.t

  @plymio_enum_enumerable_lazy [Enumerable.Stream, Enumerable.Function]

  @doc ~S"""
  Returns `true` if value is enumerable, else `false`

  ## Examples

      iex> [1,2,3] |> enum?
      true

      iex> %{a: 1} |> enum?
      true

      iex> [1,2,3] |> Stream.map(&(&1)) |> enum?
      true

      iex> 42 |> enum?
      false
  """

  @spec enum?(any) :: true | false

  def enum?(value) when is_list(value), do: true
  def enum?(%Stream{}), do: true
  def enum?(value) when is_map(value), do: true

  # note: *not* function - could be Enumerable.Function
  def enum?(value)
  when is_boolean(value)
  or is_nil(value)
  or is_atom(value)
  or is_bitstring(value)
  or is_number(value)
  or is_tuple(value)
  or is_pid(value)
  or is_reference(value)
  or is_port(value) do
    false
  end

  def enum?(value) do
    case value |> Enumerable.impl_for do
      x when x in [nil, false] -> false
      _ -> true
    end
  end

  @doc ~S"""
  Returns `true` if value is a *lazy* enumerable, else `false`

  ## Examples

      iex> [1,2,3] |> lazy?
      false

      iex> %{a: 1} |> lazy?
      false

      iex> [1,2,3] |> Stream.map(&(&1)) |> lazy?
      true

      iex> 42 |> lazy?
      false
  """

  @spec lazy?(any) :: true | false

  def lazy?(value)

  def lazy?(value) when is_list(value), do: false
  def lazy?(%Stream{}), do: true
  def lazy?(value) when is_map(value), do: false
  def lazy?(value) when value in [nil, false], do: false

  def lazy?(value) do
    case Enumerable.impl_for(value) do
      x when x in @plymio_enum_enumerable_lazy -> true
      _ -> false
    end
  end

  @doc ~S"""
  Returns `true` if value is a *real*ised enumerable, else `false`

  ## Examples

      iex> [1,2,3] |> real?
      true

      iex> %{a: 1} |> real?
      true

      iex> [1,2,3] |> Stream.map(&(&1)) |> real?
      false

      iex> 42 |> real?
      false
  """

  @spec real?(any) :: true | false

  # header
  def real?(value)

  def real?(value) when is_list(value), do: true
  def real?(%Stream{}), do: false
  def real?(value) when is_map(value), do: true
  def real?(_value), do: false

  @doc ~S"""

  Takes a value and if a *lazy* enumerable, realises (`Enum.to_list/1`), else returns the value.

  ## Examples

      iex> 1 |> maybe_realise
      1

      iex> [:a, :b, :c] |> maybe_realise
      [:a, :b, :c]

      iex> %{a: 1, b: 2, c: 3} |> maybe_realise
      %{a: 1, b: 2, c: 3}

      iex> [:a, :b, :c] |> Stream.map(&(&1)) |> maybe_realise
      [:a, :b, :c]

      iex> %{a: 1, b: 2, c: 3} |> Stream.map(&(&1)) |> maybe_realise
      [a: 1, b: 2, c: 3]
  """

  @spec maybe_realise(any) :: any

  # header
  def maybe_realise(value)

  # note: *not* function - could be Enumerable.Function
  def maybe_realise(value)
  when is_boolean(value)
  or is_nil(value)
  or is_atom(value)
  or is_bitstring(value)
  or is_number(value)
  or is_tuple(value)
  or is_pid(value)
  or is_reference(value)
  or is_port(value) do
    value
  end

  def maybe_realise(value) when is_list(value) do
    value
  end

  def maybe_realise(%Stream{} = value) do
    value |> Enum.to_list
  end

  def maybe_realise(value) when is_map(value) do
    value
  end

  # Stream.transform and ilk can return a function (&do_transform)
  # that is enumerable. No way to distinguish up front.
  def maybe_realise(value) when is_function(value) do
    try do
      value |> Enum.to_list
    rescue
      FunctionClauseError -> value
    end
  end

  def maybe_realise(value) do
    cond do
      enum?(value) -> value |> Enum.to_list
      true -> value
    end
  end

  @doc ~S"""
  Returns `true` if value is a enumerable of lists of size 2, else `false`.

  ## Examples

      iex> [1,[21, 22],3] |> enum_2lists?
      false

      iex> [[11, 12], [21, 22], [31, 32]] |> enum_2lists?
      true

      iex> %{a: 1} |> enum_2lists?
      false

      iex> [[11, 12], [21, 22], [31, 32]] |> Stream.map(&(&1)) |> enum_2lists?
      true

      iex> 42 |> enum_2lists?
      false
  """

  @spec enum_2lists?(any) :: true | false

  def enum_2lists?(value) do

    case enum?(value) do
      x when x in [nil, false] -> false
      _ ->
        Enum.all?(value,
          fn
            [_, _] -> true
            _ -> false
          end)
    end
  end

  @doc ~S"""
  Returns `true` if value is a enum of tuples of size 2, else `false`.

  ## Examples

      iex> [1,[21, 22],3] |> enum_2tuples?
      false

      iex> [a: 1, b: 2, c: 3] |> enum_2tuples?
      true

      iex> [{:a, 1}, {:b, 2}, {:c, 3}] |> enum_2tuples?
      true

      iex> [{"a", 1}, {"b", 2}, {"c", 3}] |> enum_2tuples?
      true

      iex> %{a: 1} |> enum_2tuples?
      true

      iex> [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1)) |> enum_2tuples?
      true

      iex> %{a: 1} |> Stream.map(&(&1)) |> enum_2tuples?
      true

      iex> 42 |> enum_2tuples?
      false
  """

  @spec enum_2tuples?(any) :: true | false

  def enum_2tuples?(value) do

    cond do

      real?(value) ->

        cond do

          is_map(value) -> true

          Keyword.keyword?(value) -> true

          true ->

            Enum.all?(value, fn
              {_, _} -> true
              _ -> false
            end)

        end

     lazy?(value) ->

        Enum.all?(value, fn
          {_, _} -> true
          _ -> false
        end)

     # anything else can't be an enum
     true -> false

    end

  end

  @doc ~S"""
  Converts a value to an enumerable if necessary.

  Non-enumerables are wrapped in a `List`.

  ## Examples

      iex> [1,[21, 22],3] |> to_enum
      [1,[21, 22],3]

      iex> [a: 1, b: 2, c: 3] |> to_enum
      [a: 1, b: 2, c: 3]

      iex> [{:a, 1}, {:b, 2}, {:c, 3}] |> to_enum
      [{:a, 1}, {:b, 2}, {:c, 3}]

      iex> %{a: 1} |> to_enum
      %{a: 1}

      iex> stream = [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1)) |> to_enum
      iex> Enum.to_list(stream)
      [{:a, 1}, {:b, 2}, {:c, 3}]

      iex> stream = %{a: 1} |> Stream.map(&(&1)) |> to_enum
      iex> Enum.to_list(stream)
      [a: 1]

      iex> 42 |> to_enum
      [42]

      iex> :abc |> to_enum
      [:abc]
  """

  @spec to_enum(any) :: enum

  # header
  def to_enum(value)

  def to_enum(value) when is_map(value), do: value
  def to_enum(value) when is_list(value), do: value
  def to_enum(%Stream{} = value), do: value
  # make nil an empty enumerable (i.e an empty list) (same as List.wrap)
  def to_enum(nil), do: []

  def to_enum(value) do
    cond do
      enum?(value) -> value
      true -> [value]
    end
  end

  defdelegate enum_length(arg0), to: Enum, as: :count
  defdelegate enum_length(arg0, arg1), to: Enum, as: :count

  defp enum_keys_worker(value) do
    value
    |> Stream.map(fn
      {k,_v} -> k

      _ ->

      raise FunctionClauseError, module: __MODULE__, function: :enum_keys, arity: 1

    end)
  end

  @doc ~S"""
  Returns the keys of an associative enumerable of 2tuples (e.g. `Keyword`, `Map`).

  The same key may appear more than once in the return.

  If the enumumerable is *lazy*, the return is also *lazy*.

  When the enum is realised (e.g. `Enum.to_list/1`), it will fail with a `FunctionClauseError` if the enum elements do not match `{k,v}`.

  ## Examples

      iex> [a: 1, b: 2, c: 3, a: 4, c: 5] |> keys!
      [:a, :b, :c, :a, :c]

      iex> %{a: 1} |> keys!
      [:a]

      iex> [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1))
      ...> |> keys!
      ...> |> Enum.to_list
      [:a, :b, :c]

      iex> [1, 2, 3] |> Stream.map(&(&1))
      ...> |> keys!
      ...> |> Enum.to_list
      ** (FunctionClauseError) no function clause matching in Plymio.Enum.Utils.enum_keys/1

      iex> 42
      ...> |> keys!
      ...> |> Enum.to_list
      ** (FunctionClauseError) no function clause matching in Plymio.Enum.Utils.enum_keys/1

      iex> stream = [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1))
      ...> |> keys!
      ...> match?(%Stream{}, stream)
      true

      iex> stream = %{a: 1} |> Stream.map(&(&1)) |> keys!
      iex> Enum.to_list(stream)
      [:a]
  """

  @spec keys!(enum) :: enum | no_return

  # header
  def keys!(value)

  def keys!(%Stream{} = value), do:  value |> enum_keys_worker
  def keys!(value) when is_map(value), do: value |> Map.keys

  def keys!(value) do
    cond do
      Keyword.keyword?(value) -> value |> Keyword.keys
      enum_2tuples?(value) -> value |> enum_keys_worker
      # optimistic - this will fail on the {k,v} destructure if only a 1d
      lazy?(value) -> value |> enum_keys_worker

      true ->

        # FunctionClauseError (c.f. CondClauseError) for consistency
        # with enum_keys_worker

        raise FunctionClauseError, module: __MODULE__, function: :enum_keys, arity: 1

    end
  end

  defp enum_values_worker(value) do
    value |> Stream.map(fn {_k,v} -> v end)
  end

  @doc ~S"""
  Returns the values of an enumerable of 2tuples (e.g. `Keyword`, `Map`)

  If the enumumerable is *lazy*, the return is also *lazy*.

  ## Examples

      iex> [a: 1, b: 2, c: 3, a: 4, c: 5] |> values!
      [1, 2, 3, 4, 5]

      iex> %{a: 1} |> values!
      [1]

      iex> stream = [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1)) |> values!
      iex> Enum.to_list(stream)
      [1, 2, 3]

      iex> stream = %{a: 1} |> Stream.map(&(&1)) |> values!
      iex> Enum.to_list(stream)
      [1]
  """

  @spec values!(enum) :: enum | no_return

  # header
  def values!(value)

  def values!(%Stream{} = value), do:  value |> enum_values_worker
  def values!(value) when is_map(value), do: value |> Map.values

  def values!(value) do
    cond do
      Keyword.keyword?(value) -> value |> Keyword.values
      enum_2tuples?(value) -> value |> enum_values_worker
      # optimistic - this will fail on the {k,v} destructure if only a 1d
      lazy?(value) -> value |> enum_values_worker
    end
  end

  @doc ~S"""
  Create an enumerable from the value, unless already an enumerable.

  Similar to `List.wrap/1`.

  Note a `Map` is **not** considered an enumerable when wrapping (i.e same behaviour as `List.wrap/1`).

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> wrap
      [a: 1, b: 2, c: 3]

      iex> %{a: 1} |> wrap
      [%{a: 1}]

      iex> stream = [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1)) |> wrap
      iex> Enum.to_list(stream)
      [{:a, 1}, {:b, 2}, {:c, 3}]
  """

  @spec wrap(enum) :: enum

  def wrap(value)

  def wrap(value) when is_list(value), do: value
  def wrap(%Stream{} = value), do: value
  # treat regular maps same as List.wrap
  def wrap(value) when is_map(value), do: [value]

  def wrap(value) do
    value
    |> to_enum
  end

  @doc ~S"""
  Removes `nil`s from an enumerable and returns a *lazy* enumerable.

  ## Examples

      iex> stream = [1, nil, 2, nil, 3] |> just
      iex> Enum.to_list(stream)
      [1, 2, 3]

      iex> stream = %{a: 1, b: nil, c: 3} |> just
      iex> Enum.to_list(stream)
      [a: 1, b: nil, c: 3]

      iex> stream = [{:a, 1}, nil, {:b, 2}, nil, {:c, 3}] |> Stream.map(&(&1)) |> just
      iex> Enum.to_list(stream)
      [{:a, 1}, {:b, 2}, {:c, 3}]
  """

  @spec just(enum) :: enum

  def just(value) do
    value |> Stream.reject(&is_nil/1)
  end

  defp flatten_fun(value) do
    cond do
      enum?(value) -> value |> flatten
      true -> [value]
    end
  end

  @doc ~S"""
  Flattens an enumerable.

  If the enumerable is *lazy*, the result will also be *lazy*.

  Note a `Map` is **not** considered an enumerable when flattening and an exception will be raised.

  Similar to `List.flatten/1`

  ## Examples

      iex> [{:a, 1}, [{:b1, 12}, {:b2, 22}], {:c, 3}] |> flatten
      [a: 1, b1: 12, b2: 22, c: 3]

      iex> [[{:a, 1}, {:b21, 21}], [[{:b22, 22}]], {:c, 3}] |> Stream.map(&(&1))
      ...> |> flatten
      ...> |> Enum.to_list
      [{:a, 1}, {:b21, 21}, {:b22, 22}, {:c, 3}]

      iex> stream = [[{:a, 1}, {:b21, 21}], [[{:b22, 22}]], {:c, 3}] |> Stream.map(&(&1))
      ...> |> flatten
      ...> is_function(stream)
      true

      iex> error = assert_raise FunctionClauseError, fn -> %{a: 1} |> flatten end
      ...> match?(%FunctionClauseError{}, error)
      true

      iex> [{:a, 1}, {:b, 2}, {:c, 3}] |> Stream.map(&(&1))
      ...> |> flatten
      ...> |> Enum.to_list
      [{:a, 1}, {:b, 2}, {:c, 3}]
  """

  @spec flatten(enum) :: enum

  # header
  def flatten(value)

  def flatten(value) when is_list(value) do
    value |> List.flatten
  end

  def flatten(%Stream{} = value) do
    value |> Stream.flat_map(&flatten_fun/1)
  end

  @doc ~S"""
  Flattens an enumerable, removes `nils` and returns a *lazy* enumerable.

  ## Examples

      iex> [{:a, 1}, nil, [{:b1, 12}, nil, {:b2, 22}], nil, {:c, 3}]
      ...> |> flat_just
      ...> |> Enum.to_list
      [a: 1, b1: 12, b2: 22, c: 3]

      iex> [{:a, 1}, nil, {:b, 2}, nil, {:c, 3}] |> Stream.map(&(&1))
      ...> |> flat_just
      ...> |> Enum.to_list
      [{:a, 1}, {:b, 2}, {:c, 3}]

      iex> stream = [{:a, 1}, nil, {:b, 2}, nil, {:c, 3}] |> Stream.map(&(&1))
      ...> |> flat_just
      ...> match?(%Stream{}, stream)
      true
  """

  @spec flat_just(enum) :: enum

  def flat_just(value), do: value |> flatten |> just

  def wrap_flat(value), do: value |> wrap |> flatten

  @doc ~S"""
  Wraps, flattens and removes `nils`. Returns a *lazy* enumerable.

  ## Examples

      iex> [{:a, 1}, nil, [{:b1, 12}, nil, {:b2, 22}], nil, {:c, 3}]
      ...> |> wrap_flat_just
      ...> |> Enum.to_list
      [a: 1, b1: 12, b2: 22, c: 3]

      iex> stream = [{:a, 1}, nil, [{:b1, 12}, nil, {:b2, 22}], nil, {:c, 3}]
      ...> |> wrap_flat_just
      ...> match?(%Stream{}, stream)
      true

      iex> [{:a, 1}, nil, {:b, 2}, nil, {:c, 3}] |> Stream.map(&(&1))
      ...> |> wrap_flat_just
      ...> |> Enum.to_list
      [{:a, 1}, {:b, 2}, {:c, 3}]

      iex> 42 |> wrap_flat_just
      ...> |>  Enum.to_list
      [42]
  """

  @spec wrap_flat_just(any) :: enum

  def wrap_flat_just(value), do: value |> wrap |> flatten |> just

  @doc ~S"""
  Converts an enumerable into a stream of 2tuples and returns a *lazy* enumerable.

  Uses `Enum.chunk/4` to split the enumerable up into pairs.

  ## Examples

      iex> ["a", 1, :b, 2, 31, 32]
      ...> |> to_2tuples
      ...> |> Enum.to_list
      [{"a", 1}, {:b, 2}, {31, 32}]

      iex> stream = ["a", 1, :b, 2, 31, 32]
      ...> |> to_2tuples
      ...> match?(%Stream{}, stream)
      true

      iex> [{:a, 1}, {:b, 2}, {:c, 3}, {:d, 4}]
      ...> |> to_2tuples
      ...> |> Enum.to_list
      [{{:a, 1}, {:b, 2}}, {{:c, 3}, {:d, 4}}]

      iex> [:a, 1, :b, 2, :c, 3] |> Stream.map(&(&1))
      ...> |> to_2tuples
      ...> |> Enum.to_list
      [{:a, 1}, {:b, 2}, {:c, 3}]
  """

  @spec to_2tuples(enum) :: enum

  def to_2tuples(enum) do

    enum
    |> Stream.chunk(2, 2, [])
    # to tuples; will fail if not enough elements to match [k,v] pattern i.e. [k]
    |> Stream.map(fn [k,v] -> {k,v} end)

  end

  @doc ~S"""
  Converts an enumerable into a stream of 2tuples and returns a *lazy*
  enumerable of `{atom, any}` tuples.

  ## Examples

      iex> stream = [:a, 1, :b, 2, :c, 3] |> to_keyword!
      iex> Enum.to_list(stream)
      [{:a, 1}, {:b, 2}, {:c, 3}]

      iex> stream = [:a, 1, :b, 2, :c, 3] |> Stream.map(&(&1)) |> to_keyword!
      iex> Enum.to_list(stream)
      [{:a, 1}, {:b, 2}, {:c, 3}]
  """

  @spec to_keyword!(enum) :: enum | no_return

  def to_keyword!(enum) do

    enum
    |> to_2tuples
    # validate the keys are all atoms
    |> Stream.map(fn {k, v} when is_atom(k) -> {k, v} end)

  end

end

