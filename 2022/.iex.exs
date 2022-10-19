# Load runner library if it wasn't already
if !function_exported?(Runner,  :__info__,  1) do
  c(Enum.find(~w[runner.ex ../runner.ex], &File.exists?/1))
end
