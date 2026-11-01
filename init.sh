#!/bin/bash
#script for colab

mkdir -v /content/{data,engines,model}
DIR_ENGINES="/content/engines"
DIR_DATA="/content/data"
DIR_MODEL="/content/model"

pip install -q meson ninja chess

echo "=== 1. Stockfish 클론 & 빌드 ==="
if [ ! -d "Stockfish" ]; then
  git clone --depth 1 https://github.com/official-stockfish/Stockfish.git
fi
cd Stockfish/src
make -j profile-build
#strip stockfish
cp -f stockfish "${DIR_ENGINES}/stockfish"
chmod +x "${DIR_ENGINES}/stockfish"
echo "Stockfish → ${DIR_ENGINES}/stockfish"

########################################
# Lc0 빌드 (CUDA)
########################################
echo "=== 2. Lc0 클론 & 빌드 ==="
if [ ! -d "lc0" ]; then
  git clone -b release/0.32 https://github.com/LeelaChessZero/lc0.git
fi
cd lc0

# CUDA backend로 빌드 (Colab T4용)
./build.sh || {
  # 실패 시 meson 직접 시도
  meson setup build/release --buildtype=release -Dgtest=false
  meson compile -C build/release
}

LC0_BIN="$(find build -name lc0 -type f -executable | head -n1)"
if [ -z "${LC0_BIN}" ]; then
  echo "ERROR: lc0 실행 파일을 찾을 수 없습니다."
  exit 1
fi
cp -f "${LC0_BIN}" "${DIR_ENGINES}/lc0"
chmod +x "${DIR_ENGINES}/lc0"
cd "${BUILD_DIR}"
echo "Lc0 → ${DIR_ENGINES}/lc0"

########################################
# Lc0 네트워크 (T4용 가장 큰 권장 네트워크)
# BT4-1024 (~4GB VRAM) — T4 16GB에서 여유 있게 동작
########################################
echo "=== 3. Lc0 네트워크 다운로드 (BT4 Very Large) ==="
NET_NAME="BT4-1024x15x32h-swa-6147500.pb.gz"
NET_URL="https://storage.lczero.org/files/networks-contrib/big-transformers/${NET_NAME}"
NET_PATH="${DIR_MODEL}/model.pb.gz"

if [ ! -f "${NET_PATH}" ]; then
  wget -q --show-progress -O "${NET_PATH}" "${NET_URL}" \
    || curl -L -o "${NET_PATH}" "${NET_URL}"
fi
echo "Network → ${NET_PATH}"

########################################
# 결과 확인
########################################
echo ""
echo "=== 설치 완료 ==="
echo "engines:"
ls -lh "${DIR_ENGINES}"
echo ""
echo "model:"
ls -lh "${DIR_MODEL}"
echo ""