# frozen_string_literal: true

# We only test this with the composite model.
# Since we're just calling the model's own delete method
# we don't really have to care what kind of model we're testing
# as long as the model itself knows how to delete itself.
describe PPPT::Simple::Single::Delete do
  let(:service) { PPPT::Simple::Single::Delete(Composite) }
  let(:instance) { Composite.create(a: 1, b: 1, name: 'foo') }

  it 'is successful' do
    expect(service.new.call(instance)).to be_a_successful_result
  end

  it 'resolves to nil' do
    expect(service.new.call(instance).value!).to be_nil
  end

  it 'calls the model to delete itself' do
    allow(instance).to(receive(:delete))
    service.new.call(instance)
    expect(instance).to(
      have_received(:delete)
    )
  end
end
