module ShopInvader
  class ErpService
    attr_reader :client
    attr_reader :session

    def initialize(site, session, customer, locale)
      @site         = site
      @client       = Faraday.new(
                          url: site.metafields['erp']['api_url'],
                          headers: {
                              'API_KEY' => site.metafields['erp']['api_key'],
                              'PARTNER_EMAIL' => customer && customer.email,
                              'LANG' => ShopInvader::LOCALES[locale.to_s]})
      @session      = session
    end

    def call(method, path, params)
        headers = extract_session()
        client.headers.update(headers)
        if method == 'GET'
          response = client.get path, params
        elsif method == 'POST'
          response = client.post path, params
        elsif method == 'PUT'
          response = client.put path, params
        elsif method == 'DELETE'
          response = client.delete path
        end
        parse_response(response)
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      params = {
          per_page: per_page,
          page: page,
          domain: conditions }
      path = name.sub('_', '/')
      call('GET', path, params)
    end

    def is_cached?(name)
      session.include?('store_' + name)
    end

    def read_from_cache(name)
      JSON.parse(session['store_' + name])
    end

    private

    def parse_response(response)
      res = JSON.parse(response.body)
      if res.include?('set_session')
          res['set_session'].each do |key, val|
            session['erp' + key] = val
          end
      end
      if res.include?('store_data')
        session['store_' + res['store_data']] = JSON.dump(res['data'])
      end
      { data: res['data'], size: res['size'] }
    end

    def extract_session()
        headers = {}
        if session
          session.each do |key, val|
            if key.start_with?('erp_')
                headers['SESS_' + key.sub('erp_', '')] = val.to_s
            end
          end
       end
       headers
    end

  end
end
