require_relative 'ingredient'

module CLIChef

  class Cabinet
    attr_reader :ingredients

    def initialize
      @ingredients = Hash.new
    end

    def add_ingredient ingredient
      raise "Invalid type passed as ingredientument: #{ingredient.class}." unless ingredient.is_a? Ingredient
      @ingredients[ingredient.name] = ingredient
    end

    def delete_ingredient ingredient
      @ingredients.delete (ingredient.is_a?(Symbol) ? ingredient : ingredient.name)
    end

    def ingredient_string hash
      str = ''
      hash.each do |k, v|
        ingredient = nil
        if @ingredients.include? k
          ingredient = @ingredients[k]
        else
          ingredient = @ingredients.values.find{ |val| val.aliases.include?(k) }
        end
        if ingredient
          [v].flatten.each do |vl|
            next unless vl != false
            if vl == true
              ingredient.value = nil
            else
              ingredient.value = vl
            end
            str+= ingredient.to_s + ' '
          end
        end
      end
      str.strip
    end

    def from_csv csv
      from_sv csv, ","
    end

    def from_tsv tsv
      from_sv tsv, "\t"
    end

    def from_sv sv, delim
      lines = sv.split("\n")
      headers = lines.first.split(delim).map{ |m| m.downcase.to_sym }
      lines[1..-1].each do |l|
        h = headers.zip(l.split("\t")).to_h
        add_ingredient(CLIChef::Ingredient.new h[:name], description:h[:description], default:(h[:default] == 'nil' ? nil : h[:default]), flag:(h[:flag] == 'nil' ? nil : h[:flag]), value:h[:value], spacer:h[:spacer], encapsulator:h[:encapsulator], aliases:h[:aliases].to_s.split('|'), allowed_values:h.include?(:allowed_values) ? h[:allowed_values].to_s.split('|').map{ |a| eval(a) } : Object)
      end
    end

  end

end
