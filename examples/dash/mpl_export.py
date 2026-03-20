import io
from datetime import date, datetime
from typing import Literal

import matplotlib.pyplot as plt
import plotly.graph_objects as go
from dash import Dash, dcc, html

from s5ndt import FieldSpec, FromPlotly, graph_exporter

plt.switch_backend("agg")

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
# Demonstrates: _fig_data renderer (no browser capture), FromPlotly defaults,
# all supported field types (str, int, float, bool, date, datetime, Literal,
# list, tuple), filename, styles/class_names.


def custom_renderer(
    _target,
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
    try:
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

        fig.savefig(_target, format="png", bbox_inches="tight")
    finally:
        plt.close(fig)


# --- renderer: snapshot with matplotlib title overlay ---
# Demonstrates: _snapshot_img, strip_*, capture_scale forwarded to Plotly.toImage.


def snapshot_with_title(
    _target,
    _snapshot_img,
    title: str = FromPlotly("layout.title.text", graph),  # type: ignore[assignment]
    suptitle: str = "",
    capture_scale: int = 3,
):
    dpi = 300
    img = plt.imread(io.BytesIO(_snapshot_img()))
    h, w = img.shape[:2]
    fig, ax = plt.subplots(figsize=(w / dpi, h / dpi), dpi=dpi)
    try:
        ax.imshow(img)
        ax.axis("off")
        if title:
            ax.set_title(title)
        if suptitle:
            fig.suptitle(suptitle)
        fig.savefig(_target, format="png", bbox_inches="tight", pad_inches=0)
    finally:
        plt.close(fig)


# --- renderer: configurable capture dimensions ---
# Demonstrates: capture_width/height/scale forwarded to Plotly.toImage.


def snapshot_sized(
    _target,
    _snapshot_img,
    capture_width: int = 800,
    capture_height: int = 400,
    capture_scale: int = 3,
    dpi: int = 300,
):
    img = plt.imread(io.BytesIO(_snapshot_img()))
    h, w = img.shape[:2]
    fig, ax = plt.subplots(figsize=(w / dpi, h / dpi), dpi=dpi)
    try:
        fig.subplots_adjust(0, 0, 1, 1)
        ax.imshow(img)
        ax.axis("off")
        fig.savefig(_target, format="png", bbox_inches="tight", pad_inches=0)
    finally:
        plt.close(fig)


# --- renderer: component_overrides demo ---
# Demonstrates: multiple overrides — dcc.Slider for dpi, dcc.RadioItems for
# capture_scale. Renderer stays plain Python; widgets wired at the call site.


def snapshot_with_overrides(
    _target,
    _snapshot_img,
    dpi: int = 300,
    capture_scale: int = 2,
):
    img = plt.imread(io.BytesIO(_snapshot_img()))
    h, w = img.shape[:2]
    fig, ax = plt.subplots(figsize=(w / dpi, h / dpi), dpi=dpi)
    try:
        ax.imshow(img)
        ax.axis("off")
        fig.savefig(_target, format="png", bbox_inches="tight", pad_inches=0)
    finally:
        plt.close(fig)


# --- layout ---

app.layout = html.Div(
    [
        graph,
        html.Div(
            style={"display": "flex", "gap": "8px", "flexWrap": "wrap"},
            children=[
                # 1. Default snapshot renderer — simplest usage, zero config.
                graph_exporter(
                    graph=graph,
                    trigger="Snapshot (default)",
                ),
                # 2. Custom figure-data renderer — all field types, FromPlotly,
                #    custom filename, narrowed number inputs via styles.
                graph_exporter(
                    graph=graph,
                    renderer=custom_renderer,
                    trigger="Custom renderer",
                    filename="scatter.png",
                    styles={"int": {"width": "70px"}, "float": {"width": "70px"}},
                ),
                # 3. Snapshot + title overlay — strip all Plotly chrome before
                #    capture (title, legend, annotations, axis titles, margin,
                #    colorbar); renderer redraws its own title.
                graph_exporter(
                    graph=graph,
                    renderer=snapshot_with_title,
                    trigger="Snapshot + overlay",
                    strip_title=True,
                    strip_legend=True,
                    strip_annotations=True,
                    strip_axis_titles=True,
                    strip_colorbar=True,
                    strip_margin=True,
                ),
                # 4. Configurable capture size — capture_width/height/scale
                #    forwarded to Plotly.toImage, wider dialog via styles.
                graph_exporter(
                    graph=graph,
                    renderer=snapshot_sized,
                    trigger="Capture params",
                    styles={"dialog": {"minWidth": "700px"}},
                ),
                # 5. Component overrides — dcc.Slider for dpi, dcc.RadioItems
                #    for capture_scale; renderer is plain Python.
                graph_exporter(
                    graph=graph,
                    renderer=snapshot_with_overrides,
                    trigger="Component overrides",
                    field_specs={
                        "dpi": FieldSpec(
                            component=dcc.Slider(
                                min=72,
                                max=600,
                                step=None,
                                marks={72: "72", 150: "150", 300: "300", 600: "600"},
                                value=300,
                                tooltip={"placement": "bottom", "always_visible": True},
                            )
                        ),
                        "capture_scale": FieldSpec(
                            component=dcc.RadioItems(
                                options=[
                                    {"label": f" {v}×", "value": v}
                                    for v in [1, 2, 3, 4]
                                ],
                                value=2,
                                inline=True,
                            )
                        ),
                    },
                ),
                # 6. Styled wizard — dialog, title, close, buttons, labels, and
                #    field inputs all styled via the styles dict.
                graph_exporter(
                    graph=graph,
                    renderer=custom_renderer,
                    trigger="Styled wizard",
                    styles={
                        "dialog": {
                            "borderRadius": "12px",
                            "boxShadow": "0 8px 40px rgba(0,0,0,0.2)",
                            "background": "#1e1e2e",
                            "color": "#cdd6f4",
                        },
                        "title": {
                            "fontSize": "16px",
                            "fontWeight": "700",
                            "color": "#cba6f7",
                        },
                        "close": {
                            "background": "transparent",
                            "border": "none",
                            "color": "#6c7086",
                            "fontSize": "16px",
                            "cursor": "pointer",
                        },
                        "button": {
                            "background": "#cba6f7",
                            "color": "#1e1e2e",
                            "border": "none",
                            "padding": "6px 14px",
                            "borderRadius": "6px",
                            "fontWeight": "600",
                            "cursor": "pointer",
                        },
                        "label": {
                            "fontSize": "11px",
                            "fontWeight": "600",
                            "textTransform": "uppercase",
                            "letterSpacing": "0.06em",
                            "color": "#a6adc8",
                        },
                        "str": {
                            "background": "#313244",
                            "border": "1px solid #45475a",
                            "borderRadius": "4px",
                            "color": "#cdd6f4",
                            "padding": "3px 6px",
                        },
                        "int": {
                            "width": "70px",
                            "background": "#313244",
                            "border": "1px solid #45475a",
                            "borderRadius": "4px",
                            "color": "#cdd6f4",
                            "padding": "3px 6px",
                        },
                        "float": {
                            "width": "70px",
                            "background": "#313244",
                            "border": "1px solid #45475a",
                            "borderRadius": "4px",
                            "color": "#cdd6f4",
                            "padding": "3px 6px",
                        },
                        "literal": {"background": "#313244", "color": "#cdd6f4"},
                    },
                ),
                # 7. Custom trigger component — placed here via walrus operator;
                #    graph_exporter returns only the hidden store + modal.
                (
                    custom_btn := html.Button(
                        "Custom trigger",
                        id="custom-export-btn",
                        style={
                            "backgroundColor": "#e74c3c",
                            "color": "white",
                            "border": "none",
                            "padding": "8px 16px",
                            "cursor": "pointer",
                            "borderRadius": "4px",
                        },
                    )
                ),
                graph_exporter(graph=graph, trigger=custom_btn),
            ],
        ),
    ]
)

if __name__ == "__main__":
    app.run(debug=True, port=1234)
