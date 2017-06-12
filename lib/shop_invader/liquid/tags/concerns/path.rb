module ShopInvader
  module Liquid
    module Tags
      module Concerns

        module Path

          def render_path(context, &block)
            handle = context[@handle] || @handle

            if handle.is_a?(Hash) && handle['url_key'].present?
              set_vars_from_context(context)
              build_fullpath_from_index_name(handle['index_name'], handle['url_key'])
            else
              super
            end
          end

          private

          def build_fullpath_from_index_name(index_name, url_key)
            route, _ = find_route(index_name)

            if route
              url = '/' + route.gsub('*', url_key)
              services.url_builder.prefix(url)
            end
          end

          def find_route(index_name)
            routes = JSON.parse(@site.metafields.dig('algolia', 'routes')  || '[]')

            routes.find do |(route, rule)|
              rule['index'] == index_name &&
              (template_slug.blank? || rule['tempate_handle'] == template_slug)
            end
          end

        end

      end
    end
  end
end
