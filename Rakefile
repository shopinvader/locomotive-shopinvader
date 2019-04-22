require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'colorize'
require 'algoliasearch'
require 'json'

task :clear do
  puts "\nClear partner generated from previous test\n".green
  `psql -c "DELETE FROM res_partner WHERE email ILIKE '%rspec%' OR name ILIKE '%RSPEC'"`
end

task :export_algolia do
  puts "\nExport Aloglia index\n".green
  Algolia.init(application_id: ENV['ALGOLIA_APP_ID'], api_key: ENV['ALGOLIA_API_KEY'])
  ['ci_shopinvader_variant', 'ci_shopinvader_category'].each do | index_name |
    ['fr_FR', 'en_US'].each do | lang |
      index_full_name = "#{index_name}_#{lang}"
      puts "\nExport Aloglia index #{index_full_name}\n".green
      index_out_name = index_full_name.sub('locomotive', 'ci').sub('product', 'variant')
      index = Algolia::Index.new("#{index_full_name}")
      records = []
      index.browse do | record |
        records << record
      end
      File.open("spec/integration/search-engine-data/#{index_out_name}.json","w") do |f|
        f.write(JSON.pretty_generate(records))
      end
      setting = index.get_settings()
      File.open("spec/integration/search-engine-data/#{index_out_name}_setting.json","w") do |f|
        f.write(JSON.pretty_generate(setting))
      end
    end
  end
end


task :configure_algolia do
  puts "\nConfigure algolia indexes\n".green
  Algolia.init(application_id: ENV['ALGOLIA_APP_ID'], api_key: ENV['ALGOLIA_API_KEY'])
  ['ci_shopinvader_variant', 'ci_shopinvader_category'].each do | index_name |
    ['fr_FR', 'en_US'].each do | lang |
      index_full_name = "#{index_name}_#{lang}"
      puts "\nConfigure Aloglia index #{index_full_name}\n".green
      index = Algolia::Index.new("#{index_full_name}")
      index.clear_index()
      data = JSON.parse(File.read("spec/integration/data/#{index_full_name}.json"))
      index.add_objects(data)

      data = JSON.parse(File.read("spec/integration/data/#{index_name}_setting.json"))
      index.set_settings(data)
    end
  end
end

RSpec::Core::RakeTask.new(:export_algolia) do
 Rake::Task["export_algolia"].invoke
end

RSpec::Core::RakeTask.new(:configure_algolia) do
 Rake::Task["configure_algolia"].invoke
end

RSpec::Core::RakeTask.new(:spec) do
 Rake::Task["clear"].invoke
end

#task default: :spec
