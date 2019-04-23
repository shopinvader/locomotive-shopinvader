module ShopInvader
  class ElasticService

    KEY_ATTRIBUTES = %w(url_key redirect_url_key).freeze
    NUMERIC_OPERATORS = {
      nil   => '=',
      'gt'  => '>',
      'gte' => '>=',
      'lt'  => '<',
      'lte' => '<=',
      'ne'  => '!='
    }.freeze

    attr_reader :indices, :site, :routes

    def initialize(site, customer, locale)
      @site         = site
      @customer     = customer
      @locale       = ShopInvader::LOCALES[locale.to_s]
      if site.metafields['elasticsearch']
        @indices      = JSON.parse(site.metafields.dig('elasticsearch', 'indices') || '[]')
        @client       = Elasticsearch::Client.new hosts: @site.metafields.dig('elasticsearch', 'url')
        @routes       = JSON.parse(site.metafields.dig('elasticsearch', 'routes') || '[]')
      else
        @indices    = []
        @client     = nil
        @routes     = []
      end
    end

    def find_all_products_and_categories
      indices.map do |config|
        {}.tap do |records|
          site.locales.each do |locale|
            index   = "#{config['index']}_#{ShopInvader::LOCALES[locale.to_s]}".downcase
            body =  { query: { match_all: {} } }
            body[:size]=100
            result = @client.search(
              index: index,
              scroll: '5m',
              body: body
            )

            # first search which also returns _scroll_id
            result['hits']['hits'].each do |hit|
              record = records[hit['_id']] ||= {}
              record[locale] = { name: hit['_source']['name'], url: find_route(config['name']).gsub('*', hit['_source']['url_key']) }
            end

            # Uses the `scroll` API until empty results are returned
            # https://www.elastic.co/guide/en/elasticsearch/reference/6.6/search-request-scroll.html
            while result = @client.scroll(body: { scroll_id: result['_scroll_id'] }, scroll: '5m') and not result['hits']['hits'].empty? do
              result['hits']['hits'].each do |hit|
                record = records[hit['_id']] ||= {}
                record[locale] = { name: hit['_source']['name'], url: find_route(config['name']).gsub('*', hit['_source']['url_key']) }
              end
            end
          end
        end.values
      end.flatten
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      body = {
        from: page,
        size: per_page
      }

      #if there are conditions will do a specific search
      # else search all in that index
      if conditions.length > 0
        body[:query] = build_params(conditions)
      else
        body[:query] ={ match_all: {} }
      end
      response = @client.search(
        index: find_index(name),
        body: body
      )

      response = _parse_response(response)
      res = {
        data: response['hits']['hits'].map { |hit| hit['index_name'] = name; hit['_source'] },
        size: response['hits']['total']
      }
      res
    end


    def find_by_key(name, key)
      _find_by_key(find_index(name), name, key)
    end

    private

    def _parse_response(response)
      if @customer
        role = @customer.role
      end
      role ||= @site.metafields['erp']['default_role']
      response['hits']['hits'].each do |hit|
        if hit["_source"].include?('price')
          hit["_source"]['price'] = hit["_source"]['price'][role]
        end
      end
      response
    end

    def _find_by_key(index, name, key)

      # TODO add redirect_url_key to the request
      body = {
        query:{
          bool:{
            filter: {
              term: {
                url_key: key
              }
            }
          }
        }
      }
      response = @client.search(
        index: index,
        body: body
      )
      response = _parse_response(response)
      resource = nil
      # look for the main product/category AND its variants
      response['hits']['hits'].each do |hit|
        hit['index_name'] = name
        if resource.nil?
          resource = hit['_source']
        else
          (resource['variants'] ||= []) << hit['_source']
        end
      end
      resource
    end

    def find_index(name)
      settings = @indices.detect { |settings| settings['name'] == name }
      res = "#{settings["index"]}_#{@locale}".downcase
    end

    def build_params(conditions)
      {}.tap do |params|
        params.compare_by_identity
        conditions.each do |key, value|
          name, op = key.split('.')
          build_attr(name, value).each do | name, value |
            temp = {
              name=>value
            }
            params['match'.clone]=temp
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
      @routes ||= JSON.parse(site.metafields.dig('elasticsearch', 'routes')  || '[]')
      (@routes.find { |(route, rule)| rule['index'] == index_name }).try(:first)
    end

  end
end
