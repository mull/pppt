# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module OneToMany
    module Plural
      # Create multiple parent records and multiple records for one or more one_to_many
      # associations, but only when provided with services to do so.
      #
      # Services to create "child records" must be given at class definition time.
      #
      # Child creation services must be PPPT services as of now. The class will throw (at definition
      # time) if given something else.
      #
      # Additionally we make sure that consistent keys are provided for all
      # rows to be inserted, by looking at the model and the default values.
      #
      # class CreateChapters < PPPT::Simple::Plural::Create(Chapter); end
      #
      # class CreateService < PPPT::OneToMany::Plural::Create(Book);
      #   create_chapters CreateChapters.new
      # end
      # CreateService.new.call([
      #   {title: 'Eloquent Ruby', chapters: [title: 'Write code that looks like Ruby'] }
      # ])
      # => Success([#<Book {id: 1, title: 'Eloquent Ruby', ...}>)
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Create
        include Base
        include Dry::Monads::Do.for(:create_associations)

        def self.respond_to_missing?(method_name)
          method_name.to_s.start_with?('create_')
        end

        def self.method_missing(method_name, arg)
          if method_name.to_s.start_with?('create_')
            register_association_service(method_name, arg)
          else
            super
          end
        end

        def self.register_association_service(method_name, service)
          unless service.class.included_modules.include?(PPPT::Base)
            raise ArgumentError, "#{service} cannot be used for #{method_name}!"
          end

          association_name = method_name.to_s.split('_')[1..-1].join('_').to_sym

          @_insert_service_cache ||= Hash[supported_associations_keys.zip([])]
          @_insert_service_cache[association_name] = service
        end

        def self.supported_associations_keys
          @_supported_associations_keys ||= assoc_lookup.keys
        end

        def self.supported_associations
          @_supported_associations ||= model.all_association_reflections
                                            .select { |a| a[:type] == :one_to_many }
        end

        def self.assoc_lookup
          @assoc_lookup ||= supported_associations.each_with_object({}) do |assoc, object|
            object[assoc[:name]] = assoc if assoc[:type] == :one_to_many
          end
        end

        def self.insert_service_for_association(association_name)
          if @_insert_service_cache[association_name].nil?
            raise "I cannot create #{association_name} as I have no service provided"
          end

          @_insert_service_cache[association_name]
        end

        def self.valid_columns
          @valid_columns ||= model.columns + supported_associations_keys
        end

        def call(array_of_params)
          return Success([]) if array_of_params.empty?

          inserts = validate_and_slice_params(array_of_params)

          Try[Sequel::Error] do
            # Return order is the same as given
            parents = model.dataset.returning.multi_insert(inserts).map { |hash| model.load(hash) }
            create_associations(array_of_params, parents)

            parents
          end.to_result
        end

        private

        def create_associations(array_of_params, created_parents)
          association_insertions = {}
          array_of_params.map.with_index do |item, index|
            item
              .slice(*self.class.supported_associations_keys)
              .each do |(association_name, association_params)|
                association_insertions[association_name] ||= []
                association_insertions[association_name].concat(
                  generate_association_params(
                    created_parents[index],
                    association_name,
                    association_params
                  )
                )
              end
          end

          association_insertions.each do |association_name, items|
            service = self.class.insert_service_for_association(association_name)
            yield service.call(items)
          end
        end

        def generate_association_params(parent, association_name, association_params)
          reflection = self.class.assoc_lookup[association_name]
          association_params.each do |ap|
            reflection[:keys].zip(reflection[:primary_keys]).each do |(foreign_key, primary_key)|
              ap[foreign_key] = parent.get_column_value(primary_key)
            end
          end
        end

        def validate_and_slice_params(array_of_params)
          self.class.validate_keys!(array_of_params.flat_map(&:keys).uniq)
          base_params = array_of_params.map { |p| slice_model_parameters(p) }
          all_keys = base_params.flat_map(&:keys).uniq
          slice_consistent_params(base_params, all_keys)
        end

        def add_method_for_association(association_name)
          self.class.supported_associations.find { |t| t[:name] == association_name }[:add_method]
        end

        def slice_model_parameters(params)
          params.slice(*model.columns)
        end
      end
    end
  end
end
