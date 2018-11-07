require 'spec_helper'

describe ShopInvader::Liquid::Drops::ErpItem do

  let(:session)   { {} }
  let(:services)  { build_services_for_erp(session: session) }
  let(:context)   { ::Liquid::Context.new({}, {}, { services: services }) }
  let(:drop)      { described_class.new('cart').tap { |d| d.context = context } }
  let(:response)  { {'name' => 42, 'total' => 300 } }

  describe '#cart' do

    subject { drop }

    it 'calls the erp service to return an item' do
      expect(services.erp).to receive(:call).with('GET', 'cart', nil).and_return(response)
      expect(subject.before_method('name')).to eq 42
      expect(subject.before_method('total')).to eq 300
    end

  end

end
