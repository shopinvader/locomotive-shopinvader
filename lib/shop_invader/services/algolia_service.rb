module ShopInvader
  class AlgoliaService

    KEY_ATTRIBUTES = %w(url_key redirect_url_key).freeze
    NUMERIC_OPERATORS = {
      nil   => '=',
      'gt'  => '>',
      'gte' => '>=',
      'lt'  => '<',
      'lte' => '<=',
      'ne'  => '!='
    }.freeze

    attr_reader :indices

    def initialize(site, customer, locale)
      @site         = site
      @customer     = customer
      @locale       = ShopInvader::LOCALES[locale.to_s]
      @indices      = JSON.parse(site.metafields.dig('algolia', "indices") || '[]')
      @credentials  = site.metafields['algolia'].slice('application_id', 'api_key').symbolize_keys
      @client       = Algolia::Client.new(@credentials)
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      response = find_index(name).search('',
        build_params(conditions || {}).merge({
          page:         page,
          hitsPerPage:  per_page
        })
      )
      response = _parse_response(response)
      {
        data: response['hits'].map { |hit| hit['index_name'] = name; hit },
        size: response['nbHits']
      }
    end

    def find_by_key(name, key)
      _find_by_key(find_index(name), name, key)
    end

    private

    def _parse_response(response)
      if @customer
        role = @customer.role
      end
      role ||= @site['metafields']['erp']['default_pricelist']
      response['hits'].each do |hit|
        if hit.include?('price')
          hit['price'] = hit['price'][role]
        end
      end
      response
    end

    def _find_by_key(index, name, key)
      response = index.search('', {
        filters: "(url_key:#{key} OR redirect_url_key:#{key})"
      })
      response = _parse_response(response)
      resource = nil
      # look for the main product/category AND its variants
      response['hits'].each do |hit|
        hit['index_name'] = name

        hit['redirect_url_key'] ||= []
        next if hit['url_key'] != key && !(hit['redirect_url_key']).include?(key)

        if hit['url_key'] == key || hit['redirect_url_key'].include?(key) && resource.nil?
          resource = hit
        else
          (resource['variants'] ||= []) << hit
        end
      end

      resource
    end

    def find_index(name)
      settings = @indices.detect { |settings| settings['name'] == name }
      build_index(settings)
    end

    def build_index(settings)
      name = settings['index']
      Locomotive::Common::Logger.debug "[Algolia] build index #{name}_#{@locale}"
      Algolia::Index.new("#{name}_#{@locale}", @client)
    end

    def build_params(conditions)
      { numericFilters: [], facetFilters: [] }.tap do |params|
        conditions.each do |key, value|
          name, op = key.split('.')
          name, value = build_attr(name, value)
          if value.is_a?(Numeric)
            params[:numericFilters] << "#{name} #{NUMERIC_OPERATORS[op] || '='} #{value}"
          else
            [*value].each do |_value|
              params[:facetFilters] << "#{op == 'nin' ? 'NOT ' : ''}#{name}:#{_value}"
            end
          end
        end
      end
    end

    def build_attr(name, value)
      if value.is_a?(Hash)
        key, val = value.first
        name = "#{name}.#{key}"
        build_attr(name, val)
      else
        [name, value]
      end
    end

  end
end
