require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/errors'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/services/erp_service'
require 'shop_invader/services/erp_auth_service'
require 'shop_invader/services/action_service'
require 'shop_invader/middlewares/templatized_page'
require 'shop_invader/middlewares/erp_proxy'
require 'shop_invader/middlewares/store'
require 'shop_invader/middlewares/renderer'
require 'shop_invader/middlewares/locale'
require 'shop_invader/middlewares/snippet'
require 'shop_invader/middlewares/helpers'
require_relative_all %w(concerns concerns/sitemap), 'shop_invader/middlewares'
require_relative_all %w(. drops filters tags tags/concerns), 'shop_invader/liquid'
require 'shop_invader/steam_patches'
require 'faraday'

def should_notify_erp(payload)
  payload[:request].env['steam.site'].metafields.include?('erp') && payload[:entry].content_type.name.downcase == 'customers'
end

module ShopInvader

  # Locales mapping table. Locomotive only uses the
  # main locale but not the dialect. This behavior
  # will change in Locomotive v4.
  LOCALES = {
    'en' => 'en_US',
    'de' => 'de_DE',
    'fr' => 'fr_FR',
    'bg' => 'bg_BG',
    'cs' => 'cs_CZ',
    'da' => 'da_DK',
    'el' => 'el_GR',
    'es' => 'es_ES',
    'ca' => 'ca_ES',
    'fa-IR' => 'fa_IR',
    'fi-FI' => 'fi_FI',
    'it' => 'it_IT',
    'ja-JP' => 'ja_JP',
    'lt' => 'lt_LT',
    'nl' => 'nl_NL',
    'pl-PL' => 'pl_PL',
    'pt' => 'pt_PT',
    'pt-BR' => 'it_IT',
    'ru' => 'ru_RU',
    'sv' => 'sv_SE',
    'uk' => 'uk_UA',
    'zh-CN' => 'zh_CN',
    'et' => 'et_EE',
    'hr' => 'hr_HR',
    'nb' => 'nb_NO',
    'sk' => 'sk_SK',
    'sl' => 'sl_SL',
    'sr' => 'sr_RS',
  }

  def self.setup
    Locomotive::Steam.configure do |config|
      config.middleware.insert_after Locomotive::Steam::Middlewares::TemplatizedPage, ShopInvader::Middlewares::TemplatizedPage
      config.middleware.insert_before Locomotive::Steam::Middlewares::Path, ShopInvader::Middlewares::Store
      config.middleware.insert_after Locomotive::Steam::Middlewares::Path, ShopInvader::Middlewares::ErpProxy
      config.middleware.insert_after Locomotive::Steam::Middlewares::Path, ShopInvader::Middlewares::SnippetPage
    end

    subscribe_to_steam_notifications
  end


  def self.subscribe_to_steam_notifications

    # new signups
    ActiveSupport::Notifications.subscribe('steam.auth.signed_up') do |name, start, finish, id, payload|
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      if should_notify_erp(payload)
        service.erp_auth.signed_up(payload[:entry])
      end
    end

    ActiveSupport::Notifications.subscribe('steam.auth.signed_in') do |name, start, finish, id, payload|
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      if should_notify_erp(payload)
        payload[:request].env['authenticated_entry'] = payload[:entry]
        service.erp_auth.signed_in(payload[:entry])
      end
    end

    ActiveSupport::Notifications.subscribe('steam.auth.reset_password') do |name, start, finish, id, payload|
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      if should_notify_erp(payload)
        payload[:request].env['authenticated_entry'] = payload[:entry]
        service.erp_auth.reset_password(payload[:entry])
      end
    end

    ActiveSupport::Notifications.subscribe('steam.auth.signed_out') do |name, start, finish, id, payload|
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      if should_notify_erp(payload)
        service.erp_auth.sign_out(payload[:entry])
      end
    end
  end
end

# The Rails app must call the setup itself.
unless defined?(Rails)
  # context here: Wagon site
  ShopInvader.setup
end
