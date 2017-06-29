require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/services/erp_service'
require 'shop_invader/services/action_service'
require 'shop_invader/middlewares/templatized_page'
require 'shop_invader/middlewares/erp_proxy'
require 'shop_invader/middlewares/store'
require 'shop_invader/middlewares/download'
require_relative_all %w(. drops filters tags tags/concerns), 'shop_invader/liquid'
require 'shop_invader/steam_patches'
require 'faraday'

module ShopInvader

  # Locales mapping table. Locomotive only uses the
  # main locale but not the dialect. This behavior
  # might change in Locomotive v4.
  LOCALES = {
    'fr' => 'fr_FR',
    'en' => 'en_US'
  }

  def self.setup
    Locomotive::Steam.configure do |config|
      config.middleware.insert_after Locomotive::Steam::Middlewares::Logging, ShopInvader::Middlewares::Download
      config.middleware.insert_after Locomotive::Steam::Middlewares::TemplatizedPage, ShopInvader::Middlewares::TemplatizedPage
      config.middleware.insert_after ShopInvader::Middlewares::TemplatizedPage, ShopInvader::Middlewares::Store
      config.middleware.insert_after Locomotive::Steam::Middlewares::Path, ShopInvader::Middlewares::ErpProxy
    end

    subscribe_to_steam_notifications
  end

  def self.subscribe_to_steam_notifications
    # new signups
    ActiveSupport::Notifications.subscribe('steam.auth.signup') do |name, start, finish, id, payload|
      request = payload[:request]
      entry = payload[:entry]
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      if request.params.include?('anonymous_token')
        data = service.erp.call('POST', 'anonymous/register', request.params)
      else
        params = request.params.clone
        params.update({
            'external_id': entry._id,
            'email': entry.email,
            })
        data = service.erp.call('POST', 'customer', params)
      end
      entry.role = data[:data]['role']
    end
  end

end

# The Rails app must call the setup itself.
unless defined?(Rails)
  # context here: Wagon site
  ShopInvader.setup
end
