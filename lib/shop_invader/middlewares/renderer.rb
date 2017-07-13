require 'locomotive/steam/middlewares'

module Locomotive::Steam
  module Middlewares

    class Renderer
      alias_method :orig_parse_and_render_liquid, :parse_and_render_liquid

      def parse_and_render_liquid
        begin
          orig_parse_and_render_liquid
        rescue ShopInvader::ErpMaintenance => e
          env['steam.liquid_assigns']['store_maintenance'] = true
          orig_parse_and_render_liquid
        end
      end
    end
  end
end
