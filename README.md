# Klf200

**TODO: Add description**

## Examples

Using Client API

```elixir
Klf200.Client.start_link
Klf200.Client.connect("192.168.10.50")
Klf200.Client.login("password")
Klf200.Client.command(:GW_COMMAND_SEND_REQ, %{node: 0, position: 0}) # open
Klf200.Client.command(:GW_COMMAND_SEND_REQ, %{node: 0, position: 100}) # close
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `klf200` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:klf200, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/klf200>.

