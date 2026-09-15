#!/usr/bin/env elixir
File.cd!(__DIR__)
temp = Path.join(System.tmp_dir!(), "slippi-float-#{System.pid()}-#{System.unique_integer([:positive])}")
File.mkdir!(temp)
run = fn executable, args ->
  {output, status} = System.cmd(executable, args, stderr_to_stdout: true)
  if status != 0, do: raise("#{executable} failed (#{status}):\n#{output}")
  output
end

try do
  object = Path.join(temp, "hook.o")
  run.(System.get_env("PPC_AS", "powerpc-eabi-as"), [
    "-a32", "-mbig", "-mregnames", "-mgekko", "-I", ".", "-o", object,
    "AI/OverwriteInputs/OverwriteProcessedInputs.asm"
  ])
  relocations = run.(System.get_env("PPC_READELF", "powerpc-eabi-readelf"), ["-r", object])
  if String.contains?(relocations, "R_PPC_"), do: raise("unresolved relocations:\n#{relocations}")

  # Gecko can exit successfully when its toolchain is missing. Build into
  # a fresh location so that a stale artifact can never appear successful.
  artifact = Path.join(temp, "float-inputs.txt")
  config = "float-inputs.json" |> File.read!() |> JSON.decode!()
  config = Map.put(config, "outputFiles", [%{"file" => artifact}])
  config_path = Path.join(temp, "build.json")
  File.write!(config_path, JSON.encode!(config))
  IO.write(run.(System.get_env("GECKO", "gecko"), ["build", "-c", config_path, "-defsym", "STG_EXIIndex=1"]))
  code = File.read!(artifact)
  unless String.contains?(code, "C206B0DC ") and String.contains?(code, "Direct protocol v2"),
    do: raise("unexpected assembled hook")
  File.mkdir_p!("Output")
  File.cp!(artifact, "Output/float-inputs.txt")
  IO.puts("Verified hook written to Output/float-inputs.txt")
after
  File.rm_rf!(temp)
end
