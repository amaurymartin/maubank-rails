# maubank-rails
This project provides the backend for a personal finance web application.
The development tools are listed below.

---

## Dependencies
- [Ruby v3.1.2](https://www.ruby-lang.org/en/downloads/)
- [Rails v7.0.2.4](https://guides.rubyonrails.org/getting_started.html)
---

## Set up
First, install the gems required by the application:
```bash
bundle
```
Next, execute the database migrations/schema setup:
```bash
rails db:setup
```
---

## Run application
To run the server on port 3000:

```bash
rails s
```
---

## Run tests
Test suite is using [RSpec](https://rspec.info/). To run it do:

```bash
rails spec
```
---

## Coverage
To see test coverage, after run test suite, do:

```bash
xdg-open coverage/index.html
```
---
