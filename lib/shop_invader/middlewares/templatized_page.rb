module ShopInvader
  module Middlewares
    class TemplatizedPage < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if env['steam.page'].not_found?
          if resource = find_resource
            # the liquid template needs to have access
            # to either the product or the category
            liquid_assigns[resource[:name]] = resource[:data]

            # replace the 404 page by the right (product/category/...) template
            if page = page_finder.by_handle(resource[:template])
              log "Found page \"#{page.title}\" [#{page.fullpath}]"
              env['steam.page'] = page
            else
              log "Unknown template #{resource[:template]} for the Algolia resource"
            end
          end
        end
      end

      private

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
