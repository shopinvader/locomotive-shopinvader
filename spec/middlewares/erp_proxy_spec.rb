require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::ErpProxy do

  let(:path)                { 'my-product' }
  let(:params)              { {action_proxy: 'cart/item',
                               product_code: 'char-aku',
                               product_id: 252,
                               item_qty: 1} }
  let(:response)            { {cart: {'name': 'SO00042'},
                               set_session: {'cart_id': 42}} }
  let(:session)             { {erp_cart_id: 42} }
  let(:app)                 { ->(env) { [200, env] } }
  let(:erp_service)         { instance_double('ErpService', call: response)}
  let(:services)            { instance_double('Services', erp: erp_service) }
  let(:middleware)          { described_class.new(app) }

  subject do
    env = env_for('http://models.example.com', {
      'steam.services'        => services,
      'steam.path'            => path,
      'rack.request.form_hash'=> params,
      'REQUEST_METHOD'        => 'POST',
      'steam.locale'          => 'fr',
    })
    env['steam.request'] = Rack::Request.new(env)
    code, env = middleware.call(env)
    env
  end

  context 'Call Post API' do
    it 'add item in cart' do
      expect(services.erp).to receive(:call).with(
        'POST', 'cart/item', params).and_return(response)
      is_expected.to eq(response)
      expect(subject['rack.session']['erp_cart_id']).to eq(42)
    end
  end
end
