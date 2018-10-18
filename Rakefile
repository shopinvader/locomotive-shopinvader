require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'colorize'


RSpec::Core::RakeTask.new(:spec) do
  puts "\nClear partner generated from previous test\n".green
  `psql -c "DELETE FROM res_partner WHERE email ILIKE '%rspec%'"`
end

task default: :spec
