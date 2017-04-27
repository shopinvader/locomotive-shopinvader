require 'locomotive/steam/models/pager'

module Locomotive::Steam
  module Models
    class Pager

      alias_method :initialize_without_algolia, :initialize

      def initialize(source, page, per_page)
        if source.respond_to?(:paginate, true)
          @current_page, @per_page = page || 1, per_page || DEFAULT_PER_PAGE

          collection = source.send(:paginate, @current_page, @per_page)

          @total_entries  = collection[:size]
          @total_pages    = (@total_entries.to_f / @per_page).ceil
          @collection     = collection[:data]
        else
          initialize_without_algolia(source, page, per_page)
        end
      end

    end
  end
end
