require 'locomotive/steam/services'

module Locomotive::Steam::Services
  class Instance

    register :algolia do
      ShopInvader::AlgoliaService.new(current_site, request.env['authenticated_entry'], locale)
    end

  end
end
