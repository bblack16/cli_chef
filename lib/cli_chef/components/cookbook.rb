module CLIChef
  class Cookbook
    include BBLib::Effortless

    attr_ary_of String, :default_locations, singleton: true, add_rem: true
    attr_ary_of ExitCode, :exit_codes, singleton: true, add_rem: true
    attr_ary_of Ingredient, :ingredients, singleton: true, add_rem: true
    attr_str :description
    attr_of Class, :default_job_class, default: CLIChef::Job, singleton: true

    attr_str :path, allow_nil: true, default_proc: proc { |x| x.class.path }
    attr_of Result, :result, default: nil, allow_nil: true

    before :path, :check_default_locations

    bridge_method :default_job_class, :default_locations, :exit_codes, :ingredients, :description, :ingredient

    # Returns true if the path is either set to a valid file or can be found in the
    # environment
    def ready?
      path && (File.exist?(path) || BBLib::OS.which(path))
    end

    # Executes a string as a command to this CLI wrapper in a job (threaded)
    def execute(string, opts = {}, &block)
      raise RuntimeError, "A valid path is currently not set for #{self.class}. Please set a valid path to the executable first." unless path
      return execute!(string, opts.except(:synchronous), &block) if opts[:synchronous]
      string = "#{clean_path} #{string}"
      BBLib.logger.debug("About to run cmd: #{string}")
      (opts.delete(:job_class) || default_job_class).new(opts.merge(command: string, parent: self)).tap do |job|
        job.run(&block)
      end
    end

    # Synchonous version of execute
    def execute!(string, opts = {}, &block)
      while (job ||= execute(string, opts, &block)).running?
        # Nothing
      end
      job.result
    end

    # Runs a command within a Job (seperate thread)
    # For when a command should be run asynchronously
    def run(**args, &block)
      return run!(args.except(:synchronous), &block) if args[:synchronous]
      execute(prepare_args(args), &block)
    end

    # Blocking version of run that is not executed within a thread.
    # For when a command should be run synchronously
    def run!(**args, &block)
      execute!(prepare_args(args), &block)
    end

    # Returns the full command line that would be run based on the given arguments
    def prepare(**args)
      "#{clean_path} #{prepare_args(args)}"
    end

    def prepare_args(**args)
      args.map do |name, arg|
        ingredient = self.ingredient(name)
        raise ArgumentError, "Unknown parameter #{name} for #{self.class}." unless ingredient
        ingredient.to_s(arg)
      end.join(' ')
    end

    # Produces a dynamic help menu for this wrapper. Useful mostly for console or
    # command line based interactions.
    def menu

    end

    def self.prototype
      @prototype ||= self.new
    end

    def self.method_missing(method, *args, &block)
      prototype.respond_to?(method) ? prototype.send(method, *args, &block) : super
    end

    def self.respond_to_missing?(method, include_private = false)
      prototype.respond_to?(method) || super
    end

    def self.ingredient(name)
      ingredients.find { |i| i.match?(name) }
    end

    protected

    def check_default_locations
      return if @path
      return unless found = default_locations.find { |path| File.exist?(path) || BBLib::OS.which(path) }
      self.path = found
    end

    def clean_path
      path.to_s.match?(/\s/) ? "\"#{path}\"" : path
    end

  end
end
