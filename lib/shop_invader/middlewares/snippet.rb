module ShopInvader
  module Middlewares
    # We inherit of the class Renderer in order to have the liquid_context
    # environment with all the variable inside
	class SnippetPage < Locomotive::Steam::Middlewares::Renderer

      include Locomotive::Steam::Middlewares::Helpers


      def _call
        if env['steam.path'].start_with?('snippet/')
          path = env['steam.path'].sub('snippet/', '')
          snippet = snippet_finder.find(path)
          partial = Locomotive::Steam::Liquid::Template.parse(snippet.liquid_source, {})
          # Set steam.page variable in env to avoid issue when build the liquid_context
          env['steam.page'] = nil
          content = partial.render(liquid_context)
          render_response(content, 200, nil)
        end
      end

      private

      def snippet_finder
        services.snippet_finder
      end

    end
  end
end
