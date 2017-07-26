require 'locomotive/steam'
require 'locomotive/steam/server'
require 'algoliasearch'

require 'shop_invader/version'
require 'shop_invader/errors'
require 'shop_invader/services'
require 'shop_invader/services/algolia_service'
require 'shop_invader/services/erp_service'
require 'shop_invader/services/action_service'
require 'shop_invader/middlewares/templatized_page'
require 'shop_invader/middlewares/erp_proxy'
require 'shop_invader/middlewares/store'
require 'shop_invader/middlewares/renderer'
require 'shop_invader/middlewares/download'
require_relative_all %w(concerns concerns/sitemap), 'shop_invader/middlewares'
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
    ActiveSupport::Notifications.subscribe('steam.auth.signed_up') do |name, start, finish, id, payload|
      request = payload[:request]
      entry = payload[:entry]
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      begin
        if request.params.include?('anonymous_token')
          request.params.update({'external_id': entry._id})
          data = service.erp.call('POST', 'anonymous/register', request.params)
        else
          params = request.params.clone
          params.update({
            'external_id': entry._id,
            'email': entry.email,
            })
          data = service.erp.call('POST', 'customer', params)
        end
      rescue ShopInvader::ErpMaintenance => e
        request.env['steam.liquid_assigns']['store_maintenance'] = true
        data = {error: true}
      end
      if data[:error]
        # Drop the content created (no rollback on mongodb)
        service.content_entry.delete(entry.content_type_slug, entry._id)
        # Add a fake error field to avoid content authentification
        entry.errors.add('error', 'Fail to create')
      else
        service.content_entry.update_decorated_entry(entry, {role: data['data']['role']})
      end
    end

    ActiveSupport::Notifications.subscribe('steam.auth.signed_in') do |name, start, finish, id, payload|
      # After signed in
      # - affect the customer to the current cart if exist
      # - or search for an existing cart on erp side
      service = Locomotive::Steam::Services.build_instance(payload[:request])
      payload[:request].env['authenticated_entry'] = payload[:entry]
      session = payload[:request].env['rack.session']
      if session['erp_cart_id']
        service.erp.call('PUT', 'cart', {'assign_partner': true})
      else
        service.erp.call('GET', 'cart', {})
      end
    end

    ActiveSupport::Notifications.subscribe('steam.auth.signed_out') do |name, start, finish, id, payload|
      # After signed out, drop the erp / store session
      session = payload[:request].env['rack.session']
      session.keys.each do | key |
        if key.start_with?('erp_') || key.start_with?('store_')
          session.delete(key)
        end
      end
    end
  end
end

# The Rails app must call the setup itself.
unless defined?(Rails)
  # context here: Wagon site
  ShopInvader.setup
end
