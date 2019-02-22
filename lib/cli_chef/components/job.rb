module CLIChef
  class Job
    include BBLib::Effortless

    attr_str :command
    attr_of Thread, :thread, protected: true
    attr_of Result, :result, default: nil, allow_nil: true
    attr_float :percent, default: 0
    attr_float :eta, default: nil, allow_nil: true
    attr_of BBLib::TaskTimer, :timer, default: BBLib::TaskTimer.new, serialize: false
    attr_of Object, :parent, default: nil, allow_nil: true, serialize: false
    attr_hash :arguments, default: {}

    setup_init_foundation(:type)

    def self.type
      self.class.to_s.split('::').last.method_case.to_sym
    end

    serialize_method :type
    bridge_method :type

    def run(&block)
      timer.start
      self.percent = 0.0
      self.thread = Thread.new do
        self.result = Result.new(body: '')
        # TODO Have command killed when parent process dies
        Open3.popen3(command) do |sin, out, err, pr|
          self.result.pid = pr.pid
          { stdout: out, stderr: err }.each do |name, stream|
            stream.each do |line|
              block ? yield(line, name, self) : process_line(line, name)
            end
          end
          self.result.exit_code = code_for(pr.value.exitstatus)
        end
        self.percent = 100.0
        self.timer.stop
        self.result
      end
      running?
    end

    def code_for(code)
      exit_codes.find do |ec|
        ec.code == code
      end || ExitCode.new(code)
    end

    def exit_codes
      parent ? parent.exit_codes : []
    end

    def running?
      thread && thread.alive?
    end

    def done?
      !running?
    end

    alias finished? done?

    def duration
      timer.current || timer.last
    end

    def kill
      return true unless thread
      thread.kill
    end

    def error?
      result && result.exit_code.error?
    end

    def success?
      !error?
    end

    def eta
      @eta || estimate_eta
    end

    def estimate_eta
      return 0 unless percent && timer.current && percent.positive?
      (100 - percent) / timer.current
    end

    protected

    def process_line(line, stream = :stdout)
      # This can be overriden in child job types. Here we just append the line
      # to the body of the result
      self.result.body = self.result.body + line
    end

  end
end
