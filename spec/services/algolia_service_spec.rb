require 'spec_helper'

RSpec.describe ShopInvader::AlgoliaService do

  let(:indices)     { '[]' }
  let(:metafields)  { {
    'algolia' => {
      'application_id'  => 'ID7BZRXF2I',
      'api_key'         => 'ce69775382075f4a2ade09b0aa1b0277',
      'indices'         => indices,
    }
  } }
  let(:site)      { instance_double('Site', metafields: metafields, locales: ['en']) }
  let(:customer)  { nil }
  let(:locale)    { 'fr' }
  let(:service)   { described_class.new(site, customer, locale) }

  describe '#find_all_products_and_categories' do

    let(:indices)     { '[{ "name": "products", "index": "spacediscount_product" }, { "name": "categories", "index": "spacediscount_category" }]' }
    let(:routes)      { '[["*", { "index": "categories" } ], ["*", {"index": "products" } ]]'}
    let(:metafields)  { {
      'algolia' => {
        'application_id'  => 'GH41KF783Z',
        'api_key'         => '75575d3910b3ac55428bcdfa1b0e6784',
        'indices'         => indices,
        'routes'          => routes
      }
    } }

    subject { service.find_all_products_and_categories }

    it 'returns all the products and categories in all the site locales' do
      expect(subject.size).to eq(69)
      expect(subject.first.keys).to eq(['en'])
      expect(subject.first['en'].keys).to eq([:name, :url])
    end

  end

  describe '#find_all' do

    let(:indices)       { '[{ "name": "product", "index": "public_tax_inc"}]' }
    let(:name)        { 'product' }
    let(:conditions)  { nil }

    subject { service.find_all(name, conditions: conditions) }

    it 'returns the first 20 items by default' do
      expect(subject[:data].size).to eq(20)
      expect(subject[:size]).to eq(198)
    end

    describe 'filtering by one attribute' do

      let(:conditions) { { 'categories_ids.in' => [590, 588], 'main' => true } }

      it 'returns a list filtered by the conditions' do
        expect(subject[:size]).to eq(3)
      end

    end

    describe 'filtering by many attributes (numeric and facet filters)' do

      let(:conditions) { { 'rating_value' => 5, 'categories_ids.in' => [590, 588], 'main' => true } }

      it 'returns a list filtered by the conditions' do
        expect(subject[:size]).to eq(1)
      end

    end

  end

  describe '#find_by_key' do

    subject { service.find_by_key(name, key) }

    describe 'looking for a category' do

      let(:name)  { 'category' }
      let(:indices) { '[{ "name": "category", "index": "category"}]' }
      let(:key)   { 'accessoires-telephones-portables-et-tablettes' }

      it 'returns an Algolia hit' do
        expect(subject['name']).to eq('Téléphones Portables et Tablettes')
        expect(subject['url_key']).to eq('accessoires-telephones-portables-et-tablettes')
      end

      context "the category doesn't exist" do

        let(:key) { 'not-an-existing-category' }

        it 'returns nil' do
          is_expected.to eq nil
        end

      end

      context 'the requested category url looks like an existing one' do

        let(:key) { 'accessoires-telephones-portables-et-tablettes-old' }

        it 'returns nil' do
          is_expected.to eq nil
        end

      end

    end

    describe 'looking for a product' do

      let(:name) { 'product' }
      let(:indices) { '[{ "name": "product", "index": "public_tax_exc"}]' }
      let(:key) { 'adaptateur-prise-anglaise-us-tronic' }

      it 'returns the product' do
        expect(subject['name']).to eq('Adaptateur Prise Anglaise')
        expect(subject['url_key']).to eq('adaptateur-prise-anglaise-us-tronic')
        expect(subject.dig('pricelist', 'values')[0]['price']).to eq(14.91)
      end

      it 'returns the variants of the product' do
        expect(subject['variants'].size).to eq 6
        expect(subject['variants'][0]['name']).to eq 'Adaptateur Prise Anglaise'
        expect(subject['variants'][0]['objectID']).not_to eq subject.dig(:data, 'objectID')
      end

      context 'the customer is a PRO' do

        let(:customer) { { 'name' => 'John Doe', 'role' => 'pro' } }

        it 'assigns the product (with different price from a simple visitor) in liquid' do
          expect(subject['name']).to eq('Adaptateur Prise Anglaise')
          expect(subject.dig('pricelist', 'values')[0]['price']).to eq(12.91)
        end

      end

      context 'the customer has no role' do

        let(:customer) { { 'name' => 'John Doe' } }

        it 'uses the public role to assign the product' do
          expect(subject.dig('pricelist', 'values')[0]['price']).to eq(14.91)
        end

      end

    end

  end

  # describe '#find_by_key_among_indices' do

  #   subject { service.find_by_key_among_indices(key) }

  #   context 'looking for a category' do

  #     let(:roles) { { 'public_role' => '[{ "name": "category", "index": "category", "template_handle": "category-template" }]' } }
  #     let(:key)   { 'accessoires-telephones-portables-et-tablettes' }

  #     it 'returns the category and the information attached to the matching index' do
  #       expect(subject[:name]).to eq('category')
  #       expect(subject[:template]).to eq('category-template')
  #       expect(subject.dig(:data, 'name')).to eq('Téléphones Portables et Tablettes')
  #       expect(subject.dig(:data, 'url_key')).to eq('accessoires-telephones-portables-et-tablettes')
  #     end

  #     context "the category doesn't exist" do

  #       let(:key) { 'not-an-existing-category' }

  #       it 'returns nil' do
  #         is_expected.to eq nil
  #       end

  #     end

  #     context 'the requested category url looks like an existing one' do

  #       let(:key) { 'accessoires-telephones-portables-et-tablettes-old' }

  #       it 'returns nil' do
  #         is_expected.to eq nil
  #       end

  #     end

  #   end

  #   context 'looking for a product' do



  # end

end
