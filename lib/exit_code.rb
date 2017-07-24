
module CLIChef
  # This class encapsulates an exit code. This is used to provide a final status
  # for a running program and can be used to automatically raise errors when based
  # exit codes are thrown.
  class ExitCode
    include BBLib::Effortless

    attr_int :code, required: true
    attr_str :description, default: 'Undefined exit code...'
    attr_bool :error, default: false

    def describe
      "#{error? ? 'ERROR: ' : nil}#{description} (#{code})"
    end

    # This class is raised whenever an exit code set to an error is returned.
    class ExitError < StandardError
      def initialize(msg = 'The application returned an exit code that indicates an error')
        super
      end
    end
  end
end
