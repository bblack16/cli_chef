module CLIChef
  class ExitCode
    include BBLib::Effortless

    attr_int :code, required: true, arg_at: 0
    attr_str :description, default_proc: proc { |x| x.code == 0 ? 'Success' : 'Undefined Exit Code' }, arg_at: 1
    attr_bool :error, default: false, arg_at: 2

    def describe
      "#{error? ? 'ERROR: ' : nil}#{description} (#{code})"
    end
  end

  class ExitError < StandardError
    def initialize(msg = 'The application returned an exit code that indicates an error')
      super
    end
  end
end
