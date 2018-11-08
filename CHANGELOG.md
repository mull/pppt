# Changelog

## 0.5.0
- Add OneToMany::Plural::Create

## 0.4.6
- Fix: typos/wording in README

## 0.4.5
- Fix: Plural::Update returning unexpected Success([nil, nil, ...]) instead of array of models when no db update occured

## 0.4.4
- Fix: Single::Update returning unexpected Success(nil) instead of model when no db update occured

## 0.4.3
- Fix: broken plural delete
- Add: Continuous testing

## 0.4.2
- Fix: undefined variable `array_of_params` error in `simple|plural|update`

## 0.4.1
- Add: `do_nothing` configuration for Simple::Plural::Upsert

## 0.4.0
- Breaking: Single::Update now returns a Success monad, not a Try::Value

## 0.3.0
- Breaking: When plural `Create|Delete|Update|Upsert#call` receives an empty array, return Success without trying anything else

## 0.2.1
- Fix: When default values are procs, call them

## 0.2.0
- Add: `Simple::Plural::Upsert`

## 0.1.0
Initial launch with the services.

- Add `Simple::Singular::Create`
- Add `Simple::Singular::Update`
- Add `Simple::Singular::Delete`
- Add `Simple::Plural::Create`
- Add `Simple::Plural::Update`
- Add `Simple::Plural::Delete`
