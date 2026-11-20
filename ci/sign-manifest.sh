#!/usr/bin/env bash
# 对 version.json 计算 ECDSA P-256 / SHA-256 签名，输出到 version.json.sig（DER 签名的 base64，单行）。
# 选 ECDSA 而非 Ed25519：Android 平台 Signature("Ed25519") 仅 API 33+ 支持，本项目 minSdk 26；
# SHA256withECDSA 全版本可用（Android 官方推荐算法）。DER 是 java.security/Java 与 Python cryptography
# 的默认签名格式，客户端用 Signature.getInstance("SHA256withECDSA").verify() 可直接验签。
# 私钥由 CI secret UPDATER_PRIVATE_KEY（PKCS#8 PEM 的 base64）经 env 传入，绝不落盘仓库。
# 公钥内置在两客户端，客户端验签顺序：验签 -> 解析 -> 选 artifact -> 下载 -> sha256 比对 -> 安装。
set -Eeuo pipefail
shopt -s inherit_errexit

: "${UPDATER_PRIVATE_KEY:?UPDATER_PRIVATE_KEY is required}"
MANIFEST=${1:-version.json}
SIG_OUT="${MANIFEST}.sig"

python3 - "$MANIFEST" "$SIG_OUT" <<'PY'
import base64, os, sys
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec

manifest, out = sys.argv[1], sys.argv[2]
pem = base64.b64decode(os.environ["UPDATER_PRIVATE_KEY"])
key = serialization.load_pem_private_key(pem, password=None)
if not isinstance(key, ec.EllipticCurvePrivateKey) or not isinstance(key.curve, ec.SECP256R1):
    raise SystemExit("UPDATER_PRIVATE_KEY 必须是 ECDSA P-256 (prime256v1) 私钥")
data = open(manifest, "rb").read()
der = key.sign(data, ec.ECDSA(hashes.SHA256()))   # DER 格式，java.security 直接可验
open(out, "w").write(base64.b64encode(der).decode() + "\n")
print(f"signed {manifest} -> {out} (ECDSA P-256 / DER)")
PY
