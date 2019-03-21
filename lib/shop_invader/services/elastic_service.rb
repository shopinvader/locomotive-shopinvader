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

    attr_reader :indices, :site

    def initialize(site, customer, locale)
      @site         = site
      @customer     = customer
      @locale       = ShopInvader::LOCALES[locale.to_s]
      if site.metafields['elasticsearch']
        @indices      = JSON.parse(site.metafields.dig('elasticsearch', 'indices') || '[]')
        @credentials  = site.metafields['elasticsearch'].slice('server_IP', 'server_Port').symbolize_keys
        @client       = Elasticsearch::Client.new hosts: 'http://'+@credentials[:server_IP]+':'+@credentials[:server_Port]

        Locomotive::Common::Logger.debug "[Elastic] cluster health: #{ @client.cluster.health}"

      else
        @indices    = []
        @credentials= nil
        @client     = nil
      end
    end

    def find_all_products_and_categories
      # pour tout les indices
      indices.map do |config|
        # crée un hash
        {}.tap do |records|

          site.locales.each do |locale|
            # crée un objet index pour le rechercher
            # lien de l'index: #{config['index']}_#{ShopInvader::LOCALES[locale.to_s]}

            Locomotive::Common::Logger.debug "[Elastic] find_all_products_and_categories"

            result = @client.search index: "#{config['index']}_#{ShopInvader::LOCALES[locale.to_s]}", body: { query: { match_all: {} } }

            Locomotive::Common::Logger.debug "[Elastic find_all_products_and_categories] search all result: #{result}"
            #
            # index   = Algolia::Index.new("#{config['index']}_#{ShopInvader::LOCALES[locale.to_s]}", @client)
            # filters = ''
            #
            # if config['have_variant']
            #     filter = 'main: true'
            # end
            #
            # params = {
            #    query: '',
            #    attributesToRetrieve: 'name,objectID,url_key',
            #    filters: filter,
            # }
            # index.browse(params) do |hit|
            #   record = records[hit['objectID']] ||= {}
            #   record[locale] = { name: hit['name'], url: find_route(config['name']).gsub('*', hit['url_key']) }
            # end
          end
        end.values
      end.flatten
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      Locomotive::Common::Logger.debug "[Elastic] find_all"
      Locomotive::Common::Logger.debug "[Elastic] conditions #{conditions}"
      Locomotive::Common::Logger.debug "[Elastic] conditions.length #{conditions.length}"

      Locomotive::Common::Logger.debug "[Elastic] search of: #{name}"
      Locomotive::Common::Logger.debug "[Elastic] index: #{find_index(name)}"


      # creating the body of the query
      #TODO handle page
      body = {
        size: per_page
      }

      #if there are conditions will do a specific search
      # else search all in that index
      if conditions.length > 0
        body[:query] = build_params(conditions)
      else
        body[:query] ={ match_all: {} }
      end


      Locomotive::Common::Logger.debug "[Elastic] body: #{body}"


      response = @client.search(
        index: find_index(name),
        body: body
      )

      #shows the full result in console
      # Locomotive::Common::Logger.debug "[Elastic find_all] search all result: #{result}"

      # hits = response["hits"]["hits"]
      # Locomotive::Common::Logger.debug "[Elastic find_all] HITS HITS: #{hits}"
      # Locomotive::Common::Logger.debug "[Elastic find_all] HITS HITS length: #{hits.length}"

      #display list of elements
      # hits.each {
      #   |x|
      #   Locomotive::Common::Logger.debug "[Elastic find_all] #{x["_source"]["id"]}  #{x["_source"]["name"]}"
      #   Locomotive::Common::Logger.debug " #{x["_source"]} \n"
      # }

      # todo see if need _parse_response

      Locomotive::Common::Logger.debug "[Elastic find_all] response: #{response}"
      response = _parse_response(response)

      res = {
        data: response['hits']['hits'].map { |hit| hit['index_name'] = name; hit['_source'] },
        size: response['hits']['total']
      }

      res
    end


    # def find_by_key(name, key)
    #   _find_by_key(find_index(name), name, key)
    # end

    private

    def _parse_response(response)
      if @customer
        role = @customer.role
      end
      role ||= @site.metafields['erp']['default_role']
      response['hits'].each do |hit|
        if hit.include?('price')
          hit['price'] = hit['price'][role]
        end
      end
      response
    end

    # def _find_by_key(index, name, key)
    #   response = index.search('', {
    #     filters: "(url_key:#{key} OR redirect_url_key:#{key})"
    #   })
    #   response = _parse_response(response)
    #   resource = nil
    #   # look for the main product/category AND its variants
    #   response['hits'].each do |hit|
    #     hit['index_name'] = name
    #     if resource.nil?
    #       resource = hit
    #     else
    #       (resource['variants'] ||= []) << hit
    #     end
    #   end
    #   resource
    # end

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
      @routes ||= JSON.parse(site.metafields.dig('algolia', 'routes')  || '[]')
      (@routes.find { |(route, rule)| rule['index'] == index_name }).try(:first)
    end

  end
end
