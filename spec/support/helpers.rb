require 'locomotive/common'
require 'locomotive/steam'

module Spec
  module Helpers

    def reset!
      FileUtils.rm_rf(File.expand_path('../../../site', __FILE__))
    end

    def remove_logs
      FileUtils.rm_rf(File.join(default_fixture_site_path, 'log'))
    end

    def setup_common(logger_output = nil)
      Locomotive::Common.reset
      Locomotive::Common.configure do |config|
        config.notifier = Locomotive::Common::Logger.setup(logger_output)
      end
    end

    def run_server
      require 'haml'

      output = ENV['STEAM_VERBOSE'] ? nil : File.join(default_fixture_site_path, 'log/steam.log')
      setup_common(output)

      Locomotive::Common::Logger.info 'Server started...'
      Locomotive::Steam::Server.to_app
    end

    def sign_in(params, follow_redirect = false)
      post '/account', params
      follow_redirect! if follow_redirect
      last_response
    end

    def sign_up(params, follow_redirect = false)
      post '/account/register', params
      follow_redirect! if follow_redirect
      last_response
    end

    def add_an_address(params, referer, follow_redirect = false, json = false)
      header 'Referer', referer
      if json
        header 'Content-type', "application/json"
        params = params.to_json
      else
        header 'Accept', "text/html,*/*;q=0.01"
      end
      post '/invader/addresses/create', params
      follow_redirect! if follow_redirect
      last_response
    end

    def remove_addresses
      header 'Content-type', "application/json"
      get '/invader/addresses?per_page=200&scope[address_type]=address'
      addresses = JSON.parse(last_response.body)
      if addresses
        addresses['data'].each do | address |
          delete "/invader/addresses/#{address['id']}"
        end
      end
    end

  end
end

def default_fixture_site_path
  '/tmp/site'
end

Locomotive::Steam.configure do |config|
  config.mode           = :test
  config.adapter        = { name: :filesystem, path: default_fixture_site_path }
  config.asset_path     = File.expand_path(File.join(default_fixture_site_path, 'public'))
  config.serve_assets   = true
  config.minify_assets  = true
end

