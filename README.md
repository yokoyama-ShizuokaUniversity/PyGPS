# micropyGPS の導入ガイド

このプロジェクトは GPS パースに **micropyGPS** を利用します。  
micropyGPS は MIT License で公開されている 1 ファイル構成のライブラリです（`micropyGPS.py`）。

---

## 導入方法（おすすめ順）

### 1) pip で GitHub から直接インストール（最も手軽）

```bash
# プロジェクト直下で
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

# 最新版をインストール
pip install "git+https://github.com/inmcm/micropyGPS.git"

# 特定コミットに固定（再現性が必要な場合）
pip install "git+https://github.com/inmcm/micropyGPS.git@<commit-hash>"
