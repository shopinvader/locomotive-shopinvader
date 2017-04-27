require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/steam_patches'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/middlewares/templatized_page'
require 'shop_invader/middlewares/store'

require_relative_all %w(. drops filters tags), 'shop_invader/liquid'

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
    end
  end

end

ShopInvader.setup
