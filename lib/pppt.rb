# frozen_string_literal: true

require_relative 'pppt/simple/single/create'
require_relative 'pppt/simple/single/update'
require_relative 'pppt/simple/single/delete'

require_relative 'pppt/simple/plural/create'
require_relative 'pppt/simple/plural/update'
require_relative 'pppt/simple/plural/delete'
require_relative 'pppt/simple/plural/upsert'

require_relative 'pppt/one_to_many/plural/create'

# Pretty Please Perform This
module PPPT
  # Raised when a column name is used, perhaps for inserting or updating,
  # that does not exist on the target model's table.
  class InvalidKeyError < ArgumentError; end

  # Raised when a constraint name is used that does not exist on the target model's table.
  class InvalidConstraintName < ArgumentError; end

  # Raised when required configuration for a class is not provided and we cannot
  # determine appropriate default behavior.
  class MissingConfiguration < ArgumentError; end

  def self.validate_source!(source)
    unless source.is_a?(Sequel::Model::ClassMethods)
      raise ArgumentError, "I don't know how to work with anything else than Sequel model."
    end
  end

  def self.def_service(mod, klass)
    method_name = klass.to_s.gsub(/^.*::/, '').to_sym
    service = klass
    mod.define_singleton_method(method_name) do |source|
      PPPT.service(service, source)
    end
  end

  def self.service(service, model)
    validate_source!(model)
    klass = Class.new(service)
    klass.model = model
    klass
  end

  def_service(Simple::Single, Simple::Single::Create)
  def_service(Simple::Single, Simple::Single::Update)
  def_service(Simple::Single, Simple::Single::Delete)

  def_service(Simple::Plural, Simple::Plural::Create)
  def_service(Simple::Plural, Simple::Plural::Update)
  def_service(Simple::Plural, Simple::Plural::Delete)
  def_service(Simple::Plural, Simple::Plural::Upsert)

  def_service(OneToMany::Plural, OneToMany::Plural::Create)
end
