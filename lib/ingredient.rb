# frozen_string_literal: true
module CLIChef
  class Ingredient < BBLib::LazyClass
    attr_symbol :name
    attr_string :description
    attr_string :flag, allow_nil: true
    attr_bool :space, default: true
    attr_array_of Object, :allowed_values, add_rem: true, default: []
    attr_array_of Symbol, :aliases, add_rem: true, default: []
    attr_accessor :value

    def to_s
      if @value == false
        ''
      else
        "#{@flag}#{@space && @flag ? ' ' : nil}#{clean_value}"
      end
    end

    def value=(v)
      raise "Invalid value type for #{@name} (#{v}:#{v.class}). Allowed values must match #{@allowed_values}." unless allowed?(v)
      @value = v
    end

    def allowed?(value)
      @allowed_values.any? { |av| av === value || av.nil? && (value == true || value == false) }
    end

    protected

    def clean_value
      [@value].flatten(1).map do |v|
        if v == true
          ''
        else
          v = v.to_s
          v = "\"#{v}\"" if v.include?(' ') && !v.encap_by?('"')
          v
        end
      end.join(' ')
    end
  end
end
