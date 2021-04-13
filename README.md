# AxonRLDemo

Quick-n-Dirty&tm; RL demo running against an OpenAI Gym server, built using:

- [Elixir](https://elixir-lang.org/)
- [Nx](https://github.com/elixir-nx/nx)
- [Axon](https://github.com/elixir-nx/axon)

- Video of training run with CartPole v1 [available](https://youtu.be/DsmE0VQgc5E).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `axon_rl_demo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:axon_rl_demo, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/axon_rl_demo](https://hexdocs.pm/axon_rl_demo).

### OpenAI Gym server

This requires an OpenAI Gym server to be running, using the **Python3** package from the [gym-http-server](https://github.com/saravanabalagi/gym-http-server) repo.  The file `requirements.py3` in this repo's root contains the pip dependencies to create and run the server.  Using virtualenv:

```bash
python3 -m venv ENV
. ENV/bin/activate
pip install -r requirements.py3
gym-http-server
```

Note that some systems don't have Python3 installed as `python3` so use whichever command you need to create a Python3 environment...

Once the server is up and running on your local (so you can see the agent playing CartPole-v1), run the Axon RL Demo agent!

### Axon RL Demo

The usual suspects: clone, get deps, run:

```bash
mix deps.get
mix run -e "AxonRLDemo.run()"
```
