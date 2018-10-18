require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::ErpProxy do

  let(:path)                { 'my-product' }
  let(:params)              { {'action_proxy'=> 'cart/item',
                               'product_code' => 'char-aku',
                               'product_id' => '252',
                               'item_qty' => '1'} }
  let(:response_data)       { {cart: {'name': 'SO00042'},
                               set_session: {'cart_id': 42},
                               'content-type' => 'application/json'} }
  let(:response)            { instance_double('Response', body: JSON.dump(response_data), status: 200) }
  let(:session)             { {erp_cart_id: 42} }
  let(:app)                 { ->(env) { [200, env] } }
  let(:erp_service)         { instance_double('ErpService', call: response, parse_response: {'body': response_data})}
  let(:services)            { instance_double('Services', erp: erp_service) }
  let(:middleware)          { described_class.new(app) }



  subject do
    env = env_for('http://models.example.com', {
      'steam.services'        => services,
      'steam.path'            => path,
      'REQUEST_METHOD'        => 'POST',
      'steam.locale'          => 'fr',
      params:                    params,
    })
    env['steam.request'] = Rack::Request.new(env)
    code, env = middleware.call(env)
    env
  end

  context 'Call Post API' do
    let(:path)   { 'invader/cart/item' }

    it 'add item in cart' do
      expect(services.erp).to receive(:call_without_parsing).with(
          'POST', 'cart/item', params).and_return(response)
      is_expected.to eq subject
    end
  end
end
