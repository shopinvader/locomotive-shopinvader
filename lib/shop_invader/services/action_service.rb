require 'locomotive/steam/services'

module Locomotive
  module Steam

    class ActionService
      alias_method :orig_define_built_in_functions, :define_built_in_functions

      SHOPINVADER_BUILT_IN_FUNCTIONS = %w(storeCall)

      def define_built_in_functions(context, liquid_context)
        orig_define_built_in_functions(context, liquid_context)
        SHOPINVADER_BUILT_IN_FUNCTIONS.each do |name|
          context.define_function name, &send(:"#{name.underscore}_lambda", liquid_context)
        end
      end

      def store_call_lambda(liquid_context)
        erp = liquid_context.registers[:services].erp
        -> (method, path, params) { erp.call(method, path, params) }
      end
    end
  end
end
