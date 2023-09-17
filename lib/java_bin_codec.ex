defmodule JavaBinCodec do
  alias JavaBinCodec.Decoder

  def decode(bin) when is_binary(bin) do
    Decoder.decode(bin)
  end

  def decode_file(file) do
    case File.exists?(file) do
      true ->
        file
        |> File.read!()
        |> Decoder.decode()

      _ ->
        raise "File not found: #{file}"
    end
  end
end
