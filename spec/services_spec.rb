require 'spec_helper'

RSpec.describe Locomotive::Steam::Services do

  let(:request) { instance_double('Request', env: {}) }
  let(:site) { instance_double('Site',
      metafields: { 'algolia' => { 'application_id' => '42', 'api_key' => '42' } },
      metafields_schema: [{ 'name' => 'algolia'}]
  ) }

  before do
    allow_any_instance_of(Locomotive::Steam::SiteFinderService).to receive(:find).and_return(site)
  end

  subject { Locomotive::Steam::Services.build_instance(request) }

  it 'adds Algolia as a new service' do
    expect(subject.algolia).not_to be nil
    expect(subject.algolia).to be_an_instance_of(ShopInvader::AlgoliaService)
  end

end
