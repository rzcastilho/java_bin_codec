defmodule JavaBinCodec.BinSpec do
  defmacro __using__(_opts) do
    quote do
      import Bitwise

      @version 0x02

      @null 0x00
      @bool_true 0x01
      @bool_false 0x02
      @byte 0x03
      @short 0x04
      @double 0x05
      @int 0x06
      @long 0x07
      @float 0x08
      @date 0x09
      @map 0x0A
      @solrdoc 0x0B
      @solrdoclst 0x0C
      @bytearr 0x0D
      @iterator 0x0E
      @_end 0x0F
      @solrinputdoc 0x10
      @map_entry_iter 0x11
      @enum_field_value 0x12
      @map_entry 0x13

      @str 0x01 <<< 0x05
      @sint 0x02 <<< 0x05
      @slong 0x03 <<< 0x05
      @arr 0x04 <<< 0x05
      @ordered_map 0x05 <<< 0x05
      @named_lst 0x06 <<< 0x05
      @extern_string 0x07 <<< 0x05

      def complement(value) when is_integer(value), do: complement(<<value>>)
      def complement(<<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>> = value) when is_binary(value)  do
        [a, b, c, d, e, f, g, h] = [a, b, c, d, e, f, g, h]
        |> Enum.map(fn 0 -> 1; 1 -> 0 end)
        <<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>>
      end

    end
  end
end
