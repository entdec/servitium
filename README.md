# Servitium

An implementation of the command pattern for Ruby

## Features

- Context validation
- Callbacks

  Context:

  - before_validation
  - after_validation

  Services:

  - before_perform
  - around_perform
  - after_perform

- Transations
  By default transactions are disabled, but you can include the following in your ApplicationService

  ```ruby
  transactional true
  ```

  In case transactions are enabled after_commit will triger after after_peform

- Asynchronous execution
  Instead of calling perform you can use perform_later to execute a service asynchronously, this uses ActiveJob.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'servitium'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install servitium

## Usage

You define a context for the service, which describes what goes in and out
```ruby
class ExampleContext < ApplicationContext
  attribute :some, type: String, default: "new"

  validates :some, presence: true
end
```

You can be very explicit in what goes in our out:
```ruby
class ExampleContext < ApplicationContext
  input do
    attribute :some, type: String, default: "new"
    validates :some, presence: true
  end
  output do
    attribute :some, type: String, default: "new"
  end
end
```

And you define the service itself:
```ruby
class ExampleService < ApplicationService
  def perform
    context.some.reverse!
  end
end
```

You can also include the context in the service, for less complicated services:

```ruby
class ExampleService < ApplicationService
  context do
    attribute :some, type: :string, default: "new"
  end
  def perform
    context.some.reverse!
  end
end
```

Next you use it as follows:
```ruby
ExampleService.perform(some: 'test').some # => tset
```
A service always returns it context

Services can also run in the background:
```ruby
ExampleService.perform_later(some: 'test') # => #<ExampleContext>
```

You can use the generator to generate service code: 
```
❯ rails g servitium:service Example

      create  app/services/example_service.rb
      create  app/services/example_context.rb
      create  test/services/example_service_test.rb
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Servitium project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/servitium/blob/master/CODE_OF_CONDUCT.md).
