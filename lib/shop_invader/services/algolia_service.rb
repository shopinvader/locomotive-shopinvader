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
      @role         = customer.try(:[], 'role') || 'public'
      @locale       = ShopInvader::LOCALES[locale.to_s]
      @indices      = JSON.parse(site.metafields.dig('algolia', "#{@role}_role") || '[]')
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

      { data: response['hits'], size: response['nbHits'] }
    end

    def find_by_key_among_indices(key)
      each_index do |index, settings|
        if resource = find_by_key(index, key)
          return {
            name:     settings['name'].underscore,
            data:     resource,
            template: settings['template_handle'] || settings['name'].underscore
          }
        end
      end
      nil
    end

    private

    def find_by_key(index, key)
      response = index.search(key, {
        restrictSearchableAttributes: KEY_ATTRIBUTES
      })

      response['hits'].detect do |hit|
        hit['url_key'] == key ||
        (hit['redirect_url_key'] || []).include?(key)
      end
    end

    def find_index(name)
      settings = @indices.detect { |settings| settings['name'] == name }
      build_index(settings)
    end

    def each_index
      @indices.each do |settings|
        yield(build_index(settings), settings)
      end
    end

    def build_index(settings)
      name  = settings['index']
      Locomotive::Common::Logger.debug "[Algolia] build index #{@locale}_#{name}"
      index = Algolia::Index.new("#{@locale}_#{name}", @client)
    end

    def build_params(conditions)
      { numericFilters: [], facetFilters: [] }.tap do |params|
        conditions.each do |key, value|
          name, op = key.split('.')

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
end
