# frozen_string_literal: true

class CreateChapters < PPPT::Simple::Plural::Create(Chapter); end

class CreateBooksAndChapters < PPPT::OneToMany::Plural::Create(Book)
  create_chapters CreateChapters.new
end

describe PPPT::OneToMany::Plural::Create do
  let(:chapter_double) { instance_double('CreateChapters', call: Success(nil)) }

  let(:service) { CreateBooksAndChapters.new }
  let(:params) do
    [
      {
        name: 'Eloquent Ruby',
        chapters: [
          { name: 'Write clode that looks like Ruby' },
          { name: 'Choose the Right Control Structure' },
          { name: 'Take Advantage of Ruby’s Smart Collections' },
          { name: 'Take Advantage of Ruby’s Smart Strings' },
        ],
      },
      {
        name: 'Ruby under a microscope',
        chapters: [
          { name: 'Tokenization and Parsing' },
          { name: 'Compilation' },
          { name: 'How Ruby Executes Your Code' },
        ],
      },
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
    books = service.call(params).value!
    expect(
      books.map { |b| b.chapters_dataset.count }
    ).to eq([4, 3])
  end

  it 'ignores when given invalid keys' do
    expect { service.call([{ _i_do_not_exist: 1 }]) }.to raise_error(PPPT::InvalidKeyError)
  end
end
