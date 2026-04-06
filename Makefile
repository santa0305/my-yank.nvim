.PHONY: test test_file

# これまで通り全部実行
test:
	nvim --headless -u scripts/minimal_init.lua -c "lua dofile('scripts/minitest.lua')" -c "qa"

# 特定ファイルだけ実行（FILE 変数で指定）
test_file:
	FILE=$(FILE) nvim --headless -u scripts/minimal_init.lua -c "lua dofile('scripts/minitest.lua')" -c "qa"
