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

    attr_reader :indices, :site

    def initialize(site, customer, locale)
      @site         = site
      @customer     = customer
      @locale       = ShopInvader::LOCALES[locale.to_s]
      @indices      = JSON.parse(site.metafields.dig('algolia', 'indices') || '[]')
      @credentials  = site.metafields['algolia'].slice('application_id', 'api_key').symbolize_keys
      @client       = Algolia::Client.new(@credentials)
    end

    def find_all_products_and_categories
      indices.map do |config|
        {}.tap do |records|
          site.locales.each do |locale|
            index   = Algolia::Index.new("#{config['index']}_#{ShopInvader::LOCALES[locale.to_s]}", @client)
            filters = ''

            if config['have_variant']
                filter = 'main: true'
            end

            results = index.search('', {
                'attributesToRetrieve' => 'name,objectID,url_key',
                'hitsPerPage' => 1000,
                'filters' => filter,
            })

            results['hits'].each do |hit|
              record = records[hit['objectID']] ||= {}
              record[locale] = { name: hit['name'], url: find_route(config['name']).gsub('*', hit['url_key']) }
            end
          end
        end.values
      end.flatten
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
        if resource.nil?
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
          build_attr(name, value).each do | name, value |
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
    end

    def build_attr(name, value)
      if value.is_a?(Hash)
        result = []
        value.each do | key, val |
           subname = "#{name}.#{key}"
           result.concat(build_attr(subname, val))
        end
        result
      else
        [[name, value]]
      end
    end

    def find_route(index_name)
      @routes ||= JSON.parse(site.metafields.dig('algolia', 'routes')  || '[]')
      (@routes.find { |(route, rule)| rule['index'] == index_name }).try(:first)
    end

  end
end
