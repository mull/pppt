# frozen_string_literal: true

describe PPPT::Simple::Single::Delete do
  shared_examples_for 'plural deletion' do
    it 'is successful' do
      expect(service.new.call(instances)).to be_a_successful_result
    end

    it 'resolves to the number of rows deleted' do
      expect(service.new.call(instances).value!).to be(2)
    end

    it 'deletes the rows' do
      service.new.call(instances)
      instances.each do |instance|
        expect { instance.reload }.to raise_error(Sequel::NoExistingObject)
      end
    end
  end

  describe 'for simple primary keys' do
    let(:service) { PPPT::Simple::Plural::Delete(Simple) }
    let(:instances) do
      [
        Simple.create(name: 'foo'),
        Simple.create(name: 'foo'),
      ]
    end

    it_behaves_like 'plural deletion'
  end

  describe 'for composite primary keys' do
    let(:service) { PPPT::Simple::Plural::Delete(Composite) }
    let(:instances) do
      [
        Composite.create(a: 1, b: 1, name: 'foo'),
        Composite.create(a: 2, b: 2, name: 'foo'),
      ]
    end

    it_behaves_like 'plural deletion'
  end
end
