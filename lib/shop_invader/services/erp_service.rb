module ShopInvader
  class ErpService
    FORWARD_HEADER = %w(ACCEPT ACCEPT_ENCODING ACCEPT_LANGUAGE HOST REFERER ACCEPT USER_AGENT)
    attr_reader :client
    attr_reader :session

    def initialize(request, site, session, customer, locale)
      @customer = customer
      @site     = site
      @session  = session
      headers = get_header_for_request(locale, request)
      @client   = Faraday.new(
        url: site.metafields['erp']['api_url'],
        headers: headers)
    end

    def call(method, path, params)
        if @customer && ! is_cached?('customer')
            # initialisation not have been done maybe odoo was not
            # available, init it before applying the request
            initialize_customer
        end
        _call(method, path, params)
    end

    def find_one(name)
      path = name.sub('_', '/')
      call('GET', path, nil)
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      params = { per_page: per_page, page: page }
      if conditions
        params[:scope] = conditions
      end
      path = name.sub('_', '/')
      response = call('GET', path, params)
      if response.status == 200
        parse_response(response)
      else
        catch_error(response)
      end
    end

    def is_cached?(name)
      session.include?('store_' + name)
    end

    def read_from_cache(name)
      JSON.parse(session['store_' + name])
    end

    def clear_cache(name)
      session.delete('store_' + name)
    end

    def download(path)
      # TODO: give the right url + right headers
      # https://github.com/lostisland/faraday
      conn = Faraday.new(url: 'http://via.placeholder.com')
      response = conn.get(path)
      response.status == 200 ? response : nil
    end

    def initialize_customer
      _call('POST', 'customer/sign_in', {})
    end

    def parse_response(response)
      headers = response.headers
      if headers['content-type'] == 'application/json'
          res = JSON.parse(response.body)
          if res.include?('set_session')
              res.delete('set_session').each do |key, val|
                session['erp_' + key] = val
              end
          end
          if res.include?('store_cache')
            res.delete('store_cache').each do | key, value |
              session['store_' + key] = JSON.dump(value)
            end
          end
          res['content-type'] = 'application/json'
        res
      else
        {
            'body': response.body,
            'headers': {
                'Content-Type': headers['content-type'],
                'Content-Disposition': headers['content-disposition'],
                'Content-Length': headers['content-length'],
            }
        }
      end
    end

    def catch_error(response)
        res = JSON.load(response.body)
        res.update(
            data: [],
            size: 0,
            'error': true
        )
        if response.status == 500
          log_error 'Odoo Error: server have an internal error, active maintenance mode'
          raise ShopInvader::ErpMaintenance.new('ERP under maintenance')
        else
          log_error 'Odoo Error: controler raise en error'
          session['store_notifications'] = JSON.dump([{
            'type': 'danger',
            'message': res['description'],
            }])
        end
        res
    end

    private

    def log_error(msg)
      Locomotive::Common::Logger.error msg
    end

    def add_header_info_from_session(headers)
       if session
          session.keys.each do |key|
            if key.start_with?('erp_')
                headers[('sess_' + key.sub('erp_', '')).to_sym] = session[key].to_s
            end
          end
       end
    end

    def add_client_header(request, headers)
      FORWARD_HEADER.each do | key |
        headers["INVADER_CLIENT_#{key}"] = request.get_header("HTTP_#{key}")
      end
      headers["INVADER_CLIENT_IP"] = request.ip
    end

    def get_header_for_request(locale, request)
      headers = {
        api_key: @site.metafields['erp']['api_key'],
        ACCEPT_LANGUAGE: ShopInvader::LOCALES[locale.to_s],
      }
      if @customer && @customer.email
        headers[:partner_email] = @customer.email
      end
      add_client_header(request, headers)
      add_header_info_from_session(headers)
      headers
    end

    def _call(method, path, params)
        method = method.downcase
        begin
          if ['post', 'put'].include?(method)
            content_type = 'application/json'
            params = params.to_json
          else
            content_type = 'application/x-www-form-urlencoded'
          end
          client.headers.update({'Content-Type': content_type})
          client.send(method.downcase, path, params)
        rescue
          log_error 'Odoo Error: server have an internal error, active maintenance mode'
          raise ShopInvader::ErpMaintenance.new('ERP under maintenance')
        end
    end

  end
end
