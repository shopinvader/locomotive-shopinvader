require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::Download do

  let(:app)                 { ->(env) { [200, env, ['Hello world']] } }
  let(:erp_service)         { instance_double('ErpService') }
  let(:services)            { instance_double('Services', erp: erp_service) }
  let(:middleware)          { described_class.new(app) }

  subject { middleware.call(build_env) }

  describe 'incorrect path' do

    let(:path) { '_store/downloa/invoice.pdf' }

    subject { code, _, body = middleware.call(build_env); [code, body] }

    it 'goes to the next middleware' do
      is_expected.to eq [200, ['Hello world']]
    end

  end

  describe 'downloading a file' do

    let(:service) { instance_double('ErpService') }
    let(:path) { '_store/download/subfolder/invoice.pdf' }

    it 'sets the right response headers' do
      expect(erp_service).to receive(:download).with('subfolder/invoice.pdf').and_return(instance_double('Response', {
        headers:  { 'content-type' => 'application/pdf', 'content-length' => 42 },
        body:     'Hello world'
      }))
      expect(subject[1]['Content-Type']).to eq 'application/pdf'
      expect(subject[1]['Content-Disposition']).to eq 'attachment; filename="invoice.pdf"'
      expect(subject[1]['Content-Length']).to eq 42
      expect(subject[2]).to eq(['Hello world'])
    end

  end

  def build_env
    env_for('http://models.example.com', {
      'steam.path'      => path,
      'steam.services'  => services
    })
  end

end
