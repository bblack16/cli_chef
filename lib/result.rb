module CLIChef
  # This class encapsulates the result of a command. This includes the response
  # an the exit code wrapper. If a command is non-blocking this also includes
  # the running thread.
  class Result
    include BBLib::Effortless

    attr_of Object, :body, default: nil, allow_nil: true
    attr_str :cmd, default: nil, allow_nil: true
    attr_of ExitCode, :exit_code, default: nil, allow_nil: true
    attr_int :pid, default: 0

  end
end
