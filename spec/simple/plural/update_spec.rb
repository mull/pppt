# frozen_string_literal: true

describe PPPT::Simple::Plural::Update do
  let(:service) { PPPT::Simple::Plural::Update(Composite) }
  let(:instance) { Composite.create(a: 1, b: 2, name: 'foo') }

  it 'is successful' do
    expect(service.new.call([[instance, name: 'bar']])).to be_a_successful_result
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

  context 'when a db update is performed' do
    let(:outcome) { service.new.call([[instance, name: new_name]]).value! }
    let(:new_name) { 'bar' }

    it 'returns instances of its model' do
      expect(outcome).to(
        all(be_instance_of(service.model))
      )
    end
  end

  context 'when no db update is performed' do
    let(:outcome) { service.new.call([[instance, name: current_name]]).value! }
    let(:current_name) { instance.name }

    it 'returns instances of its model' do
      expect(outcome).to(
        all(be_instance_of(service.model))
      )
    end
  end
end
