[![PyPI](https://img.shields.io/pypi/v/dash-fn-interact)](https://pypi.org/project/dash-fn-interact/)
[![Python](https://img.shields.io/pypi/pyversions/dash-fn-interact)](https://pypi.org/project/dash-fn-interact/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Plotly](https://img.shields.io/badge/Plotly-3F4F75?logo=plotly&logoColor=white)](https://plotly.com/python/)
[![Dash](https://img.shields.io/badge/Dash-008DE4?logo=plotly&logoColor=white)](https://dash.plotly.com/)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json)](https://github.com/astral-sh/uv)
[![ty](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ty/main/assets/badge/v0.json)](https://github.com/astral-sh/ty)
[![prek](https://img.shields.io/badge/prek-checked-blue)](https://github.com/saemeon/prek)

# dash-fn-interact

An introspection-based UI generator for Plotly Dash. Automatically transform type-hinted Python functions into reactive Dash forms.

**Documentation: [saemeon.github.io/dash-fn-interact](https://saemeon.github.io/dash-fn-interact/)**

## Installation

```bash
pip install dash-fn-interact
```

## Quickstart

```python
from dash import Dash, Input, Output, html
from dash_fn_interact import build_config

app = Dash(__name__)

def my_renderer(title: str = "Chart", dpi: int = 150, show_grid: bool = True):
    ...

cfg = build_config("render", my_renderer)

app.layout = html.Div([
    cfg.div,
    html.Button("Apply", id="apply"),
])

@app.callback(Output("result", "children"), Input("apply", "n_clicks"), *cfg.states)
def on_apply(n, *values):
    kwargs = cfg.build_kwargs(values)
    # kwargs == {"title": "Chart", "dpi": 150, "show_grid": True}
    ...
```

## API

| Name | Description |
|------|-------------|
| `build_config(id, fn, field=FieldSpec(...), field=(min,max,step), ...)` | Introspect a callable into a `Config` |
| `Config.div` | `html.Div` with labeled input fields — embed anywhere |
| `Config.states` | `list[State]` to pass to a Dash callback |
| `Config.build_kwargs(values)` | Reconstruct typed `**kwargs` from callback values |
| `Config.register_populate_callback(input)` | Auto-fill hooked fields when a dialog opens |
| `Config.register_restore_callback(input)` | Reset all fields to defaults |
| `FieldSpec` | Per-field customization (label, style, component override, min/max/step, hook) |
| `FieldHook` | Base class for runtime defaults derived from Dash state |
| `FromComponent(component, prop)` | Built-in hook — reads another component's property as the default |
| `field_id(config_id, name)` | Compute the Dash component ID for a field |

**Supported types:** `str`, `int`, `float`, `bool`, `date`, `datetime`, `Literal[...]`, `list[T]`, `tuple[T, ...]`, `T | None`

## Credits

| Feature | Inspiration |
|---------|-------------|
| `visible` rules (conditional field visibility) | [dash-pydantic-form](https://github.com/RenaudLN/dash-pydantic-form) — the idea of encoding visibility conditions in a component's `id` dict and handling all visibility toggling in a single clientside callback via pattern matching (`ALL`/`MATCH`) comes directly from their implementation. |

## License

MIT
