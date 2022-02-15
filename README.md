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

See tests for usage examples.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Servitium project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/servitium/blob/master/CODE_OF_CONDUCT.md).
