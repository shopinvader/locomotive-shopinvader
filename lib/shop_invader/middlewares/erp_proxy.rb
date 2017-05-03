module ShopInvader
  module Middlewares
    class ErpProxy < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        params = env['rack.request.form_hash']
        puts params && params.include?('action_proxy')
        if params && params.include?('action_proxy')
          method = env['REQUEST_METHOD']
          path = params.delete('action_proxy')
          erp.call(env['REQUEST_METHOD'], path, params)
        end
      end

      private

      def erp
        services.erp
      end

    end
  end
end
