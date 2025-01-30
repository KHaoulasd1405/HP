After any pull:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

To run the app:

```bash
julia --project=. Julia/app.jl
```

Then open a browser and go to : http://localhost:8050