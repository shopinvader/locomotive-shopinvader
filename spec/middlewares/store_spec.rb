require 'spec_helper'

RSpec.describe ShopInvader::Middlewares::Store do

  let(:app)                 { ->(env) { [200, env] } }
  let(:middleware)          { described_class.new(app) }

  subject do
    env = env_for('http://models.example.com', {
      'steam.liquid_assigns'  => {},
    })
    code, env = middleware.call(env)
    env
  end

  it 'adds the store drop to the liquid assigns' do
    expect(subject['steam.liquid_assigns']['store']).to be_an_instance_of(ShopInvader::Liquid::Drops::Store)
  end

end
