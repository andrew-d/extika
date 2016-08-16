# ExTika

[![Build Status](https://travis-ci.org/andrew-d/extika.svg?branch=master)](https://travis-ci.org/andrew-d/extika)

Wrapper around [Apache Tika][tika].

## Installation

The package can be installed as:

  1. Add `extika` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:extika, "~> 0.0.1"}]
    end
    ```

  2. Ensure `extika` is started before your application:

    ```elixir
    def application do
      [applications: [:extika]]
    end
    ```


[tika]: https://tika.apache.org/
