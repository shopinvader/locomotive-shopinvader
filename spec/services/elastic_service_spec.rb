require 'spec_helper'

RSpec.describe ShopInvader::ElasticService do

  let(:metafields)  { { 'elasticsearch' => { 'url' => 'http://elastic' }} }
  let(:metafields_schema) { [{'name' => 'elasticsearch'}] }
  let(:site)      { instance_double('Site', metafields: metafields, metafields_schema: metafields_schema, locales: ['en']) }
  let(:customer)  { nil }
  let(:locale)    { 'fr' }
  let(:service)   { described_class.new(site, customer, locale) }

  describe 'Test if it is configured' do

    subject { service.send(:is_configured?) }

    context "Elasticsearch is configured" do
      it 'returns True (configured)' do
        expect(subject).to eq(true)
      end
    end

    context "Elasticsearch is configured but metafield is missing" do
      let(:metafields_schema) { [] }

      it 'returns False (not configured)' do
        expect(subject).to eq(false)
      end
    end

    context "Elasticsearch is not configured but metafield exist" do
      let(:metafields)  { {} }
      it 'returns False (not configured)' do
        expect(subject).to eq(false)
      end
    end

    context "Elasticsearch is empty but metafield exist" do
      let(:metafields)  { {'elasticsearch' => {'url' => ''}} }
      it 'returns False (not configured)' do
        expect(subject).to eq(false)
      end
    end

  end

  describe '#build_index_name for local fr' do

    subject { service.send(:build_index_name, 'shopinvader_variant', 'fr') }

    it 'returns the index with the lang fr_FR' do
      expect(subject).to eq('shopinvader_variant_fr_fr')
    end

    context "with specific lang mapping for Belgium" do

      let(:metafields) { {'_store' => {'locale_mapping' => '{"fr": "fr_be"}'}} }

      it 'return the index with the lang fr_be' do
        expect(subject).to eq('shopinvader_variant_fr_be')
      end

    end
  end

  describe 'Building params from condition' do
    subject { service.send(:build_params, conditions) }

    context "with numeric filter" do
      let(:conditions) { { 'categories_ids' => 5 } }

      it 'returns 1 term filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:term=>{"categories_ids"=>5}}], :must_not=>[]})
      end
    end

    context "with nested numeric filter" do
      let(:conditions) { { 'categories' => {'id': 5} } }

      it 'returns 1 term filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:term=>{"categories.id"=>5}}], :must_not=>[]})
      end
    end

    context "with nested in" do
      let(:conditions) { { 'attributes.in' => {'color': ['red', 'yellow'] } } }

      it 'returns 1 terms filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:terms=>{"attributes.color"=>["red", "yellow"]}}], :must_not=>[]})
      end
    end

    context "with nested facet filter" do
      let(:conditions) { { 'attributes' => {'color': 'red'} } }

      it 'returns 1 term filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:term=>{"attributes.color"=>"red"}}], :must_not=>[]})
      end
    end

    context "with nested not equal" do
      let(:conditions) { { 'attributes.ne' => {'color': 'red'} } }

      it 'returns 1 must not filter"' do
        expect(subject).to eq(:bool => {:filter=>[], :must_not=>[{:term=>{"attributes.color"=>"red"}}]})
      end
    end

    context "with nested not in" do
      let(:conditions) { { 'attributes.nin' => {'color': ['red', 'yellow'] } } }

      it 'returns 2 must not filter"' do
        expect(subject).to eq(:bool => {:filter=>[], :must_not=>[{:term=>{"attributes.color"=>"red"}}, {:term=>{"attributes.color"=>"yellow"}}]})
      end
    end

    context "with nested comparator" do
      let(:conditions) { { 'price.gt' => {'value': 10} } }

      it 'returns 1 range filter with comparator"' do
        expect(subject).to eq(:bool => {:filter=>[{:range=>{"price.value"=>{"gt"=>10}}}], :must_not=>[]})
      end
    end

    context "with nested range" do
      let(:conditions) { { 'price.gt' => {'value': 10}, 'price.lt' => {'value': 30} } }

      it 'returns 2 range filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:range=>{"price.value"=>{"gt"=>10}}}, {:range=>{"price.value"=>{"lt"=>30}}}], :must_not=>[]})
      end
    end

    context "with all" do
      let(:conditions) { { 'attributes.nin' => {'color': ['red', 'yellow'] },'categories' => {'id': 5} , 'attributes' => {'color': 'red'},  'price.gt' => { 'value': 10 } } }

      it 'returns all filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:term=>{"categories.id"=>5}}, {:term=>{"attributes.color"=>"red"}}, {:range=>{"price.value"=>{"gt"=>10}}}], :must_not=>[{:term=>{"attributes.color"=>"red"}}, {:term=>{"attributes.color"=>"yellow"}}]})
      end
    end

    context "with raw query" do
     let(:conditions) { { 'raw_es_query' => {:bool => {:filter=>[{:terms=>{"attributes.color"=>["red", "yellow"]}}]} } } }

      it 'returns 2 range filter"' do
        expect(subject).to eq(:bool => {:filter=>[{:terms=>{"attributes.color"=>["red", "yellow"]}}]} )
      end
    end

  end
end
