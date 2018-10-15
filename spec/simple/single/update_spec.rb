# frozen_string_literal: true

describe PPPT::Simple::Single::Update do
  let(:service) { PPPT::Simple::Single::Update(Composite) }
  let!(:instance) { Composite.create(a: 1, b: 1, name: 'foo') }
  let(:params) { { name: 'bar' } }

  it 'is successful' do
    expect(service.new.call(instance, params)).to be_success
  end

  it 'returns the updated model' do
    expect(service.new.call(instance, name: 'bar').value!).to be(instance)
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
end
