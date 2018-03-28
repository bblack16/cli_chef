# CLIChef

CLI Chef is a simple command line interface wrapper for Ruby. It is made to make writing wrappers an easy and flexible process.
Basic examples of how to use CLIChef are included in the wrappers directory.
These are also full functional CLI wrappers for the following apps:

- 7Zip
- MediaInfo
- Handbrake

## Installation


__Note:__ Currently this gem is not available via RubyGems.
Once it is the following is how to install it.
For now, grab it from github.

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

- *Cookbook*: A cookbook is the base wrapper class of CLI Chef. The cookbook handles interaction with the CLI. It stores all possible ingredients. It also contains an exit code map, default application locations and the results of the previously run command.
- *Ingredient*: An ingredient is essentially a CLI argument. It contains a name for the argument, its flag (if it has one) and its value (again, if it has one). There are many other properties in ingredients that control how it is constructed. For more detailed information, check out the source code or one of the sample wrappers.

### Examples

A few example wrappers comes with this gem. Check them out under the /lib/cli_chef/apps
directory. They are complete and showcase how easy it is to setup a basic wrapper.

## Pre-Built Wrappers

CLI Chef ships with several pre-made wrappers for 7Zip, HandBrake and MediaInfo. Below is an example of how to include these in your projects.

```ruby
# NOTE: You do not have to require cli_chef separately as the wrappers will if it is not already loaded.
require 'cli_chef'

# Load 7Zip
require 'cli_chef/apps/sevenzip'

# Load HandBrake
require 'cli_chef/apps/hand_brake'

# Load MediaInfo
require 'cli_chef/apps/media_info'
```

_NOTE: For the wrappers to work you must have the CLI executables for each of the above applications installed._

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cli_chef. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
