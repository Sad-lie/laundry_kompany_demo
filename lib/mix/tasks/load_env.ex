defmodule Mix.Tasks.LoadEnv do
  use Mix.Task

  @shortdoc "Loads .env file into environment variables"

  def run(_) do
    if File.exists?(".env") do
      ".env"
      |> File.stream!()
      |> Stream.each(fn line ->
        line = String.trim(line)

        cond do
          String.starts_with?(line, "#") ->
            :skip

          String.contains?(line, "=") ->
            [key, value] = String.split(line, "=", parts: 2)
            System.put_env(String.trim(key), String.trim(value))

          true ->
            :skip
        end
      end)
      |> Stream.run()

      IO.puts("✓ Loaded .env file")
    else
      IO.puts("⚠ No .env file found")
    end
  end
end
