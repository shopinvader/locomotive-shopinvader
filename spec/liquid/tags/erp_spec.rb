require 'spec_helper'

describe Locomotive::Steam::Liquid::Tags::Consume do

  let(:method)    { 'get' }
  let(:source)    { "{% erp #{method} sale_order %}" }
  let(:session)   { {} }
  let(:assigns)   { {} }
  let(:services)  { build_services_for_erp(session: session) }
  let(:context)   { ::Liquid::Context.new(assigns, {}, { services: services }) }
  let(:response)  { {'name' => 'SO42', 'total' => 42} }
  let(:id)        { 42 }
  let(:params)    { [method.upcase, 'sale_order', nil]}

  subject { render_template(source, context) }

  describe 'validating syntax' do

    before { allow(services.erp).to receive(:call).with(*params).and_return(response) }

    describe 'validates a basic syntax' do
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'validates syntax with result' do
      let(:source)  { '{% erp get sale_order as sale %}' }
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'validates syntax with result and render it' do
      let(:source)  { '{% erp get sale_order as sale %}{{ sale }}' }
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '{"name"=>"SO42", "total"=>42}' }
    end

    describe 'validates syntax with params' do
      let(:source)  { '{% erp get sale_order with 42 %}' }
      let(:params)    { ['GET', 'sale_order', 42]}
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'validates syntax with params and result and render it' do
      let(:source)  { '{% erp get sale_order as sale with 42 %}{{ sale }}' }
      let(:params)    { ['GET', 'sale_order', 42]}
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '{"name"=>"SO42", "total"=>42}' }
    end

    describe 'raises an error if the syntax is incorrect' do
      let(:source)  { '{% erp get as sale with 42 %}{{ sale }}' }
      it { expect { subject }.to raise_exception(Liquid::SyntaxError) }
    end

    describe 'validates a basic syntax with put' do
      let(:method)    { 'put' }
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'validates a basic syntax with post' do
      let(:method)    { 'post' }
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'validates a basic syntax with delete' do
      let(:method)    { 'delete' }
      it { expect { subject }.not_to raise_exception }
      it { is_expected.to eq '' }
    end

    describe 'raises an error if the method is incorrect' do
      let(:method)    { 'foo' }
      it { expect { subject }.to raise_exception(Liquid::SyntaxError) }
    end

  end
end
