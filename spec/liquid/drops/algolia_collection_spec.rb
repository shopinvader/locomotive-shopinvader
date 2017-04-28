require 'spec_helper'

describe ShopInvader::Liquid::Drops::AlgoliaCollection do

  let(:services)  { build_services_for_algolia(roles: {}) }
  let(:context)   { ::Liquid::Context.new({}, {}, { services: services }) }
  let(:drop)      { described_class.new('product').tap { |d| d.context = context } }

  describe '#total_entries' do

    subject { drop.total_entries }

    it 'calls the algolia service to return the collection' do
      expect(services.algolia).to receive(:find_all).with('product',
        conditions: nil,
        page: 0,
        per_page: 20).and_return(size: 42, data: %w(a b c))
      is_expected.to eq(42)
    end

  end

  describe '#first' do

    subject { drop.first }

    it 'grabs the first element of the collection (Algolia index)' do
      expect(services.algolia).to receive(:find_all).and_return(size: 42, data: %w(a b c))
      is_expected.to eq('a')
    end

  end

  describe '#size' do

    subject { drop.size }

    it 'calls the algolia service to get the size of the collection' do
      expect(services.algolia).to receive(:find_all).and_return(size: 42, data: %w(a b c))
      is_expected.to eq(3)
    end

  end

  describe '#paginate' do

    subject { drop.send(:paginate, 1, 4) }

    it 'calls the algolia service to get a paginated list' do
      expect(services.algolia).to receive(:find_all).with('product',
        conditions: nil,
        page: 0,
        per_page: 4).and_return('paginated list')
      is_expected.to eq('paginated list')
    end

  end

end
