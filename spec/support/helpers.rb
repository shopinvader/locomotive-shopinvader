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

    def add_an_address(params, referer, follow_redirect = false)
      header 'Referer', referer
      post '/invader/addresses', params
      follow_redirect! if follow_redirect
      last_response
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

