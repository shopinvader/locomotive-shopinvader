require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'colorize'

task :clear do
  puts "\nClear partner generated from previous test\n".green
  `psql -c "DELETE FROM res_partner WHERE email ILIKE '%rspec%' OR name ILIKE '%RSPEC'"`
end

RSpec::Core::RakeTask.new(:spec) do
   Rake::Task["clear"].invoke
end


task default: :spec
