module Locomotive::Steam
  module Middlewares

    module Helpers

      alias_method :orig_render_response, :render_response

      def render_response(content, code = 200, type = nil)
        status, headers, body = orig_render_response(content, code, type)
        if status == 200
          set_200_header(headers)
        end
        @next_response = [status, headers, body]
      end

      private

      def set_200_header(headers)
        if env['steam.cache_control']
          headers['Cache-Control'] = env['steam.cache_control']
        else
          headers['Cache-Control'] = "max-age=0, private, must-revalidate"
        end
        if env['steam.cache_vary']
          headers['Vary'] = env['steam.cache_vary'].join(",")
        end
      end

    end
  end
end
