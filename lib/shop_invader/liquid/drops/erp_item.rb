module ShopInvader
  module Liquid
    module Drops

      class ErpItem < ::Liquid::Drop

        def initialize(name)
          @name = name
        end

        def before_method(meth)
          if fetch_resource
            fetch_resource[meth]
          end
        end

        private

        def fetch_resource
          if service.is_cached?(@name)
            @resource ||= service.read_from_cache(@name) || {}
          else
            @resource ||= service.find_one(@name)[:data]
          end
        end

        def service
          @context.registers[:services].erp
        end

      end

    end
  end
end
