# One

**1up Health API documentation**

This module is an Elixir wrapper for 1up Health APIs along with the description and test for each endpoint.
You can find `ExDoc` generated documentations in you App directory here: 

``$ /one/doc/One.html``

It also provides an easy to use `mix` command to download bulk data for specific resources such as `Patient`, `Observation`, ...

```
$ mix one /tmp Patient 
$ mix one /path-to-donwload  Patient Observation
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `one` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:one, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/one](https://hexdocs.pm/one).

