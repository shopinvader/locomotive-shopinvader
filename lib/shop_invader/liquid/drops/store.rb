module ShopInvader
  module Liquid
    module Drops

      # Examples:
      #
      # {{ store.category.size }}
      #
      # with_scope
      #
      # {{ store.category.all | paginate: per_page: 2, page: params.page }}
      # {{ store.category | find: '42' }}
      # {{ store.category.all | where: name: 'something' }}
      # {{ store.category.all | where: rating_value }}
      #
      class Store < ::Liquid::Drop

        def before_method(meth)
          if is_algolia_collection?(meth)
            AlgoliaCollection.new(meth)
          else
            nil
          end
        end

        private

        def is_algolia_collection?(name)
          service.indices.any? { |index| index['name'] == name }
        end

        def service
          @context.registers[:services].algolia
        end

      end

    end
  end
end
