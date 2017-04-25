defmodule Plymio.Enum.Transform do

  @moduledoc ~S"""
  Building, Composing and Applying `Transform Functions` for Enumerables.

  A `transform function` normally takes one argument -- usually an
  enumerable -- and applies a pipeline of `discrete transforms`, returning (again usually)
  another enumerable.

  Each `discrete transform` is usually the name of  a `Stream` or `Enum` function (e.g. `:map`, `:filter`, `:group_by`, etc).

  A `transform function` tries to be as *lazy* as possible, using (preferring) `Stream` over `Enum` and, if possible,  returning a *lazy* enumerable.

  A macro is provided (`defenumtransform/1`) to define a named function from a pipeline of discrete transforms.

  > The companion module `Plymio.Enum.Tranform.Dictionary` supports a map-like dictionary of named transforms. It also supports the **composition** of higher level transforms from transforms in the dictionary, stand alone transforms, and/or new pipelines. **Composed** transforms can be saved in the dictionary.

  ## Building a Transform Function

  `build/1` builds a `transform function` from a pipeline of `discrete transforms`.

  Each `discrete transform` is (usually) the name of a function
  supported by `Stream` and/or `Enum` (e.g. `:filter`, `:map`, `:reject`,
  `:group_by`, etc), together with the arguments taken by the function.

  Each `discrete transform` in the pipeline results in a call to
  `Stream` (or `Enum` when the transform is `Enum`-only e.g.
  `Enum.group_by/2`). The calls to `Stream` / `Enum` are then
  [**composed**](https://en.wikipedia.org/wiki/Function_composition_(computer_science)) into a single function.

  In this example, all the discrete transforms can be lazily applied
  (i.e. are supported by `Stream`) so a `Stream` is returned. (The
  stream can be realised using `Enum.to_list/1`):

      iex> fun = [filter: fn v -> is_number(v) end,
      ...>        filter: fn v -> v > 0 end,
      ...>        map: fn v -> v * v end,
      ...>        map: fn v -> v + 42 end,
      ...>        reject: fn v -> v < 45 end,
      ...>        reject: fn v -> v > 50 end]
      ...> |> build
      ...> stream = [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)] |> fun.()
      ...> stream |> Enum.to_list
      [46]

  In this example, the last transformation is `Enum.group_by/2` which
  always returns a `Map`.

      iex> fun = [filter: fn {_k,v} -> is_number(v) end,
      ...>        map: fn {k,v} -> {k,v*v} end,
      ...>        group_by: fn {k,_v} -> k |> to_string end]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.()
      %{"a" => [a: 1], "b" => [b: 4], "c" => [c: 9]}

  Arguments to each discrete transforms must be given is the expected
  order. This example includes a final `Enum.reduce/2` with zero as
  the initial value of the accumulator.

      iex> fun = [filter: fn {_k,v} -> is_number(v) end,
      ...>        map: fn {k,v} -> {k,v*v} end,
      ...>        group_by: fn {k,_v} -> k |> to_string end,
      ...>        reduce: [0, fn {_k,v},s -> (Keyword.values(v) |> Enum.sum) + s end]]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.()
      14

  ## Composing Prebuilt Transform Functions

  Prebuilt `transform functions` can be **composed**  just by including them in the pipeline of discrete transforms passed to `build/1`:

  In this example a new `transform function` is **composed**  from 3 separate, prebuilt `transform functions` and a final subpipeline (`[map: fn v - 4 end]`) (which is built recursively).

      iex> filter_fun = [filter: [fn v -> is_number(v) end, fn v -> v > 0 end]]
      ...> |> build
      ...> mapper_fun = [map: [fn v -> v * v end, fn v -> v + 42 end]]
      ...> |> build
      ...> reject_fun = [reject: [fn v -> v < 45 end, fn v -> v > 50 end]]
      ...> |> build
      ...> fun = [filter_fun, mapper_fun, reject_fun, [map: fn v -> v - 4 end]] |> build
      ...> stream = [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)] |> fun.()
      ...> stream |> Enum.to_list
      [42]

  ## Using Multiple Functions in Discrete Transforms

  Usually multiple functions can be used in each discrete transform.

  For example the first example above can be rewritten with a list of functions for each discrete transform:

      iex> fun = [filter: [fn v -> is_number(v) end, fn v -> v > 0 end],
      ...>        map: [fn v -> v * v end, fn v -> v + 42 end],
      ...>        reject: [fn v -> v < 45 end, fn v -> v > 50 end]]
      ...> |> build
      ...> stream = [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)] |> fun.()
      ...> stream |> Enum.to_list
      [46]

  Discrete transforms with multiple arguments (e.g. `Stream.map_every/3`) can also use multiple functions. In this example every other element in the enumerable is mapped. Note the two functions in a list.

  > Note: `Stream.map_every/3` *always* maps the zeroth element of the enumerable.

      iex> fun = [map_every: [2, [fn v -> v * v end, fn v -> v + 42 end]]]
      ...> |> build
      ...> stream = [1, 2, 3, 4, 5] |> fun.()
      ...> stream |> Enum.to_list
      [43, 2, 51, 4, 67]

  When multiple functions are given, they have to be "combined" according to their purpose (e.g. `filter`):

  ### Combining Multiple Functions: filter

  Multiple `filter`-type functions `AND` together the results of applying each one to the value being tested (using `Enum.all?/2`) e.g.

      iex> fun = fn value ->
      ...>   [fn v -> is_number(v) end, fn v -> v > 0 end]
      ...>   |> Enum.all?(fn f -> f.(value) end)
      ...> end
      ...> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)] |> Enum.filter(fun)
      [1, 2, 3]

  ### Combining Multiple Functions: reject

  Multiple `reject`-type functions are `OR`-ed together using `Enum.any?/2` e.g.

      iex> fun = fn value ->
      ...>   [fn v -> v < 45 end, fn v -> v > 50 end]
      ...>   |> Enum.any?(fn f -> f.(value) end)
      ...> end
      ...> [43, 46, 51] |> Enum.reject(fun)
      [46]

  ### Combining Multiple Functions: map

  Multiple `map`-type functions are combined using `Enum.reduce/2` e.g.

      iex> fun = fn value ->
      ...>    [fn v -> v * v end, fn v -> v + 42 end]
      ...>   |> Enum.reduce(value, fn f,v -> f.(v) end)
      ...> end
      ...> [1, 2, 3] |> Enum.map(fun)
      [43, 46, 51]

  ### Combining Multiple Functions: reduce

  `reduce` functions are normally arity 2 taking the current value from the enumerable, togther with the accumulator.

  This constraint is relaxed when multiple functions are used and each function can be arity 1 or 2. An arity 1 is passed just the result of the previous function, no accumulator (just like a map). The code to combine multiple functions looks something like this.

  > Note for each value of the enumerable, each function is passed the *same* accumulator.

      iex> fun1 = fn v, s -> v + s end
      ...> fun2 = fn v -> v - 42 end
      ...> fun3 = fn v, s -> v * s end
      ...> fun = fn value, acc ->
      ...>   [fun1, fun2, fun3]
      ...>   |> Enum.reduce(value, fn
      ...>        f,v when is_function(f, 2) -> f.(v,acc)
      ...>        f,v when is_function(f, 1) -> f.(v)
      ...>   end)
      ...> end
      ...> [1, 2, 3] |> Enum.reduce(7, fun)
      4375094500

  ## Discrete Transform Forms

  In the examples above the pipeline of discrete transforms  was a `Keyword` where the keys were `Stream` and/or `Enum` functions, and the values their additional arguments (without the enumerable).

  More generally the definition of each discrete transformation can have a number of forms.

  > Its worth stressing that the discrete transform pipeline is *always* a List but not always a Keyword.

  ### Discrete Transform Forms: {name,args} when is_atom(name)

  This is the form used so far. The `name` (an `Atom`) *must* be a function of `Stream` or `Enum`.

      iex> fun = [filter: fn {_k,v} -> is_number(v) end]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.() |> Enum.to_list
      [a: 1, b: 2, c: 3]

  When the discrete transform doesn't take any other arguments other than the enumerable, the args in the 2tuple can be nil or an empty list.

      iex> fun = [count: nil]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.()
      4

  ### Discrete Transform Forms: name when is_atom(name)

  When  `name` is an `Atom`, it *must* be a function of `Stream` or `Enum` that *only* takes an  enumerable; no other arguments.

      iex> fun = [:count]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.()
      4

  Using this form means the other discrete transforms must be e.g. {name,args} else the Elixir compiler will complain since the pipeline is no longer a `Keyword`:

      iex> fun = [{:map, fn {_k,v} -> v*v end}, :sum]
      ...> |> build
      ...> [a: 1, b: 2, c: 3] |> fun.()
      14

  ### Discrete Transform Forms: {mod,fun_name,args}

  The general purpose MFA (`module,function,arguments`) form used with  `Kernel.apply/3` is supported.  The enumerable is prepended to the arguments (`[enum | arguments]`).

  This example uses the MFA form of `[map: &(&1)]`

      iex> fun = [{Stream, :map, [&(&1)]}] |> build
      iex> [a: 1, b: 2, c: 3, d: :atom] |> fun.() |> Enum.to_list
      [a: 1, b: 2, c: 3, d: :atom]

  However, an MFA can call *any* module and function, not just `Stream` or `Enum` ones. For example `List.duplicate/2` is used to create an enumerable to feed the map squaring each value, with a final `:sum` to add up all the values.

      iex> fun = [{List, :duplicate, [3]}, {:map, fn v -> v*v end}, :sum]
      ...> |> build
      ...> 42 |> fun.()
      5292

  Here is another example combining `Stream` / `Enum` 2tuples with an
  MFA. Note though, the result of the `filter`, `map` and `reject`
  discrete transforms will be a `Stream`. `List` functions require a
  list as input, hence the `:to_list` in the transform pipeline just
  before the `insert_at`.

  > Since the pipeline definition is no longer a `Keyword`, it must use the explicit 2tuple syntax.

      iex> fun = [{:filter, [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end]},
      ...>        {:map, [fn {k,v} -> {k, v * v} end, fn {k,v} -> {k, v + 42} end]},
      ...>        {:reject, [fn {_k,v} -> v < 45 end, fn {_k,v} -> v > 50 end]},
      ...>        :to_list,
      ...>        {List, :insert_at, [2, {:e, "five"}]}]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.() |> Enum.to_list
      [b: 46, e: "five"]

  ### Discrete Transform Forms: fun when is_function(fun)

  The transform can also be a function and is passed the
  result of the previous transforms:

      iex> fun = [{:filter, [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end]},
      ...>        {:map, [fn {k,v} -> {k, v * v} end, fn {k,v} -> {k, v + 42} end]},
      ...>        # a transform function
      ...>        fn enum -> enum |> Stream.map(fn {k,v} -> {k |> to_string, v} end) end,
      ...>        {:into, %{}}]
      ...> |> build
      ...> [a: 1, b: 2, c: 3, d: :atom] |> fun.()
      %{"a" => 43, "b" => 46, "c" => 51}

  ## Applying a Transform Function

  `transform/2` is a convenience function taking an enumerable and *either* a `transform function` *or* pipeline of discrete transforms.

  If a pipeline is given, the `transform function` is built
  *on-the-fly* (using `build/1`), used to transform the enumerable and then discarded. If the transform
  is expected to be used many times, it is more efficient to build the
  `transform function` first.

  Here the `transform function` is built *on-the-fly*

      iex> pipeline = [{:map, fn {_k,v} -> v*v end}, :sum]
      ...> [a: 1, b: 2, c: 3] |> transform(pipeline)
      14

  Here the `transform function` is prebuilt and passed to `transform/2`

      iex> fun = [{:map, fn {_k,v} -> v*v end}, :sum] |> build
      ...> [a: 1, b: 2, c: 3] |> transform(fun)
      14

  Frequently the result of `transform/2` is *lazy*

      iex> fun = [{:map, fn {_k,v} -> v*v end}] |> build
      ...> result = [a: 1, b: 2, c: 3] |> transform(fun)
      ...> match?(%Stream{}, result)
      true

  > `Plymio.Enum.Transform.Dictionary` provides support for easily applying prebuilt transforms.

  ## Realising the Result of a Transformed Function

  `realise/2` is another convenience function taking an enumerable and *either* a `transform function` *or* pipeline of discrete transforms.

  `transform/2` is used to apply the transformation, and if the result is a *lazy* enumerable, it is *realised* (using `Enum.to_list/1`).

  Here the `transform function` is prebuilt and passed to `realise/2`. Note the enumerable is *lazy*.

      iex> fun = [{:map, fn {_k,v} -> v*v end}, :sum] |> build
      ...> [a: 1, b: 2, c: 3] |> Stream.map(&(&1)) |> realise(fun)
      14

  ## Defining a Named Transform Function

  Although the focus of this module is to create `transform functions` at run time, it is possible to define a named `transform function`, using a pipeline of discrete transforms.

  The `defenumtransform/1` macro is quite simple, its takes the name of the  function together with the pipeline as the argument:

      defenumtransform named_transform1([{:map, fn {_k,v} -> v*v end}, :sum])

  The named function can be used as expected:

      iex> [a: 1, b: 2, c: 3] |> Stream.map(&(&1)) |> realise(&named_transform1/1)
      14

  ## Notes

  ### `each`

  `Stream.each/2` is preferred but it returns the **original** enumerable whereas `Enum.each/2` returns `:ok`.

      iex> fun = [each: fn {_k,v} -> v*v end] |> build
      ...> [a: 1, b: 2, c: 3] |> realise(fun)
      [a: 1, b: 2, c: 3]

   Here the MFA form of a discrete transform is used to explicitly call `Enum.each/2`:

      iex> fun = [{Enum, :each, [fn {_k,v} -> v*v end]}] |> build
      ...> [a: 1, b: 2, c: 3] |> realise(fun)
      :ok

  ### `into`

  `Enum.into/2` is  preferred over `Stream.into/2` as the latter "loses" the type of the collectable when it is realised:

      iex> fun = [into: %{}] |> build
      ...> [a: 1, b: 2, c: 3] |> realise(fun)
      %{a: 1, b: 2, c: 3}

  Here the MFA form of a discrete transform is used to explicitly call `Stream.into/2`:

      iex> fun = [{Stream, :into, [%{}]}] |> build
      ...> [a: 1, b: 2, c: 3] |> realise(fun)
      [a: 1, b: 2, c: 3]

  """

  alias Plymio.Enum.Utils, as: PEU
  require Logger

  @type enum :: Enumerable.t

  @type discrete_function_name :: atom
  @type discrete_module :: atom
  @type discrete_function :: (any -> any)
  @type discrete_module_function_name_tuple :: {discrete_module, discrete_function_name}
  @type discrete_args :: nil | any | [any]

  @type discrete_transform ::
  discrete_function_name |
  {discrete_function_name, discrete_args} |
  {discrete_module, discrete_function_name, discrete_args} |
  {discrete_module_function_name_tuple, discrete_args} |
  discrete_function |
  {discrete_function, discrete_args}

  @type transform_pipeline :: [discrete_transform]

  @type transform_function :: nil | (any -> any)

  @plymio_transform_enum_fva Enum.__info__(:functions)
  @plymio_transform_stream_fva Stream.__info__(:functions)

  @plymio_transform_enum_keys @plymio_transform_enum_fva |> Keyword.keys |> Enum.uniq
  @plymio_transform_stream_keys @plymio_transform_stream_fva |> Keyword.keys |> Enum.uniq

  @plymio_transform_enum_only_keys @plymio_transform_enum_keys -- @plymio_transform_stream_keys

  # edit_verbs where should use ENUM
  @plymio_transform_enum_preferred_keys [:into] ++ @plymio_transform_enum_only_keys
  |> Enum.uniq

  # edit_verbs where should use STREAM
  @plymio_transform_stream_preferred_keys @plymio_transform_stream_keys -- [:into, :__struct__]

  @plymio_transform_enum_preferred_tuples @plymio_transform_enum_preferred_keys
  |> Enum.map(fn key -> {key, {Enum,key}} end)

  @plymio_transform_stream_preferred_tuples @plymio_transform_stream_preferred_keys
  |> Enum.map(fn key -> {key, {Stream,key}} end)

  # remember: first (Enum) wins
  @plymio_transform_preferred_map @plymio_transform_enum_preferred_tuples ++ @plymio_transform_stream_preferred_tuples
  |> Enum.into(%{})

  @plymio_transform_preferred_keys @plymio_transform_preferred_map |> Map.keys |> Enum.sort

  # In the below the part after @plymio_transform_transform_opts_ follow this convention:
  # n = arity (- 1 i.e after the enum)
  # v = value
  # m = mapper fun (value -> value)
  # r = reduce fun (value, acc -> acc)
  # f = filter fun (multiple filters are AND-ed)
  # g = not filter fun (NOT AND)
  # j = reject fun (miltiple rejects are OR-ed)
  # k = not reject fun (OR)
  # c = compare (value,1, value2 -> boolean)

  @plymio_transform_transform_opts_0 [
    :"all?",
    :"any?",
    :count,
    :cycle,
    :dedup,
    :"empty?",
    :join,
    :interval,
    :max,
    :min,
    :min_max,
    :random,
    :reverse,
    :run,
    :shuffle,
    :sort,
    :sum,
    :to_list,
    :uniq,
    :unzip,
    :with_index,
    :zip,
  ]

  @plymio_transform_transform_opts_1_f [
    :"all?",
    :"any?",
    :count,
    :filter,
    :find,
    :find_index,
    :find_value,
    :split_with,
    :take_while,
  ]

  @plymio_transform_transform_opts_1_g [
  ]

  @plymio_transform_transform_opts_1_j [
    :drop_while,
    :reject,
    :split_while,
  ]

  @plymio_transform_transform_opts_1_k [

  ]

  @plymio_transform_transform_opts_1_m [
    :chunk_by,
    :dedup_by,
    :each,
    :flat_map,
    :group_by,
    :iterate,
    :map,
    :map_join,
    :max_by,
    :min_by,
    :min_max_by,
    :repeatedly,
    :sort_by,
    :uniq_by,
  ]

  @plymio_transform_transform_opts_1_r [
    :reduce,
    :scan,
  ]

  @plymio_transform_transform_opts_1_c [
    :sort
  ]

  # all funs that take one args that is a fun or list of funs
  @plymio_transform_transform_opts_1_fun @plymio_transform_transform_opts_1_f ++
    @plymio_transform_transform_opts_1_g ++
    @plymio_transform_transform_opts_1_j ++
    @plymio_transform_transform_opts_1_k ++
    @plymio_transform_transform_opts_1_m ++
    @plymio_transform_transform_opts_1_r

  @plymio_transform_transform_opts_1_v [
    :at,
    :with_index,
    :chunk,
    :concat,
    :drop,
    :drop_every,
    :fetch,
    :"fetch!",
    :intersperse,
    :into,
    :join,
    :member?,
    :reverse,
    :slice,
    :split,
    :take,
    :take_every,
    :take_random,
    :timer,
    :with_index,
    :zip,
  ]

  # do *not* add anything else without reviewing
  # normalise_edit_opts
  @plymio_transform_transform_opts_2_v_f [
    :find,
    :find_value,
    :unfold,
  ]

  @plymio_transform_transform_opts_2_v_m [
    :into,
    :map_every,
    :map_join,
  ]

  @plymio_transform_transform_opts_2_v_r [
    :flat_map_reduce,
    :map_reduce,
    :reduce,
    :reduce_while,
    :scan,
    :transform,
  ]

  @plymio_transform_transform_opts_2_f_m [
    :filter_map,
  ]

  @plymio_transform_transform_opts_2_m_c [
    :sort_by,
  ]

  @plymio_transform_transform_opts_2_v_v [
    :at,
    :chunk,
    :slice,
    :reverse_slice,
  ]

  @plymio_transform_transform_opts_3_v_v_v [
    :chunk,
  ]

  @plymio_transform_transform_opts_3_m_r_m [
    :transform,
  ]

  # these are the function that have arities 2 or 3 e.g. reduce
  # where multiple funs can be ambguous
  @plymio_transform_transform_opts_2_v_fjmr_OR_1_fjmr [

    [@plymio_transform_transform_opts_1_f, @plymio_transform_transform_opts_2_v_f],

    [@plymio_transform_transform_opts_1_m, @plymio_transform_transform_opts_2_v_m],

    [@plymio_transform_transform_opts_1_r, @plymio_transform_transform_opts_2_v_r]
  ]
  |> Enum.reduce([],
  fn fun_lists, s ->

    # find the intersection of the fun_lists
    funs = fun_lists
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(&MapSet.intersection/2)
    |> MapSet.to_list

    s ++ funs

  end)
  |> List.flatten

  defp normalise_edit_funs(funs) do
    funs |> List.wrap |> List.flatten |> Enum.reject(&is_nil/1)
  end

  defp reduce_edit_funs(edit_verb, edit_funs)

  defp reduce_edit_funs(:map, edit_funs) do

    fn value ->

      edit_funs |> Enum.reduce(value, fn fun, s -> fun.(s) end)
    end

  end

  defp reduce_edit_funs(:reduce, edit_funs) do
    fn value, s ->
      edit_funs
      |> Enum.reduce(value,
      fn
        fun, value when is_function(fun, 2) -> fun.(value, s)
        fun, value when is_function(fun, 1) -> fun.(value)
      end)
    end
  end

  defp reduce_edit_funs(edit_verb, edit_funs)
  when edit_verb in [:and, :filter] do
    fn value ->
      edit_funs |> Enum.all?(fn fun -> fun.(value) end)
    end
  end

  defp reduce_edit_funs(edit_verb, edit_funs)
  when edit_verb in [:or, :reject] do
    fn value ->
      edit_funs |> Enum.any?(fn fun -> fun.(value) end)
    end
  end

  defp resolve_edit_fun(edit_verb, edit_funs)

  defp resolve_edit_fun(_edit_verb, edit_fun) when is_function(edit_fun) do
    edit_fun
  end

  defp resolve_edit_fun(edit_verb, [edit_fun])
  when is_function(edit_fun) and (not is_tuple(edit_verb)) do
    edit_fun
  end

  defp resolve_edit_fun(edit_verb, edit_funs) when is_list(edit_funs) do

    edit_funs
    |> normalise_edit_funs
    |> case do

         # simple fun
         [edit_fun] -> edit_fun

         # multiple funs => reduce
         edit_funs -> reduce_edit_funs(edit_verb, edit_funs)

       end

  end

  # header
  defp resolve_edit_args(edit_verb, edit_opts)

  defp resolve_edit_args(edit_verb, [])
  when edit_verb in @plymio_transform_transform_opts_0 do
    []
  end

  # two funs: mapper and sorter (compare)
  # BEFORE 1_M (to catch sort_by)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_m_c
  and is_list(edit_opts) and length(edit_opts) == 2 do

    mapper_fun = resolve_edit_fun(:mapper, edit_opts |> List.first)

    sorter_fun = edit_opts |> List.last

    [mapper_fun, sorter_fun]

  end

  # one or more filter fun(s)
  # filter funs are effectively AND-ed
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_f
  and is_list(edit_opts) and length(edit_opts) == 1 do
    resolve_edit_fun(:filter, edit_opts)
    |> List.wrap
  end

  # one or more reject fun(s)
  # reject funs are effectively OR-ed
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_j
  and is_list(edit_opts) and length(edit_opts) == 1 do
    resolve_edit_fun(:reject, edit_opts)
    |> List.wrap
  end

  # one or more mapper fun(s)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_m
  and is_list(edit_opts) and length(edit_opts) == 1 do
    resolve_edit_fun(:map, edit_opts)
    |> List.wrap
  end

  # one or more reduce fun(s)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_r
  and is_list(edit_opts) and length(edit_opts) == 1 do
    resolve_edit_fun(:reduce, edit_opts)
    |> List.wrap
  end

  # a compare fun
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_c
  and is_list(edit_opts) and length(edit_opts) == 1 do
    edit_opts
  end

  # just a value
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_v
  and is_list(edit_opts) and length(edit_opts) == 1 do
    edit_opts
  end

  # two funs: filter and mapper
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_f_m
  and is_list(edit_opts) and length(edit_opts) == 2 do

    filter_fun = resolve_edit_fun(:filter, edit_opts |> List.first)

    mapper_fun = resolve_edit_fun(:map, edit_opts |> List.last)

    [filter_fun, mapper_fun]

  end

  # value + filter fun(s)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_f
  and is_list(edit_opts) and length(edit_opts) == 2 do

    edit_fun = resolve_edit_fun(:filter, edit_opts |> List.last)

    [edit_opts |> List.first, edit_fun]

  end

  # value + mapper fun(s)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_m
  and is_list(edit_opts) and length(edit_opts) == 2 do

    edit_fun = resolve_edit_fun(:map, edit_opts |> List.last)

    [edit_opts |> List.first, edit_fun]

  end

  # value + reducer fun(s)
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_r
  and is_list(edit_opts) and length(edit_opts) == 2 do

    edit_fun = resolve_edit_fun(:reduce, edit_opts |> List.last)

    [edit_opts |> List.first, edit_fun]

  end

  # two values
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_v
  and is_list(edit_opts) and length(edit_opts) == 2 do
    edit_opts
  end

  # three values
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_3_v_v_v
  and is_list(edit_opts) and length(edit_opts) == 3 do
    edit_opts
  end

  # mapper, reducer, mapper
  defp resolve_edit_args(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_3_m_r_m
  and is_list(edit_opts) and length(edit_opts) == 3 do

    mapper1_fun = resolve_edit_fun(:map, edit_opts |> Enum.at(0))

    reducer_fun = resolve_edit_fun(:map, edit_opts |> Enum.at(1))

    mapper2_fun = resolve_edit_fun(:map, edit_opts |> Enum.at(2))

    [mapper1_fun, reducer_fun, mapper2_fun]

  end

  defp normalise_edit_opts(edit_verb, edit_opts)

  # into: [] => into: [[]] i.e. list of args in a list with an empty list
  defp normalise_edit_opts(edit_verb, [])
  when edit_verb in [:into] do
    [[]]
  end

  defp normalise_edit_opts(edit_verb, nil)
  when edit_verb in @plymio_transform_transform_opts_0 do
    []
  end

  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in [:into] do

    edit_opts = edit_opts |> List.wrap

    case edit_opts |> length do

      # empty? => into a list
      0 -> [[]]

      # collectable
      1 ->

          cond do

            is_map(edit_opts |> List.first) -> edit_opts
            Keyword.keyword?(edit_opts) -> [edit_opts]
            true -> edit_opts

          end

      # ambiguous
      2 ->

          case edit_opts |> List.last |> is_function do

            # collectable + transform
            true ->

              edit_opts

           # collectable
            _ ->

             edit_opts

         end

     # collectable
     _ ->

       [edit_opts]

    end

  end

  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in [:sort_by] do

    edit_opts |> List.wrap

 end

  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_fjmr_OR_1_fjmr do

    edit_opts = edit_opts |> List.wrap

    case edit_opts |> length do

      # ambiguous
      2 ->

        # this code can *not* disambiguate a 2list where the value
        # is a fun and the fjm is just one fun.
        # to cater, make the fjm fun a list of one fun.

        cond do

          # is a list of funs? => no value
          Enum.all?(edit_opts, fn fun -> fun |> is_function end) ->

            [edit_opts]

          # value + one or more funs
          true ->

            edit_opts

        end

     # just funs
     _ ->

        [edit_opts]

    end

  end

  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_2_v_f do

    edit_opts = edit_opts |> List.wrap

    case edit_opts |> length do

      # ambiguous
      2 ->

        # this code can *not* disambiguate a 2list where the default
        # is a fun and the filter is just one fun.
        # to cater, make the filter fun a list of one fun.

        cond do

          # is a list of funs? => no default
          Enum.all?(edit_opts, fn fun -> fun |> is_function end) ->

            [edit_opts]

            # default + one or more filter funs
            true ->

            edit_opts

        end

        # just (filter) funs
        _ ->

        [edit_opts]

    end

  end

  # could be a list of funs - need to make a list with one entry
  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in [:concat]
  and is_list(edit_opts) do

    cond do

      # is a list of enums? create a new list so that the build_apply_fun works
      Enum.all?(edit_opts, fn enum -> enum |> PEU.enum? end) ->

        [edit_opts]

     # nope - must be a left, right signature. make a list of a list of (one) enums
     # so apply build works
     PEU.enum?(edit_opts) ->

        [[edit_opts]]

        # no default

    end

  end

  # one or more funs of type filter, reject, mapper or reduce
  defp normalise_edit_opts(edit_verb, edit_opts)
  when edit_verb in @plymio_transform_transform_opts_1_fun and is_list(edit_opts) do

    # force a wrap; will be flattened later
    [edit_opts |> List.wrap]

  end

  # default
  defp normalise_edit_opts(_edit_verb, edit_opts) do
    edit_opts |> List.wrap
  end

  defp resolve_edit_tuple(edit_tuple)

  defp resolve_edit_tuple(edit_verb) when is_atom(edit_verb) do
    @plymio_transform_preferred_map |> Map.fetch!(edit_verb)
  end

  defp resolve_edit_tuple({edit_mod, edit_fun})
  when is_atom(edit_mod) and is_atom(edit_fun) do
    {edit_mod, edit_fun}
  end

  # header
  defp build_discrete_fun(edit_tuple, edit_args, edit_opts)

  # list of enumerables
  defp build_discrete_fun({edit_mod, edit_verb}, edit_args, edit_opts)
  when edit_verb in [:concat] and is_list(edit_opts) and length(edit_opts) == 1 do

    fn enum ->

      args = edit_args
      |> List.first
      |> List.insert_at(0, enum)

      apply(edit_mod, edit_verb, [args])

    end

  end

  defp build_discrete_fun({edit_mod, edit_verb}, edit_args, _edit_opts)
  when edit_verb in @plymio_transform_preferred_keys do

    fn enum -> apply(edit_mod, edit_verb, [enum | edit_args]) end

#     fn enum ->

#       apply(edit_mod, edit_verb, [enum | edit_args])

#     end

  end

  defp build_discrete_fun({edit_mod, edit_verb}, edit_args, _edit_opts) do

    fn enum -> apply(edit_mod, edit_verb, [enum | edit_args]) end

  end

  defp build_discrete_fun(fun, edit_args, _edit_opts)
  when is_function(fun) do

    fn enum -> apply(fun, [enum | edit_args]) end

  end

  # header
  defp build_reduce_fun(edit_tuple, edit_opts)

  defp build_reduce_fun({edit_mod, edit_verb}, edit_opts)
  when edit_mod in [Enum, Stream] do

    edit_opts = normalise_edit_opts(edit_verb, edit_opts)

    edit_args = resolve_edit_args(edit_verb, edit_opts)

    build_discrete_fun({edit_mod, edit_verb}, edit_args, edit_opts)

  end

  defp build_reduce_fun({edit_mod, edit_verb}, edit_opts) do

    edit_args = edit_opts |> List.wrap

    build_discrete_fun({edit_mod, edit_verb}, edit_args, edit_opts)

  end

  defp build_reduce_fun(fun, edit_opts)
  when is_function(fun) do

    edit_args = edit_opts |> List.wrap

    build_discrete_fun(fun, edit_args, edit_opts)

  end

  @doc ~S"""
  Builds a transform function when given a discrete transform pipeline.

  See examples above.
  """

  @spec build(transform_pipeline) :: transform_function

  def build(opts) do

    # build the fun for each edit

    # each edit_fun must take a enum and return an enum (maybe emtpy)
    edit_funs = opts
    |> List.wrap
    # regularise the opts
    |> Enum.map(fn

      # fun
      fun when is_function(fun) ->

        {fun, []}

      # fun + opts
      {fun, edit_opts} when is_function(fun) ->

        {fun, edit_opts}

      # mfa
      {edit_mod, edit_fun, edit_args} ->

        {{edit_mod, edit_fun}, edit_args}

      {edit_tuple, edit_opts} ->

      {edit_tuple |> resolve_edit_tuple, edit_opts}

      # just the verb i.e no other args other than enum
      edit_verb when is_atom(edit_verb) ->

      {edit_verb |> resolve_edit_tuple, []}

      # another (sub)pipeline?
      pipeline when is_list(pipeline) ->

        # recurse to build the subpipeline
        fun = pipeline |> build

        {fun, []}

    end)
    # build the edit_fun
    |> Enum.map(fn {edit_tuple, edit_opts} ->
      build_reduce_fun(edit_tuple, edit_opts)
    end)

    fn enum ->
      edit_funs
      |> Enum.reduce(enum, fn fun, s -> fun.(s) end)
    end

  end

  @doc ~S"""
  `transform/2` is a convenience function whose arguments
  are an enumerable together with a `transform_function` or
  `transform_pipeline`.

  If a `transform_pipeline` is given, a `transform_function` is built
  using `build/1`. (This is not optimal if the same call will be made repeatedly.)

  The `transform_function` (either passed as an argument or built on the fly) is
  then applied to the enumerable.

  The result is often a lazy enumerable (e.g. `Stream`), but not always.

  ## Examples

  > Note, in this example the final discrete transform `group_by` produces a `Map`.

  Here a `transform_pipeline` is passed forcing the `transform_function` to be built on the fly:

      iex> [a: 1, b: 2, c: 3, d: :atom]
      ...> |> transform(
      ...>      filter: fn {_k,v} -> is_number(v) end,
      ...>      map: fn {k,v} -> {k,v*v} end,
      ...>      group_by: fn {k,_v} -> k |> to_string end)
      %{"a" => [a: 1], "b" => [b: 4], "c" => [c: 9]}

  In this example, the apply is passed a pre-built `transform_function`:

      iex> fun = [filter: fn {_k,v} -> is_number(v) end,
      ...>        map: fn {k,v} -> {k,v*v} end,
      ...>        group_by: fn {k,_v} -> k |> to_string end]
      ...> |> build
      iex> [a: 1, b: 2, c: 3, d: :atom] |> transform(fun)
      %{"a" => [a: 1], "b" => [b: 4], "c" => [c: 9]}

  """

  @spec transform(enum, transform_function | transform_pipeline) :: any
  def transform(enum, opts \\ [])

  def transform(enum, []) do
    enum
  end

  def transform(enum, fun) when is_function(fun) do

    fun.(enum)

  end

  def transform(enum, opts) when is_list(opts) do

    edit_fun = opts
    |> build

    edit_fun.(enum)

  end

  @doc ~S"""
  `transform/2` is another convenience function whose arguments
  are an enumerable together with a `transform_function` or
  `transform_pipeline`.

  `transform/2` is used to generate the result but, if the result is a lazy enum,erable (e.g. `Stream`), it is realised recursively.

  ## Examples

  Here a `transform_pipeline` is passed forcing the
  `transform_function` to be built on the fly:

      iex> [a: 1, b: 2, c: 3, d: :atom]
      ...> |> realise(
      ...>       filter: [fn {_k,v} -> is_number(v) end, fn {_k,v} -> v > 0 end],
      ...>       map: [fn {k,v} -> {k, v * v} end, fn {k,v} -> {k, v + 42} end],
      ...>       reject: [fn {_k,v} -> v < 45 end, fn {_k,v} -> v > 50 end])
      [b: 46]
  """

  @spec realise(enum, transform_function | transform_pipeline) :: any

  def realise(enum, opts \\ [])

  def realise(enum, []) do

    enum
    |> PEU.maybe_realise

  end

  def realise(enum, opts) do

    transform(enum, opts)
    |> PEU.maybe_realise

  end

  @doc ~S"""
  The `defenumtransform/1` macro creates a named `transform function`
  from a pipeline of discrete transforms.

  ## Examples

  This example shows the definition of a named `transform function`
  called *clean_the_data* that applies a pipeline of `filters`, `maps`
  and `rejects` and finally `to_list` to realise the result of the
  previous transforms.

      defenumtransform clean_the_data(
        filter: [fn v -> is_number(v) end, fn v -> v > 0 end],
        map: [fn v -> v * v end, fn v -> v + 42 end],
        reject: [fn v -> v < 45 end, fn v -> v > 50 end,
        to_list: nil])

      iex> [-1, make_ref(), 1, :atom, 2, "string", 3, &(&1)] |> clean_the_data
      [46]

  """

  @spec defenumtransform(transform_pipeline) :: Macro.t

  defmacro defenumtransform(args) do

    {fun_name, args} = args
    |> Macro.decompose_call

    quote_opts =
      case args |> length do
        # should be a keyword
        1 -> args |> List.first
        _ -> args
      end

    quote bind_quoted: [
      fun_name: fun_name,
      quote_opts: quote_opts,
      caller_module: __CALLER__.module,
      transform_module: __MODULE__,
    ] do

      # create a unique name (atom) for the transform function module attribute
      fun_attr_name =  "#{fun_name}_#{make_ref() |> inspect |> String.slice(11..-2) |> String.replace(".", "_")}"
      |> String.to_atom

      # build the transform function
      transform_fun = quote_opts |> transform_module.build

      # store the transform function in a persistent module attribute
      Module.register_attribute(caller_module, fun_attr_name, persist: true)

      Module.put_attribute(caller_module, fun_attr_name, transform_fun)

      def unquote(fun_name)(enum) do

        # get the transform function from the module attribute
        transform_fun = :attributes
        |> __MODULE__.__info__
        |> Keyword.fetch!(unquote(fun_attr_name))
        |> List.first

        enum |> transform_fun.()

      end

    end

  end

end

