require 'spec_helper'

RSpec.describe ShopInvader::AlgoliaService do

  let(:indices)     { '[{ "name": "products", "index": "locomotive_shopinvader_product" }, { "name": "categories", "index": "locomotive_shopinvader_category" }]' }
  let(:routes)      { '[]' }
  let(:metafields)  { {
    'algolia' => {
      'application_id'  => ENV['ALGOLIA_APP_ID'],
      'api_key'         => ENV['ALGOLIA_API_KEY'],
      'indices'         => indices,
      'routes'          => routes
    },
    'erp' => { 'default_pricelist' => 'public_tax_inc' }
  } }
  let(:site)      { instance_double('Site', metafields: metafields, locales: ['en']) }
  let(:customer)  { nil }
  let(:locale)    { 'fr' }
  let(:service)   { described_class.new(site, customer, locale) }

  describe '#find_all_products_and_categories' do

    let(:routes)      { '[["*", { "index": "categories" } ], ["*", {"index": "products" } ]]'}

    subject { service.find_all_products_and_categories }

    it 'returns all the products and categories in all the site locales' do
      expect(subject.size).to eq(78)
      expect(subject.first.keys).to eq(['en'])
      expect(subject.first['en'].keys).to eq([:name, :url])
    end

  end

  describe '#find_all' do
    let(:name)        { 'products' }
    let(:conditions)  { nil }

    subject { service.find_all(name, conditions: conditions) }

    it 'returns the first 20 items by default' do
      expect(subject[:data].size).to eq(20)
      expect(subject[:size]).to eq(71)
    end

    describe 'filtering by one attribute' do

      let(:conditions) { { 'categories' => {'id': 21}, 'main' => true } }

      it 'returns a list filtered by the conditions' do
        expect(subject[:size]).to eq(3)
      end

    end

    describe 'filtering by many attributes (numeric and facet filters)' do

      let(:conditions) { { 'rating' => {'reviews.rating': 5} , 'categories' => {'id': 21}, 'main' => true } }

      it 'returns a list filtered by the conditions' do
        expect(subject[:size]).to eq(2)
      end

    end

  end

  describe '#find_by_key' do

    let(:name)  { 'categories' }
    subject { service.find_by_key(name, key) }

    describe 'looking for a category' do
      let(:key)   { 'all/saleable/accessories' }

      it 'returns an Algolia hit' do
        expect(subject['name']).to eq('Accessories')
        expect(subject['url_key']).to eq('all/saleable/accessories')
      end

      context "the category doesn't exist" do

        let(:key) { 'not-an-existing-category' }

        it 'returns nil' do
          is_expected.to eq nil
        end

      end

      context 'the requested category url looks like an existing one' do

        let(:key) { 'all/saleable/accessories-old' }

        it 'returns nil' do
          is_expected.to eq nil
        end

      end

    end

    describe 'looking for a product' do

      let(:name)  { 'products' }
      let(:key) { 'ipad-retina-display-A2323' }

      it 'returns the product' do
        expect(subject['model_name']).to eq('iPad Retina Display')
        expect(subject['url_key']).to eq(key)
        expect(subject.dig('price', 'value')).to eq(750)
      end

      it 'returns the variants of the product' do
        expect(subject['variants'].size).to eq 2
        expect(subject['variants'][0]['model_name']).to eq 'iPad Retina Display'
        expect(subject['variants'][0]['main']).to eq false
        expect(subject['variants'][0]['objectID']).not_to eq subject.dig(:data, 'objectID')
      end

      context 'the customer is a PRO' do
        let(:customer) { instance_double('Customer', role: 'pro_tax_exc', name: 'John Doe') }

        it 'assigns the product (with different price from a simple visitor) in liquid' do
          expect(subject['model_name']).to eq('iPad Retina Display')
          expect(subject.dig('price', 'value')).to eq(600)
        end

      end

      context 'the customer has no role' do

        let(:customer) { instance_double('Customer', role: nil, name: 'John Doe') }

        it 'uses the public role to assign the product' do
          expect(subject.dig('price', 'value')).to eq(750)
        end

      end

    end

  end

end
