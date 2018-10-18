require 'simplecov'

SimpleCov.start do
  if ENV['TRAVIS']
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end

  add_filter 'bin/'
  add_filter 'spec/'

  add_group 'Middlewares',    'lib/shop_invader/middlewares'
  add_group 'Liquid',         'lib/shop_invader/liquid'
  add_group 'Services',       'lib/shop_invader/services'
end

require 'bundler/setup'

require_relative 'support/helpers'
require_relative 'support/request'
require_relative 'support/steam'
require_relative 'support/liquid'

require 'shop_invader'
require_relative '../lib/shop_invader.rb'

RSpec.configure do |config|
  config.include Spec::Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.before(:all) { remove_logs; setup_common }
  #config.before { reset! }
  #config.after  { reset! }
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
