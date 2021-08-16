defmodule DownloadTest do
  use ExUnit.Case

  @file_url "https://file-examples-com.github.io/uploads/2017/02/index.html"
  # 1 MB
  @file_size 137_453

  @project_path File.cwd!()

  describe "get_file" do
    setup do
      {:ok, temp_path: temp_path()}
    end

    test "" do
      (@project_path <> "/" <> "index.html")
      |> File.rm()

      assert {:ok, saved_path} = Download.get_file(@file_url, %{})
      IO.puts(saved_path)
      assert file_was_properly_downloaded(saved_path)

      File.rm!(saved_path)
    end

    test "saved to specified download path", %{temp_path: temp_path} do
      assert {:ok, temp_path} = Download.get_file(@file_url, %{}, path: temp_path)
      assert file_was_properly_downloaded(temp_path)
    end

    test "smaller than max_file_size", %{temp_path: temp_path} do
      assert Download.get_file(@file_url, %{}, path: temp_path, max_file_size: 400_000) ==
               {:ok, temp_path}

      assert file_was_properly_downloaded(temp_path)
    end

    test "bigger than max_file_size", %{temp_path: temp_path} do
      assert {:error, :file_is_too_large} ==
               Download.get_file(@file_url, %{}, path: temp_path, max_file_size: 10_000)

      refute File.exists?(temp_path)
    end

    test "returns error for redirecting url", %{temp_path: temp_path} do
      assert {:error, :unexpected_status_code, 404} ==
               Download.get_file(
                 "https://file-examples-com.github.io/uploads/2017/02/index.html1111",
                 %{},
                 path: temp_path
               )

      refute File.exists?(temp_path)
    end

    test "returns error if file exists already" do
      download_path = File.cwd!() <> "/" <> "test/test_helper.exs"

      assert Download.get_file(@file_url, %{}, path: download_path) == {:error, :eexist}
    end
  end

  defp file_was_properly_downloaded(path) do
    File.exists?(path) && File.stat!(path).size == @file_size
  end

  defp temp_path() do
    hash = :crypto.strong_rand_bytes(30) |> Base.encode16(case: :lower)
    "/tmp/#{hash}"
  end
end
