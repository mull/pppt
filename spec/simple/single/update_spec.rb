# frozen_string_literal: true

describe PPPT::Simple::Single::Update do
  let(:service) { PPPT::Simple::Single::Update(Composite) }
  let!(:instance) { Composite.create(a: 1, b: 1, name: 'foo') }
  let(:params) { { name: 'bar' } }

  it 'is successful' do
    expect(service.new.call(instance, params)).to be_a_successful_result
  end

  it 'returns an instance of its model' do
    expect(service.new.call(instance, params).value!).to be_instance_of(service.model)
  end

  it 'passes only the values we pass' do
    allow(instance).to(receive(:update))
    service.new.call(instance, params)
    expect(instance).to(
      have_received(:update).with(params)
    )
  end

  it 'raises when given invalid keys' do
    expect { service.new.call(instance, _i_do_not_exist: 1) }.to(
      raise_error(PPPT::InvalidKeyError)
    )
  end

  it 'raises when primary keys are included' do
    expect { service.new.call(instance, a: 2) }.to(
      raise_error(PPPT::InvalidKeyError)
    )
  end

  context 'when a db update is performed' do
    let(:outcome) { service.new.call(instance, name: new_name).value! }
    let(:new_name) { 'bar' }

    it 'returns the updated model' do
      expect(outcome).to be(instance)
    end
  end

  context 'when no db update is performed' do
    let(:outcome) { service.new.call(instance, name: current_name).value! }
    let(:current_name) { 'foo' }

    it 'returns the same model' do
      expect(outcome).to be(instance)
    end
  end
end
