module ShopInvader
  module Liquid
    module Drops

      class ErpItem < ::Liquid::Drop

        def initialize(name)
          @name = name
        end

        def before_method(meth)
          fetch_resource[meth]
        end

        private

        def fetch_resource
          if service.is_cached?(@name)
            @resource ||= service.read_from_cache(@name) || {}
          else
            if @context['store_maintenance']
              {}
            else
              @resource ||= service.find_one(@name)['data']
            end
          end
        end

        def service
          @context.registers[:services].erp
        end

      end

    end
  end
end
