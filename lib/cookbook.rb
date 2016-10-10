require_relative 'ingredient'

module CLIChef

  class Cookbook < BBLib::LazyClass
    attr_string :name, :description
    attr_valid_file :path, allow_nil: true
    attr_array_of String, :default_locations, default: []
    attr_array_of Ingredient, :ingredients
    attr_array_of Recipe, :recipes
    attr_int :exit_code
    attr_reader :exit_codes, :result

    def run **args, &block
      if args.delete(:non_blocking)
        @thread = Thread.new {
          run_cmd(args, &block)
        }
      else
        run_cmd(args, &block)
      end
    end

    def exit_status
      @exit_codes[@exit_code]
    end

    def prepare **args
      arguments = args.map do |k, v|
        if ingredient = @ingredients.find{ |i| i.name == k || i.aliases.include?(k) }
          ingredient.value = v
          ingredient.to_s
        else
          raise ArgumentError, "Unknown parameter #{k} for #{@name}."
        end
      end.join(' ')
      "#{clean_path} #{arguments}"
    end

    def menu
      menu = %"
      ▄████████  ▄█        ▄█        ▄████████    ▄█    █▄       ▄████████    ▄████████
     ███    ███ ███       ███       ███    ███   ███    ███     ███    ███   ███    ███
     ███    █▀  ███       ███▌      ███    █▀    ███    ███     ███    █▀    ███    █▀
     ███        ███       ███▌      ███         ▄███▄▄▄▄███▄▄  ▄███▄▄▄      ▄███▄▄▄
     ███        ███       ███▌      ███        ▀▀███▀▀▀▀███▀  ▀▀███▀▀▀     ▀▀███▀▀▀
     ███    █▄  ███       ███       ███    █▄    ███    ███     ███    █▄    ███
     ███    ███ ███▌    ▄ ███       ███    ███   ███    ███     ███    ███   ███
     ████████▀  █████▄▄██ █▀        ████████▀    ███    █▀      ██████████   ███
                ▀" +
      "\n\t#{@name} - #{@description}\n\t" + '-' * 50
      @ingredients.each do |ingredient|
        menu += "\n\t\t#{ingredient.name} - #{ingredient.description}" +
                "\n\t\t\tFlag: #{ingredient.flag}" +
                "\n\t\t\tAllowed Values: #{ingredient.allowed_values.map{ |v| v.nil? ? 'nil' : v.to_s }.join(', ')}" +
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

    protected

      def lazy_setup
        @exit_codes = Hash.new
        @ingredients = Array.new
        @result = nil
        setup_defaults
        check_default_paths
      end

      def setup_defaults
        # Reimplement this in child class
      end

      def process_line line, stream
        # This method is used to determine what to do when a cmd generates
        # stdout or stderr. Messages will be passed in line by line
        # puts line
      end

      def add_ingredient *ingredients
        ingredients.each do |ingredient|
          ingredient = Ingredient.new(ingredient) if ingredient.is_a?(Hash)
          raise TypeError, "Invalid object type passed as Ingredient: #{ingredient.class}" unless ingredient.is_a?(Ingredient)
          @ingredients.push(ingredient)
        end
      end

      def add_default_location *paths
        @default_locations = (@default_locations + paths).uniq
      end

      def check_default_paths
        if found = @default_locations.find{ |path| File.exists?(path) }
          self.path = found
        end
      end

      def add_exit_codes hash
        hash.each do |code, description|
          @exit_codes[code] = description
        end
      end

      def clean_path
        if @path.include?(' ')
          "\"#{@path}\""
        else
          @path
        end
      end

      def run_cmd args, &block
        result = Array.new
        Open3.popen3(prepare(args)) do |i, o, e, w|
          @pid = w.pid
          { stdout: o, stderr: e }.each do |name, stream|
            stream.each do |line|
              result << line
              if block_given?
                yield line, name
              else
                process_line(line, name)
              end
            end
          end
          @exit_code = w.value.exitstatus
        end
        @result = result.join
      end

  end

end
