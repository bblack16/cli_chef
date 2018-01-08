module CLIChef
  class Result
    include BBLib::Effortless

    attr_of Object, :body, default: nil, allow_nil: true
    attr_str :cmd, default: nil, allow_nil: true
    attr_of ExitCode, :exit_code, default: nil, allow_nil: true
    attr_int :pid, default: 0

  end
end
