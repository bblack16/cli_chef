require 'bblib' unless defined?(BBLib)

require_relative 'cli_chef/version'
require_relative 'cookbook'
require_relative 'wrappers/_wrappers'
require_relative 'bblib/bbfiles'

require 'open3'

module CLIChef
end
