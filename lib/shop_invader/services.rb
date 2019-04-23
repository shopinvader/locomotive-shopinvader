require 'locomotive/steam/services'

module Locomotive::Steam::Services
  class Instance

    register :elastic do
      ShopInvader::ElasticService.new(current_site, request.env['authenticated_entry'], locale)
    end

    register :algolia do
      ShopInvader::AlgoliaService.new(current_site, request.env['authenticated_entry'], locale)
    end

    register :search_engine do
      ShopInvader::SearchEngineService.new(current_site, elastic, algolia)
    end

    register :erp do
      ShopInvader::ErpService.new(
          request, current_site, request.env['rack.session'], request.env['authenticated_entry'], locale, cookie)

    end

    register :erp_auth do
      ShopInvader::ErpAuthService.new(request, erp, content_entry)
    end

  end
end
