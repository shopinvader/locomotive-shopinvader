require 'locomotive/steam/services'

module Locomotive::Steam::Services
  class Instance

    register :algolia do
      ShopInvader::AlgoliaService.new(current_site, request.env['steam.authenticated_entry'], locale)
    end

    register :erp do
      ShopInvader::ErpService.new(
        request, current_site, request.env['rack.session'], request.env['steam.authenticated_entry'], locale, cookie)
    end

    register :erp_auth do
      ShopInvader::ErpAuthService.new(request, erp, content_entry)
    end

  end
end
