module CLIChef
  class Ingredient
    include BBLib::Effortless
    attr_sym :name
    attr_ary_of Symbol, :aliases, pre_proc: proc { |x| [x].flatten.map { |i| i.to_s.to_sym } }
    attr_str :flag, default: nil, allow_nil: true
    attr_of Object, :argument, serialize: false
    attr_str :delimiter, :flag_delimiter, default: ' '
    attr_str :description
    attr_bool :boolean_argument, default: false
    attr_ary :allowed_values, add_rem: true

    before :argument=, :allowed!, send_arg: true

    def to_s(value = nil)
      return '' if boolean_argument? && value == false
      cleaned_arg = cleaned_argument(value)
      argument == false ? '' : "#{flag}#{flag && !cleaned_arg.empty? ? flag_delimiter : nil}#{cleaned_arg}"
    end

    def cleaned_argument(value = nil)
      allowed!(value)
      return '' if boolean_argument?
      [value].flatten(1).map(&:to_s).map do |arg|
        arg.include?(/\s/) && !arg.encap_by?('"') ? "\"#{arg.gsub('"','\\"')}\"" : arg
      end.join(delimiter)
    end

    def match?(name)
      self.name == name || aliases.include?(name)
    end

    def allowed?(value)
      return true if allowed_values.empty?
      allowed_values.any? do |av|
        av === value || av.nil? && (value == true || value == false)
      end
    end

    protected

    def allowed!(value)
      raise ArgumentError, "#{name} does not accept the value passed to it: #{value} (#{value.class})" unless allowed?(value)
    end
  end
end
