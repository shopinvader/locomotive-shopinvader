module ShopInvader
  class ErpAuthService
    attr_reader :request
    attr_reader :entry_service
    attr_reader :erp_service

    def initialize(request, erp_service, entry_service)
      @erp_service = erp_service
      @entry_service = entry_service
      @request     = request
    end

    def signed_up(auth_entry)
      rollback = false
      path, params = _prepare_erp_call(auth_entry)
      begin
        data = erp_service.call('POST', path, params)
      rescue ShopInvader::ErpMaintenance => e
        request.env['steam.liquid_assigns']['store_maintenance'] = true
        rollback_user_creation(auth_entry)
      else
        if data.include?(:error)
          rollback_user_creation(auth_entry)
        else
          # Update the customer data with the result given by the API
          update_customer_from_response(auth_entry, data)
        end
      end
    end

    def signed_in(auth_entry)
      initialize_customer(auth_entry)
    end

    def reset_password(auth_entry)
      initialize_customer(auth_entry)
    end

    def sign_out(auth_entry)
      # After signed out, drop the full session
      erp_service.clear_session
    end

    private

    def update_customer_from_response(auth_entry, data)
      unless data.include?('role')
        data['role'] = request.env['steam.site'].metafields['erp']['default_role']
      end
      vals = {}
      current_vals = auth_entry.to_hash
      data.each do |key, val|
        if current_vals.include?(key) && current_vals[key] != data[key]
          vals[key] = val
        end
      end
      entry_service.update_decorated_entry(auth_entry, vals)
    end

    def rollback_user_creation(auth_entry)
       # Drop the content created (no rollback on mongodb)
       entry_service.delete(auth_entry.content_type_slug, auth_entry._id)
       # Add a fake error field to avoid content authentification
       auth_entry.errors.add('error', 'Fail to create')
    end

    def _prepare_customer_params(auth_entry)
      params = request.params.clone
      params.update({
          'external_id': auth_entry._id,
          'email': auth_entry.email
          })

      %w(auth_action auth_disable_email auth_content_type auth_id_field
         auth_password_field auth_email_handle auth_callback auth_entry).each do | key |
        params.delete(key)
      end
      params
    end

    def guest
      @guest |= request.params.include?('auth_guest_signup')
    end

    def _prepare_erp_call(auth_entry)
      if guest
        params = {
          'external_id': auth_entry._id,
          # TODO it will be better to not pass this arg, we will discusse about it
          # on odoo side then remove this comment of teh email here
          'email': auth_entry.email
        }
        path = 'guest/register'
      else
        params = _prepare_customer_params(auth_entry)
        path = 'customer'
      end
      [path, params]
    end

    def initialize_customer(auth_entry)
      request.env['authenticated_entry'] = auth_entry
      begin
        erp_service.initialize_customer
      rescue ShopInvader::ErpMaintenance => e
        # TODO add special logging
      end
    end
  end
end
