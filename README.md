# Pretty Please Perform This
Opinionated service object generator for Sequel models.

The namespaces of PPPT are divided into the concept of complexity, currently only Single exists, and plurality.

## Simple
There's no fuzz here. It handles composite primary keys easily.

The library will validate that no keys that don't exist on the model are attempted to be written to. If so it raises `PPPT::InvalidKeyError` with a message. Similarly if one tries to update the primary key of a row the same exception is raised.

### Singular
```ruby
class SomeModel < Sequel::Model
  # id SERIAL PRIMARY KEY
  # name VARCHAR
  # count INTEGER NOT NULL DEFAULT 0
end
```

#### Create
```ruby
class SimpleSingularInsert < PPPT::Simple::Single::Create(SomeModel); end

SimpleSingularInsert.new.call(name: 'foo') # => Success(SomeModel#<id: 1, name: 'foo')
```

#### Update
Update is very simple: given an instance and some params, update it.

```ruby
class SimpleSingularUpdate < PPPT::Simple::Single::Update(SomeModel); end
SimpleSingularUpdate.new.call(SomeModel.first, name: 'bar') #=> Success(SomeModel#<id: 1, name: 'bar'>)
```

However, update also guards against updating the primary key and raises an error you try:

```ruby
SimpleSingularUpdate.new.call(SomeModel.first, id: 2) #=> raises PPPT::InvalidKeyError<"The primary key (id) cannot be updated on SimpleModel">
```

#### Delete
Delete resolves to nil upon successs, rather than returning a deleted model.

```ruby
class SimpleSingularDelete < PPPT::Simple::Single::Delete(SomeModel); end
SimpleSingularDelete.new.call(SomeModel.first) #=> Success(nil)
```

### Plural
#### Create
Takes an array of hashes to insert. This results in only one call to Postgres (multi_insert), but will return instances of the model.

```ruby
class SimplePluralCreate < PPPT::Simple::Plural::Create(SomeModel); end
SimplePluralUpdate.new.call([{name: 'foo'}, {name: 'bar'}])
# => Success([SimpleModel<id: 1, name: 'foo'>, SimpleModel<id: 2, name: 'bar'>])
```

Creation is a tiny bit smart though. If you refer back to the definition of SomeModel you'll see that the column `count` is non-nullable and has a default value. PPPT will look at the hashes given to it and ensure that all inserts have the equal amount of columns. It will first attempt to find the default values of the column from the model:

```ruby
SimplePluralUpdate.new.call({name: 'foo', count: 1}, {name: 'bar'})
# => INSERT INTO some_models (name, count) VALUES ('foo', 1), ('bar', 0)
```

If the column has no default value it will attempt to use nil:

```ruby
SimplePluralUpdate.new.call({count: 1}, {name: 'bar'})
# => INSERT INTO some_models (name, count) VALUES (NULL, 1), ('bar', 0)
```

##### Update
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


##### Delete
Deletion takes an array of model instances and deletes them in one statement.

```ruby
class SimplePluralDelete < PPPT::Simple::Plural::Delete(SomeModel); end
SimplePluralDelete.new.call([instance_a, instance_b]) # => Success(2)
```
