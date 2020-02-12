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
