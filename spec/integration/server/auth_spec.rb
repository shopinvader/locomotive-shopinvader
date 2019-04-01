require File.dirname(__FILE__) + '/../integration_helper'

describe 'Authentication' do

  include Rack::Test::Methods

  def app
    run_server
  end

  describe 'sign up action' do

    it 'renders the form' do
      get '/account/register'
      expect(last_response.body).to include '/account/register'
    end

    describe 'press the sign up button' do

      let(:email)  { 'thibault.rey+rspec@akretion.com' }
      let(:name)   { 'Thibault' }
      let(:password_confirmation) { 'easyone' }
      let(:params) { {
        auth_action:          'sign_up',
        auth_content_type:    'customers',
        auth_id_field:        'email',
        auth_password_field:  'password',
        auth_callback:        '/account/register-validation',
        city:                 'Lyon',
        street:               'Rue du gouté',
        country:              {id: 76},
        name:                 name,
        zip:                  69004,
        auth_entry: {
          email:                  email,
          password:               'easyone',
          password_confirmation:  password_confirmation,
          role:                   'default',
        }
      } }

      it 'redirects to the callback' do
        sign_up(params)
        expect(last_response.status).to eq 301
        expect(last_response.location).to eq '/account/register-validation'
      end

      it 'displays the profile page as described in the params' do
        params[:name]               = 'Didier'
        params[:auth_entry][:email] = 'did+rspec@locomotivecms.com'
        sign_up(params, true)
        expect(last_response.body).to include "Account Created"
        expect(last_response.body).to include "Didier"
      end

      context 'wrong parameters' do
        let(:name)                  { 'Sebastien' }
        let(:email)                 { 'sebastien.beau+rspec@akretion.com' }
        let(:password_confirmation) { 'easyone2' }

        it 'renders the sign up page with an error message' do
          sign_up(params)
          expect(last_response.status).to eq 200
          expect(last_response.body).to include '/account/register'
          expect(last_response.body).to include "doesn't match password"
        end
      end
    end
  end

  describe 'sign in action' do

    let(:password)  { 'password' }
    let(:params)    { {
      auth_action:          'sign_in',
      auth_content_type:    'customers',
      auth_id_field:        'email',
      auth_password_field:  'password',
      auth_id:              'osiris@shopinvader.com',
      auth_password:        password,
      auth_callback:        '/account/customer'
    } }

    it 'renders the form' do
      get '/account'
      expect(last_response.body).to include '/account'
      expect(last_response.body).to include "Account page, not logged"
    end

    describe 'press the sign in button' do

      it 'redirects to the callback and set cookies and session' do
        sign_in(params)
        expect(last_response.status).to eq 301
        expect(last_response.location).to eq '/account/customer'
        expect(last_response.headers['Set-Cookie']).to include 'customer='
        expect(last_response.headers['Set-Cookie']).to include 'cart='
        expect(session).to include "erp_cart_id"
        expect(session).to include "store_customer"
        expect(session).to include "store_cart"
        expect(session['authenticated_entry_id']).to eq 'osiris-at-shopinvader-dot-com'
      end

      it 'displays the profile page as described in the params' do
        sign_in(params, true)
        expect(last_response.body).to include "My name is: Osiris"
        expect(last_response.body).to include "current page: /account/customer"
      end

      context 'wrong credentials' do
        let(:password) { 'dontrememberit' }

        it 'renders the sign in page with an error message' do
          sign_in(params)
          expect(last_response.status).to eq 200
          expect(last_response.body).to include '/account'
          expect(last_response.body).to include 'Wrong credentials!'
        end
      end
    end
  end

  describe 'sign out action' do
    before :each do
     sign_in({
       auth_action:          'sign_in',
       auth_content_type:    'customers',
       auth_id_field:        'email',
       auth_password_field:  'password',
       auth_id:              'osiris@shopinvader.com',
       auth_password:        'password',
       auth_callback:        '/account/customer'
       })
    end

    it 'should redirect to account and drop cookies and session' do
      sign_out
      expect(last_response.status).to eq 301
      expect(last_response.headers['Set-Cookie']).to include 'customer=; path=/; max-age=0'
      expect(last_response.headers['Set-Cookie']).to include 'cart=; path=/; max-age=0'
      expect(session).not_to include "erp_cart_id"
      expect(session).not_to include "store_customer"
      expect(session).not_to include "store_cart"
      expect(session['authenticated_entry_id']).to eq ''
    end

    it 'should be not logged' do
      sign_out(true)
      expect(last_response.body).to include 'current page: /account'
      expect(last_response.body).to include "Account page, not logged"
    end

  end
end
