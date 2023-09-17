defmodule JavaBinCodec.Encoder do
  use JavaBinCodec.BinSpec

  def encode(map), do: encode(<<@version>>, map)

  def encode(acc, [%{} = map | rest]) do
    acc
    |> encode(map)
    |> encode(rest)
  end

  def encode(acc, %{} = map) do
    acc = write_tag(@ordered_map, map_size(map), acc)
    map
    |> Map.to_list()
    |> encode(acc)
  end

  # def encode(acc, [{key, value} | rest]) when is_list(value) or is_map(value) do
  #   acc = encode(value, acc <> key)
  #   encode(rest, acc)
  # end

  # def encode(acc, [{key, value} | rest]) when is_number(value) do
  #   encode(rest, acc <> key <> "#{value}")
  # end

  # def encode(acc, [{key, value} | rest]) do
  #   encode(rest, acc <> key <> "#{value}")
  # end

  def encode(acc, []), do: acc

  def write_tag(acc, tag, size) do
    case band(tag, 0xe0) do
      0 ->
        1
      n ->
        2
    end
  end

  def write_number(acc, number) do

  end

  def btilde(<<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>>)  do
    [a, b, c, d, e, f, g, h] = [a, b, c, d, e, f, g, h]
    |> Enum.map(fn 0 -> 1; 1 -> 0 end)
    <<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>>
  end

end
