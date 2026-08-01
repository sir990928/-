#!/data/data/com.termux/files/usr/bin/bash
set -e
export DISPLAY=:99
# ZeroTermux build script lang=zh-Hans-CN zt-gui-v8 — 可手动编辑或由 AI 修改

                ensure_java() {
                  if command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1; then
                    return 0
                  fi
                  echo '[ZeroTermux Editor] 正在安装 OpenJDK…'
                  pkg install -y openjdk-17 || pkg install -y openjdk-21 || pkg install -y openjdk
                  if ! command -v javac >/dev/null 2>&1 || ! command -v java >/dev/null 2>&1; then
                    echo '[ZeroTermux Editor] OpenJDK 安装失败'
                    exit 1
                  fi
                }

                ensure_cc() {
                  if command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1 || command -v cc >/dev/null 2>&1; then
                    return 0
                  fi
                  echo '[ZeroTermux Editor] 正在安装 C 编译器 (clang)…'
                  pkg install -y clang || pkg install -y gcc
                  if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v cc >/dev/null 2>&1; then
                    echo '[ZeroTermux Editor] C 编译器安装失败'
                    exit 1
                  fi
                }

                resolve_cc() {
                  ensure_cc
                  if command -v gcc >/dev/null 2>&1; then
                    CC=gcc
                  elif command -v clang >/dev/null 2>&1; then
                    CC=clang
                  else
                    CC=cc
                  fi
                }

                ensure_python() {
                  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
                    return 0
                  fi
                  echo '[ZeroTermux Editor] 正在安装 Python…'
                  pkg install -y python
                  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
                    echo '[ZeroTermux Editor] Python 安装失败'
                    exit 1
                  fi
                }

                resolve_python() {
                  ensure_python
                  if command -v python3 >/dev/null 2>&1; then
                    PYTHON=python3
                  else
                    PYTHON=python
                  fi
                }

                ensure_php() {
                  if command -v php >/dev/null 2>&1; then
                    return 0
                  fi
                  echo '[ZeroTermux Editor] 正在安装 PHP 与 Composer…'
                  pkg install -y php composer
                  if ! command -v php >/dev/null 2>&1; then
                    echo '[ZeroTermux Editor] PHP 安装失败'
                    exit 1
                  fi
                }

                ensure_node() {
                  if command -v node >/dev/null 2>&1; then
                    return 0
                  fi
                  echo '[ZeroTermux Editor] 正在安装 Node.js 与 npm…'
                  pkg install -y nodejs
                  if ! command -v node >/dev/null 2>&1; then
                    echo '[ZeroTermux Editor] Node.js 安装失败'
                    exit 1
                  fi
                }

                editor_gui_frame_fresh() {
  [ -f "${HOME}/.zerotermux/gui/frame.jpg" ] && [ -s "${HOME}/.zerotermux/gui/frame.jpg" ] && return 0
  [ -f "${HOME}/.zerotermux/gui/frame.ppm" ] && [ -s "${HOME}/.zerotermux/gui/frame.ppm" ]
}
editor_gpu_env() {
  unset LIBGL_ALWAYS_SOFTWARE 2>/dev/null || true
}
stop_editor_gui_bridge() {
  if [ -f "${HOME}/.zerotermux/editor-gui.pid" ]; then
    while read -r _pid; do
      [ -n "$_pid" ] && kill "$_pid" 2>/dev/null || true
    done < "${HOME}/.zerotermux/editor-gui.pid"
    : > "${HOME}/.zerotermux/editor-gui.pid"
  fi
}
ensure_editor_xvfb() {
  if pgrep -f "Xvfb :99" >/dev/null 2>&1; then
    return 0
  fi
  pkill -f "Xvfb :99" 2>/dev/null || true
  mkdir -p "${HOME}/.zerotermux"
  Xvfb :99 -screen 0 800x600x24 -ac +extension GLX +render -noreset >>${HOME}/.zerotermux/editor-gui.log 2>&1 &
  sleep 1
  pgrep -f "Xvfb :99" >/dev/null 2>&1
}
editor_gui_capture_once() {
  export DISPLAY=:99
  mkdir -p "${HOME}/.zerotermux/gui"
  if command -v scrot >/dev/null 2>&1; then
    scrot -o "${HOME}/.zerotermux/gui/frame.tmp.jpg" 2>/dev/null \
      && mv -f "${HOME}/.zerotermux/gui/frame.tmp.jpg" "${HOME}/.zerotermux/gui/frame.jpg"
    return
  fi
  if command -v import >/dev/null 2>&1; then
    import -depth 8 -window root -display :99 \
      "jpeg:${HOME}/.zerotermux/gui/frame.tmp.jpg" 2>/dev/null \
      && mv -f "${HOME}/.zerotermux/gui/frame.tmp.jpg" "${HOME}/.zerotermux/gui/frame.jpg"
  fi
}
ensure_editor_gui_bridge() {
  export DISPLAY=:99
  mkdir -p "${HOME}/.zerotermux/gui" "${HOME}/.zerotermux/gui/input.d"
  stop_editor_gui_bridge
  (
    export DISPLAY=:99
    _input_dir="${HOME}/.zerotermux/gui/input.d"
    while true; do
      shopt -s nullglob 2>/dev/null || setopt nullglob 2>/dev/null || true
      for _cmd in "$_input_dir"/*.cmd; do
        [ -f "$_cmd" ] || continue
        _line=$(head -n 1 "$_cmd" 2>/dev/null)
        rm -f "$_cmd"
        [ -n "$_line" ] || continue
        case "$_line" in
          click:*)
            _xy="${_line#click:}"; _x="${_xy%%,*}"; _y="${_xy#*,}"
            xdotool mousemove "$_x" "$_y" click 1 2>/dev/null || true
            ;;
        esac
      done
      sleep 0.01
    done
  ) >>${HOME}/.zerotermux/editor-gui.log 2>&1 &
  echo $! >> "${HOME}/.zerotermux/editor-gui.pid"
  (
    export DISPLAY=:99
    while true; do
      editor_gui_capture_once
      sleep 0.08
    done
  ) >>${HOME}/.zerotermux/editor-gui.log 2>&1 &
  echo $! >> "${HOME}/.zerotermux/editor-gui.pid"
  sleep 0.2
  editor_gui_capture_once
}
start_editor_gui() {
  ensure_editor_xvfb || return 1
  ensure_editor_gui_bridge
}
ensure_editor_gui_stack() {
  export DISPLAY=:99
  editor_gpu_env
  start_editor_gui
}
refresh_editor_gui_display() {
  export DISPLAY=:99
  ensure_editor_gui_stack || return 1
  command -v xrefresh >/dev/null 2>&1 && xrefresh -display ":99" || true
}
wait_for_editor_gui() {
  for _ in $(seq 1 80); do
    if editor_gui_frame_fresh; then
      return 0
    fi
    if [ $(( _ % 4 )) -eq 0 ]; then
      editor_gui_capture_once 2>/dev/null || true
    fi
    sleep 0.25
  done
  return 1
}


                ensure_java_gui() {
                  export DISPLAY=:99
                  ensure_editor_gui_stack || exit 1
                  editor_gpu_env
                  if ! pkg list-installed 2>/dev/null | grep -q ttf-dejavu; then
                    echo '[ZeroTermux Editor] 正在安装 GUI 字体…'
                    pkg install -y ttf-dejavu 2>/dev/null || true
                  fi
                }

# 当前文件: Makefile
echo '请编辑 build.sh 以构建/运行 Makefile'
