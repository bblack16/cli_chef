module CLIChef
  class Job
    include BBLib::Effortless

    attr_str :command
    attr_of Thread, :thread, protected: true
    attr_of Result, :result, default: nil, allow_nil: true
    attr_ary_of ExitCode, :exit_codes
    attr_float :percent, :eta, default: 0
    attr_of BBLib::TaskTimer, :timer, default: BBLib::TaskTimer.new

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
        Open3.popen3(command) do |sin, out, err, pr|
          self.result.pid = pr.pid
          { stdout: out, stderr: err }.each do |name, stream|
            stream.each do |line|
              block ? yield(line, name) : process_line(line, name)
            end
          end
          self.result.exit_code = code_for(pr.value.exitstatus)
        end
        self.precent = 100.0
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

    def running?
      thread && thread.alive?
    end

    def done?
      !running?
    end

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

    protected

    def process_line(line, stream = :stdout)
      self.result.body = self.result.body + line
      case stream
      when :stderr
        STDERR.puts line
      else
        # Nothing happens with stdout in the default job class
        # puts line
      end
    end

  end
end
