module ShopInvader
  module Liquid
    module Drops

      class ErpCollection < ::Liquid::Drop

        delegate :first, :last, :each, :each_with_index, :empty?, :any?, :map, :size, :count, to: :collection

        def initialize(name)
          @name = name
        end

        def total_entries
          fetch_collection["size"]
        end

        private

        def collection
          if service.is_cached?(@name)
            @collection ||= service.read_from_cache(@name) || {}
          else
            @collection ||= fetch_collection["data"]
          end
        end

        def paginate(page, per_page)
          fetch_collection(page: page, per_page: per_page)
        end

        def fetch_collection(page: 1, per_page: 20)
          service.find_all(@name,
            conditions: @context['with_scope'],
            page:       page,
            per_page:   per_page
          )
        end

        def service
          @context.registers[:services].erp
        end

      end

    end
  end
end
