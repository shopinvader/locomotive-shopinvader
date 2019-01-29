require File.dirname(__FILE__) + '/../integration_helper'

describe 'When I am logged in' do

  include Rack::Test::Methods

  def app
    run_server
  end

  describe 'testing page with erp drop' do
    before :all do
      sign_in({
        auth_action:          'sign_in',
        auth_content_type:    'customers',
        auth_id_field:        'email',
        auth_password_field:  'password',
        auth_id:              'osiris@shopinvader.com',
        auth_password:        'password',
        auth_callback:        '/account/orders'
        })
      remove_addresses
    end
    let(:country) { {id: 74} }
    let(:address_params) { {
      city: 'Mizérieux',
      country: country,
      name: 'Osiris',
      phone: '0000000000',
      street:   'Rue des treffles',
      zip: '42110',
    } }

    it 'get on "/erp-call-tag/addresses" return a json of existing address' do
        get '/erp-call-tag/addresses'
      expect(last_response.status).to eq 200
      response = JSON.parse(last_response.body)
      expect(response[0]['name']).to eq 'Osiris'
    end

  end
end
