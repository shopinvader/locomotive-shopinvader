source 'https://rubygems.org'

# Specify your gem's dependencies in shop_invader.gemspec
gemspec

gem 'locomotivecms_steam', github: 'akretion/steam', branch: 'fix-impersonnate'
#gem 'locomotivecms_steam', path: '/gems/steam'
gem 'faraday'
gem 'algoliasearch'
gem 'elasticsearch'

group :test do
  gem 'simplecov',      require: false
  gem 'codecov',        require: false
  gem 'byebug',         require: false
  gem 'rack-test',      '~> 0.8.2'
  gem 'haml',           '~> 5.0.4'
  gem 'pg'
end
