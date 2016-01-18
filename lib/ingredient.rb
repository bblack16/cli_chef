module BBLib

  module CliChef

    class Ingredient
      attr_reader :name, :description, :flag, :value, :spacer, :encapsulator, :aliases
      attr_reader :allowed_values, :default, :encap_space_values

      def initialize name, description:nil, default: nil, flag:nil, value:nil, spacer: ' ', encapsulator:nil, aliases:nil, allowed_values:Object, encap_space_values:true
        self.name = name
        self.allowed_values = allowed_values
        self.default = default
        self.description = description
        self.flag = flag
        self.spacer = spacer
        self.encapsulator = encapsulator
        @aliases = []
        self.aliases = aliases
        self.encap_space_values = encap_space_values
        if value then self.value = value end
      end

      def to_s
        enc = !@encap_space_values || @value.to_s.include?(' ') ? @encapsulator : nil
        "#{@flag}#{@flag && @flag != '' ? @spacer : nil}#{enc}#{@value}#{enc}"
      end

      def name= n
        @name = n.to_s.gsub('_',' ').drop_symbols.gsub(' ','_').downcase.to_sym
      end

      def description= d
        @description = d.to_s
      end

      def default= d
        @default = d
      end

      def flag= f
        @flag = f.to_s
      end

      def value= v
        raise "Invalid value type for #{@name} (#{v}:#{v.class}). Allowed values must match #{@allowed_values} or #{@default}." unless allowed?(v)
        @value = DEFAULTS.include?(v) ? @default : v.to_s
      end

      def spacer= s
        @spacer = s.to_s
      end

      def encapsulator= e
        @encapsulator = e.to_s
      end

      def aliases= a
        return unless a
        @aliases = [a].flatten.map{ |a| a.to_sym }.uniq
      end

      def add_alias a
        @aliases << a.to_sym
        self.aliases = @aliases
      end

      def allowed_values= a
        @allowed_values = [a].flatten.uniq
      end

      def add_allowed_value a
        if !@allowed_values.include? a
          @allowed_values << a
        end
      end

      def encap_space_values= e
        @encap_space_values = e == true
      end

      private

        DEFAULTS = [ :default, :def, :d ]

        def allowed? val
          return true if DEFAULTS.include? val
          valid = false
          @allowed_values.each{ |a| a === val ? valid = true : nil }
          if !valid && val == @default then valid = true end
          valid
        end

    end

  end

end
