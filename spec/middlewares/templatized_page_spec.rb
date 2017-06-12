require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::TemplatizedPage do

  let(:metafields) { { 'algolia' => { 'routes' => <<-JSON
      [
        ["cart/*", { "name": "product", "template_handle": "product_in_cart", "index": "products" }],
        ["*", { "name": "category", "tempate_handle": "category", "index": "categories" } ],
        ["*", { "name": "product", "tempate_handle": "product", "index": "products" } ]
      ]
    JSON
  } } }
  let(:indices)             { [{ "name": "product", "index": "public_tax_inc"}] }
  let(:resource)            { nil }
  let(:customer)            { nil }
  let(:template)            { nil }
  let(:site)                { instance_double('Site', metafields: metafields) }
  let(:page)                { instance_double('Page', not_found?: true) }
  let(:services)            { instance_double('Services', page_finder: page_finder_service) }
  let(:page_finder_service) { instance_double('PageFinder', by_handle: template) }
  let(:algolia_service)     { instance_double('AlgoliaService', find_by_key: resource) }
  let(:services)            { instance_double('Services', page_finder: page_finder_service, algolia: algolia_service) }
  let(:path)                { 'algolia-product-or-category-key' }
  let(:app)                 { ->(env) { [200, env] } }
  let(:middleware)          { described_class.new(app) }

  subject do
    code, env = middleware.call(build_env)
    env
  end

  context 'the resource exists' do

    let(:template)  { instance_double('Template', title: 'Category template', not_found?: false, fullpath: '/template/category') }
    let(:resource)  { { 'name' => 'Téléphones Portables et Tablettes' } }

    it 'assigns the category in liquid' do
      expect(subject['steam.liquid_assigns'].dig('category', 'name')).to eq('Téléphones Portables et Tablettes')
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

    context 'the path matches one of the redirect_url_key but not the url_key itself' do

      let(:resource)  { {
        'name'    => 'Téléphones Portables et Tablettes',
        'url_key' => 'new-algolia-product-or-category-key',
        'redirect_url_key' => ['algolia-product-or-category-key']
      } }

      subject do
        code, env = middleware.call(build_env)
        [code, env['Location']]
      end

      it 'redirects to the url_key (301)' do
        is_expected.to eq [301, '/new-algolia-product-or-category-key']
      end

    end

    context 'the url_key includes slashes' do

      let(:path)      { 'new/algolia-product-url-key' }
      let(:resource)  { {
        'name'    => '[NEW] Téléphones Portables et Tablettes',
        'url_key' => 'new/algolia-product-url-key',
        'redirect_url_key' => []
      } }

      it 'assigns the category in liquid' do
        expect(subject['steam.liquid_assigns'].dig('category', 'name')).to eq('[NEW] Téléphones Portables et Tablettes')
      end

    end

  end

  context "the resource doesn't exist" do

    it 'renders the 404 page' do
      expect(subject['steam.page'].not_found?).to eq true
    end

  end

  def build_env
    env_for('http://models.example.com', {
      'steam.services'        => services,
      'steam.site'            => site,
      'steam.page'            => page,
      'steam.path'            => path,
      'steam.locale'          => 'fr',
      'steam.liquid_assigns'  => {},
      'authenticated_entry'   => customer
    }).tap do |env|
      env['steam.request'] = Rack::Request.new(env)
    end
  end

end
