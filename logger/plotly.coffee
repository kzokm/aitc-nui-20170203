config = require './config'

plotly = (require 'plotly')
  username: config.PLOTLY_USERNAME
  apiKey: config.PLOTLY_API_KEY

graph_options =
  fileopt: 'extend'
  filename: 'bedroom-environments'
  layout:
    title: 'Bedroom'
    xaxis:
      title: 'date'
      type: 'date'
      autorange: true
    yaxis:
      title: 'temperature'
      titlefont: color: '#7dd667'
      tickfont: color: '#7dd667'
      range: [0, 40]
    yaxis2:
      title: 'humidity'
      titlefont: color: '#1f77b4'
      tickfont: color: '#1f77b4'
      range: [0, 100]
      overlaying: 'y'
      side: 'left'
      anchor: 'free'
      position: 0.05
    yaxis3:
      title: 'pressure'
      titlefont: color: '#c76edb'
      tickfont: color: '#c76edb'
      range: [900, 1100]
      overlaying: 'y'
      side: 'left'
      anchor: 'free'
      position: 0.10
    yaxis4:
      title: 'wind'
      titlefont: color: '#15e8da'
      tickfont: color: '#15e8da'
      range: [0, 200]
      overlaying: 'y'
      side: 'right'
      anchor: 'free'
      position: 0.90
    yaxis5:
      title: 'light'
      titlefont: color: '#ffbb0e'
      tickfont: color: '#ffbb0e'
      range: [0, 1024]
      overlaying: 'y'
      side: 'right'
      anchor: 'free'
      position: 0.95
    yaxis6:
      title: 'noise'
      titlefont: color: '#d62728'
      tickfont: color: '#d62728'
      range: [0, 1024]
      overlaying: 'y'
      side: 'right'

init_data = [
  x: []
  y: []
  name: graph_options.layout.yaxis.title
  line: color: graph_options.layout.yaxis.titlefont.color
  stream:
    token: config.PLOTLY_STREAM_TOKENS.temperature
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y2'
  name: graph_options.layout.yaxis2.title
  line: color: graph_options.layout.yaxis2.titlefont.color
  stream:
    token: config.PLOTLY_STREAM_TOKENS.humidity
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y3'
  name: graph_options.layout.yaxis3.title
  line: color: graph_options.layout.yaxis3.titlefont.color
  stream:
    token: config.PLOTLY_STREAM_TOKENS.pressure
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y4'
  name: graph_options.layout.yaxis4.title
  line: color: graph_options.layout.yaxis4.titlefont.color
  stream:
    token: config.PLOTLY_STREAM_TOKENS.wind
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
,
  x: []
  y: []
  name: graph_options.layout.yaxis5.title
  line: color: graph_options.layout.yaxis5.titlefont.color
  yaxis: 'y5'
  stream:
    token: config.PLOTLY_STREAM_TOKENS.light
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
,
  x: []
  y: []
  name: graph_options.layout.yaxis6.title
  line: color: graph_options.layout.yaxis6.titlefont.color
  yaxis: 'y6'
  stream:
    token: config.PLOTLY_STREAM_TOKENS.noise
    maxpoints: config.PLOTLY_MAX_STREAM_POINTS
]

data_keys = 'thpwls'

@plot = (callback)->
  create_stream = (token, callback)->
    stream = plotly.stream token, (err, res)->
      if err
        console.log err
        clearInterval timer
        stream.end ->
        stream = create_stream token, callback
        callback stream
    callback stream
    timer = setInterval health_check(stream), 50000
    stream

  health_check = (stream)->
    -> stream.write '\r\n'

  summary =
    reset: ->
      for name in data_keys
        @[name] =
          min: Number.MAX_VALUE
          max: Number.MIN_VALUE
          sum: 0
          ave: 0
          count: 0
      @

    put: (name, value)->
      s = @[name]
      if value >= 1024 or value < s.ave / 10
        return console.log 'error: invalid value', name, value
      s.count += 1
      s.sum += value
      s.ave = s.sum / s.count
      s.min = Math.min s.min, value
      s.max = Math.max s.min, value

  previous_time = new Date().getTime()
  PLOT_INTERVAL_MILLIS = 10 * 1000

  putData = (data)->
    for name in data_keys
      try
        summary.put name, data[name]
      catch error
        console.log 'error: summary.put', name, error

    now = data.d
    if now.getTime() >= previous_time + PLOT_INTERVAL_MILLIS
      localtime = now.toFormat 'YYYY-MM-DD HH24:MI:SS.LL'

      for name of streams
        if name?
          type =
            if name == 's' then 'max' else 'ave'
          stream_object = JSON.stringify
            x: localtime
            y: summary[name][type].toFixed(2)
          streams[name].write "#{stream_object}\r\n"
          console.log name, stream_object

      do summary.reset
      previous_time = now.getTime()

  plotly.plot init_data, graph_options, (err, msg)->
    streams = []
    for i, key of data_keys
      create_stream init_data[i].stream.token, (stream)->
        streams[key] = stream

    do summary.reset

    callback
      put: putData
