# Validation Auditor

[![Build Status](https://travis-ci.org/pupeno/validation_auditor.png?branch=master)](https://travis-ci.org/pupeno/validation_auditor)
[![Coverage Status](https://coveralls.io/repos/pupeno/validation_auditor/badge.png?branch=master)](https://coveralls.io/r/pupeno/validation_auditor?branch=master)
[![Code Climate](https://codeclimate.com/github/pupeno/validation_auditor.png)](https://codeclimate.com/github/pupeno/validation_auditor)
[![Inline docs](http://inch-ci.org/github/pupeno/validation_auditor.png?branch=master)](http://inch-ci.org/github/pupeno/validation_auditor)
[![Gem Version](https://badge.fury.io/rb/validation_auditor.png)](http://badge.fury.io/rb/validation_auditor)
[![Dependency Status](https://gemnasium.com/pupeno/validation_auditor.svg)](https://gemnasium.com/pupeno/validation_auditor)

A user visits your web app, tries to do something with it but it fails due to a validation error. Generally, the
validation is stopping a user from doing something bad, but every now and then it's the validation that is bad. Don't
you hate it when the credit card processor won't accept your name as written in the credit card due to an unexpected
character and won't accept anything else because that's not your name? We all do.

This gem allows you to easily keep a log of validation errors, so you can later inspect them to try to find those cases
where things are going wrong.

This gem supports [Rails 4.0 through 4.2 running on Ruby 1.9 through 2.3](https://travis-ci.org/pupeno/validation_auditor)
(latest stable version of each).

Ruby 1.9 and 2.1 are not being actively tested due to issues with bundler in the continuous integration server. Tests
for Ruby 2.0 should ensure 2.1 works fine anyway, Ruby 1.9 might accidentally become unsupported, please, [report a bug](https://github.com/pupeno/validation_auditor/issues)
if you experience.

Rails 3.2 is not being actively supported because of the time investment required to maintain the test suite but no
specific action against Rails 3.2 is being taken and re-enabling the 3.2 test suite is not discarded. The last branch to
test and support Rails 3.2 was [v1.0](https://github.com/pupeno/validation_auditor/tree/v1.0) and the last release was
[v1.0.0](https://github.com/pupeno/validation_auditor/releases/tag/v1.0.0).

## Installation

Add this line to your application's Gemfile:

    gem "validation_auditor"

If you are on Rails < 4.0, then you need to install the latest version from the
[1.0 branch](https://github.com/pupeno/validation_auditor/tree/v1.0):

    gem "validation_auditor", "~> 1.0.0"

And then execute:

    $ bundle

You need to install the migration file in your Rails project, which you can do by:

    $ rails generate validation_auditor:install

## Usage

After you run the migration, you need to enable the validation auditor in each model by calling the class method:
`audit_validation_errors`, for example:

    class Blog < ActiveRecord::Base
      audit_validation_errors
    end

From then on, every time saving that record fails, a record will be saved to validation_audits with the failure message
and some extra information.

If you enable validation audit on the controller, by calling `audit_validation_errors` as in:

    class BlogsController < ApplicationController
      audit_validation_errors
    end

then you'll also get params, url and user agent in the validation audit. This breaks the model-controller separation, so
it's optional.

If for some reason saving a validation audit fails, the exception will be left to propagate into your application so
that no exception is silently swallowed. You may not want to let a secondary system, like auditing, stop your
application from working (depending on how critical auditing is for you). If that's the case, you can define an
exception handler that can report the exception in whatever fashion you normally report exceptions to your dev team and
then swallow the exception. This may or may not work in Rails < 4.

    ValidationAuditor.exception_handler = lambda do |e, va|
        puts "When trying to save validation audit #{va}, exception #{e} was encountered."
    end

## Users

This gem is being used by:

- [Watu](https://watuapp.com)
- You? please, let us know if you are using this gem.

## Changelog

### validation_auditor next_release
- Dropped testing and official support for Rails 3.2.
- Added testing and official support for Rails 4.2.
- Added testing and official support for Ruby 2.2.X.
- Added testing and official support for Ruby 2.3.X

### validation_auditor 1.0.0 (Nov 17, 2014)
- Started testing Ruby 2.1.3 and 2.1.4.
- Refactoring to make code more readable (increased code climate to 4.0).
- Marked internal methods as private.
- Improved documentation.

### validation_auditor 0.2.1 (Sep 5, 2014)
- When cleaning params to save them as yaml, also clean each element of arrays.

### validation_auditor 0.2.0 (Jul 23, 2014)
- Respect the filter_parameters configuration from Rails.

### validation_auditor 0.1.1 (Jul 23, 2014)
- Don't crash in the presence of file uploads when reporting validation errors.

### validation_auditor 0.1.0 (January 8, 2014)
- Everything.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
