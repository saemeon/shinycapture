from datetime import date, datetime
from typing import Literal

import matplotlib.pyplot as plt
import plotly.graph_objects as go
from dash import Dash, dcc, html

from s5ndt.mpl_export import FromPlotly, mpl_export_button, snapshot_figure

app = Dash(__name__)

# --- figure ---

graph = dcc.Graph(
    id="main-graph",
    figure=go.Figure(
        go.Scatter(x=[1, 2, 3, 4, 5], y=[4, 2, 5, 1, 3], mode="markers"),
        layout={
            "title": {"text": "All-types example"},
            "xaxis": {"title": {"text": "X axis"}},
        },
    ),
)


# --- renderer: full custom (figure data, all wizard field types) ---
# Demonstrates: figure-data renderer (no browser capture), FromPlotly defaults,
# all supported wizard field types (str, int, float, bool, date, datetime,
# Literal, list, tuple).


def custom_renderer(
    _fig_data,
    title: str = FromPlotly("layout.title.text", graph),  # type: ignore[assignment]
    xlabel: str = FromPlotly("layout.xaxis.title.text", graph),  # type: ignore[assignment]
    dpi: int = 100,
    alpha: float = 0.8,
    show_grid: bool = True,
    report_date: date | None = None,
    as_of: datetime | None = None,
    marker_style: Literal["o", "s", "^", "x"] = "o",
    y_ticks: list[float] | None = None,
    xlim: tuple[float, float] | None = None,
):
    x = _fig_data["data"][0]["x"]
    y = _fig_data["data"][0]["y"]

    fig, ax = plt.subplots(dpi=dpi)
    ax.scatter(x, y, alpha=alpha, marker=marker_style)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.grid(show_grid)

    if xlim:
        ax.set_xlim(*xlim)
    if y_ticks:
        ax.set_yticks(y_ticks)
    if report_date:
        fig.text(0, 0, str(report_date), fontsize=7)
    if as_of:
        ax.set_xlabel(f"as of {as_of.strftime('%Y-%m-%d %H:%M')}")

    return fig


# --- renderer: snapshot with matplotlib title overlay ---
# Demonstrates: browser-snapshot renderer (_img_b64), strip_title to remove the
# Plotly title before capture so matplotlib can draw its own, FromPlotly default.


def snapshot_with_title(
    _fig_data,
    _img_b64: str = "",
    title: str = FromPlotly("layout.title.text", graph),  # type: ignore[assignment]
    suptitle: str = "",
):
    fig, ax = snapshot_figure(_img_b64)
    if title:
        ax.set_title(title)
    if suptitle:
        fig.suptitle(suptitle)
    return fig


# --- layout ---

app.layout = html.Div(
    [
        graph,
        html.Div(
            style={"display": "flex", "gap": "8px", "flexWrap": "wrap"},
            children=[
                # 1. Simplest usage: default snapshot renderer, no configuration.
                mpl_export_button(
                    graph_id="main-graph",
                    label="Snapshot (default)",
                ),
                # 2. Custom figure-data renderer: rebuilds the chart from raw data,
                #    no browser capture required.
                mpl_export_button(
                    graph_id="main-graph",
                    renderer=custom_renderer,
                    label="Custom renderer",
                ),
                # 3. Snapshot with matplotlib title overlay: strips the Plotly title
                #    before capturing so the renderer can place its own.
                mpl_export_button(
                    graph_id="main-graph",
                    renderer=snapshot_with_title,
                    label="Snapshot + title overlay",
                    strip_title=True,
                ),
                # 4. High-resolution capture: scale=5 gives 5× pixel density.
                mpl_export_button(
                    graph_id="main-graph",
                    label="Snapshot high-res (scale=5)",
                    scale=5,
                ),
                # 5. Fixed capture size: overrides the displayed graph dimensions.
                mpl_export_button(
                    graph_id="main-graph",
                    label="Snapshot fixed size (800×400)",
                    width=800,
                    height=400,
                ),
                # 6. Fixed size + high-res: explicit dimensions combined with scale.
                mpl_export_button(
                    graph_id="main-graph",
                    label="Snapshot fixed + high-res (800×400, scale=3)",
                    width=800,
                    height=400,
                    scale=3,
                ),
            ],
        ),
    ]
)

if __name__ == "__main__":
    app.run(debug=True)
