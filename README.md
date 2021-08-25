# elixir_chunk_download
Uses HTTPoison's Async modules to download a file in chunks asynchronously. It also uses background processes to execute the download streaming.

# Documentation
https://hexdocs.pm/chunk_download/api-reference.html

# Hex package
https://hex.pm/packages/chunk_download


# Return values
Returns: 

- `{:ok, path}` if file successfully downloaded
- `{:error, :eexist}` if the distination file already exists 
- `{:error, :file_is_too_large}` if the remote file's size is greater than max_file_size
- `{:error, reason}` if the file can't be downloaded or open with a reason

# Examples
```elixir
# Without headers, no `:path` provided, uses default path to save file
Download.get_file(file_url)

# With headers, no `:path` provided, uses default path to save file
Download.get_file(file_url, %{"api-key" => "abc"})

# With provided path, provided custom `:path`
Download.get_file(file_url, %{"api-key" => "abc"}, path: my_path)

# With max_file_size provided
Download.get_file(file_url, %{"api-key" => "abc"}, path: my_path, max_file_size: 80_000_000)
```

# Contributions
Contributions are welcome! Please send a PR and/or open an issue.
