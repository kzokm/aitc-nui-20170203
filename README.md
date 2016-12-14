# aitc-nui-20161208
JS2017に向けた睡眠環境データ収集

This repository was forked from https://github.com/kzokm/aitc-nui-20160916

## ./arduino
Arduino用のスケッチです

## ./server
Arduinoで測定したデータを収集するサーバープログラムです。

1. Node.jsをインストールしてください
2. serverディレクトリ下で npm install を実行してください
3. config.coffee ファイルを各自の動作環境に合わせて書き直してください(COMポートなど）
4. node index.js でサーバが起動します
5. logディレクトリ下に測定データファイルが保存されます
