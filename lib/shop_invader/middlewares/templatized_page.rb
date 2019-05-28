module ShopInvader
  module Middlewares
    class TemplatizedPage < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Concerns::Helpers

      def _call
        if env['steam.page'].not_found? && resource = find_resource
          if redirect_to_main_variant?(resource)
            same_locale = locale == default_locale
            if site.prefix_default_locale || !same_locale
              redirect_url = "/#{locale}/#{resource[:data]['url_key']}"
            else
              redirect_url = "/#{resource[:data]['url_key']}"
            end
            redirect_to(redirect_url, 301)
            return
          end

          # the liquid template needs to have access
          # to either the product or the category
          liquid_assigns[resource[:name]] = resource[:data]
          # replace the 404 page by the right (product/category/...) template
          find_and_set_page(resource)
        end
      end

      private

      def find_resource
        match_routes.each do |route|
          rules = route.try(:last)

          if rules && data = search_engine.find_by_key(rules['index'], env['steam.path'])
            return {
              name:     rules['name'],
              data:     data,
              template: rules['template_handle'] || rules['name']
            }
          end
        end
        nil
      end

      def find_and_set_page(resource)
        if page = page_finder.by_handle(resource[:template], false)
          log "Found page \"#{page.title}\" [#{page.fullpath}]"
          env['steam.page'] = page
        else
          log "Unknown template #{resource[:template]} for the Algolia resource"
        end
      end

      def redirect_to_main_variant?(resource)
        _resource = resource[:data]
        !_resource['url_key'].blank? && _resource['url_key'] != env['steam.path']
      end

      def match_routes
        if search_engine.routes
          search_engine.routes.find_all do |(path, _)|
            regexp = Regexp.new("\\A#{path.gsub('*', '.*')}\\Z")
            regexp.match(env['steam.path'])
          end
        else
          []
        end
      end

      def page_finder
        services.page_finder
      end

      def search_engine
        services.search_engine
      end

    end
  end
end
