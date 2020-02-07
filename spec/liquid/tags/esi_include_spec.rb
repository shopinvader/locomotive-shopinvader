require 'spec_helper'

describe Locomotive::Steam::Liquid::Tags::EsiSnippet do

  let(:locale)          { :en }
  let(:source)          { "{% esi_include 'foo' %}" }
  let(:services)        { Locomotive::Steam::Services.build_instance }
  let(:prefix_default)  { false }
  let(:site)            { instance_double('Site', default_locale: 'en', prefix_default_locale: prefix_default) }
  let(:assigns)         { {} }
  let(:context)         { ::Liquid::Context.new(assigns, {}, { services: services, site: site, locale: locale }) }

  subject { render_template(source, context) }

  describe 'Should render esi tag' do
    ENV['WAGON_ESI'] = 'true'
    it { is_expected.to eq "<esi:include src=\"/snippet/foo\"/>" }

    context 'With specific fr lang' do
      let(:locale)    { :fr }
      it { is_expected.to eq "<esi:include src=\"/fr/snippet/foo\"/>" }
    end

    context 'With prefix default lang activated' do
      let(:prefix_default)  { :en }
      it { is_expected.to eq "<esi:include src=\"/en/snippet/foo\"/>" }
    end

    context 'With a dynamic snippet name' do
      let(:assigns)    { {'dynamic' => 'bar' }}
      let(:source)     { "{% esi_include dynamic %}" }
      it { is_expected.to eq "<esi:include src=\"/snippet/bar\"/>" }
    end
  end
end
