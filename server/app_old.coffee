fs = require 'fs'
require 'date-utils'

XBEE_API_MODE = true
XBEE_TARGET_ADDRESS = '3756'
SERIAL_PORT = process.env.SERIAL_PORT

XBeeAPI = require 'xbee-api'
XBee = XBeeAPI.constants
xbee = new XBeeAPI.XBeeAPI
  api_mode: 1

xbee.on 'error', (e)->
  console.log 'error: xbee: ', e

serialport = require 'serialport'
com = new serialport.SerialPort SERIAL_PORT,
  baudRate: 115200
  parser: xbee.rawParser()

com.on 'error', (e)->
  console.log 'error: serialport: ', e

plotly = (require 'plotly')
  username: process.env.PLOTLY_USERNAME
  apiKey: process.env.PLOTLY_API_KEY

MAX_STREAM_POINTS = 5 * 24 * 3600 * 2

STREAM_TOKENS =
  'kazuhide.okamura': [
    'kqvjkftd9m'
    'lhqocrc0vl'
    '7k53evzppy'
    '6gjcn94rnk'
    'v6yko1qpi0'
    '8zoanohb22'
  ]
  'kzokm': [
    ''
    ''
    ''
    ''
    ''
    ''
  ]
stream_tokens = STREAM_TOKENS[process.env.PLOTLY_USERNAME]

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
    token: stream_tokens[0]
    #maxpoints: MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y2'
  name: graph_options.layout.yaxis2.title
  line: color: graph_options.layout.yaxis2.titlefont.color
  stream:
    token: stream_tokens[1]
    #maxpoints: MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y3'
  name: graph_options.layout.yaxis3.title
  line: color: graph_options.layout.yaxis3.titlefont.color
  stream:
    token: stream_tokens[2]
    #maxpoints: MAX_STREAM_POINTS
,
  x: []
  y: []
  yaxis: 'y4'
  name: graph_options.layout.yaxis4.title
  line: color: graph_options.layout.yaxis4.titlefont.color
  stream:
    token: stream_tokens[3]
    #maxpoints: MAX_STREAM_POINTS
,
  x: []
  y: []
  name: graph_options.layout.yaxis5.title
  line: color: graph_options.layout.yaxis5.titlefont.color
  yaxis: 'y5'
  stream:
    token: stream_tokens[4]
    #maxpoints: MAX_STREAM_POINTS
,
  x: []
  y: []
  name: graph_options.layout.yaxis6.title
  line: color: graph_options.layout.yaxis6.titlefont.color
  yaxis: 'y6'
  stream:
    token: stream_tokens[5]
    #maxpoints: MAX_STREAM_POINTS
]


plotly.plot init_data, graph_options, (err, msg)->
  throw err if err

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

  streams = {}
  for i in [0...(labels = 'thpwls').length]
    create_stream init_data[i].stream.token, (stream)->
      streams[labels.charAt i] = stream

  xbee.on 'frame_object', (frame)->
    console.log 'frame>', frame
    if frame.type == XBee.FRAME_TYPE.ZIGBEE_RECEIVE_PACKET or
        frame.type == XBee.FRAME_TYPE.ZIGBEE_EXPLICIT_RX
      if frame.remote16 == XBEE_TARGET_ADDRESS
        prepareReceivedData frame.data
    return

  previous_data = ''

  prepareReceivedData = (buffer)->
    data = previous_data += buffer.toString()
    if (p = data.indexOf '\n') >= 0
      previous_data = data.substring p + 1
      parseReceivedData data.substring 0, p
    return

  sum = {}

  parseReceivedData = (data)->
    now = new Date()
    console.log now, data

    try
      data = JSON.parse data
    catch
      return console.log 'error: JSON.parse'
    data.d = now

    log = now.toFormat 'log/YYYYMMDD.txt'
    fs.appendFile log, "#{JSON.stringify data}\r\n", 'utf8', (err)->
      console.log 'error:', err if err

    localtime = now.toFormat 'YYYY-MM-DD HH24:MI:SS.LL'

    for label of streams
      if label?
        stream_object = JSON.stringify
          x: localtime
          y: data[label]
        streams[label].write "#{stream_object}\r\n"
        console.log label, stream_object
    false
