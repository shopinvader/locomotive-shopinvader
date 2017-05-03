require 'spec_helper'

RSpec.describe ShopInvader::ErpService do

  let(:method)              { 'GET' }
  let(:path)                { 'orders' }
  let(:page)                { 1 }
  let(:per_page)            { 5 }
  let(:params)              { {domain: conditions, page: page, per_page: per_page} }
  let(:conditions)          { nil }
  let(:session)             { nil }
  let(:expected_session)    { session }
  let(:headers)             { {} }
  let(:data)                { {'name' => 'SO00042'} }
  let(:erp_response)        { {'data' => data, 'size' => 1} }
  let(:parsed_response)     { {data: data, size: 1} }
  let(:jsondata )           { JSON.dump(data) }
  let(:client)              { instance_double('FaradayClient', get: response, headers: headers) }
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
    let(:session)              { {'erp_cart_id' => 42} }

    before { allow(service).to receive(:client).and_return(client) }
    subject { service.call(method, path, params) }

    context "The result is not cache in session" do
      it 'should call the erp with the method, the path and the params' do
        expect(client).to receive(:get).with('orders', params).and_return(response)
        is_expected.to eq(parsed_response)
        expect(client.headers['SESS_cart_id']).to eq '42'
        expect(session).to eq(expected_session)
      end
    end

    context "The result is ask for storing it" do
      let(:expected_session)   { {'erp_cart_id' => 42, 'store_cart' => jsondata} }
      let(:erp_response)       { {'data' => {'name' => 'SO00042'},
                                  'size' => 1,
                                  'store_data' => 'cart'} }

      it 'should call the erp and store the data in the session' do
        expect(client).to receive(:get).with('orders', params).and_return(response)
        is_expected.to eq(parsed_response)
        expect(session).to eq(expected_session)
      end
    end

  end

  describe '#read_from_cache' do
    before { allow(service).to receive(:client).and_return(client) }
    subject { service.read_from_cache(path) }

    context "Get the result from session storage" do
      let(:path)               { 'cart' }
      let(:session)            { {'erp_cart_id' => 42, 'store_cart' => jsondata} }

      it 'should read the data from the session' do
        expect(subject).to eq(data)
      end
    end
  end

  describe '#find all' do
    before { allow(service).to receive(:client).and_return(client) }
    subject { service.find_all(path, conditions: conditions, page: page, per_page: per_page) }

    it 'should call the get method on the orders with the params' do
      expect(client).to receive(:get).with('orders', params).and_return(response)
      is_expected.to eq(parsed_response)
    end

    describe 'filtering by string, boolean, float' do

      let(:conditions) { { 'name' => 'SO0042', 'shipped' => true, 'amount.gt' => 42} }

      it 'should call the erp with the domain in the params' do
        expect(client).to receive(:get).with('orders', params).and_return(response)
        is_expected.to eq(parsed_response)
      end

    end
  end

end
