# frozen_string_literal: true

describe PPPT::Simple::Plural::Create do
  let(:service) { PPPT::Simple::Plural::Create(Simple) }
  let(:dataset) do
    dataset = instance_double(Sequel::Dataset)
    allow(dataset).to(receive(:returning)).and_return(dataset)
    dataset
  end

  it 'is successful' do
    expect(service.new.call([name: 'foo'])).to be_success
  end

  it 'returns instances of its model' do
    expect(service.new.call([name: 'foo']).value!).to all(be_instance_of(Simple))
  end

  it 'raises when given invalid keys' do
    expect { service.new.call([_i_do_not_exist: 1]) }.to raise_error(PPPT::InvalidKeyError)
  end

  describe 'key consistency' do
    before do
      allow(Simple).to(receive(:dataset).and_return(dataset))
      allow(dataset).to(receive(:multi_insert)).and_return([])
    end

    it 'includes default values' do
      service.new.call([name: 'foo'])
      expect(dataset).to(have_received(:multi_insert).with([{ name: 'foo', labor_hours: 0 }]))
    end

    it 'sets nil when there are key discrepancies and no default values' do
      service.new.call([{ name: 'foo', foo: 'bla' }, { name: 'bar' }])
      expect(dataset).to(
        have_received(:multi_insert).with([
                                            { name: 'foo', labor_hours: 0, foo: 'bla' },
                                            { name: 'bar', labor_hours: 0, foo: nil },
                                          ])
      )
    end
  end
end
