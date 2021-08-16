defmodule Download do
  alias HTTPoison.{AsyncHeaders, AsyncStatus, AsyncChunk, AsyncEnd}

  @wait_timeout 5000
  @max_file_size 1024 * 1024 * 1000

  def get_file(url, headers, opts \\ []) do
    max_file_size = Keyword.get(opts, :max_file_size, @max_file_size)
    path = Keyword.get(opts, :path, download_path(url))

    with {:ok, file} <- create_file(path),
         {:ok, response_parsing_pid} <- create_process(file, max_file_size, path),
         {:ok, _pid} <- start_download_stream(url, headers, response_parsing_pid, path),
         {:ok} <- wait_for_download(),
         do: {:ok, path}
  end

  defp download_path(url) do
    file_name = url |> String.split("/") |> List.last()
    Path.join([File.cwd!(), file_name])
  end

  defp create_file(path), do: File.open(path, [:write, :exclusive])

  defp create_process(file, max_file_size, path) do
    opts = %{
      file: file,
      max_file_size: max_file_size,
      controlling_pid: self(),
      path: path,
      downloaded_content_length: 0
    }

    {:ok, spawn_link(__MODULE__, :do_download, [opts])}
  end

  defp start_download_stream(url, headers, response_parsing_pid, path) do
    request = HTTPoison.get(url, headers, stream_to: response_parsing_pid)

    case request do
      {:error, _reason} ->
        File.rm!(path)

      _ ->
        nil
    end

    request
  end

  defp wait_for_download() do
    receive do
      reason -> reason
    end
  end

  def do_download(opts) do
    receive do
      response_chunk -> handle_async_response_chunk(response_chunk, opts)
    after
      @wait_timeout -> {:error, :timeout_failure}
    end
  end

  defp handle_async_response_chunk(%AsyncStatus{code: 200}, opts), do: do_download(opts)

  defp handle_async_response_chunk(%AsyncStatus{code: status_code}, opts) do
    finish_download({:error, :unexpected_status_code, status_code}, opts)
  end

  defp handle_async_response_chunk(%AsyncHeaders{headers: headers}, opts) do
    Enum.find(headers, fn {header_name, _value} -> header_name === "Content-Length" end)
    |> do_handle_content_length(opts)
  end

  defp handle_async_response_chunk(%AsyncChunk{chunk: data}, opts) do
    downloaded_content_length = opts.downloaded_content_length + byte_size(data)

    if downloaded_content_length < opts.max_file_size do
      IO.binwrite(opts.file, data)

      Map.put(opts, :downloaded_content_length, downloaded_content_length)
      |> do_download()
    else
      finish_download_with_file_too_big_error(opts)
    end
  end

  defp handle_async_response_chunk(%AsyncEnd{}, opts), do: finish_download({:ok}, opts)

  defp do_handle_content_length({"Content-Length", content_length}, opts) do
    if String.to_integer(content_length) > opts.max_file_size do
      finish_download_with_file_too_big_error(opts)
    else
      do_download(opts)
    end
  end

  defp do_handle_content_length(nil, opts), do: do_download(opts)

  defp finish_download(reason, opts) do
    File.close(opts.file)

    if elem(reason, 0) == :error do
      File.rm!(opts.path)
    end

    send(opts.controlling_pid, reason)
  end

  defp finish_download_with_file_too_big_error(opts),
    do: finish_download({:error, :file_is_too_large}, opts)
end
