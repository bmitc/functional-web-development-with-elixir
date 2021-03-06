[![build and test](https://github.com/bmitc/functional-web-development-with-elixir/actions/workflows/build-and-test.yml/badge.svg?branch=main)](https://github.com/bmitc/functional-web-development-with-elixir/actions/workflows/build-and-test.yml)

# Functional Web Development with Elixir, OTP, and Phoenix

This repository is code developed along with the excellent book [*Functional Web Development with Elixir, OTP, and Phoenix* by Lance Halvorsen](https://pragprog.com/titles/lhelph/functional-web-development-with-elixir-otp-and-phoenix/). For the most part, the code follows along with the book but has been modified to:

* Include thorough documentation and typespecs
* Fully comply with Dialyzer and Credo in strict mode and some check modifications
* Convert the IEx sessions in the book to tests
* Clean up or update some of the code in the book
* Use structs more thoroughly than in the book and add in custom types for more domain driven development
* [Convert the book's use of `Supervisor` with the `:simple_one_for_one` strategy, which has been deprecated, to use `DynamicSupervisor`](https://hexdocs.pm/elixir/DynamicSupervisor.html#module-migrating-from-supervisor-s-simple_one_for_one).
