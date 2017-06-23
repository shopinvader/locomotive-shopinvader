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
          if store[meth]
            read_from_store(meth)
          elsif is_algolia_collection?(meth)
            AlgoliaCollection.new(meth)
          elsif is_plural?(meth)
            ErpCollection.new(meth)
          else
            ErpItem.new(meth)
          end
        end

        private

        def is_plural?(value)
          value.singularize != value
        end

        def is_algolia_collection?(name)
          service.indices.any? { |index| index['name'] == name }
        end

        def service
          @context.registers[:services].algolia
        end

        def read_from_store(meth)
          # Exemple of configuration of store
          # that allow to use store.available_countries
		  # _store:
          #     available_countries: >
          #         {"fr": [
          #             { "name": "France", "id": 74 },
          #             { "name": "Belgique", "id": 20 },
          #             { "name": "Espagne", "id": 67 }
          #             ]
          #         }
          data = JSON.parse(store[meth])
          if data.is_a?(Hash) and data[locale]
            data[locale]
          else
            data
          end
        end

        def store
          @store ||= @context.registers[:site][:metafields][:_store] || {}
        end

        def locale
          @locale ||= @context.registers[:locale].to_s
        end
      end

    end
  end
end
