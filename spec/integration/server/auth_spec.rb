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
        params[:auth_entry][:email] = 'did@locomotivecms.com'
        sign_up(params, true)
        expect(last_response.body).to include "Your customer account as been succefully created"
      end

      context 'wrong parameters' do
        let(:name)                  { 'Sebastien' }
        let(:email)                 { 'sebastien.beau@akretion.com' }
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
      auth_callback:        '/account/orders'
    } }

    it 'renders the form' do
      get '/account'
      expect(last_response.body).to include '/account'
      expect(last_response.body).not_to include "You've been signed out"
    end

    describe 'press the sign in button' do

      it 'redirects to the callback' do
        sign_in(params)
        expect(last_response.status).to eq 301
        expect(last_response.location).to eq '/account/orders'
      end

      it 'displays the profile page as described in the params' do
        sign_in(params, true)
        expect(last_response.body).to include "Osiris"
        expect(last_response.body).to include "Happy to see you again ;)"
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
end
