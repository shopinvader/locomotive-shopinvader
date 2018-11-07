require File.dirname(__FILE__) + '/../integration_helper'

describe 'When I am logged in' do

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
    let(:invader_error_url) { '/account/addresses-form' }
    let(:address_params) { {
      city: 'Mizérieux',
      country: country,
      invader_error_url: invader_error_url,
      invader_success_url: '/account/addresses',
      name: 'Osiris RSPEC',
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
      add_an_address(address_params, '/account/addresses-form')
      expect(last_response.status).to eq 302
      expect(last_response.location).to eq '/account/addresses'
    end

    it 'displays the address created' do
      add_an_address(address_params, '/account/addresses-form', true)
      expect(last_response.status).to eq 200
      expect(last_response.body).to include "Osiris"
      expect(last_response.body).to include "Rue des treffles"
    end

    context 'with missing country' do

      let(:country) { {} }

      it 'redirects to the invader_error_url' do
        add_an_address(address_params, '/account/addresses-fake')
        expect(last_response.status).to eq 302
        expect(last_response.location).to eq '/account/addresses-form'
      end

      it 'displays the form with the previous params' do
        add_an_address(address_params, '/account/addresses-form', true)
        expect(last_response.status).to eq 200
        expect(last_response.body).to include "BadRequest {'country': ['required field']}"
        expect(last_response.body).to include "/account/addresses-form"
      end

      context 'with no invader_error_url' do

        let(:invader_error_url) { {} }

        it 'redirects to the referer' do
          add_an_address(address_params, '/account/addresses-form')
          expect(last_response.status).to eq 302
          expect(last_response.location).to eq '/account/addresses-form'
        end
      end
    end
  end
end
