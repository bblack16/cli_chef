module CLIChef

  class Recipe
    attr_reader :name, :description, :ingredients, :required_input

    def initialize name, description:nil, ingredients:{}, required_input:[]
      @name = name.to_clean_sym
      self.description = description
      @ingredients, @required_input = Hash.new, []
      ingredients.each{ |k, v| add_ingredient k, v }
      required_input.each{ |r| add_required_input r }
    end

    def description= d
      @description = d.to_s
    end

    def remove_ingredient name
      @ingredients.delete name
    end

    def add_ingredient name, default
      @ingredients[name] = default
    end

    def add_required_input value
      if !@required_input.include?(value)
        @required_input << value
        if !@ingredients.include? value then add_ingredient(value, nil) end
      end
    end

    def mix input
      check_for_missing input
      recipe = Hash.new
      @ingredients.each do |k, v|
        recipe[k] = input.include?(k) ? input[k] : v
        if recipe[k].nil? then recipe.delete k end
      end
      recipe
    end

    private

      def check_for_missing input
        missing = []
        @required_input.each do |k|
          if !input.include?(k) then missing << k end
        end
        if !missing.empty?
          raise "Recipe is missing ingredients. You must specify the following: #{missing}."
        end
      end

  end

end
