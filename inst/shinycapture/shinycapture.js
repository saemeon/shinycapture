/*
 * shinycapture — Browser-side capture pipeline for Shiny.
 *
 * Three-stage architecture:
 *   1. preprocess (JS) — modify element before capture
 *   2. capture (JS)    — element → base64 string
 *   3. postprocess (R) — raw bytes → processed bytes (server-side)
 *
 * Strip-patch JS fragments are kept in sync with the Python version
 * in packages/dash-capture/src/dash_capture/strategies.py.
 */

var shinycapture = {

  // ---- Built-in capture strategies ----

  strategies: {
    plotly: {
      capture: async function(el, opts) {
        var graphDiv = el.querySelector('.js-plotly-plot') || el;
        var target = el._scap_tmp || graphDiv;
        try {
          return await Plotly.toImage(target, opts);
        } finally {
          if (el._scap_tmp) {
            document.body.removeChild(el._scap_tmp);
            delete el._scap_tmp;
          }
        }
      }
    },
    html2canvas: {
      capture: async function(el, opts) {
        if (!window.html2canvas) {
          console.error('shinycapture: html2canvas is not loaded. '
            + 'Include it via tags$script(src=...) in your UI.');
          return null;
        }
        var canvas = await html2canvas(el, {
          scale: opts.scale || 2,
          useCORS: true,
          logging: false
        });
        return canvas.toDataURL('image/png');
      }
    },
    canvas: {
      capture: async function(el, opts) {
        var cvs = el.querySelector('canvas') || el;
        return cvs.toDataURL('image/' + (opts.format || 'png'));
      }
    }
  },

  // ---- Pipeline runner ----

  run: async function(el, strategyName, preprocessJs, opts) {
    var strategy = shinycapture.strategies[strategyName];
    if (!strategy) {
      console.error('shinycapture: unknown strategy "' + strategyName + '"');
      return null;
    }

    // Stage 1: preprocess (async — may contain await for Plotly.newPlot etc.)
    if (preprocessJs) {
      var AsyncFunction = Object.getPrototypeOf(async function(){}).constructor;
      var preprocess = new AsyncFunction('el', 'opts', 'graphDiv', preprocessJs);
      var graphDiv = el.querySelector('.js-plotly-plot') || el;
      await preprocess(el, opts, graphDiv);
    }

    // Stage 2: capture
    return await strategy.capture(el, opts);
  }
};

// ---- Shiny message handler ----

Shiny.addCustomMessageHandler('shinycapture-capture', async function(msg) {
  var el = document.getElementById(msg.id);
  if (!el) {
    console.error('shinycapture: element "' + msg.id + '" not found');
    return;
  }

  var opts = msg.opts || {};
  var base64 = await shinycapture.run(
    el,
    msg.strategy || 'plotly',
    msg.preprocess_js || null,
    opts
  );

  if (base64) {
    Shiny.setInputValue(
      msg.input_id,
      base64,
      { priority: 'event' }
    );
  }
});
