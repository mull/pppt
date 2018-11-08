# Pretty Please Perform This
Opinionated service object generator for Sequel models.

The namespaces of PPPT are divided into the concept of complexity, currently only Single exists, and plurality.

# Simple
There's no fuzz here. It handles composite primary keys easily.

The library will validate that no keys that don't exist on the model are attempted to be written to. If so it raises `PPPT::InvalidKeyError` with a message. Similarly if one tries to update the primary key of a row the same exception is raised.

## Singular
```ruby
class SomeModel < Sequel::Model
  # id SERIAL PRIMARY KEY
  # name VARCHAR
  # count INTEGER NOT NULL DEFAULT 0
end
```

### Create
```ruby
class SimpleSingularInsert < PPPT::Simple::Single::Create(SomeModel); end

SimpleSingularInsert.new.call(name: 'foo') # => Success(SomeModel#<id: 1, name: 'foo')
```

### Update
Update is very simple: given an instance and some params, update it.

```ruby
class SimpleSingularUpdate < PPPT::Simple::Single::Update(SomeModel); end
SimpleSingularUpdate.new.call(SomeModel.first, name: 'bar') # => Success(SomeModel#<id: 1, name: 'bar'>)
```

However, update also guards against updating the primary key and raises an error when you try:

```ruby
SimpleSingularUpdate.new.call(SomeModel.first, id: 2) # => raises PPPT::InvalidKeyError<"The primary key (id) cannot be updated on SimpleModel">
```

In case the params match the current values and no update is performed the same instance of the model is returned:
```ruby
SimpleSingularUpdate.new.call(SomeModel.first, name: 'foo') # => Success(SomeModel#<id: 1, name: 'foo')
```

### Delete
Delete resolves to nil upon success, rather than returning a deleted model.

```ruby
class SimpleSingularDelete < PPPT::Simple::Single::Delete(SomeModel); end
SimpleSingularDelete.new.call(SomeModel.first) # => Success(nil)
```

## Plural
### Create
Takes an array of hashes to insert. This results in only one call to Postgres (multi_insert), but will return instances of the model.

```ruby
class SimplePluralCreate < PPPT::Simple::Plural::Create(SomeModel); end
SimplePluralCreate.new.call([{name: 'foo'}, {name: 'bar'}])
# => Success([SimpleModel<id: 1, name: 'foo'>, SimpleModel<id: 2, name: 'bar'>])
```

Creation is a tiny bit smart though. If you refer back to the definition of SomeModel you'll see that the column `count` is non-nullable and has a default value. PPPT will look at the hashes given to it and ensure that all inserts have the equal amount of columns. It will first attempt to find the default values of the column from the model:

```ruby
SimplePluralCreate.new.call({name: 'foo', count: 1}, {name: 'bar'})
# => INSERT INTO some_models (name, count) VALUES ('foo', 1), ('bar', 0)
```

If the column has no default value it will attempt to use nil:

```ruby
SimplePluralCreate.new.call({count: 1}, {name: 'bar'})
# => INSERT INTO some_models (name, count) VALUES (NULL, 1), ('bar', 0)
```

### Update
Update takes array pairs of `[model, params]`. Like singular update it will prevent you from updating the primary key of a row.

```ruby
class SimplePluralUpdate < PPPT::Simple::Plural::Update(SomeModel); end
SimplePluralUpdate.new.call([
  [instance_a, name: 'foofoo'],
  [instance_b, name: 'barbar'],
])
# => Success([SimpleModel<id: 1, name: 'foofoo'>, SimpleModel<id: 2, name: 'barbar'])
```

As of now plural update produces one SQL statement per model it updates.


### Delete
Deletion takes an array of model instances and deletes them in one statement.

```ruby
class SimplePluralDelete < PPPT::Simple::Plural::Delete(SomeModel); end
SimplePluralDelete.new.call([instance_a, instance_b]) # => Success(2)
```


### Upsert
Upsert makes use of Postgres' native [ON CONFLICT insertion](https://www.postgresql.org/docs/10/static/sql-insert.html). As of writing this (0.2.0) it only allows specifying a constraint name. By default it will do nothing (same behaviour as Sequel). For any keys to be updated they must be provided. All keys are defaulted to `EXCLUDED.column_name`. At some later stage this may change.

Unlike other services this one makes no use of models and takes no models as input. It does however make use of the model by:

1. Validating that the constraint given exists
2. Validating that the keys specified exist as columns

The successful value of this service is:

1. New rows inserted are returned
2. Untouched rows, or existing rows, are left out

Meaning **this service only returns the new rows that were created**.


By default we _DO NOTHING_:

```ruby
class UpsertService < PPPT::Simple::Plural::Upsert(ModelWithConstraint)
  constraint :unique_constraint_on_column_a
end
UpsertService.new.call([{name: 'foo', a: 1}]) # => Success([])

# INSERT INTO "model_with_constraint" ("name", "a") VALUES ('foo', 1) ON CONFLICT ON CONSTRAINT "unique_constraint_on_column_a" DO NOTHING RETURNING *
```

Additionally we can explicitly say that the service is doing nothing:

```ruby
class UpsertService < PPPT::Simple::Plural::Upsert(ModelWithConstraint)
  constraint :unique_constraint_on_column_a
  do_nothing
end
UpsertService.new.call([{name: 'foo', a: 1}]) # => Success([])

# INSERT INTO "model_with_constraint" ("name", "a") VALUES ('foo', 1) ON CONFLICT ON CONSTRAINT "unique_constraint_on_column_a" DO NOTHING RETURNING *
```

If we specify the keys we want to update, we'll get that effect:

```ruby
class UpsertService < PPPT::Simple::Plural::Upsert(ModelWithConstraint)
  constraint :unique_constraint_on_column_a
  update :name
end
UpsertService.new.call([{name: 'foo', a: 1}]) # => Success([])

# INSERT INTO "model_with_constraint" ("name", "a") VALUES ('foo', 1) ON CONFLICT ON CONSTRAINT "unique_constraint_on_column_a" DO UPDATE SET "name" = "excluded"."name" RETURNING *
```

# One to Many
Handle creation of parents and children.

## Plural

### Create
Given services as definition time to create children for a model's association we can easily create multiple parents and children without writing glue code to fill in the foreign keys. Sequel models lets us know how to fill in the associations, yet the inserts are done in batch.


```ruby
class CreateChapters < PPPT::Simple::Plural::Create(Chapter); end

class CreateBooksAndChapters < PPPT::OneToMany::Plural::Create(Book)
  create_chapters CreateChapters.new
end

CreateBooksAndChapters.new.call([
  {
    title: 'Eloquent Ruby',
    chapters: [
      { title: 'Write code that looks like Ruby' },
      { title: 'Choose the Right Control Structure' }
    ]
  },
  {
    title: 'Ruby under a microscope',
    chapters: [
      { title: 'Tokenization and Parsing' },
      { title: 'Compilation' }
    ]
  }
])

# INSERT INTO books (title) VALUES ('Eloquent Ruby'), ('Ruby under a microscope') RETURNING *
# INSERT INTO chapters (book_id, title) VALUES (1, 'Write code that looks like Ruby'), (1, 'Choose the Right Control Structure'), (2, 'Tokenization and Parsing'), (2, 'Compilation')

# => # => Success([Book<id: 1, title: 'Eloquent Ruby'>, Book<id: 2, title: 'Ruby under a microscope'>])


