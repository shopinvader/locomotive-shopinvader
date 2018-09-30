module ShopInvader
  module Middlewares
    class ErpProxy < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if env['steam.path'].start_with?('invader/')
          path = env['steam.path'].sub('invader/', '')
          response = erp.call(env['REQUEST_METHOD'], path, params)
          # the check_payment path always need to render an html page
          # as this is the redirection done by the payment provider
          # if we have some other case with the same need maybe it will be
          # better to pass an args, but for now we check the path
          if path.include?('check_payment')
            _render_html(response)
          elsif env['CONTENT_TYPE'] == "application/json" || env['REQUEST_METHOD'] == 'GET'
            _render_json(response)
          else
            _render_html(response)
          end
        end
      end

      def _render_json(response)
        if response.status == 200
          data = erp.parse_response(response)['data']
          render_response(JSON.dump(data), 200, 'application/json')
        else
          render_response(response.body, response.status, 'application/json')
        end
      end

      def _render_html(response)
        if response.status == 200
          data = erp.parse_response(response)
          if data.include?('redirect_to')
            redirect_to data['redirect_to'], 302
          elsif params.include?('invader_success_url')
            redirect_to params['invader_success_url'], 302
          else
            redirect_to env['HTTP_REFERER'], 302
          end
        else
          erp.catch_error(response)
          if params.include?('invader_error_url')
            redirect_to params['invader_error_url'], 302
          else
            redirect_to env['HTTP_REFERER'], 302
          end
        end

        # TODO process pdf / binary file
        #@next_response = [200, response[:headers].stringify_keys, [response[:body]]]
      end

      private

      def erp
        services.erp
      end

    end
  end
end
