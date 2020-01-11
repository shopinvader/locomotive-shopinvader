module ShopInvader
  module Liquid
    module Drops
      ONLY_SESSION_STORE = %w(last_sale notifications maintenance cart)
      ONLY_ONE_TIME = %w(notifications maintenance)
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

        def liquid_method_missing(meth)
          if ONLY_SESSION_STORE.include?(meth)
            data = service.erp.is_cached?(meth) && service.erp.read_from_cache(meth)
            if ONLY_ONE_TIME.include?(meth)
              service.erp.clear_cache(meth)
            end
            data
          elsif store[meth]
            read_from_site(meth)
          elsif is_search_engine_collection?(meth)
            SearchEngineCollection.new(meth)
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

        def is_search_engine_collection?(name)

          service.search_engine.adapter && service.search_engine.indices.any? { |index| index['name'] == name }
        end

        def service
          @context.registers[:services]
        end

        def read_from_site(meth)
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
          @store ||= @context.registers[:site].metafields[:_store] || {}
        end

        def locale
          @locale ||= @context.registers[:locale].to_s
        end
      end

    end
  end
end
