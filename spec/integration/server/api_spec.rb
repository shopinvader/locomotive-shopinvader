require File.dirname(__FILE__) + '/../integration_helper'

describe 'When I am logged in' do

  include Rack::Test::Methods

  def app
    run_server
  end

  describe 'testing json api' do
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

    it 'get on "/invader/addresses" return a json of existing address' do
      get '/invader/addresses'
      expect(last_response.status).to eq 200
      response = JSON.parse(last_response.body)
      expect(response[0]['name']).to eq 'Osiris'
    end

    it 'post on "/invader/addresses" add an address and return it' do
      add_an_address(address_params, '/invader/addresses', follow_redirect=false, json=true)
      expect(last_response.status).to eq 200
      response = JSON.parse(last_response.body)
      expect(response[0]['name']).to eq 'Osiris'
    end

    context 'with missing country' do

      let(:country) { {} }

      it 'post on "/invader/addresses" raise a 400 error' do
        add_an_address(address_params, '/invader/addresses', follow_redirect=false, json=true)
        expect(last_response.status).to eq 400
        expect(last_response.body).to include 'Bad Request'
      end

    end
  end
end
