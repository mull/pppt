# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module OneToMany
    module Plural
      # Create multiple parent records and multiple records for one or more one_to_many associations,
      # but only when provided with services to do so.
      #
      # Services to create "child records" must be given at class definition time.
      #
      # Child creation services must PPPT services as of now. The class will throw (at definition time)
      # if given something else.
      #
      # Additionally we make sure that consistent keys are provided for all
      # rows to be inserted, by looking at the model and the default values.
      #
      # class CreateChapters < PPPT::Simple::Plural::Create(Chapter); end
      #
      # class CreateService < PPPT::OneToMany::Plural::Create(Book);
      #   create_chapters CreateChapters.new
      # end
      # CreateService.new.call([ { title: 'Eloquent Ruby', chapters: [title: 'Write code that looks like Ruby'] } ])
      # => Success([#<Book {id: 1, title: 'Eloquent Ruby', ...}>)
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Create
        include Base

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

          association_name = method_name.to_s.split('_').last.to_sym

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

        def self.ensure_valid_keys!(array_of_params)
          all_keys = array_of_params.flat_map(&:keys).uniq
          all_keys.each do |key|
            unless valid_columns.include?(key)
              raise InvalidKeyError, "The key \"#{key}\" is not allowed on #{model.name}"
            end
          end
        end

        def self.valid_columns
          @valid_columns ||= model.columns + supported_associations_keys
        end

        def call(array_of_params)
          return Success([]) if array_of_params.empty?

          # all_keys = array_of_params.flat_map(&:keys).uniq
          # ensure_valid_keys!(all_keys)
          # inserts = slice_consistent_params(array_of_params, all_keys)
          self.class.ensure_valid_keys!(array_of_params)
          base_params = array_of_params.map { |p| slice_model_parameters(p) }
          all_keys = base_params.flat_map(&:keys).uniq
          inserts = slice_consistent_params(base_params, all_keys)

          Try[Sequel::Error] do
            parents = model.dataset.returning.multi_insert(inserts).map { |hash| model.load(hash) }
            # Return order is the same as given
            association_insertions = {}
            array_of_params.map.with_index do |item, index|
              associations = item.slice(*self.class.supported_associations_keys)
              parent = parents[index]
              associations.each do |(association_name, association_params)|
                reflection = self.class.assoc_lookup[association_name]

                association_insertions[association_name] ||= []
                association_insertions[association_name].concat(
                  association_params.map do |ap|
                    ap.merge(reflection[:key] => parent[reflection[:primary_key]])
                  end
                )
              end
            end

            association_insertions.each do |association_name, items|
              service = self.class.insert_service_for_association(association_name)
              service.call(items)
            end

            parents
          end.to_result
        end

        private

        def add_method_for_association(association_name)
          self.class.supported_associations.find { |t| t[:name] == association_name }[:add_method]
        end

        def slice_model_parameters(params)
          params.slice(*model.columns)
        end

        def slice_consistent_params(array_of_params, all_keys)
          consistent_keys =
            all_keys
            .zip([nil])
            .to_h
            .merge(self.class.evaluate_default_values)

          array_of_params.map do |params|
            consistent_keys.merge(params)
          end
        end
      end
    end
  end
end
