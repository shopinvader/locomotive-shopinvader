module ShopInvader
  module Liquid
    module Drops

      class ElasticCollection < ::Liquid::Drop

        delegate :first, :last, :each, :each_with_index, :empty?, :any?, :map, :size, :count, to: :collection

        def initialize(name)
          @name = name
        end

        def total_entries
          fetch_collection[:size]
        end

        private

        def collection
          @collection ||= fetch_collection[:data]
        end

        def paginate(page, per_page)
          fetch_collection(page: page, per_page: per_page)
        end

        def fetch_collection(page: 1, per_page: 20)
          Locomotive::Common::Logger.debug "[Elastic collection] fetch_collection"

          service.find_all(@name,
            conditions: @context['with_scope'],
            page:       page.to_i - 1,
            per_page:   per_page
          )
        end

        def service
          @context.registers[:services].elastic
        end

      end

    end
  end
end
