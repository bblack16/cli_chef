require_relative "cli_chef/version"
require_relative 'cookbook'
require_relative 'wrappers/7zip'
require_relative 'wrappers/media_info'
require_relative 'wrappers/handbrake'
require 'bblib' if !defined?(BBLib::VERSION)

module CLIChef

end
