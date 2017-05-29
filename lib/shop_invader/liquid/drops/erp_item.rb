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
          service.find_all(@name)
        end

      end

    end
  end
end
