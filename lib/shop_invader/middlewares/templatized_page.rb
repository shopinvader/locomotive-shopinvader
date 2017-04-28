module ShopInvader
  module Middlewares
    class TemplatizedPage < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if env['steam.page'].not_found? && resource = find_resource
          if redirect_to_main_variant?(resource)
            redirect_to('/' + resource[:data]['url_key'], 301)
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

      def redirect_to_main_variant?(resource)
        _resource = resource[:data]
        !_resource['url_key'].blank? && _resource['url_key'] != env['steam.path']
      end

      def find_and_set_page(resource)
        if page = page_finder.by_handle(resource[:template])
          log "Found page \"#{page.title}\" [#{page.fullpath}]"
          env['steam.page'] = page
        else
          log "Unknown template #{resource[:template]} for the Algolia resource"
        end
      end

      def find_resource
        algolia.find_by_key_among_indices(env['steam.path'])
      end

      def page_finder
        services.page_finder
      end

      def algolia
        services.algolia
      end

    end
  end
end
