require File.dirname(__FILE__) + '/../integration_helper'

describe 'When I am loggin' do

  include Rack::Test::Methods

  def app
    run_server
  end

  describe 'adding an address' do
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
    end
    let(:country) { {id: 74} }
    let(:address_params) { {
      city: 'Mizérieux',
      country: country,
      invader_error_url: '/account/addresses?add=true',
      invader_success_url: '/account/addresses',
      name: 'Osiris',
      phone: '0000000000',
      street:   'Rue des treffles',
      zip: '42110',
    } }

    it 'display the address page as describe in the params' do
      get '/account/addresses'
      expect(last_response.body).to include "Osiris"
      expect(last_response.body).to include "My shipping addresses"
    end

    it 'redirects to the success callback' do
      add_an_address(address_params, '/account/addresses?add=true')
      expect(last_response.status).to eq 302
      expect(last_response.location).to eq '/account/addresses'
    end

    it 'displays the address created' do
      add_an_address(address_params, '/account/addresses?add=true', true)
      expect(last_response.status).to eq 200
      expect(last_response.body).to include "Osiris"
      expect(last_response.body).to include "Rue des treffles"
    end

    context 'with missing country' do

      let(:country) { {} }

      it 'redirects to the error callback' do
        add_an_address(address_params, '/account/addresses?add=true')
        expect(last_response.status).to eq 302
        expect(last_response.location).to eq '/account/addresses'
      end

      it 'redirects to the referer if no callback have been defined' do
        add_an_address(address_params, '/account/addresses?add=true')
        expect(last_response.status).to eq 302
        expect(last_response.location).to eq '/account/addresses'
      end

      it 'displays the form with the previous params' do
        add_an_address(address_params, '/account/addresses?add=true', true)
        expect(last_response.status).to eq 200
        expect(last_response.body).to include "Osiris"
        expect(last_response.body).to include "Rue des treffles"
      end
    end
  end
end


