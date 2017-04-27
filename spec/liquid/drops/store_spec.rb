require 'spec_helper'

describe ShopInvader::Liquid::Drops::Store do

  let(:roles)     { {} }
  let(:services)  { build_services_for_algolia(roles: roles) }
  let(:context)   { ::Liquid::Context.new({}, {}, { services: services }) }
  let(:drop)      { described_class.new.tap { |d| d.context = context } }

  describe 'asking for an algolia collection' do

    it { expect(drop.before_method('category')).to eq nil }

    context "the collection exists" do

      let(:roles) { { 'public_role' => '[{"name": "category" }]' } }

      it { expect(drop.before_method('category')).to be_an_instance_of(ShopInvader::Liquid::Drops::AlgoliaCollection) }

    end

  end

end
