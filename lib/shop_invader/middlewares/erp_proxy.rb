module ShopInvader
  module Middlewares
    class ErpProxy < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if env['steam.path'].start_with?('_store/')
          path = env['steam.path'].sub('_store/', '')
          response = call_erp(env['REQUEST_METHOD'], path, params)
          render_response(JSON.dump(response), 200, 'application/json')
        else params && params.include?('action_proxy')
          if params.include?('action_method')
            method = params.delete('action_method').upcase
          else
            method = env['REQUEST_METHOD']
          end
          path = params.delete('action_proxy')
          call_erp(method, path, params)
        end
      end

      private

      def erp
        services.erp
      end

      def call_erp(method, path, params)
        erp.call(method, path, params)
      end

    end
  end
end
