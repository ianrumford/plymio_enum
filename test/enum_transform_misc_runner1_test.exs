defmodule PlymioEnumTransformMiscRunner1Test do

  use PlymioEnumHelpersTest

  test "functions: misc" do

    test_value = [a: 1, b: 2, c: 3]

    helper_run_and_realise_tests_default1(
      test_value: test_value,
      test_specs: [

        # Other Discrete Transform forms

        # arbitrary {mod,fun} tuple as the "key"
        [[a: 1, b: 2, c: 3], [{{List,:flatten}, []}]],

        # mfa - a will be passed through List.wrap/1
        [[b: 2, c: 3], [{List,:delete_at, 0}]],
        [[b: 2, c: 3], [{List,:delete_at, [0]}]],
        [[a: 1, b: 2, c: 3, d: 4], [{{List,:flatten}, [[d: 4]]}]],

        # fun + no args
        [[a: 1, b: 2, c: 3], [{fn x -> x end, []}]],

        # fun only
        [[a: 1, b: 2, c: 3], [fn x -> x end]],
        # not sensible but demonstrates an explicit fun
        [[a: 1, b: 4, c: 9], [fn enum -> enum |> Enum.map(fn {k,v} -> {k,v*v} end) end]],

        ])

  end

end

