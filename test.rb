# frozen_string_literal: true

require 'sequel'
require 'pry'
require 'logger'
require 'dry/monads/result'
require 'dry/monads/do'

require 'pppt'

$logger = Logger.new($stdout)

DB = Sequel.connect(database: 'weissmaler-be-task', adapter: :postgres)
DB.loggers << $logger

DB.execute <<~SQL
  DROP TABLE IF EXISTS models;
  CREATE TABLE models (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    labor_hours INTEGER NOT NULL DEFAULT 0,
    some_other VARCHAR
  );
SQL

Sequel::Model.plugin :defaults_setter

class SampleModel < Sequel::Model(:models); end

class SampleModelCreateService < PPPT::Simple::Single::Create(SampleModel); end
class SampleModelUpdateService < PPPT::Simple::Single::Update(SampleModel); end
class SampleModelDeleteService < PPPT::Simple::Single::Delete(SampleModel); end
class SamplePluralCreateService < PPPT::Simple::Plural::Create(SampleModel); end
class SamplePluralUpdateService < PPPT::Simple::Plural::Update(SampleModel); end
class SamplePluralDeleteService < PPPT::Simple::Plural::Delete(SampleModel); end

def inform(message)
  $logger << "----\n"
  message.split("\n").each do |line|
    $logger << "---- #{line}\n"
  end
  $logger << "----\n"
end

inform('Going to create, update, and then delete')

result =
  SampleModelCreateService.new
                          .call(name: 'oi')
                          .bind { |m| SampleModelUpdateService.new.call(m, name: 'fuck you') }
                          .bind { |m| SampleModelDeleteService.new.call(m) }

inform("Result: #{result}")

inform('Creating multiple sample models')
result = SamplePluralCreateService.new.call([
                                              { name: 'bla' },
                                              { name: 'bar', labor_hours: 3 },
                                            ])
inform("Result of that: #{result}")

inform('Going to create a singular model with a field that does not exist')
begin
  SampleModelCreateService.new.call(name: 'oi', a_field_that_does_not_exist_in_the_table: 1)
rescue StandardError => e
  inform("Error received: #{e}")
end

inform('Going to create plural models with a field that does not exist')
begin
  SamplePluralCreateService.new.call([
                                       { name: 'oi' },
                                       { name: 'bla', a_field_that_does_not_exist_in_the_table: 1 },
                                     ])
rescue StandardError => e
  inform("Error received: #{e}")
end

inform('Going to create plural (valid) models and then batch update them')
models = SamplePluralCreateService.new.call([{ name: 'bla' }, { name: 'foo' }]).value!
inform("Before updating: #{models}")
input = models.map { |m| [m, { name: m.name * 2 }] }
result = SamplePluralUpdateService.new.call(input)
inform("After updating: #{result}")
inform("I'm going to delete the previously created models.")
result = SamplePluralDeleteService.new.call(result.value!)
inform("Result of that: #{result}")
