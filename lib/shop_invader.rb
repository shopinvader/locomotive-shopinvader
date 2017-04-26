require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/middlewares/templatized_page'

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
    end
  end

end

ShopInvader.setup
