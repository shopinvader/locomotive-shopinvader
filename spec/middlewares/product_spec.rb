require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::Product do

  let(:roles)       { {} }
  let(:metafields)  { {
    'algolia' => {
      'application_id'  => 'ID7BZRXF2I',
      'api_key'         => 'ce69775382075f4a2ade09b0aa1b0277'
    }.merge(roles)
  } }

  let(:customer)        { nil }
  let(:template)        { nil }
  let(:site)            { instance_double('Site', default_locale: 'en', metafields: metafields) }
  let(:page)            { instance_double('Page', not_found?: true) }
  let(:service)         { instance_double('PageFinder', by_handle: template) }
  let(:app)             { ->(env) { [200, env] } }
  let(:middleware)      { described_class.new(app) }

  before do
    allow_any_instance_of(described_class).to receive(:page_finder).and_return(service)
  end

  subject do
    env = env_for('http://models.example.com', {
      'steam.site'            => site,
      'steam.page'            => page,
      'steam.path'            => path,
      'steam.locale'          => 'fr',
      'steam.liquid_assigns'  => {},
      'authenticated_entry'   => customer
    })
    code, env = middleware.call(env)
    env
  end

  context 'looking for a category' do

    let(:roles)     { { 'public_role' => '[{ "name": "category", "index": "category", "template_handle": "category" }]' } }
    let(:template)  { instance_double('Template', title: 'Category template', not_found?: false) }
    let(:path)      { 'accessoires-telephones-portables-et-tablettes' }

    it 'assigns the category in liquid' do
      expect(subject['steam.liquid_assigns'].dig('category', 'name')).to eq('Téléphones Portables et Tablettes')
      expect(subject['steam.liquid_assigns'].dig('category', 'url_key')).to eq('accessoires-telephones-portables-et-tablettes')
    end

    it 'finds the page used as a template' do
      expect(subject['steam.page'].title).to eq 'Category template'
      expect(subject['steam.page'].not_found?).to eq false
    end

    context "the template doesn't exist" do

      let(:template) { nil }

      it 'renders the 404 page' do
        expect(subject['steam.page'].not_found?).to eq true
      end

    end

    context "the category doesn't exist" do

      let(:path) { 'not-an-existing-category' }

      it 'renders the 404 page' do
        expect(subject['steam.page'].not_found?).to eq true
      end

    end

    context 'the request category url looks like an existing one' do

      let(:path) { 'accessoires-telephones-portables-et-tablettes-old' }

      it 'renders the 404 page' do
        expect(subject['steam.page'].not_found?).to eq true
      end

    end

  end

  context 'looking for a product' do

    let(:roles)     { {
      'public_role' => '[
        { "name": "product", "index": "public_tax_exc", "template_handle": "product" }
      ]',
      'pro_role' => '[
        { "name": "product", "index": "pro_tax_exc", "template_handle": "product" }
      ]'
    } }
    let(:template)  { instance_double('Template', title: 'Product template', not_found?: false) }
    let(:path)      { 'adaptateur-prise-anglaise-us-tronic' }

    it 'assigns the product in liquid' do
      expect(subject['steam.liquid_assigns'].dig('product', 'name')).to eq('Adaptateur Prise Anglaise')
      expect(subject['steam.liquid_assigns'].dig('product', 'url_key')).to eq('adaptateur-prise-anglaise-us-tronic')
      expect(subject['steam.liquid_assigns'].dig('product', 'pricelist', 'values')[0]['price']).to eq(14.91)
    end

    it 'finds the page used as a template' do
      expect(subject['steam.page'].title).to eq 'Product template'
      expect(subject['steam.page'].not_found?).to eq false
    end

    context 'the customer is a PRO' do

      let(:customer) { { 'name' => 'John Doe', 'role' => 'pro' } }

      it 'assigns the product (with different price from a simple visitor) in liquid' do
        expect(subject['steam.liquid_assigns'].dig('product', 'name')).to eq('Adaptateur Prise Anglaise')
        expect(subject['steam.liquid_assigns'].dig('product', 'pricelist', 'values')[0]['price']).to eq(12.91)
      end

    end

    context 'the customer has no role' do

      let(:customer) { { 'name' => 'John Doe' } }

      it 'uses the public role to assign the product' do
        expect(subject['steam.liquid_assigns'].dig('product', 'pricelist', 'values')[0]['price']).to eq(14.91)
      end

    end

  end

end
