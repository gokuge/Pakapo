# Pakapo
![Pakapo](https://user-images.githubusercontent.com/57989544/70847481-52295180-1ea8-11ea-964f-4ff5f6cfe82e.png)

Mac OS用の少機能イメージビューアです  
Mac OSで愛用していた偉大なcooViewerが、catalinaの登場により利用出来なくなってしまいました  
色々と代替アプリを探してみたのですが、しっくり来るのが見つからなかったので  
主に自分の使っていた機能の範囲で、cooViewerっぽいものを作りました

## インストール
1. [release](https://github.com/gokuge/Pakapo/releases) から最新バージョンのdmgをDLして下さい
2. DLしたdmgをマウント後、Pakapo.appをアプリケーションフォルダ等に入れて下さい

## 使い方
メニューの開くからファイル/フォルダを選択し、  
キーボードショートカット/マウス操作でファイルを表示していきます  

### 表示する順番について
選択されたフォルダ(ファイルを選択していた場合は  
そのファイルが含まれているフォルダ)の中身を  

- 名前順
- ファイル優先
- サブフォルダは後回し

の順に表示していきます  
フォルダ内のファイルを表示し終えたらサブフォルダへ移動します  
(サブフォルダを読み込むかどうかはメニューで選択出来ます)

#### 圧縮ファイルについて
zipに対応しています  
メモリ上に展開し、中にあるファイルを表示します  

### 表示形式について
ファイルの表示形式は下記があります  
メニュー、キーボードショートカットのいずれかで変更出来ます

- 画面内に収める
  - ウィンドウサイズに合わせて長辺フィットさせて表示します
- 画面の横幅に合わせる
  - ウィンドウサイズの横一杯に合わせて表示します
- 画面に合わせない
  - スケールなしで表示します
    - ウィンドウサイズより小さいサイズのファイルの場合は長辺フィットします
- 見開き分割
  - 横幅が一定以上(740px以上)の場合は横幅2倍で表示します
  - 一定未満の場合は横幅フィットで表示します

#### 拡大縮小について
どの表示形式でも表示しているファイルの拡大縮小が可能です  
メニュー、マウススクロール、ピンチイン/ピンチアウトのいずれかで変更出来ます  
**拡大縮小中はマウススクロールの挙動が変わります**

### キーボードショートカット
最も優先される動作です。表示形式やズーム中等の状態に左右される事はありません  
(ページ送りの方向についてはメニューで選択出来ます)

|      |  右ページ送り / 左ページ送り  |
| ---- | ---- |
|  →  |  次のページへ / 前のページへ  |
|  ←  |  前のページへ / 次のページへ  |
|  ↑  |  前のフォルダへ  |
|  ↓  |  次のフォルダへ  |
|  esc  |  フルスクリーン解除  |

### マウス/トラックパッド操作
表示形式やズーム中等の状態に左右される項目があります

- 主ボタン(左クリック)
  - ウィンドウの中心から右をクリックでキーボードショートカットの → と同等
  - ウィンドウの中心から左をクリックでキーボードショートカットの ← と同等
- 副ボタン(右クリック)
  - 表示中のファイルをFinderで表示
  - 表示中のファイルをコピー
  - 表示中のフォルダをFinderで表示
  - 表示中のフォルダをコピー
- マウススクロール
  - スクロールのみ
    - 表示形式が「画面内に収める」で、拡大縮小していない場合
      - 上方向で前のページを表示
      - 下方向で次のページを表示
    - それ以外の場合
      - 表示しているウィンドウのスクロール
  - Controlキー + スクロール
    - 拡大/縮小
- ピンチイン/ピンチアウト
  - 拡大/縮小

## ループの挙動
下記に細かいループの挙動を記載しますが、  
実際に使って見た方が理解しやすいと思います  

### 図説
下記のようなツリー構造があったとして

```
tmp_dir
├── tmp1.jpg
├── tmp2.jpg   
├── A_dir  
│   ├── A1.jpg  
│   └── Aa_dir  
│   │   └── Aa1.jpg  
│   └── Ab_dir  
│       └── Ab1.jpg  
├── B_dir  
│   ├── B1.jpg  
│   └── Ba_dir  
│       └── Baa_dir  
│           └── Baa1.jpg
│           └── Baa2.jpg  
├── C_dir  
    └── Ca_dir    
```
- **A_dir** を開いた場合は **A1.jpg** が表示されます
- A_dirを持っているtmp_dirがrootとして設定されます
  - rootより上の階層は表示対象になりません
  - rootは**ファイル/フォルダを開いた際に決定します**
- A1.jpgから次のページへの挙動(前へは逆)
  - サブフォルダを読み込む
    - Aa1.jpg -> Ab1.jpg -> B1.jpg -> Baa1.jpg -> Baa2.jpg -> tmp1.jpg -> tmp2.jpg -> A1.jpg
  - サブフォルダを読み込まない
    - Aa1.jpg -> B1.jpg -> tmp1.jpg -> tmp2.jpg -> A1.jpg
- A1.jpgから次のフォルダへの挙動
  - サブフォルダを読み込む
    - Aa1.jpg
  - サブフォルダを読み込まない
    - B1.jpg
- B1.jpgから前のフォルダへの挙動
  - サブフォルダを読み込む
    - Ab1.jpg
  - サブフォルダを読み込まない
    - A1.jpg
- tmp1.jpgから前のフォルダへの挙動
  - サブフォルダを読み込む
    - Baa1.jpg
  - サブフォルダを読み込まない
    - B1.jpg

## 謝辞
- coo様(cooViewer開発者)
- [codelynx]((https://github.com/codelynx))様(ZUnzip作者)

## Licence
- `Pakapo` - MIT
- `ZUnzip` - [MIT](https://github.com/codelynx/ZUnzip/blob/master/LICENSE.md)
- `fmemopen` - [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0)
- `libzip` - [zlib license](https://libzip.org/license/)
