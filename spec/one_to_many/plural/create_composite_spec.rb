# frozen_string_literal: true

class CreateCompositeChildren < PPPT::Simple::Plural::Create(CompositeChild); end

class CreateCompositesAndChildren < PPPT::OneToMany::Plural::Create(Composite)
  create_composite_children CreateCompositeChildren.new
end

describe PPPT::OneToMany::Plural::Create do
  let(:service) { CreateCompositesAndChildren.new }
  let(:params) do
    [
      {
        a: 1,
        b: 2,
        name: 'composite 1',
        composite_children: [
          {
            name: 'child 1',
          },
          {
            name: 'child 2',
          },
        ],
      },
      {
        a: 2,
        b: 1,
        name: 'composite 2',
        composite_children: [
          { name: 'child 1' }
        ]
      }
    ]
  end

  it 'is successful' do
    expect(service.call(params)).to be_a_successful_result
  end

  it 'creates the base models' do
    service.call(params)
    expect(service.model.count).to eq(params.length)
  end

  it 'returns arrays of its model' do
    expect(service.call(params).value!).to all(be_instance_of(service.model))
  end

  it 'creates the associated records' do
    composites = service.call(params).value!
    expect(
      composites.map { |b| b.composite_children_dataset.count }
    ).to eq([2, 1])
  end
end
