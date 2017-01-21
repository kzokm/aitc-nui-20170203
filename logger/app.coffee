config = require './config'
for k of config
 if process.env[k]
   config[k] = process.env[k]

fs = require 'fs'
require 'date-utils'

fs.exists config.LOG_DIR, (exists)->
  fs.mkdir config.LOG_DIR unless exists

if config.XBEE_API_MODE
  XBeeAPI = require 'xbee-api'
  XBee = XBeeAPI.constants
  xbee = new XBeeAPI.XBeeAPI
    api_mode: config.XBEE_API_MODE

  xbee.on 'error', (e)->
    console.log 'error: xbee: ', e

serialport = require 'serialport'
com = new serialport.SerialPort config.SERIAL_PORT,
  baudRate: config.SERIAL_SPEED
  parser: xbee?.rawParser() || serialport.parsers.readline '\n'

com.on 'error', (e)->
  console.log 'error: serialport: ', e

new Promise (resolve)->
  if config.PLOTLY_USERNAME
    require './plotly'
      .plot (plot)->
        resolve plot
  else
    resolve null

.then (plot)->
  xbee?.on 'frame_object', (frame)->
    console.log 'frame>', frame
    if frame.type == XBee.FRAME_TYPE.ZIGBEE_RECEIVE_PACKET or
        frame.type == XBee.FRAME_TYPE.ZIGBEE_EXPLICIT_RX
      if frame.remote16 == config.XBEE_TARGET_ADDRESS
        prepareReceivedData frame.data
    return

  previous_data = ''

  prepareReceivedData = (buffer)->
    data = previous_data += buffer.toString()
    if (p = data.indexOf '\n') >= 0
      previous_data = data.substring p + 1
      parseReceivedData data.substring 0, p
    return

  com.on 'data', (data)->
    parseReceivedData data

  parseReceivedData = (data)->
    now = new Date()
    console.log now, data

    try
      data = JSON.parse data
    catch
      return console.log 'error: JSON.parse'
    data.d = now

    log = now.toFormat "#{config.LOG_DIR}/YYYYMMDD.txt"
    fs.appendFile log, "#{JSON.stringify data}\r\n", 'utf8', (err)->
      console.log 'error:', err if err

    plot?.put data
