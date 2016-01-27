# CLIChef

CLI Chef is a simple command line interface wrapper for Ruby. It is made to make writing wrappers an easy and flexible process.

CLI Chef is part of the BBLib (Brandon Black Library) for Ruby. BBLib is a requirement and includes a large number of other useful methods that help make CLI Chef easier to use. You can read documentation here: (BBLib)[https://github.com/bblack16/bblib-ruby].

###Disclaimer

CLI Chef is in a very early state. It is functional, but not heavily tested. As such, it will likely undergo frequent changes and may be buggy. Use at your own risk.

## Installation


__Note:__ Currently this gem is not available via RubyGems. Once it is the following is how to install it. For now, grab it from github.

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
class SevenZip < BBLib::CLIChef::Cookbook
  # Code goes here
end
```
*NOTE*: It is highly recommended NOT to define an initialize method and let the parent class handle it. If you have a need to create such a methd, be sure to call the protected _init_ method passing the name, description and path as arguments.

There are a few setup methods that you need to override as well as a few that can be, but are optional.

```ruby
class SevenZip < BBLib::CLIChef::Cookbook

  protected

  ##########REQUIRED

  # Though ingredients can be added post instantiation it is nearly essential
  # that some be added by writing the setup_ingredients method.
  # Without this setup method the wrapper is not useable.
  # There are multiple ways to populate a Cookbook with Ingredients.
  # The next section discusses these methods.
  def setup_ingredients
    # Manually construct and Ingredient and add it to the Cabinet
    @cabinet.add_ingredient( BBLib::CLIChef::Ingredient.new(:extract, flag:'e'))

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
    @recipe_book.add_recipe BBLib::CLIChef::Recipe.new 'add', ingredients: ({add:true, type:'7z', include:nil, exclude:nil, recurse:nil, volumes:nil, working_dir:nil, password:nil, method:nil}), required_input: [:file, :output]
    @recipe_book[:add].description = 'Adds a file to the specified archive. If the archive does not exist it is created. Both the input file and output archive are required arguments and must be valid file paths. The :type ingredient can be used to toggle what type of archive is created. By default it is a 7z.'
  end
end
```

#### Adding Ingredients to _setup_ingredients_


There are a couple of ways to add ingredients to a cookbook during initialization within the _setup_ingredients_ method. Both are shown above in the sample code for a 7Zip wrapper.


__1 Add Ingredient to @cabinet__

  As shown above, an Ingredient object can be created and passed into the _add_ingredient_ method of @cabinet.


__2 Parse From Separated Values__
  For additional convenience, the Cabinet class can parse text such as tsv or csv to generate Ingredients quickly. This allows you to setup the CLI arguments in an application such as Excel and have the Cabinet parse them into Ingredients. The SV must include headers as the first row and must include at least the header 'name'. The following list may also be specified in the SV:


- *name* (required) - A string name. Use lower case and avoid spaces. Any spaces will be replaced with underscores. Symbols are stripped as well, so stick to alpha-numeric chars.

- *description* - A full text description of the ingredient. If using a csv, avoid commas. It is recommended that you use the TSV parser instead, so commas are allowed.

- *default* - Specifies what the default value of the ingredient is. This value must conform to the allowed_values field options.

- *flag* - The flag for this ingredient (EX: '-c', 't', '--help').

- *spacer* - What should be used to separate the flag and the value. The default is no space. Commonly this may be a single white space (' ').

- *encapsulator* - Used to encapsulate a value. Commonly left nil or as a quote or single quote. For instance, a file path that could have spaces may need this to be set to '"'.

- *aliases* - A pipe ('|') separated list of aliases for this ingredient. Avoid naming conflicts with other ingredients and their aliases.

- *allowed_values* - A pipe separated list of allowed values for this ingredient. If values are strings, they need to be encapsulated by single quotes (such as 'zip'). Anything left without quotes will be treated literally in Ruby. So String, would mean any String object is allowed.

### Ingredients

Ingredients (arguments) are components of a full command to be executed by the Cookbook. Ingredients are comprised of the following attributes:

- *name*: The name of this ingredient. This MUST be unique across all Ingredients in the Cabinet. It should be a symbol with no symbol characters or white spaces. A String object can be passed as the name, but it will be downcased, striped of symbols and have all white space replaced by underscores.

- *description*: This should describe the Ingredient and what it does. Place descriptions of the options here as well. This attribute is optional, but recommended.

- *default*: This the default value of the ingredient. Generally this is set to nil. When an Ingredient is contructed, the symbol :default being passed as the value with be converted to this.

- *flag*: The flag for this Ingredient. Not all arguments have a flag, so this should be nil if it is one of those. This should be a string. (EX: '-c', 't', '--help').

- *spacer*: The spacer is used to divide the flag and the value. By default it is ' ', which means there is a space. So an Ingredient with a '-c' flag and a 'Text' value would be constructed as '-c Test'. If, instead, you want there to be no space, spacer can be set to nil or ''. This would construct like '-cTest'.

- *encapsulator*: Used to encapsulate a value. Commonly left nil or as a quote or single quote. For instance, a file path that could have spaces may need this to be set to '"'. The toggle encap_space_values controls whether or not the encapsulator is used. If encap_space_values is set to true, the encapsulator will only be added to the value if it contains a space. This is the default behavior.

- *encap_space_values*: _See encapsulator above._

- *aliases*: An array of aliases for this ingredient. This must also be unique, just like the name. This means unique across all Ingredient names AND aliases.

- *allowed_values*: An array of allowed values to this Ingredient. These can be objects such as specific strings or numbers or classes or regular expressions. If the value equates to true against the '===' with any of these allowed values it is permitted.

```ruby
ing = BBLib::CLIChef::Ingredient.new :archive_type, flag: '-t', default: 'zip', description: 'Sets the type of archive.', allowed_values: ['zip', '7z', 'tar', 'gz'], aliases: [:type]

ing.value = 'tar'
puts ing.to_s
#=> '-t tar'

ing.spacer = nil
puts ing.to_s
#=> '-ttar'
```

### Cabinets

Cabinets store all the possible ingredients that a Cookbook (CLI) has. Most interaction with it is handled by the Cookbook class. Methods of note are _add_ingredient(ingredient)_ which allows new ingredients to be added. If any ingredient with the same name already exists, it is overwritten by the new one. _remove_ingredient(name)_ allows ingredients to be removed from the cabinet.

The Cookbook extends some convenience methods to retrieve information from the cabinet such as:

- *ingredient_list*: Displays a list of all available ingredient names.
- *ingredient_options(name)*: Returns the allowed values for the named ingredient.
- *ingredient(name)*: Returns the ingredient with _name_ from the cabinet.
- *add_ingredient(ingredient)*: Adds an ingredient to the cabinet. Must be an Ingredient object.
- *remove_ingredient(name)*: Removes the named ingredient from the cabinet if it exists.

### Recipes && Recipe Books

Recipes are collections of ingredients with default values. Four things make up a recipe:

- *name*: The name of the recipe. Must be a symbol and needs to be unique across all other recipes in the Cookbook.
- *description*: A brief description of what the recipe is for and how to use it.
- *ingredients*: A hash of ingredient names and values for them. If the value is nil or false, it will not be used within the _mix_ method, and thus, not included in the final cmd. The order of this hash is the order in which the ingredients will be added to the cmd.
- *required_input*: An Array of ingredient names that must be passed in to the _mix_ method's input hash along with values. When _mix_ is called, if any of these are missing from the input hash, an error is raised listing the missing ingredients. If the name argument is not already in the ingredients list it is added with nil as its value.

__mix__

The _mix_ method is used to build a cmd hash from the recipe that can be used in the _cook_ or _preheat_ methods of a Cookbook. An input hash needs to be passed in with key:value pairs for any ingredient values that need to be set. If an ingredient is in the @required_input Array it MUST be passed in the input hash. Values in the input hash override all values in the @ingredients hash. For an example, see below. This method is used behind the scenes and will handled by the Cookbook.

```ruby
rec = BBLib::CLIChef::Recipe.new :extract_archive
rec.description = 'Extracts a single archive to the same directory as the archive file. Use the :archive ingredient to set the path to the archive to extract'
rec.add_ingredient :extract, true
rec.add_ingredient :archive, nil
rec.add_required_input :archive

puts rec.mix({archive: 'D:/test/archive.zip'})
#=> {:extract=>true, :archive=>"D:/test/archive.zip"}
```

#### Recipe Book

Each cookbook has a recipe book. They are collections of recipes that can be referenced and used by the cookbook. Interaction with the book is handled by the Cookbook through the methods below:

- *recipe_list*: Provides a list of all recipes in the recipe book.
- *add_recipe(recipe)*: Adds a recipe to the book. Must be a Recipe object.
- *remove_recipe(name)*: Removes the named recipe from the book if it exists.

### Putting it to use

Once a Cookbook has been created and provided with ingredients and recipes, it can be used.

#### Using the __run__ & __prepare__ methods

The cookbook has run method which is used to execute a cmd on the shell. Only one argument is needed; ingredients. Ingredients is a key:value pair, where key is the exact name of an ingredient in the cabinet and value is the value to pass to it. The value may also be an Array. If it is, all items in the Array are added to the cmd including the corresponding flags if they exist. The response for the cmd as well as information on the exit code is returned in a hash. To retrieve only the stdout response, set the name variable _detailed_ to false.

Prepare takes the exact same arguments, but returns a full constructed cmd line argument rather than running it.

```ruby
# Using the example 7zip wrapper included in the wrappers section
sz = BBLib::CLIChef::SevenZip.new
ingredients = {test:true, archive:'D:/test/test.7z'}
puts sz.run(ingredients)
#=>{:response=>"\n7-Zip [64] 15.06 beta : Copyright (c) 1999-2015 Igor Pavlov : 2015-08-09\n\nScanning the drive for archives:\n1 file, 1357418 bytes (1326 KiB)\n\nTesting archive: D:\\test\\test.7z\n--\nPath = D:\\test\\test.7z\nType = 7z\nPhysical Size = 1357418\nHeaders Size = 1724\nMethod = LZMA2:6m LZMA:48k BCJ\nSolid = +\nBlocks = 3\n\nEverything is Ok\n\nFolders: 4\nFiles: 110\nSize:       4895076\nCompressed: 1357418\n", :exit=>{:code=>0, :desc=>"No error"}}

puts sz.prepare(ingredients)
#=> "C:/Program Files/7-Zip/7z.exe" t D:/test/test.7z
```

#### Using the __cook__ & __preheat__ methods

Cook and preheat are similar to run and prepare, except instead, they use recipes to construct the cmds. A similar input hash (similar to what run needs) is required as the second argument to both, but a recipe name is also needed first. The ingredient hash is passed to the _mix_ method of the recipe which is then passed to either the run or prepare method.

```ruby
puts sz.preheat(:extract, {archive:'D:/test/test.7z'})
#=> '"C:/Program Files/7-Zip/7z.exe" x -y D:/test/test.7z'

puts sz.cook(:extract, {archive:'D:/test/test.7z'})
#=> {:response=>"\n7-Zip [64] 15.06 beta : Copyright (c) 1999-2015 Igor Pavlov : 2015-08-09\n\nScanning the drive for archives:\n1 file, 1357418 bytes (1326 KiB)\n\nExtracting archive: D:\\test\\test.7z\n--\nPath = D:\\test\\test.7z\nType = 7z\nPhysical Size = 1357418\nHeaders Size = 1724\nMethod = LZMA2:6m LZMA:48k BCJ\nSolid = +\nBlocks = 3\n\nEverything is Ok\n\nFolders: 4\nFiles: 110\nSize:       4895076\nCompressed: 1357418\n", :exit=>{:code=>0, :desc=>"No error"}}
```

### The Menu

Cookbook has a method called _menu_ which prints out a list of all recipes with descriptions and details as well as all ingredients and their descriptions and details. It is constructed to be somewhat of a --help page for the wrapper.

## Examples

A small subset of example wrappers comes with this gem. Currently only 7Zip is completed. For an example of how the framework currently works, look at the source code for it.

More coming soon...

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cli_chef. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
