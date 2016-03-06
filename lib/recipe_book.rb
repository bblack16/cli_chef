require_relative 'recipe'

module CLIChef

  class RecipeBook
    attr_reader :recipes

    def initialize
      @recipes = Hash.new
    end

    def add_recipe recipe
<<<<<<< HEAD
      raise "Invalid class passed for recipe (#{recipe.class}). Must be a CLIChef::Recipe." unless recipe.is_a? CLIChef::Recipe
=======
      raise "Invalid class passed for recipe (#{recipe.class}). Must be a CLIChef::Recipe." unless recipe.is_a? BBLib::CLIChef::Recipe
>>>>>>> 896d203583c4558e650a861afc52a50df6c6c37e
      @recipes[recipe.name] = recipe
    end

    def remove_recipe name
      @recipes.delete recipe
    end

    def [] recipe
      @recipes[recipe]
    end

    def include? name
      @recipes.include? name
    end

  end

end
