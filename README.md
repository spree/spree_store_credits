# Spree Store Credits

[![Build Status](https://travis-ci.org/spree-contrib/spree_store_credits.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_store_credits)
[![Code Climate](https://codeclimate.com/github/spree-contrib/spree_store_credits/badges/gpa.svg)](https://codeclimate.com/github/spree-contrib/spree_store_credits)

This Spree extension allows admins to issue arbitrary amounts of store credit to users. Users can redeem store credit during checkout, as part or full payment for an order. Also extends My Account page to display outstanding credit balance, and orders that used store credit.

---

## Installation

Add spree_affiliate to your `Gemfile`:

```ruby
gem 'spree_store_credits', github: 'spree-contrib/spree_store_credits', branch: '2-4-stable'
```

Run:
```sh
bundle
bundle exec rails g spree_store_credits:install
```

---

## Configuration

By default Spree Store Credits does not require your order total to be above an amount to apply store credits.

To change this, use the :use_store_credit_minimum preference. For information on setting Spree preferences visit http://guides.spreecommerce.com/developer/preferences.html

One possible implementation looks like this:

```ruby
# app/model/spree/store_credit_decorator.rb

Spree::StoreCredit.class_eval do
  Spree::Config[:use_store_credit_minimum] = 0.01
end
```

---

## Contributing

See corresponding [guidelines][1]

---

## License

Copyright (c) 2014 [Roman Smirnov][2], [Brian Quinn][3], and other [contributors][4], released under the [New BSD License][5]

[1]: https://github.com/spree-contrib/spree_store_credits/blob/master/CONTRIBUTING.md
[2]: https://github.com/romul
[3]: https://github.com/BDQ
[4]: https://github.com/spree-contrib/spree_store_credits/graphs/contributors
[5]: https://github.com/spree-contrib/spree_store_credits/blob/master/LICENSE.md
