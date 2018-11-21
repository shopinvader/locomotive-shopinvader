module Locomotive::Steam
  module Middlewares

    module Helpers

      alias_method :orig_render_response, :render_response
      alias_method :orig_inject_cookies, :inject_cookies

      def render_response(content, code = 200, type = nil)
        status, headers, body = orig_render_response(content, code, type)
        if status == 200
          set_200_header(headers)
        end
        @next_response = [status, headers, body]
      end

      private

      def set_200_header(headers)
        headers['Cache-Control'] = env['steam.cache_control'] || "max-age=0, private, must-revalidate"

        # Always inject a vary on accept-language for the header
        # if the site have multiple lang on the home page
        # indeed home page do not have the lang in the path
        # and so the content can vary depending of the accept-language
        if is_index_page? and site.locales.size > 1
          unless env['steam.cache_vary']
            env['steam.cache_vary'] = []
          end
          env['steam.cache_vary'] << "accept-language"
        end

        if env['steam.cache_vary']
          headers['Vary'] = env['steam.cache_vary'].join(",")
        end
      end

      def inject_cookies(headers)
        role = customer && customer.role
        if role != default_role
          # TODO make the max_age configurable maybe we should use the same age as the main cookie
          request.env['steam.cookies']['role'] = {value: role, path: '/', max_age: 1.year}
        elsif request.cookies.include?('role')
          # Delete the role if exist in the request
          request.env['steam.cookies']['role'] = {value: '', path: '/', max_age: 0}
        end
        orig_inject_cookies(headers)
      end

      def customer
        @customer ||= request.env['authenticated_entry']
      end

      def default_role
        @default_role ||= site.metafields['erp']['default_role']
      end

      def is_index_page?
        ['/', ''].include?(request.path_info)
      end

    end
  end
end
