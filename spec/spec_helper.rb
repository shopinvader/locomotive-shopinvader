require 'simplecov'
SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter])

  add_filter 'bin/'
  add_filter 'spec/'

  add_group 'Middlewares',    'lib/shop_invader/middlewares'
  add_group 'Liquid',         'lib/shop_invader/liquid'
  add_group 'Services',       'lib/shop_invader/services'
end

require 'bundler/setup'
require 'shop_invader'

require_relative 'support/request'
require_relative 'support/steam'
require_relative 'support/liquid'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
