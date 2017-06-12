require 'spec_helper'

describe Locomotive::Steam::Liquid::Tags::PathTo do

  let(:prefix_default)  { false }
  let(:assigns)         { {} }
  let(:metafields)      { { 'algolia' => { 'routes' => <<-JSON
      [
        ["*", { "name": "category", "tempate_handle": "category", "index": "categories" } ],
        ["*", { "name": "product", "tempate_handle": "product", "index": "products" } ],
        ["on-sale/*", { "name": "product", "tempate_handle": "on_sale_product", "index": "products" } ]
      ]
    JSON
  } } }
  let(:services)        { Locomotive::Steam::Services.build_instance }
  let(:context)         { ::Liquid::Context.new(assigns, {}, { services: services, site: site, locale: 'en' }) }
  let(:site)            { instance_double('Site', locales: ['en'], default_locale: 'en', prefix_default_locale: prefix_default, metafields: metafields) }

  subject { render_template(source, context) }

  before { allow(services).to receive(:current_site).and_return(site) }

  describe 'from a product' do

    let(:assigns)       { { 'product' => product } }
    let(:product)       { { 'index_name' => 'products', 'url_key' => 'ipad-pro', 'name' => 'New shiny iPad pro' } }
    let(:source)        { '{% path_to product %}' }

    it { is_expected.to eq '/ipad-pro' }

    context 'with a different template' do

      let(:source) { "{% path_to product, with: on_sale_product %}" }
      it { is_expected.to eq '/on-sale/ipad-pro' }

    end

  end

  describe 'from a category' do

    let(:assigns)       { { 'category' => category } }
    let(:category)      { { 'index_name' => 'categories', 'url_key' => 'tablets', 'name' => 'Tablets' } }
    let(:source)        { '{% path_to category %}' }

    it { is_expected.to eq '/tablets' }

  end

end
