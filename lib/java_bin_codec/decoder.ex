defmodule JavaBinCodec.Decoder do
  use JavaBinCodec.BinSpec

  def decode(<<@version, rest::binary>>) do
    {value, _, _} = read_object(rest, [])
    value
  end

  def decode(_), do: raise("invalid version and/or content")

  def read_object(<<tag::unsigned-8, rest::binary>>, cache) do
    shifted_tag = tag >>> 0x05

    cond do
      shifted_tag == @str >>> 5 ->
        read_string(tag, rest, cache)

      shifted_tag == @sint >>> 5 ->
        read_small_number(tag, rest)
        |> Tuple.append(cache)

      shifted_tag == @slong >>> 5 ->
        read_small_number(tag, rest)
        |> Tuple.append(cache)

      shifted_tag == @arr >>> 5 ->
        read_array(tag, rest, cache)

      shifted_tag == @ordered_map >>> 5 ->
        read_ordered_map(tag, rest, cache)

      shifted_tag == @named_lst >>> 5 ->
        raise "unhandled tag named_lst (#{inspect(tag)})"

      shifted_tag == @extern_string >>> 5 ->
        read_extern_string(tag, rest, cache)

      true ->
        case tag do
          @null ->
            {nil, rest, cache}

          @date ->
            read_date(rest)
            |> Tuple.append(cache)

          @int ->
            read_integer(rest)
            |> Tuple.append(cache)

          @bool_true ->
            {true, rest, cache}

          @bool_false ->
            {false, rest, cache}

          @float ->
            read_float(rest)
            |> Tuple.append(cache)

          @double ->
            read_double(rest)
            |> Tuple.append(cache)

          @long ->
            read_long(rest)
            |> Tuple.append(cache)

          @byte ->
            read_byte(rest)
            |> Tuple.append(cache)

          @short ->
            read_short(rest)
            |> Tuple.append(cache)

          @map ->
            raise "unhandled tag map (#{inspect(tag)})"

          @solrdoc ->
            read_solr_document(rest, cache)

          @solrdoclst ->
            read_solr_document_list(rest, cache)

          @bytearr ->
            raise "unhandled tag bytearr (#{inspect(tag)})"

          @iterator ->
            raise "unhandled tag iterator (#{inspect(tag)})"

          @_end ->
            raise "unhandled tag end (#{inspect(tag)})"

          @solrinputdoc ->
            raise "unhandled tag solrinputdoc (#{inspect(tag)})"

          @enum_field_value ->
            raise "unhandled tag enum_field_value (#{inspect(tag)})"

          @map_entry ->
            raise "unhandled tag map_entry (#{inspect(tag)})"

          @map_entry_iter ->
            raise "unhandled tag map_entry_iter (#{inspect(tag)})"

          _ ->
            raise "unknown tag (#{inspect(tag)})"
        end
    end
  end

  def read_string(tag, rest, cache) do
    {count, rest} = read_size(tag, rest)
    <<str::binary-size(count), rest::binary>> = rest
    {str, rest, cache}
  end

  def read_small_number(tag, rest) do
    case band(tag, 0x10) do
      0 ->
        {band(tag, 0x0F), rest}

      _ ->
        v = band(tag, 0x0F)
        <<b::integer-signed-8, rest::binary>> = rest
        n = band(b, 0x7F)

        case band(b, 0x80) do
          0 ->
            {bor(n <<< 4, v), rest}

          _ ->
            {number, rest} = read_v_number(rest, n)
            {bor(number <<< 4, v), rest}
        end
    end
  end

  def read_ordered_map(tag, rest, cache) do
    {count, rest} = read_size(tag, rest)

    Enum.reduce(0..(count - 1), {%{}, rest, cache}, fn _, {map, rest, cache} ->
      {key, rest, cache} = read_object(rest, cache)
      {value, rest, cache} = read_object(rest, cache)
      {Map.put(map, key, value), rest, cache}
    end)
  end

  def read_solr_document(<<tag::integer-signed-8, rest::binary>>, cache) do
    {count, rest} = read_size(tag, rest)

    Enum.reduce(0..(count - 1), {%{}, rest, cache}, fn _, {map, rest, cache} ->
      {key, rest, cache} = read_object(rest, cache)
      {value, rest, cache} = read_object(rest, cache)
      {Map.put(map, key, value), rest, cache}
    end)
  end

  def read_solr_document_list(rest, cache) do
    {[num_found, start, max_score, num_found_exact], rest, cache} = read_object(rest, cache)
    {docs, rest, cache} = read_object(rest, cache)

    {
      %{}
      |> Map.put("numFound", num_found)
      |> Map.put("start", start)
      |> Map.put("maxScore", max_score)
      |> Map.put("numFoundExact", num_found_exact)
      |> Map.put("docs", docs),
      rest,
      cache
    }
  end

  def read_array(tag, rest, cache) do
    {count, rest} = read_size(tag, rest)

    Enum.reduce(0..(count - 1), {[], rest, cache}, fn _, {array, rest, cache} ->
      {value, rest, cache} = read_object(rest, cache)
      {array ++ [value], rest, cache}
    end)
  end

  def read_extern_string(tag, rest, cache) do
    {count, rest} = read_size(tag, rest)

    case count do
      0 ->
        <<b::signed-8, rest::binary>> = rest
        {str, rest, cache} = read_string(b, rest, cache)
        {str, rest, cache ++ [str]}

      index ->
        {Enum.at(cache, index - 1), rest, cache}
    end
  end

  def read_size(tag, rest) do
    case band(tag, 0x1F) do
      0x1F = v ->
        <<b::integer-signed-8, rest::binary>> = rest
        n = band(b, 0x7F)

        case band(b, 0x80) do
          0 ->
            {v + n, rest}

          _ ->
            {number, rest} = read_v_number(rest, v + n)
            {number, rest}
        end

      number ->
        {number, rest}
    end
  end

  def read_byte(<<number::integer-8, rest::binary>>) do
    {number, rest}
  end

  def read_short(<<number::integer-16, rest::binary>>) do
    {number, rest}
  end

  def read_integer(<<number::integer-32, rest::binary>>) do
    {number, rest}
  end

  def read_float(<<number::float-32, rest::binary>>) do
    {number, rest}
  end

  def read_long(<<number::integer-64, rest::binary>>) do
    {number, rest}
  end

  def read_double(<<number::float-64, rest::binary>>) do
    {number, rest}
  end

  def read_date(<<number::integer-64, rest::binary>>) do
    {
      number
      |> div(1000)
      |> DateTime.from_unix!(),
      rest
    }
  end

  def read_v_number(rest, number, shift \\ 7)

  def read_v_number(<<b::integer-signed-8, rest::binary>>, number, shift)
      when band(b, 0x80) != 0 do
    i = number + (band(b, 0x7F) <<< shift)
    read_v_number(rest, i, shift + 7)
  end

  def read_v_number(<<b::integer-signed-8, rest::binary>>, number, shift) do
    {number + (band(b, 0x7F) <<< shift), rest}
  end
end
