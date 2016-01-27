require_relative 'recipe'

module BBLib

  module CLIChef

    class RecipeBook
      attr_reader :recipes

      def initialize
        @recipes = Hash.new
      end

      def add_recipe recipe
        raise "Invalid class passed for recipe (#{recipe.class}). Must be a BBLib::CLIChef::Recipe." unless recipe.is_a? BBLib::CLIChef::Recipe
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

end
