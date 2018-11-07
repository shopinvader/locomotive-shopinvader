require 'spec_helper'

describe ShopInvader::Liquid::Drops::ErpCollection do

  let(:session)   { {} }
  let(:services)  { build_services_for_erp(session: session) }
  let(:context)   { ::Liquid::Context.new({}, {}, { services: services }) }
  let(:drop)      { described_class.new('orders').tap { |d| d.context = context } }
  let(:response)  { {'size' => 42, 'data' => %w(a b c)} }

  describe '#total_entries' do

    subject { drop.total_entries }

    it 'calls the erp service to return the collection' do
      expect(services.erp).to receive(:find_all).with('orders',
        conditions: nil,
        page: 1,
        per_page: 20).and_return(response)
      is_expected.to eq(42)
    end

  end

  describe '#first' do

    subject { drop.first }

    it 'grabs the first element of the ERP collection' do
      expect(services.erp).to receive(:find_all).and_return(response)
      is_expected.to eq('a')
    end

  end

  describe '#size' do

    subject { drop.size }

    it 'calls the erp service to get the size of the collection' do
      expect(services.erp).to receive(:find_all).and_return(response)
      is_expected.to eq(3)
    end

  end

  describe '#paginate' do

    subject { drop.send(:paginate, 1, 4) }

    it 'calls the erp service to get a paginated list' do
      expect(services.erp).to receive(:find_all).with('orders',
        conditions: nil,
        page: 1,
        per_page: 4).and_return(response)
      is_expected.to eq(response)
    end

  end

end
