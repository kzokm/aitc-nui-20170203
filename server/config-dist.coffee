# このファイルは各自の環境に合わせて書き換えてください。

module.exports =
  SERIAL_PORT: 'COM5'
  SERIAL_SPEED: 9600

  # PLOTLY_USERNAMEが設定されていない場合には、plot.lyへの出力を行いません
  PLOTLY_USERNAME: ''
  PLOTLY_API_KEY: ''
  PLOTLY_STREAM_TOKENS:
    temperature: ''
    humidity: ''
    pressure: ''
    wind: ''
    light: ''
    noise: ''
  PLOTLY_MAX_STREAM_POINTS: 10 * 24 * 3600

  # XBeeを使う場合は1にしてください。
  XBEE_API_MODE: 0
  XBEE_TARGET_ADDRESS: ''

  LOG_DIR: './log'
