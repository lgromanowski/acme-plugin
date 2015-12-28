# letsencrypt-plugin 
[![Build Status](https://travis-ci.org/lgromanowski/letsencrypt-plugin.svg?branch=master)](https://travis-ci.org/lgromanowski/letsencrypt-plugin) [![Gem Version](https://badge.fury.io/rb/letsencrypt_plugin.svg)](https://badge.fury.io/rb/letsencrypt_plugin) [![Dependency Status](https://gemnasium.com/lgromanowski/letsencrypt-plugin.svg)](https://gemnasium.com/lgromanowski/letsencrypt-plugin) [![Code Climate](https://codeclimate.com/github/lgromanowski/letsencrypt-plugin/badges/gpa.svg)](https://codeclimate.com/github/lgromanowski/letsencrypt-plugin) [![Test Coverage](https://codeclimate.com/github/lgromanowski/letsencrypt-plugin/badges/coverage.svg)](https://codeclimate.com/github/lgromanowski/letsencrypt-plugin/coverage)

`letsencrypt-plugin` is a Ruby on Rails helper for [Let's Encrypt](https://letsencrypt.org/) service for retrieving SSL certificates (without using sudo, like original letsencrypt client does). It uses [acme-client](https://github.com/unixcharles/acme-client) gem for communication with Let's Encrypt server.

**Important note:** As of version 0.0.3 of this gem dependency to SQLite has been removed (it can be used on [Heroku](https://www.heroku.com/)), but it still need database to store challenge response, so you have to add some database gem to your application (ie. pg, mysql or sqlite)
 

## Installation

Add below line to your application's Gemfile:
```ruby
gem 'letsencrypt_plugin'
```
And then execute:
```bash
$ bundle install
```
Or install it yourself as:
```bash
$ gem install letsencrypt_plugin
```

After that you have to run two following commands to copy letsencrypt_plugin database migration to your application and create `letsencrypt_plugin_challenges` table: 
```bash
$ rake letsencrypt_plugin:install:migrations
```
```bash
$ rake db:migration RAILS_ENV=production
```

Next, you have to create configuration (template below):
```yaml
endpoint: "https://acme-v01.api.letsencrypt.org/"
email: "your@email.address"
domain: "example.com"
private_key: "key/keyfile.pem"                            # in Rails.root
output_cert_dir: "certificates"                           # in Rails.root
```
and put it into `Rails.root/config/letsencrypt_plugin.yml` file. If you don't have previously generated private key you can create it by running following command:
```bash
$ openssl genrsa 4096 > key/keyfile.pem
```
`output_cert_dir` must exist - it wont be created automaticaly.

Next, you have to mount `letsencrypt_plugin` engine in routes.rb:

```ruby
Rails.application.routes.draw do
  mount LetsencryptPlugin::Engine, at: "/"  # It must be at root level

  # Other routes...

end
```

and restart your application:
```bash
$ touch tmp/restart.txt
```

## Usage
Run `letsencrypt_plugin` rake task:
```bash
$ rake letsencrypt_plugin RAILS_ENV=production
```

If everything was done correctly, then you should see output similar to the one below:
```bash
I, [2015-12-06T17:28:15.582308 #25931]  INFO -- : Loading private key...
I, [2015-12-06T17:28:15.582592 #25931]  INFO -- : Trying to register at Let's Encrypt service...
I, [2015-12-06T17:28:16.381682 #25931]  INFO -- : Already registered.
I, [2015-12-06T17:28:16.381749 #25931]  INFO -- : Sending authorization request...
I, [2015-12-06T17:28:16.646616 #25931]  INFO -- : Storing challenge information...
I, [2015-12-06T17:28:18.193827 #25931]  INFO -- : Waiting for challenge status...
I, [2015-12-06T17:28:21.643566 #25931]  INFO -- : Creating CSR...
I, [2015-12-06T17:28:22.173471 #25931]  INFO -- : Saving certificates and key...
I, [2015-12-06T17:28:22.174312 #25931]  INFO -- : Certificate has been generated.
```
and in `output_cert_dir` directory you should have four files:
- domain.name-cert.pem - Domain certificate
- domain.name-chain.pem - Chained certificate
- domain.name-fullchain.pem - Full chain of certificates
- domain.name-key.pem - Domain certificate key


## Bugs, issues, feature requests?

If you encounter a bug, issue or you have feature request please submit it in [issue tracker](https://github.com/lgromanowski/letsencrypt-plugin/issues). 

## License

```
Copyright 2015 Lukasz Gromanowski <lgromanowski@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
