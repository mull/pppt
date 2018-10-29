# frozen_string_literal: true

describe PPPT::Simple::Single::Create do
  let(:service) { PPPT::Simple::Single::Create(Composite) }
  let(:params) { { a: 1, b: 1, name: 'foo' } }

  it 'is successful' do
    expect(service.new.call(params)).to be_a_successful_result
  end

  it 'returns an instance of its model' do
    expect(service.new.call(params).value!).to be_instance_of(service.model)
  end

  it 'passes only the values we pass' do
    allow(service.model).to(receive(:create))
    service.new.call(params)
    expect(service.model).to(
      have_received(:create).with(params)
    )
  end

  it 'raises when given invalid keys' do
    expect { service.new.call(_i_do_not_exist: 1) }.to raise_error(PPPT::InvalidKeyError)
  end
end
