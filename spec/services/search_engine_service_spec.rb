require 'spec_helper'

RSpec.describe ShopInvader::SearchEngineService do

  let(:indices)     { '[{ "name": "products", "index": "ci_shopinvader_variant" }, { "name": "categories", "index": "ci_shopinvader_category" }]' }
  let(:routes)      { '[]' }
  let(:metafields)  { {} }
  let(:site)      { instance_double('Site', metafields: metafields, locales: ['en']) }
  let(:customer)  { nil }
  let(:locale)    { 'en' }
  let(:elastic)   { ShopInvader::ElasticService.new(site, customer, locale) }
  let(:algolia)   { ShopInvader::AlgoliaService.new(site, customer, locale) }
  let(:service)   { described_class.new(site, locale, elastic, algolia) }

  ['elastic', 'algolia'].each do | backend |
    describe "# Testing Backend #{backend.titleize}" do

      if backend == 'elastic'

        let(:metafields)  { {
          'erp' => { 'default_role' => 'public_tax_inc' },
          'elasticsearch' => {
            'url'             => 'http://elastic:9200',
            'indices'         => indices,
            'routes'          => routes
            }
          } }

      elsif backend == 'algolia'

        let(:metafields)  { {
          'erp' => { 'default_role' => 'public_tax_inc' },
          'algolia' => {
            'application_id'  => ENV['ALGOLIA_APP_ID'],
            'api_key'         => ENV['ALGOLIA_API_KEY'],
            'indices'         => indices,
            'routes'          => routes
            }
          } }

      end

      describe '#find_all_products_and_categories' do

        let(:routes)      { '[["*", { "index": "categories" } ], ["*", {"index": "products" } ]]'}

        subject { service.find_all_products_and_categories }

        it 'returns all the products and categories in all the site locales' do
          expect(subject.size).to eq(8)
          expect(subject.first.keys).to eq(['en'])
          expect(subject.first['en'].keys).to eq([:name, :url])
        end

      end

      describe '#find_all' do
        let(:name)        { 'products' }
        let(:conditions)  { nil }
        let(:page)        { 0 }
        let(:per_page)    { 20 }

        subject { service.find_all(name, conditions: conditions, page: page, per_page: per_page) }

        it 'returns all the item' do
          expect(subject[:data].size).to eq(5)
          expect(subject[:size]).to eq(5)
        end

        describe 'limit 2 products per page' do
          let(:per_page)    { 2 }

          context 'request the first page' do
            let(:page)        { 0 }
            it 'returns two product' do
              expect(subject[:data].size).to eq(2)
              expect(subject[:size]).to eq(5)
            end
          end

          context 'request the second page' do
            let(:page)        { 1 }
            it 'returns two product' do
              expect(subject[:data].size).to eq(2)
              expect(subject[:size]).to eq(5)
            end
          end

          context 'request the third page' do
            let(:page)        { 2 }
            it 'returns one product' do
              expect(subject[:data].size).to eq(1)
              expect(subject[:size]).to eq(5)
            end
          end

        end

        describe 'filtering by one attribute' do

          let(:conditions) { { 'categories' => {'id': 2}  } }

          it 'returns a list filtered by the conditions' do
            expect(subject[:size]).to eq(4)
          end

        end

        describe 'filtering by many attributes' do

          let(:conditions) { { 'categories' => {'id': 2}, 'main' => true } }

          it 'returns a list filtered by the conditions' do
            expect(subject[:size]).to eq(2)
          end

        end

      end

      describe '#find_by_key' do

        let(:name)  { 'categories' }
        subject { service.find_by_key(name, key) }

        describe 'looking for a category' do
          let(:key)   { 'furniture/living-room' }

          it 'returns an Search Engine hit' do
            expect(subject['name']).to eq('Living room')
            expect(subject['url_key']).to eq('furniture/living-room')
          end

          context "the category doesn't exist" do

            let(:key) { 'not-an-existing-category' }

            it 'returns nil' do
              is_expected.to eq nil
            end

          end

          context 'the requested category url looks like an existing one' do

            let(:key) { 'furniture/living' }

            it 'returns nil' do
              is_expected.to eq nil
            end

          end

          context 'the requested category url is a redirection' do

            let(:key) { 'furniture/living-room-redirect' }

            it 'returns an Search Engine hit' do
              expect(subject['name']).to eq('Living room')
              expect(subject['url_key']).to eq('furniture/living-room')
            end

          end

        end

        describe 'looking for a product' do

          let(:name)  { 'products' }
          let(:key)   { 'mid-century-armchair' }
          let(:customer) { instance_double('Customer', role: 'public_tax_inc', name: 'John Doe') }

          it 'returns the product' do
            expect(subject['name']).to eq('Mid-Century Armchair (Red)')
            expect(subject['url_key']).to eq(key)
            expect(subject.dig('price', 'value')).to eq(60)
          end

          it 'returns the variants of the product' do
            expect(subject['variants'].size).to eq 2
            expect(subject['variants'][0]['name']).to eq 'Mid-Century Armchair (Blue)'
            expect(subject['variants'][0]['main']).to eq false
            expect(subject['variants'][0]['id']).not_to eq subject.dig(:data, 'id')
          end

          context 'the customer have the role public_tax_exc' do
            let(:customer) { instance_double('Customer', role: 'public_tax_exc', name: 'John Doe') }

            it 'assigns the product (with different price from a simple visitor) in liquid' do
              expect(subject['name']).to eq('Mid-Century Armchair (Red)')
              expect(subject.dig('price', 'value')).to eq(50)
            end

          end

          context 'the customer has no role' do

            let(:customer) { instance_double('Customer', role: nil, name: 'John Doe') }

            it 'uses the public tax inc role to assign the product' do
              expect(subject.dig('price', 'value')).to eq(60)
            end

          end

        end

      end

    end
  end
end
