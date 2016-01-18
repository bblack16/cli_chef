# CliChef

CLI Chef is a simple command line interface wrapper for Ruby. It is made to make writing wrappers an easy and flexible process.

CLI Chef is part of the BBLib (Brandon Black Library) for Ruby. BBLib is a requirement and includes a large number of other useful methods that help make CLI Chef easier to use. You can read documentation here: (BBLib)[https://github.com/bblack16/bblib-ruby].

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cli_chef'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cli_chef

## Usage

CLI Chef is made up of the following components:

- *Cookbook*: A cookbook is the base wrapper class of CLI Chef. The cookbook handles interaction with the CLI. It stores all possible ingredients and recipes. It can also contain an exit code map, default application locations and the results of the previously run command.
- *Ingredient*: An ingredient is essentially a CLI argument. It contains a name for the argument, its flag (if it has one) and its value (again, if it has one). There are many other properties in ingredient that control how it is constructed. For more detailed information scroll down.
- *Cabinet*: A cabinet is a container of all the various ingredients available in a cookbook.
- *Recipe*: A recipe is a set of arguments in a specified order, with specified values that can easily be passed to the cookbook to run.
- *Recipe Book*: A recipe book is a container for recipes within a cookbook.

### Cookbook

Cookbooks are the core class of CLI Chef. It is meant to be an abstract class from which CLI wrappers can be constructed. It handles a lot of the work needed by default, but requires a few setup methods to be implemented in any of its sub-classes.

To create a new cookbook you simple create a new class that inherits from it:

```ruby
class SevenZip < BBLib::CliChef::Cookbook
  # Code goes here
end
```
*NOTE*: It is highly recommended NOT to define an initialize method and let the parent class handle it. If you have a need to create such a methd, be sure to call the protected _init_ method passing the name, description and path as arguments.

There are a few setup methods that you need to override as well as a few that can be, but are optional.

```ruby
class SevenZip < BBLib::CliChef::Cookbook

  protected

  ##########REQUIRED

  # Though ingredients can be added post instantiation it is nearly essential
  # that some be added by writing the setup_ingredients method.
  # Without this setup method the wrapper is not useable.
  # There are multiple ways to populate a Cookbook with Ingredients.
  # The next section discusses these methods.
  def setup_ingredients
    # Manually construct and Ingredient and add it to the Cabinet
    @cabinet.add_ingredient( BBLib::CliChef::Ingredient.new(:extract, flag:'e'))

    # OR add using TSV loader
    tsv = %"name	description	flag	default	allowed_values	aliases	spacer	encapsulator
add	Adds files to archive.	a	nil	nil	a
extract	Extracts files from an archive to the current directory or to the output directory.	e	nil	nil	e
extract_full_paths	Extracts files from an archive with their full paths in the current directory, or in an output directory if specified.	x	nil	nil	x"

    @cabinet.from_tsv(tsv)
  end

  ##########OPTIONAL

  # Default locations can be provided. If a path is not passed to initialize
  # these paths will be checked until one exists. If none exist, the wrapper is
  # set to invalid and cannot be used to run commands until a valid path is provided.
  # There is no limit to how many defaults can be provided.
  def setup_default_locations
    @default_locations << ['C:/Program Files/7Zip/7z.exe', '/opt/7zip/bin/7z']
  end

  # The instance variable @exit_codes holds a mapping to exit codes.
  # This method MAY be added to control what codes exist for the wrapper.
  # The @exit_codes variable is already initialized as a hash, so items can be
  # added to it or you can assign a new hash to it, as done below.
  # The key should be the numeric code and its value a description of what that code signifies.
  def setup_exit_codes
    @exit_codes = {
      0 => 'No error',
      1 =>	'Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.',
      2	=> 'Fatal error',
      7	=> 'Command line error',
      8	=> 'Not enough memory for operation',
      255	=> 'User stopped the process'
    }
  end

  # Recipes can be added post instantiation, but the below method allows them
  # to be added to every instance of the wrapper. An easy way of adding recipes is shown below.
  # See the recipe section for more information on recipes.
  def setup_recipes
    @recipe_book.add_recipe BBLib::CliChef::Recipe.new 'add', ingredients: ({add:true, type:'7z', include:nil, exclude:nil, recurse:nil, volumes:nil, working_dir:nil, password:nil, method:nil}), required_input: [:file, :output]
    @recipe_book[:add].description = 'Adds a file to the specified archive. If the archive does not exist it is created. Both the input file and output archive are required arguments and must be valid file paths. The :type ingredient can be used to toggle what type of archive is created. By default it is a 7z.'
  end
end
```

#### Adding Ingredients to _setup_ingredients_


There are a couple of ways to add ingredients to a cookbook during initialization within the _setup_ingredients_ method. Both are shown above in the sample code for a 7Zip wrapper.


*1 Add Ingredient to @cabinet*
  As shown above, an Ingredient object can be created and passed into the _add_ingredient_ method of @cabinet.


*2 Parse From Separated Values*
  For additional convenience, the Cabinet class can parse text such as tsv or csv to generate Ingredients quickly. This allows you to setup the CLI arguments in an application such as excel and have the Cabinet parse them into Ingredients. The SV must include headers as the first row and must include at least the header 'name'. The following list may also be specified in the SV:


- *name* (required) - A string name. Use lower case and avoid spaces. Any spaces will be replaced with underscores. Symbols are stripped as well, so stick to alpha-numeric chars.

- *description* - A full text description of the ingredient. If using a csv, avoid commas. It is recommended that you use the TSV parser instead, so commas are allowed.

- *default* - Specifies what the default value of the ingredient is. This value must conform to the allowed_values field options.

- *flag* - The flag for this ingredient (EX: '-c', 't', '--help').

- *spacer* - What should be used to separate the flag and the value. The default is no space. Commonly this may be a single white space (' ').

- *encapsulator* - Used to encapsulate a value. Commonly left nil or as a quote or single quote. For instance, a file path that could have spaces may need this to be set to '"'.

- *aliases* - A pipe ('|') separated list of aliases for this ingredient. Avoid naming conflicts with other ingredients and their aliases.

- *allowed_values* - A pipe separated list of allowed values for this ingredient. If values are strings, they need to be encapsulated by single quotes (such as 'zip'). Anything left without quotes will be treated literally in Ruby. So String, would mean any String object is allowed.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cli_chef. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
