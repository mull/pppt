# frozen_string_literal: true

describe PPPT::Simple::Plural::Upsert do
  let(:result) { service.new.call(params) }
  let(:value) { result.value! }

  shared_examples_for 'a successful call' do
    it 'is successful' do
      expect(result).to be_success
    end

    it do
      expect(value).to all(be_instance_of(service.model))
    end
  end

  context 'when given constraint' do
    let(:model_params) { [{ name: 'bar', a: 1, b: 1 }, { name: 'foo', a: 2, b: 2}] }

    before { model_params.each { |p| service.model.create(p) } }

    context 'when doing nothing implicitly' do
      class WithConstraintImplicitDoNothing < PPPT::Simple::Plural::Upsert(UniqueConstraint)
        constraint :with_unique_constraint_a_b_key
      end

      let(:params) { model_params }
      let(:service) { WithConstraintImplicitDoNothing }

      it_behaves_like 'a successful call'
    end

    context 'when doing nothing explicitly' do
      class WithConstraintExplicitDoNothing < PPPT::Simple::Plural::Upsert(UniqueConstraint)
        constraint :with_unique_constraint_a_b_key
        do_nothing
      end

      let(:params) { model_params }
      let(:service) { WithConstraintExplicitDoNothing }

      it_behaves_like 'a successful call'
    end

    context 'when updating keys' do
      class WithConstraintDoUpdate < PPPT::Simple::Plural::Upsert(UniqueConstraint)
        constraint :with_unique_constraint_a_b_key
        update :name
      end

      let(:params) { [{ name: 'barbar', a: 1, b: 1 }] }
      let(:service) { WithConstraintDoUpdate }

      it_behaves_like 'a successful call'

      describe 'outcome' do
        let(:result) { service.new.call(params) }

        it 'performs the update' do
          result
          expect(service.model[a: 1, b: 1].name).to eq('barbar')
        end

        it 'returns the models that were updated' do
          expect(result.value!).to all(be_instance_of(service.model))
        end
      end
    end
  end
end
