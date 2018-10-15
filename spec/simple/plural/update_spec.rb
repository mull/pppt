# frozen_string_literal: true

describe PPPT::Simple::Plural::Update do
  let(:service) { PPPT::Simple::Plural::Update(Composite) }
  let(:instance) { Composite.create(a: 1, b: 2, name: 'foo') }

  it 'is successful' do
    expect(service.new.call([[instance, name: 'bar']])).to be_success
  end

  it 'returns instances of its model' do
    expect(service.new.call([[instance, name: 'bar']]).value!).to(
      all(be_instance_of(service.model))
    )
  end

  it 'raises when given invalid keys' do
    expect { service.new.call([[instance, _i_do_not_exist: 1]]) }.to(
      raise_error(PPPT::InvalidKeyError)
    )
  end

  it 'raises when primary keys are included' do
    expect { service.new.call([[instance, id: 4]]) }.to(
      raise_error(PPPT::InvalidKeyError)
    )
  end
end
