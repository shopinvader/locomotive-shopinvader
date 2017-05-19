module ShopInvader
  module Middlewares
    class ErpProxy < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if params && params.include?('action_proxy')
          if params.include?('action_method')
            method = params.delete('action_method').upcase
          else
            method = env['REQUEST_METHOD']
          end
          path = params.delete('action_proxy')
          erp.call(method, path, params)
        end
      end

      private

      def erp
        services.erp
      end

    end
  end
end
