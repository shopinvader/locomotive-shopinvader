module ShopInvader
  class ErpService

    attr_reader :client
    attr_reader :session

    def initialize(site, session, customer, locale)
      headers = {
        api_key:  site.metafields['erp']['api_key'],
        lang:     ShopInvader::LOCALES[locale.to_s]
      }
      if customer && customer.email
        headers[:partner_email] = customer.email
      end
      @site     = site
      @session  = session
      @client   = Faraday.new(
        url: site.metafields['erp']['api_url'],
        headers: headers)
    end

    def call(method, path, params)
        headers = extract_session()
        client.headers.update(headers)
        response = client.send(method.downcase, path, params)
        parse_response(response)
    end

    def find_one(name)
      path = name.sub('_', '/')
      call('GET', path, nil)
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
            session['erp_' + key] = val
          end
      end
      if res.include?('store_cache')
        res['store_cache'].each do | key, value |
          session['store_' + key] = JSON.dump(value)
        end
      end
      { data: res['data'], size: res['size'] }
    end

    def extract_session()
        headers = {}
        if session
          session.keys.each do |key|
            if key.start_with?('erp_')
                headers[('sess_' + key.sub('erp_', '')).to_sym] = session[key].to_s
            end
          end
       end
       headers
    end

  end
end
