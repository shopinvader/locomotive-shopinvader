module ShopInvader
  module Middlewares
    class ErpProxy < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        params = env['rack.request.form_hash']
        if params && params.include?('action_proxy')
          method = env['REQUEST_METHOD']
          path = params.delete('action_proxy')
          byebug
          response = erp.call(env['REQUEST_METHOD'], path, params, request.session)
          if response['set_session']
              response['set_session'].each do |key, val|
                  sym_key = ('erp_' + key).to_sym
                  request.session[sym_key] = val
              end
          end
          if response['store_data']
              response['store_data'].each do |key|
                  sym_key = ('store_' + key).to_sym
                  request.session[sym_key] = JSON.dump(response[key])
              end
          end
          #Affect the result into the store object or in the session
        end
      end

      private

      def erp
        services.erp
      end

    end
  end
end
