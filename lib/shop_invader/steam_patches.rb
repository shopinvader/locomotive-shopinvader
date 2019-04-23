require 'locomotive/steam/models/pager'

module Locomotive::Steam::Models
  class Pager

    alias_method :initialize_without_algolia, :initialize

    def initialize(source, page, per_page)
      if source.respond_to?(:paginate, true)
        @current_page, @per_page = page || 1, per_page || DEFAULT_PER_PAGE

        collection = source.send(:paginate, @current_page, @per_page)

        # TODO refactor me when we will have a correct
        # encapsulation response on odoo side
        if collection.include?('size')
          @total_entries  = collection['size']
        elsif collection.include?(:size)
          @total_entries  = collection[:size]
        end
        @total_pages    = (@total_entries.to_f / @per_page).ceil
        if collection.include?('data')
          @collection     = collection['data']
        elsif collection.include?(:data)
          @collection  = collection[:data]
        end
      else
        initialize_without_algolia(source, page, per_page)
      end
    end

  end
end

# Middlewares

require 'locomotive/steam/middlewares/sitemap'

module Locomotive::Steam::Middlewares
  class Sitemap < ThreadSafe
    # TODO check in metafield to use correct sitemap
    include ShopInvader::Middlewares::Concerns::Sitemap::Algolia
    include ShopInvader::Middlewares::Concerns::Sitemap::Elasticsearch
  end
end

# Liquid

require 'locomotive/steam/liquid/tags/path_to'
require 'locomotive/steam/liquid/tags/link_to'

module Locomotive::Steam::Liquid::Tags
  class PathTo < ::Liquid::Tag
    include ShopInvader::Liquid::Tags::Concerns::Path
  end
end

module Locomotive::Steam::Liquid::Tags
  class LinkTo < Hybrid
    include ShopInvader::Liquid::Tags::Concerns::Path
  end
end
