# frozen_string_literal: true
require_relative 'ingredient'
require_relative 'exit_code'
require_relative 'result'

module CLIChef
  class Cookbook
    include BBLib::Effortless

    attr_string :name, :description
    attr_str :path, allow_nil: true, serialize: true, always: true
    attr_array_of String, :default_locations, default: [], serialize: true, always: true, uniq: true, add_rem: true, adder_name: 'add_default_location', remover_name: 'remove_default_location'
    attr_array_of Ingredient, :ingredients, default: [], serialize: true, always: true, add_rem: true, adder_name: 'add_ingredient', remover_name: 'remove_ingredient'
    attr_of ExitCode, :exit_code, serialize: false, allow_nil: true
    attr_array_of ExitCode, :exit_codes, default: [], add_rem: true
    attr_of Result, :result, default: nil, allow_nil: nil

    def self.prototype
      @prototype ||= self.new
    end

    def self.method_missing(*args, &block)
      if prototype.respond_to?(args.first)
        prototype.send(*args, *block)
      else
        super
      end
    end

    def exec(string, &block)
      run_cmd(string, freeform: true, &block)
      self.result
    end

    def run(*args, &block)
      self.exit_code = nil
      named = BBLib.named_args(*args)
      if named.delete(:non_blocking)
        @thread = Thread.new do
          run_cmd(named, &block)
        end
        running?
      else
        run_cmd(named, &block)
        self.result
      end
    end

    def prepare(*args)
      named = BBLib.named_args(*args)
      arguments = named.map do |k, v|
        if ingredient = ingredients.find { |ing| ing.name == k || ing.aliases.include?(k) }
          ingredient.value = v
          ingredient.to_s
        else
          raise ArgumentError, "Unknown parameter #{k} for #{name}."
        end
      end.join(' ')
      "#{clean_path} #{arguments}"
    end

    def prepare_freeform(cmd)
      "#{clean_path} #{cmd}"
    end

    def menu
      menu = %(
      ▄████████  ▄█        ▄█        ▄████████    ▄█    █▄       ▄████████    ▄████████
     ███    ███ ███       ███       ███    ███   ███    ███     ███    ███   ███    ███
     ███    █▀  ███       ███▌      ███    █▀    ███    ███     ███    █▀    ███    █▀
     ███        ███       ███▌      ███         ▄███▄▄▄▄███▄▄  ▄███▄▄▄      ▄███▄▄▄
     ███        ███       ███▌      ███        ▀▀███▀▀▀▀███▀  ▀▀███▀▀▀     ▀▀███▀▀▀
     ███    █▄  ███       ███       ███    █▄    ███    ███     ███    █▄    ███
     ███    ███ ███▌    ▄ ███       ███    ███   ███    ███     ███    ███   ███
     ████████▀  █████▄▄██ █▀        ████████▀    ███    █▀      ██████████   ███
                ▀) \
             "\n\t#{name} - #{description}\n\t" + '-' * 50
      ingredients.each do |ingredient|
        menu += "\n\t\t#{ingredient.name} - #{ingredient.description}" \
                "\n\t\t\tFlag: #{ingredient.flag}" \
                "\n\t\t\tAllowed Values: #{ingredient.allowed_values.map { |v| v.nil? ? 'nil' : v.to_s }.join(', ')}" \
                "\n\t\t\tAliases: #{ingredient.aliases.map(&:to_s).join(', ')}"
      end
      menu
    end

    def running?
      @thread && @thread.alive?
    end

    def done?
      !running?
    end

    def error?
      exit_code&.error?
    end

    def success?
      exit_code && !error?
    end

    protected

    def simple_setup
      setup_defaults
      check_default_paths
    end

    def setup_defaults
      # Reimplement this in child class
    end

    def process_line(line, stream)
      # This method is used to determine what to do when a cmd generates
      # stdout or stderr. Messages will be passed in line by line
      # puts line
    end

    def check_default_paths
      return unless found = default_locations.find { |path| File.exist?(path) || BBLib::OS.which(path) }
      self.path = found
    end

    def clean_path
      if path.to_s.include?(' ')
        "\"#{path}\""
      else
        path
      end
    end

    def run_cmd(args, freeform: false)
      result = []
      pid = 0
      cmd = freeform ? prepare_freeform(args.to_s) : prepare(args)
      Open3.popen3(cmd) do |sin, out, err, pr|
        pid = pr.pid
        { stdout: out, stderr: err }.each do |name, stream|
          stream.each do |line|
            result << line
            if block_given?
              yield line, name
            else
              process_line(line, name)
            end
          end
        end
        self.exit_code = exit_codes.find { |ec| ec.code == pr.value.exitstatus } || ExitCode.new(code: pr.value.exitstatus)
      end
      self.result = Result.new(body: result.join, pid: pid, cmd: cmd, exit_code: self.exit_code)
      raise ExitCode::ExitError, "#{name} (code #{exit_code.code}): #{exit_code.description}" if exit_code.error?
    end
  end
end
