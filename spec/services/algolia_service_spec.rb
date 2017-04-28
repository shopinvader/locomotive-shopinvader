require 'spec_helper'

RSpec.describe ShopInvader::AlgoliaService do

  let(:roles)       { {} }
  let(:metafields)  { {
    'algolia' => {
      'application_id'  => 'ID7BZRXF2I',
      'api_key'         => 'ce69775382075f4a2ade09b0aa1b0277'
    }.merge(roles)
  } }
  let(:site)      { instance_double('Site', metafields: metafields) }
  let(:customer)  { nil }
  let(:locale)    { 'fr' }
  let(:service)   { described_class.new(site, customer, locale) }

  describe '#find_all' do

    let(:roles)       { { 'public_role' => '[{ "name": "product", "index": "public_tax_inc", "template_handle": "product" }]' } }
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

  describe '#find_by_key_among_indices' do

    subject { service.find_by_key_among_indices(key) }

    context 'looking for a category' do

      let(:roles) { { 'public_role' => '[{ "name": "category", "index": "category", "template_handle": "category-template" }]' } }
      let(:key)   { 'accessoires-telephones-portables-et-tablettes' }

      it 'returns the category and the information attached to the matching index' do
        expect(subject[:name]).to eq('category')
        expect(subject[:template]).to eq('category-template')
        expect(subject.dig(:data, 'name')).to eq('Téléphones Portables et Tablettes')
        expect(subject.dig(:data, 'url_key')).to eq('accessoires-telephones-portables-et-tablettes')
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

    context 'looking for a product' do

      let(:roles) { {
        'public_role' => '[
          { "name": "product", "index": "public_tax_exc", "template_handle": "product" }
        ]',
        'pro_role' => '[
          { "name": "product", "index": "pro_tax_exc", "template_handle": "product" }
        ]'
      } }
      let(:key) { 'adaptateur-prise-anglaise-us-tronic' }

      it 'returns the product' do
        expect(subject.dig(:data, 'name')).to eq('Adaptateur Prise Anglaise')
        expect(subject.dig(:data, 'url_key')).to eq('adaptateur-prise-anglaise-us-tronic')
        expect(subject.dig(:data, 'pricelist', 'values')[0]['price']).to eq(14.91)
      end

      it 'returns the variants of the product' do
        expect(subject.dig(:data, 'variants').size).to eq 6
        expect(subject.dig(:data, 'variants')[0]['name']).to eq 'Adaptateur Prise Anglaise'
        expect(subject.dig(:data, 'variants')[0]['objectID']).not_to eq subject.dig(:data, 'objectID')
      end

      context 'the customer is a PRO' do

        let(:customer) { { 'name' => 'John Doe', 'role' => 'pro' } }

        it 'assigns the product (with different price from a simple visitor) in liquid' do
          expect(subject.dig(:data, 'name')).to eq('Adaptateur Prise Anglaise')
          expect(subject.dig(:data, 'pricelist', 'values')[0]['price']).to eq(12.91)
        end

      end

      context 'the customer has no role' do

        let(:customer) { { 'name' => 'John Doe' } }

        it 'uses the public role to assign the product' do
          expect(subject.dig(:data, 'pricelist', 'values')[0]['price']).to eq(14.91)
        end

      end

    end

  end

end
