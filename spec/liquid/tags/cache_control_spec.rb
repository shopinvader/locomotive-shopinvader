require 'spec_helper'

describe Locomotive::Steam::Liquid::Tags::Consume do

  let(:source)    { "{% cache_control 'mykey' %}" }
  let(:env)       { {} }
  let(:cache)     { {} }
  let(:site)      { instance_double('Site', { metafields: { cache: cache } }) }
  let(:request)   { instance_double('Request', env: env) }
  let(:context)   { ::Liquid::Context.new({}, {}, { request: request, site: site }) }

  subject { render_template(source, context) }

  describe 'validating syntax' do

    describe 'Setting cache control' do
      it 'It set nil by default' do
        expect { subject }.not_to raise_exception
        expect(env).to include 'steam.cache_control'
        expect(env['steam.cache_control']).to eq nil
      end

      context "with cache configured" do
        let(:cache)     { { 'mykey' => 10} }
        it 'It set nil by default' do
          expect { subject }.not_to raise_exception
          expect(env).to include 'steam.cache_control'
          expect(env['steam.cache_control']).to eq "max-age=0,s-maxage=10"
        end
      end
    end

    describe 'Configure vary' do
      it 'It nothing by default' do
        expect { subject }.not_to raise_exception
        expect(env).not_to include 'steam.cache_vary'
      end

      context 'it set the value local and currency' do
        let(:source)    { "{% cache_control 'mykey' vary 'local', 'currency' %}" }
        it 'It set not cache vary' do
          expect { subject }.not_to raise_exception
          expect(env).to include 'steam.cache_vary'
          expect(env['steam.cache_vary']).to eq ['local', 'currency']
        end
      end
    end
  end
end
