require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/steam_patches'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/services/erp_service'
require 'shop_invader/middlewares/templatized_page'
require 'shop_invader/middlewares/erp_proxy'
require 'shop_invader/middlewares/store'
require_relative_all %w(. drops filters tags), 'shop_invader/liquid'
require 'byebug'
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
      config.middleware.insert_after Locomotive::Steam::Middlewares::TemplatizedPage, ShopInvader::Middlewares::TemplatizedPage
      config.middleware.insert_after ShopInvader::Middlewares::TemplatizedPage, ShopInvader::Middlewares::Store
      config.middleware.insert_after Locomotive::Steam::Middlewares::Path, ShopInvader::Middlewares::ErpProxy
    end
  end

end

# The Rails app must call the setup itself.
unless defined?(Rails)
  # context here: Wagon site
  ShopInvader.setup
end
