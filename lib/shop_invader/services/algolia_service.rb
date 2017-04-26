module ShopInvader
  class AlgoliaService

    KEY_ATTRIBUTES = %w(url_key redirect_url_key)

    def initialize(site, customer, locale)
      @site         = site
      @customer     = customer
      @role         = customer.try(:[], 'role') || 'public'
      @locale       = ShopInvader::LOCALES[locale.to_s]
      @indices      = JSON.parse(site.metafields.dig('algolia', "#{@role}_role") || '[]')
      @credentials  = site.metafields['algolia'].slice('application_id', 'api_key').symbolize_keys
      @client       = Algolia::Client.new(@credentials)
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

    def each_index
      @indices.each do |settings|
        name  = settings['index']
        index = Algolia::Index.new("#{@locale}_#{name}", @client)
        yield(index, settings)
      end
    end

  end
end
