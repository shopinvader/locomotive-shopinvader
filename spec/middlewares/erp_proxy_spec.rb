require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::ErpProxy do

  let(:path)                { 'my-product' }
  let(:params)              { {'action_proxy'=> 'cart/item',
                               'product_code' => 'char-aku',
                               'product_id' => '252',
                               'item_qty' => '1'} }
  let(:accept)              {}
  let(:response_data)       { {cart: {'name': 'SO00042'},
                               set_session: {'cart_id': 42},
                               'content-type' => 'application/json'} }
  let(:response)            { instance_double('Response', body: JSON.dump(response_data), status: 200, headers: {})}
  let(:session)             { {erp_cart_id: 42} }
  let(:app)                 { ->(env) { [200, env] } }
  let(:erp_service)         { instance_double('ErpService', call: response, parse_response: {'body': response_data})}
  let(:recaptcha_service)   { instance_double('RecaptchaService', verify: false)}
  let(:services)            { instance_double('Services', erp: erp_service, recaptcha: recaptcha_service) }
  let(:middleware)          { described_class.new(app) }
  let(:api_required_recaptcha) { "[{\"method\": \"post\", \"actions\": [\"customer\", \"customer/create\"]}]" }
  let(:site)                { instance_double('Site', locales: ['en', 'fr'], default_locale: 'en', metafields: {'erp'=> {'api_required_recaptcha'=> api_required_recaptcha}} ) }

  subject do
    env = env_for('http://models.example.com', {
      'steam.site'            => site,
      'steam.services'        => services,
      'steam.path'            => path,
      'REQUEST_METHOD'        => 'POST',
      'steam.locale'          => 'fr',
      'steam.cookies'         => {},
      'steam.liquid_assigns'  => {},
      params:                    params,
    })
    env['steam.request'] = Rack::Request.new(env)
    env['steam.request'].add_header 'HTTP_ACCEPT', accept
    code, env, content = middleware.call(env)
    [code, env, content]
  end

  context 'Call Post API' do
    let(:path)   { 'invader/cart/item' }

    it 'add item in cart' do
      expect(services.erp).to receive(:call_without_parsing).with(
          'POST', 'cart/item', params).and_return(response)
      is_expected.to eq subject
    end
  end

  describe 'Call Recaptcha Required json' do
    let(:path)   { 'invader/customer' }
    let(:params) { {'g-recaptcha-response': 'foo' }}

    context "In json" do
      it 'return a 403' do
        expect(services.recaptcha).to receive(:verify).with('foo').and_return(false)
        is_expected.to eq [403, {"Content-Type"=>"application/json"}, ["{'recaptcha_invalid': true}"]]
      end
    end

    context "With full path" do
      let(:path)   { 'invader/customer/create' }
      it 'return a 403' do
        expect(services.recaptcha).to receive(:verify).with('foo').and_return(false)
        is_expected.to eq [403, {"Content-Type"=>"application/json"}, ["{'recaptcha_invalid': true}"]]
      end
    end


    context 'With force redirection' do
      let(:params) { {'invader_error_url': 'http://bar', 'g-recaptcha-response': 'foo', 'force_apply_redirection': true} }

      it 'return a redirection' do
        expect(services.recaptcha).to receive(:verify).with('foo').and_return(false)
        is_expected.to eq [302, {"Content-Type"=>"text/html", "Location"=>"http://bar"}, []]
      end
    end

    context 'with http form' do
      let(:accept) { 'text/html'}
      let(:params) { {'invader_error_url': 'http://bar', 'g-recaptcha-response': 'foo'} }
      it 'return a redirection' do
        expect(services.recaptcha).to receive(:verify).with('foo').and_return(false)
        is_expected.to eq [302, {"Content-Type"=>"text/html", "Location"=>"http://bar"}, []]
      end
    end
  end

end
