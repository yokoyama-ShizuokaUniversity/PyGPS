# micropyGPS の導入ガイド

このプロジェクトは GPS パースに [ **micropyGPS** ](https://github.com/inmcm/micropyGPS) を利用します。  
micropyGPS は MIT License で公開されている 1 ファイル構成のライブラリです（`micropyGPS.py`）。

---

## 導入方法（おすすめ順）

### 1) pip で GitHub から直接インストール（最も手軽）

```bash
# プロジェクト直下で
python -m venv .venv
source .venv/bin/activate

# 最新版をインストール
pip install "git+https://github.com/inmcm/micropyGPS.git"
```