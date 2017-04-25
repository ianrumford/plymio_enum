defmodule PlymioEnumTransformDoctest1Test do

  use PlymioEnumHelpersTest

  require Plymio.Enum.Transform
  import Plymio.Enum.Transform

  defenumtransform named_transform1([{:map, fn {_k,v} -> v*v end}, :sum])

  defenumtransform clean_the_data(
    filter: [fn v -> is_number(v) end, fn v -> v > 0 end],
    map: [fn v -> v * v end, fn v -> v + 42 end],
    reject: [fn v -> v < 45 end, fn v -> v > 50 end],
    to_list: nil)

  doctest Plymio.Enum.Transform

end
