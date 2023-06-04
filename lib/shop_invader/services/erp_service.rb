require 'digest'

ODOO_SESSION = {}

module ShopInvader
  class ErpService
    include ShopInvader::Services::Concerns::LocaleMapping
    FORWARD_HEADER = %w(ACCEPT ACCEPT_ENCODING ACCEPT_LANGUAGE HOST REFERER ACCEPT USER_AGENT)
    UTM_KEY = %w(source medium term content campaign from time lp)

    attr_reader :client
    attr_reader :session
    attr_reader :request

    def initialize(request, site, session, customer, locale, cookie_service, entry_service)
      @customer = customer
      @site     = site
      @session  = session
      headers = get_header_for_request(locale, request)
      @client   = Faraday.new(
        url: site.metafields['erp']['api_url'],
        headers: headers)
      @cookie_service = cookie_service
      @entry_service = entry_service
      @request = request
    end

    def call(method, path, params)
        response = call_without_parsing(method, path, params)
        if response.status == 200
          parse_response(response)
        else
          catch_error(response)
        end
    end

    def call_without_parsing(method, path, params)
        if @customer && ! is_cached?('customer')
            # initialisation not have been done maybe odoo was not
            # available, init it before applying the request
            initialize_customer
        end
        response = _call(method, path, params)
    end

    def find_one(name)
      call('GET', name, nil)
    end

    def find_all(name, conditions: nil, page: 1, per_page: 20)
      params = { per_page: per_page, page: page }
      if conditions
        params[:scope] = conditions
      end
      call('GET', name, params)
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

    def initialize_customer
      response = _call('POST', 'customer/sign_in', {})
      parse_response(response)
    end

    def authenticate_customer(email)
      entry = @entry_service.all('customers', 'email' => email)

      if entry.nil?
        log "Invalid email '#{email}' for customer, skip impersonate"
      else
        entry = entry.first
        session[:authenticated_entry_type]  = 'customers'
        session[:authenticated_entry_id]    = entry&._id.to_s

        request.env['steam.authenticated_entry'] = entry
        request.env['steam.liquid_assigns']["current_customer"] = entry
      end
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
            json = JSON.dump(value)
            session['store_' + key] = json
            # set a specific cookie for the version kept in cache
            # this allow to vary the content cached by proxy like varnish
            set_cookie_cache(key, json)
          end
        end
        if res.include?('force_authenticate_customer')
          authenticate_customer(res['force_authenticate_customer'])
        end
        # TODO we can remove this if when on odoo side we will have correct
        # response encapsulation
        # {'data': {'redirect_to': '...'}}
        # the size and data in data
        # {'data': {'items': [], 'size': ..}}
        if res.include?('redirect_to')
          {'redirect_to' => res['redirect_to']}
        elsif res.include?('size')
          {'data' => res['data'], 'size' => res['size']}
        elsif res.include?('data')
          if !res['data'].kind_of?(Array)
            res['data']
          else
            {'data' => res['data'], 'size' => res['data'].length}
          end
        else
          res
        end
      else
        {
            body: response.body,
            headers: {
                'Content-Type': headers['content-type'],
                'Content-Disposition': headers['content-disposition'],
                'Content-Length': headers['content-length'],
            }
        }
      end
    end

    def set_cookie_cache(key, json)
      value = Digest::SHA256.hexdigest json
      # TODO make the max_age configurable maybe we should use the same age as the main cookie
      @cookie_service.set(key, {value: value, path: '/', max_age: 1.year})
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

    def clear_session
      session.keys.each do | key |
        if key.start_with?('store_')
            cookie_key = key.gsub('store_', '')
            @cookie_service.set(cookie_key, {
                value: '',
                path: '/',
                max_age: 0})
            session.delete(key)
        end
        if key.start_with?('erp_')
            session.delete(key)
        end
      end
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

    def add_utm_header(request, headers)
      UTM_KEY.each do | key |
        headers["utm_#{key}".to_sym] = request.env["utm.#{key}"]
      end
    end

    def add_client_header(request, headers)
      FORWARD_HEADER.each do | key |
        headers["invader_client_#{key.downcase()}".to_sym] = request.get_header("HTTP_#{key}")
      end
      headers[:invader_client_ip] = request.ip
    end

    def get_header_for_request(locale, request)
      headers = {
        api_key: @site.metafields['erp']['api_key'],
        accept_language: map_locale(locale.to_s),
      }
      add_utm_header(request, headers)
      add_client_header(request, headers)
      add_header_info_from_session(headers)
      if @customer && @customer.email
        headers[:partner_email] = @customer.email
      elsif !session['store_customer'].nil?
        # for the guest mode the email is into the store cache
        # indeed no session is initialized therefore the service is initialized with a nil customer
        customer = read_from_cache('customer')
        if customer && customer['email']
          headers[:partner_email] = customer['email']
        end
      end
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
          client.headers.update({
              'Content-Type': content_type,
              'Cookie': "session_id=#{ODOO_SESSION[@site._id]}"
          })
          response = client.send(method.downcase, path, params)
          cookies = Rack::Utils.parse_cookies_header(response.headers['set-cookie'])
          if cookies["session_id"]
            ODOO_SESSION[@site._id] = cookies['session_id']
          end
          response
        rescue
          log_error 'Odoo Error: server have an internal error, active maintenance mode'
          raise ShopInvader::ErpMaintenance.new('ERP under maintenance')
        end
    end

  end
end
