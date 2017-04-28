require 'spec_helper'

RSpec.describe ShopInvader::ErpService do

  let(:method)              { 'GET' }
  let(:params)              { {} }
  let(:path)                { 'orders' }
  let(:page)                { 1 }
  let(:per_page)            { 5 }
  let(:conditions)          { nil }
  let(:session)             { nil }
  let(:headers)             { {} }
  let(:erp_response)        { {'data' => [{'name' => 'SO00042'}], 'size' => 1} }
  let(:response)            { instance_double('Response', body: JSON.dump(erp_response)) }
  let(:client)              { instance_double('FaradayClient', get: response, headers: headers) }

  let(:metafields)  { {
    'erp' => {
        'api_url'  => 'http://models.example.com/shopinvader',
        'api_key'  => '42'
     }
  } }
  let(:locale)    { 'fr' }
  let(:customer)  { nil }
  let(:site)      { instance_double('Site', metafields: metafields) }
  let(:service)   { described_class.new(site, session, customer, locale)}

  describe '#call GET' do
    let(:session)   { {'erp_cart_id' => 42} }

    before { allow(service).to receive(:client).and_return(client) }
    subject { service.call(method, path, params) }

    it 'should call the erp with the method, the path and the params' do
      expect(client).to receive(:get).with('orders', params).and_return(response)
      is_expected.to eq(erp_response)
      expect(client.headers['SESS_cart_id']).to eq '42'
    end
  end

  describe '#find all' do
    let(:params)  { {page: 1, per_page: 5} }

    before { allow(service).to receive(:client).and_return(client) }
    subject { service.find_all(path, conditions: conditions, page: page, per_page: per_page) }

    it 'should call the get method on the orders with the params' do
      expect(client).to receive(:get).with('orders', params).and_return(response)
      is_expected.to eq(erp_response)
    end
  end


end
