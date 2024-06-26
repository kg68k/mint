# mint - Madoka INTerpreter

　X680x0 用ファイラ mint です。無保証につき各自の責任で使用してください。


## 新規インストール方法

　はじめて mint を使う場合は、以下の手順で導入してください。

1. 書庫に含まれるファイルを全て展開します。
2. mint.x を実行します。

　書庫に含まれる定義ファイル _mint はサンプルなので、自分の好みで書き換えて自由
にカスタマイズしてください。

　定義ファイルは以下の順で検索されます。好みによって、ファイル名やディレクトリを
変更することができます。

1. 環境変数 MINTRC3 で指定したファイル
2. 環境変数 MINTRC2 で指定したファイル
3. 環境変数 HOME で指定したディレクトリの .mint
4. 環境変数 HOME で指定したディレクトリの _mint
5. mint.x の存在するディレクトリの .mint
6. mint.x の存在するディレクトリの _mint


## アップデート方法

　すでに mint version 3 以降を使用している場合は、定義ファイル（_mint）以外のフ
ァイルを上書きしてください。


## 対応環境

### OS
　Human68k version 3.02 以降

### シェル
　COMMAND.X を使用する場合は、version 3.00 以降が望ましいです。

### IOCS
　以下のいずれかが必須です。
* IOCS バージョン 1.3 以降(X68030 の ROM)
* IOCS.X version 1.50
* HIOCS version 1.10+16
* HIOCS PLUS version version 1.10+16.19 以降

　68020 以降のアクセラレータを装着している場合は、`IOCS _SYS_STAT` が正常に動作
するようになっていることが必須です(MPU が68000の場合は不要)。

　アクセラレータを装着していたり、クロックアップ改造を行っている場合は、
`IOCS _TXRASCPY` が正常に動作するようになっていることが必須です。

### FLOAT (浮動小数点演算パッケージ)
　FLOAT が必須です。以下のバージョン以降が望ましいです。
* 060turbo.sys 内蔵パッケージ(-fe 指定が必要)
* FLOAT2.X version 2.03
* FLOAT3.X version 2.03
* FLOAT4.X version 1.02
  * 上記バージョンより古いものは正常動作しません。
  * MPU が68040、68060 の場合、FLOAT4.X 単体では正常動作しません。

### 060turbo.sys
　060turbo を装着している場合は以下のドライバが必須です。
* 060turbo.sys version 0.59 以降

### スプリアス割り込み対策
　スプリアス割り込みが発生する機体の場合、割り込み発生時に白帯が出ないようにする
ために HIOCS PLUS や curemfp などを組み込んでください(必須)。

### その他
　SRAM に記憶された設定によって起動時にキーボードの LED が点灯する場合、ROM IOCS
の不具合によりキー入力が正常に行えないことがあります。その場合は KeyWitch を組み
込む、LED を消灯する、SRAM の設定を変更して再起動するなどの処置をしてください。

　フリーソフトウェアのツール、ドライバ、常駐プログラムなどを使用する場合は、最新
(最終)バージョンを使用してください。古すぎると対応していないものもあります。


## 制限

　ファイルサイズが 2G バイト(2,147,483,648 バイト)以上のファイルは正常に取り扱う
ことができず、コピーや閲覧などの操作をしようとしてもエラーになります。

　これは Human68k の仕様による制限です。


## Build

　PC やネット上での取り扱いを用意にするために、src/ 内のファイルは UTF-8 で記述
されています。X680x0 上でビルドする際には、UTF-8 から Shift_JIS への変換が必要で
す。

### u8tosjを使用する方法

　あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をビルドしてインストール
しておいてください。

　トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. build/ ディレクトリの作成。
2. src/ 内の各ファイルを Shift_JIS に変換して build/ へ保存。

　次に、カレントディレクトリを build/ に変更し、`make`を実行してください。実行フ
ァイルが作成されます。

### u8tosjを使用しない方法

　ファイルを適当なツールで Shift_JIS に変換してから`make`を実行してください。
UTF-8 のままでは正しくビルドできませんので注意してください。


## 著作権及び配布規定

　GNU GENERAL PUBLIC LICENSE のバージョン3またはそれ以降のバージョンに従います。


## 参考資料

[AKT](http://akt.d.dooo.jp/)氏のmint_px2.zipを参考にしています。


## 連絡先

TcbnErik / 立花@桑島技研  
https://github.com/kg68k/mint
