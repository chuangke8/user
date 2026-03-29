#!/usr/bin/env bash
# ==================================================
# Dujiao-Next - One-Click Deploy & Ops Script
# Author  : LangGe  Telegram: @luoyanglang
# Modified: chuangke8/user (Tag: v0.1.7) for Docker
# Based on: dujiao-next/community-projects (MIT)
# ==================================================
set -euo pipefail

# ── Repos ──────────────────────────────────────────
DUJIAO_API_REPO="dujiao-next/dujiao-next"
# 修改点：更换 User 仓库源
DUJIAO_USER_REPO="chuangke8/user"
DUJIAO_ADMIN_REPO="dujiao-next/admin"

# ── State ──────────────────────────────────────────
STATE_DIR="${HOME}/.dujiao-next-one-click"
STATE_FILE="${STATE_DIR}/state.env"

# ── Author ─────────────────────────────────────────
AUTHOR_TG="https://t.me/luoyanglang"
AUTHOR_DONATE="TMW6EFjwrqrEU827oLZgiig9fkuVi3nfCA"

# ── Colors ─────────────────────────────────────────
if [[ -t 1 ]]; then
  R=$'\033[0;31m' G=$'\033[0;32m' Y=$'\033[1;33m'
  B=$'\033[0;34m' C=$'\033[0;36m' M=$'\033[0;35m'
  BOLD=$'\033[1m' DIM=$'\033[2m' BM=$'\033[95m' NC=$'\033[0m'
else
  R='' G='' Y='' B='' C='' M='' BOLD='' DIM='' BM='' NC=''
fi

# ── Print helpers ──────────────────────────────────
info()    { printf "${B}[INFO]${NC} %s\n" "$1"; }
warn()    { printf "${Y}[WARN]${NC} %s\n" "$1"; }
error()   { printf "${R}[ERROR]${NC} %s\n" "$1" >&2; }
success() { printf "${G}[OK]${NC} %s\n" "$1"; }
print_line() { printf '%s\n' "────────────────────────────────────────────────────"; }

# ── Author info ────────────────────────────────────
print_author() {
  echo ""
  print_line
  echo "  ${C}☕ 如果本脚本对你有帮助，欢迎请作者喝杯咖啡：${NC}"
  echo "      USDT (TRC20): ${Y}${AUTHOR_DONATE}${NC}"
  echo ""
  echo "  ${C}📬 遇到问题？联系作者获取支持：${NC}"
  echo "      Telegram: ${Y}${AUTHOR_TG}${NC}"
  print_line
  echo ""
}

print_fail_author() {
  echo ""
  print_line
  echo "  ${R}❌ 安装遇到问题，需要帮助？${NC}"
  echo "      Telegram: ${Y}${AUTHOR_TG}${NC}"
  print_line
  echo ""
}

# ── Banner ─────────────────────────────────────────
print_banner() {
  local year; year="$(date +%Y)"
  clear
  printf '%b\n' "${BM}╔══════════════════════════════════════════════════════════╗${NC}"
  printf '%b\n' "${BM}║       🦄 Dujiao-Next 一键部署 & 运维脚本 (Docker版)      ║${NC}"
  printf '%b\n' "${BM}║          User Source: chuangke8/user:v0.1.7              ║${NC}"
  printf '%b\n' "${BM}╚══════════════════════════════════════════════════════════╝${NC}"
  printf '%b\n' "${C}██████╗ ██╗   ██╗     ██╗██╗ █████╗  ██████╗      ███╗   ██╗███████╗██╗  ██╗████████╗${NC}"
  printf '%b\n' "${C}██╔══██╗██║   ██║     ██║██║██╔══██╗██╔═══██╗     ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝${NC}"
  printf '%b\n' "${C}██║  ██║██║   ██║     ██║██║███████║██║   ██║     ██╔██╗ ██║█████╗    ╚███╔╝    ██║   ${NC}"
  printf '%b\n' "${C}██║  ██║██║   ██║██   ██║██║██╔══██║██║   ██║     ██║╚██╗██║██╔══╝    ██╔██╗    ██║   ${NC}"
  printf '%b\n' "${C}██████╔╝╚██████╔╝╚█████╔╝██║██║  ██║╚██████╔╝     ██║ ╚████║███████╗██╔╝ ██╗   ██║   ${NC}"
  printf '%b\n' "${C}╚═════╝  ╚═════╝  ╚════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝   ${NC}"
  printf '%b\n' "${G}${BOLD}开源仓库地址${NC}"
  printf '%b\n' "${B}• Root:    https://github.com/dujiao-next${NC}"
  printf '%b\n' "${B}• API:     https://github.com/dujiao-next/dujiao-next${NC}"
  printf '%b\n' "${B}• User:    https://github.com/chuangke8/user (Custom)${NC}"
  printf '%b\n' "${B}• Admin:   https://github.com/dujiao-next/admin${NC}"
  printf '%b\n' "${DIM}版权所有 (c) ${year} LangGe  |  基于 dujiao-next (MIT)${NC}"
}

# ══════════════════════════════════════════════════
# 工具函数
# ══════════════════════════════════════════════════
trim() {
  local v="${1:-}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "${v}"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_command() {
  if ! command_exists "$1"; then
    error "未找到命令: $1，请先安装后重试"
    print_fail_author; return 1
  fi
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then "$@"; return $?; fi
  if command_exists sudo; then sudo "$@"; return $?; fi
  return 1
}

prompt_with_default() {
  local prompt="$1" default="${2:-}" value=""
  if [[ -n "${default}" ]]; then
    printf '%s [%s]: ' "${prompt}" "${default}" >&2
    read -r value
    value="$(trim "${value}")"
    [[ -z "${value}" ]] && value="${default}"
  else
    printf '%s: ' "${prompt}" >&2
    read -r value
    value="$(trim "${value}")"
  fi
  printf '%s' "${value}"
}

ask_yes_no() {
  local prompt="$1" default="${2:-y}" answer="" hint="[Y/n]"
  [[ "${default}" == "n" ]] && hint="[y/N]"
  while true; do
    printf '%s %s: ' "${prompt}" "${hint}" >&2
    read -r answer
    answer="$(trim "${answer}")"
    [[ -z "${answer}" ]] && answer="${default}"
    answer="$(printf '%s' "${answer}" | tr '[:upper:]' '[:lower:]')"
    case "${answer}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)     warn "请输入 y 或 n" ;;
    esac
  done
}

random_string() {
  local length="${1:-32}"
  if command_exists openssl; then
    printf '%s' "$(openssl rand -hex 64)" | cut -c1-"${length}"
    return 0
  fi
  local fb="${1}$(date +%s%N)$$"; while [[ "${#fb}" -lt "${length}" ]]; do fb="${fb}$(date +%s)"; done
  printf '%s' "${fb}" | cut -c1-"${length}"
}

backup_file() {
  local f="$1"; [[ -f "${f}" ]] && cp -f "${f}" "${f}.bak"
}

restore_file_if_needed() {
  local f="$1"; [[ -f "${f}.bak" ]] && cp -f "${f}.bak" "${f}"
}

validate_port_number() {
  local port="$1"
  [[ "${port}" =~ ^[0-9]+$ ]] || return 1
  (( port >= 1 && port <= 65535 ))
}

set_config_kv() {
  local file="$1" key="$2" value="$3"
  if grep -Eq "^[#[:space:]]*${key}[[:space:]]+" "${file}"; then
    sed -i -E "s|^[#[:space:]]*${key}[[:space:]].*|${key} ${value}|" "${file}"
  else
    printf '%s %s\n' "${key}" "${value}" >> "${file}"
  fi
}

find_sshd_bin() {
  local candidate
  for candidate in /usr/sbin/sshd /usr/local/sbin/sshd; do
    [[ -x "${candidate}" ]] && { printf '%s' "${candidate}"; return 0; }
  done
  command -v sshd 2>/dev/null || true
}

test_sshd_config() {
  local sshd_bin
  sshd_bin="$(find_sshd_bin)"
  [[ -n "${sshd_bin}" ]] || return 1
  "${sshd_bin}" -t -f "${1}"
}

restart_ssh_service() {
  systemctl restart ssh 2>/dev/null || \
    systemctl restart sshd 2>/dev/null || \
    service ssh restart 2>/dev/null || \
    service sshd restart 2>/dev/null
}

write_ufw_after_rules() {
  local target="$1"
  local marker_begin="# BEGIN UFW AND DOCKER"
  local marker_end="# END UFW AND DOCKER"
  local block
  block="$(cat <<'EOF'
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16
-A DOCKER-USER -j ufw-user-forward
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12
-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
)"

  if [[ -f "${target}" ]] && grep -Fq "${marker_begin}" "${target}"; then
    awk -v begin="${marker_begin}" -v end="${marker_end}" -v block="${block}" '
      BEGIN { replaced=0; skipping=0 }
      $0 == begin {
        if (!replaced) {
          print block
          replaced=1
        }
        skipping=1
        next
      }
      $0 == end {
        skipping=0
        next
      }
      !skipping { print }
      END {
        if (!replaced) {
          if (NR > 0) print ""
          print block
        }
      }
    ' "${target}" > "${target}.tmp" && mv -f "${target}.tmp" "${target}"
  else
    {
      [[ -f "${target}" ]] && cat "${target}"
      [[ -f "${target}" ]] && printf '\n'
      printf '%s\n' "${block}"
    } > "${target}"
  fi
}

validate_domain() {
  local d="$1"
  [[ -z "${d}" ]] && return 1
  [[ "${d}" == *"example.com"* ]] && return 1
  [[ "${d}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[A-Za-z]{2,63}$ ]]
}

resolve_domain_ip() {
  local domain="$1" ip=""
  if command_exists getent; then ip="$(getent ahosts "${domain}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"; fi
  if [[ -z "${ip}" ]] && command_exists dig; then ip="$(dig +short A "${domain}" | head -n1 || true)"; fi
  if [[ -z "${ip}" ]] && command_exists nslookup; then ip="$(nslookup "${domain}" 2>/dev/null | awk '/^Address: /{print $2}' | tail -n1 || true)"; fi
  printf '%s' "${ip}"
}

ensure_domain_resolved() {
  local domain="$1"
  if ! validate_domain "${domain}"; then error "域名格式无效: ${domain}"; return 1; fi
  local ip; ip="$(resolve_domain_ip "${domain}")"
  if [[ -z "${ip}" ]]; then error "无法解析域名 ${domain}，请先完成 DNS 解析"; return 1; fi
  info "域名解析正常: ${domain} -> ${ip}"
}

is_port_in_use() {
  local port="$1"
  if command_exists ss; then ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$" && return 0; fi
  if command_exists netstat; then netstat -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$" && return 0; fi
  return 1
}

fetch_latest_release_tag() {
  local repo="$1" response tag
  response="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || true)"
  [[ -z "${response}" ]] && printf '' && return 0
  tag="$(printf '%s\n' "${response}" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  printf '%s' "${tag}"
}

docker_install_residue_detected() {
  local deploy_dir="$1"
  [[ -f "${deploy_dir}/.env" ]] && return 0
  [[ -f "${deploy_dir}/config/config.yml" ]] && return 0
  [[ -f "${deploy_dir}/docker-compose.postgres.yml" ]] && return 0
  [[ -f "${deploy_dir}/docker-compose.sqlite.yml" ]] && return 0
  [[ -d "${deploy_dir}/data/postgres" ]] && return 0
  [[ -d "${deploy_dir}/data/db" ]] && return 0
  [[ -d "${deploy_dir}/data/redis" ]] && return 0

  local name
  for name in dujiaonext-api dujiaonext-user dujiaonext-admin dujiaonext-redis dujiaonext-postgres; do
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Fxq "${name}"; then
      return 0
    fi
  done
  return 1
}

cleanup_partial_docker_install() {
  local deploy_dir="$1" compose_path project_name name
  info "清理旧的 Docker 安装残留..."

  for compose_path in "${deploy_dir}/docker-compose.postgres.yml" "${deploy_dir}/docker-compose.sqlite.yml"; do
    if [[ -f "${compose_path}" ]]; then
      if [[ -f "${deploy_dir}/.env" ]]; then
        docker compose --env-file "${deploy_dir}/.env" -f "${compose_path}" down -v --remove-orphans >/dev/null 2>&1 || true
      else
        docker compose -f "${compose_path}" down -v --remove-orphans >/dev/null 2>&1 || true
      fi
    fi
  done

  for name in dujiaonext-api dujiaonext-user dujiaonext-admin dujiaonext-redis dujiaonext-postgres; do
    docker rm -f "${name}" >/dev/null 2>&1 || true
  done

  project_name="$(basename "${deploy_dir}")"
  docker network rm "${project_name}_dujiao-net" >/dev/null 2>&1 || true

  rm -f "${deploy_dir}/.env" \
    "${deploy_dir}/docker-compose.postgres.yml" \
    "${deploy_dir}/docker-compose.sqlite.yml" \
    "${deploy_dir}/config/config.yml"
  rm -rf "${deploy_dir}/data/postgres" \
    "${deploy_dir}/data/db" \
    "${deploy_dir}/data/redis"
}

wait_for_docker_service_ready() {
  local env_file="$1" compose_file="$2" service="$3"
  local cid="" status="" retry=0

  while true; do
    cid="$(docker compose --env-file "${env_file}" -f "${compose_file}" ps -q "${service}" 2>/dev/null | head -n1)"
    [[ -n "${cid}" ]] || { sleep 2; retry=$((retry+1)); [[ ${retry} -gt 40 ]] && return 1; continue; }
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${cid}" 2>/dev/null || true)"
    case "${status}" in
      healthy|running) return 0 ;;
      exited|dead) return 1 ;;
    esac
    retry=$((retry+1))
    [[ ${retry} -gt 40 ]] && return 1
    sleep 3
  done
}

wait_for_docker_dependencies() {
  local env_file="$1" compose_file="$2" db_mode="$3"
  info "等待依赖服务就绪..."
  wait_for_docker_service_ready "${env_file}" "${compose_file}" "redis" || {
    error "Redis 服务未就绪"
    return 1
  }
  if [[ "${db_mode}" == "postgres" ]]; then
    wait_for_docker_service_ready "${env_file}" "${compose_file}" "postgres" || {
      error "PostgreSQL 服务未就绪"
      return 1
    }
  fi
}

restart_docker_app_services() {
  local env_file="$1" compose_file="$2"
  info "重启应用容器以刷新与 Redis/数据库 的连接状态..."
  docker compose --env-file "${env_file}" -f "${compose_file}" restart api user admin >/dev/null 2>&1 || {
    warn "应用容器重启失败，请稍后手动执行 docker compose restart api user admin"
    return 1
  }
  sleep 3
}

# ══════════════════════════════════════════════════
# 状态管理
# ══════════════════════════════════════════════════
STATE_ALLOWED_KEYS=(
  MODE INSTALL_DIR API_TAG USER_TAG ADMIN_TAG DB_MODE DEPLOYED_AT
  HTTPS_ENABLED HTTPS_MODE USER_DOMAIN ADMIN_DOMAIN CERT_PROVIDER
  HTTPS_UPDATED_AT API_PORT POSTGRES_HOST POSTGRES_PORT
  POSTGRES_DB_NAME POSTGRES_DB_USER API_DOMAIN
)

ensure_state_dir() {
  mkdir -p "${STATE_DIR}"
  chmod 700 "${STATE_DIR}" 2>/dev/null || true
}

encode_state_value() {
  printf '%s' "${1}" | base64 | tr -d '\n'
}

decode_state_value() {
  printf '%s' "${1}" | base64 -d 2>/dev/null
}

parse_legacy_state_value() {
  local raw="$1"
  [[ "${raw}" == "''" ]] && { printf ''; return 0; }
  if [[ "${raw}" =~ ^\'(.*)\'$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "${raw}" == *'$('* || "${raw}" == *'`'* || "${raw}" == *';'* ]]; then
    return 1
  fi
  raw="${raw//\\ / }"
  raw="${raw//\\\\/\\}"
  printf '%s' "${raw}"
}

clear_state_vars() {
  local key
  for key in "${STATE_ALLOWED_KEYS[@]}"; do
    unset "${key}"
  done
}

write_state_file() {
  local values=(
    "${1-}" "${2-}" "${3-}" "${4-}" "${5-}" "${6-}" "${7-}" "${8-}" "${9-}" "${10-}"
    "${11-}" "${12-}" "${13-}" "${14-}" "${15-}" "${16-}" "${17-}" "${18-}" "${19-}"
  )
  local i
  ensure_state_dir
  {
    printf 'STATE_ENCODING=base64\n'
    for i in "${!STATE_ALLOWED_KEYS[@]}"; do
      printf '%s=%s\n' "${STATE_ALLOWED_KEYS[$i]}" "$(encode_state_value "${values[$i]}")"
    done
  } > "${STATE_FILE}"
  chmod 600 "${STATE_FILE}" 2>/dev/null || true
}

save_deploy_state() {
  write_state_file "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" \
     "$(date '+%Y-%m-%d %H:%M:%S')" "false" "" "" "" "" "" \
    "" "" "" "" "" ""
}

save_https_state() {
  if ! load_deploy_state; then error "未找到部署记录"; return 1; fi
  write_state_file "${MODE:-}" "${INSTALL_DIR:-}" "${API_TAG:-}" "${USER_TAG:-}" \
    "${ADMIN_TAG:-}" "${DB_MODE:-}" "${DEPLOYED_AT:-}" "true" \
    "${1}" "${2}" "${3}" "${4}" "$(date '+%Y-%m-%d %H:%M:%S')" \
    "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" \
    "${POSTGRES_DB_NAME:-}" "${POSTGRES_DB_USER:-}" "${5:-${API_DOMAIN:-}}"
}

load_deploy_state() {
  [[ ! -f "${STATE_FILE}" ]] && return 1
  clear_state_vars

  local is_base64="false"
  local line key value decoded legacy_rewrite="false"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" != *=* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "${key}" == "STATE_ENCODING" ]]; then
      [[ "${value}" == "base64" ]] && is_base64="true"
      continue
    fi
    [[ " ${STATE_ALLOWED_KEYS[*]} " == *" ${key} "* ]] || continue
    if [[ "${is_base64}" == "true" ]]; then
      decoded="$(decode_state_value "${value}")" || return 1
    else
      decoded="$(parse_legacy_state_value "${value}")" || return 1
      legacy_rewrite="true"
    fi
    printf -v "${key}" '%s' "${decoded}"
  done < "${STATE_FILE}"

  if [[ "${legacy_rewrite}" == "true" ]]; then
    write_state_file \
      "${MODE:-}" "${INSTALL_DIR:-}" "${API_TAG:-}" "${USER_TAG:-}" "${ADMIN_TAG:-}" \
      "${DB_MODE:-}" "${DEPLOYED_AT:-}" "${HTTPS_ENABLED:-}" "${HTTPS_MODE:-}" \
      "${USER_DOMAIN:-}" "${ADMIN_DOMAIN:-}" "${CERT_PROVIDER:-}" "${HTTPS_UPDATED_AT:-}" \
      "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" "${POSTGRES_DB_NAME:-}" \
      "${POSTGRES_DB_USER:-}" "${API_DOMAIN:-}"
  fi
  return 0
}

get_saved_api_port() {
  if [[ -n "${API_PORT:-}" ]]; then
    printf '%s' "${API_PORT}"
    return 0
  fi

  local install_dir="${INSTALL_DIR:-}"
  if [[ -n "${install_dir}" && -f "${install_dir}/.env" ]]; then
    grep '^API_PORT=' "${install_dir}/.env" 2>/dev/null | cut -d= -f2 | head -n1
    return 0
  fi

  if [[ -n "${install_dir}" && -f "${install_dir}/config.yml" ]]; then
    awk '
      /^server:/ { in_server=1; next }
      /^[^[:space:]]/ { if (in_server) exit }
      in_server && $1 == "port:" { print $2; exit }
    ' "${install_dir}/config.yml"
    return 0
  fi

  printf '8080'
}

get_saved_env_value() {
  local key="$1" default_value="${2:-}"
  local install_dir="${INSTALL_DIR:-}"
  if [[ -n "${install_dir}" && -f "${install_dir}/.env" ]]; then
    local value
    value="$(grep "^${key}=" "${install_dir}/.env" 2>/dev/null | cut -d= -f2- | head -n1 || true)"
    [[ -n "${value}" ]] && { printf '%s' "${value}"; return 0; }
  fi
  printf '%s' "${default_value}"
}

# ══════════════════════════════════════════════════
# 写入 Docker .env 文件
# ══════════════════════════════════════════════════
write_docker_env_file() {
  local env_file="$1"  tag="$2"       tz="$3"
  local api_port="$4"  user_port="$5" admin_port="$6"
  local redis_port="$7" postgres_port="$8" redis_password="$9"
  local postgres_db="${10}" postgres_user="${11}" postgres_password="${12}"
  local admin_username="${13}" admin_password="${14}"

  cat > "${env_file}" << ENVEOF
TAG=${tag}
TZ=${tz}
API_PORT=${api_port}
USER_PORT=${user_port}
ADMIN_PORT=${admin_port}
REDIS_PORT=${redis_port}
POSTGRES_PORT=${postgres_port}
REDIS_PASSWORD=${redis_password}
POSTGRES_DB=${postgres_db}
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
DJ_DEFAULT_ADMIN_USERNAME=${admin_username}
DJ_DEFAULT_ADMIN_PASSWORD=${admin_password}
ENVEOF
}

# ══════════════════════════════════════════════════
# 自动安装 Docker
# ══════════════════════════════════════════════════
auto_install_docker() {
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    systemctl start docker 2>/dev/null || true
    return 0
  fi

  warn "未检测到 Docker，正在自动安装..."
  local installed=false

  _cleanup_docker_apt() {
    rm -f /etc/apt/sources.list.d/docker.list \
          /usr/share/keyrings/docker-archive-keyring.gpg \
          /usr/share/keyrings/docker.gpg \
          /tmp/docker.gpg 2>/dev/null || true
    rm -f /etc/apt/keyrings/docker.gpg \
          /etc/apt/keyrings/docker.asc 2>/dev/null || true
    apt-get clean -qq 2>/dev/null || true
  }

  _try_install_from_mirror() {
    local gpg_url="$1" apt_url="$2" label="$3"
    info "尝试 ${label} 镜像..."
    _cleanup_docker_apt

    apt-get update -qq 2>/dev/null || true

    if ! curl -fsSL --connect-timeout 10 "${gpg_url}" -o /tmp/docker.gpg 2>/dev/null; then
      warn "${label}: GPG key 下载失败，跳过"
      return 1
    fi

    mkdir -p /usr/share/keyrings
    gpg --batch --yes --dearmor < /tmp/docker.gpg \
      > /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null
    chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
    rm -f /tmp/docker.gpg

    if ! gpg --no-default-keyring \
             --keyring /usr/share/keyrings/docker-archive-keyring.gpg \
             --list-keys >/dev/null 2>&1; then
      warn "${label}: GPG key 无效，跳过"
      return 1
    fi

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
${apt_url} $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    if apt-get update -qq 2>&1 | grep -q "NO_PUBKEY\|not signed"; then
      warn "${label}: apt update 签名验证仍失败，跳过"
      return 1
    fi

    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  }

  _cleanup_docker_apt
  if curl -fsSL --connect-timeout 8 https://get.docker.com -o /tmp/get-docker.sh 2>/dev/null; then
    if bash /tmp/get-docker.sh 2>&1; then installed=true; fi
  fi

  if [[ "${installed}" == false ]] && command_exists apt-get; then
    apt-get install -y -qq apt-transport-https ca-certificates gnupg lsb-release curl 2>/dev/null || true

    local mirrors=(
      "https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg|https://mirrors.aliyun.com/docker-ce/linux/ubuntu|阿里云"
      "https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu/gpg|https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu|腾讯云"
      "https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg|https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu|中科大"
    )
    for entry in "${mirrors[@]}"; do
      local gpg_url apt_url label
      gpg_url="${entry%%|*}"
      apt_url="${entry#*|}"
      apt_url="${apt_url%%|*}"
      label="${entry##*|}"
      if _try_install_from_mirror "${gpg_url}" "${apt_url}" "${label}"; then
        installed=true; break
      fi
    done
  elif [[ "${installed}" == false ]] && command_exists yum; then
    yum install -y -q yum-utils
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin && installed=true
  fi

  if ! command_exists docker; then
    error "Docker 自动安装失败，请手动执行："
    error "  curl -fsSL https://get.docker.com | bash"
    print_fail_author; exit 1
  fi

  systemctl start docker
  systemctl enable docker 2>/dev/null || true
  success "Docker 安装完成"
}

# ══════════════════════════════════════════════════
# Docker 镜像加速
# ══════════════════════════════════════════════════
setup_docker_mirror() {
  info "检测 Docker Hub 连通性..."
  if curl -s --connect-timeout 5 https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
    success "Docker Hub 连通正常，无需配置镜像加速"
    return 0
  fi
  warn "Docker Hub 不可达，配置国内镜像加速..."
  local mirrors=("https://docker.1ms.run" "https://docker.xuanyuan.me" "https://docker.m.daocloud.io" "https://hub.rat.dev")
  local available=""
  for m in "${mirrors[@]}"; do
    if curl -s --connect-timeout 3 "${m}/v2/" > /dev/null 2>&1; then
      available="${m}"; success "可用镜像源: ${m}"; break
    fi
  done
  [[ -z "${available}" ]] && available="https://docker.1ms.run"
  mkdir -p /etc/docker
  [[ -f /etc/docker/daemon.json ]] && cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
  cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["${available}", "https://docker.1ms.run", "https://docker.m.daocloud.io"],
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m", "max-file": "3"}
}
EOF
  systemctl daemon-reload 2>/dev/null || true
  systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || true
  success "Docker 镜像加速配置完成"
}

fix_redis_kernel_params() {
  if [[ "$(sysctl -n vm.overcommit_memory 2>/dev/null)" != "1" ]]; then
    info "设置 vm.overcommit_memory=1（Redis 推荐）..."
    sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1 || true
    grep -q "vm.overcommit_memory" /etc/sysctl.conf       || echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  fi
  if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
  fi
}

# ══════════════════════════════════════════════════
# Docker 部署核心配置 (换源点)
# ══════════════════════════════════════════════════
select_docker_database_mode() {
  local choice=""
  while true; do
    print_line
    echo "  请选择数据库方案："
    print_line
    echo "  1) SQLite + Redis      （轻量级，适合低流量场景）"
    echo "  2) PostgreSQL + Redis （稳定可靠，推荐生产环境）"
    print_line
    printf '  请输入选项 [1-2] (默认 1): ' >&2
    read -r choice
    choice="$(trim "${choice:-1}")"
    case "${choice}" in
      1) _DB_MODE="sqlite";   return 0 ;;
      2) _DB_MODE="postgres"; return 0 ;;
      *) warn "无效选项: ${choice}，请输入 1 或 2" ;;
    esac
  done
}

write_docker_config_file() {
  local config_file="$1" db_mode="$2" redis_password="$3"
  local postgres_db="$4" postgres_user="$5" postgres_password="$6"
  local jwt_secret; jwt_secret="$(random_string 40)"
  local user_jwt_secret; user_jwt_secret="$(random_string 40)"
  local dsn
  if [[ "${db_mode}" == "postgres" ]]; then
    dsn="host=postgres user=${postgres_user} password=${postgres_password} dbname=${postgres_db} port=5432 sslmode=disable TimeZone=Asia/Shanghai"
  else
    dsn="/app/db/dujiao.db"
  fi
  cat > "${config_file}" << CFGEOF
server:
  host: 0.0.0.0
  port: 8080
  mode: release

log:
  dir: /app/logs

database:
  driver: ${db_mode}
  dsn: "${dsn}"

jwt:
  secret: ${jwt_secret}
  expire_hours: 24

user_jwt:
  secret: ${user_jwt_secret}
  expire_hours: 24
  remember_me_expire_hours: 168

redis:
  enabled: true
  host: redis
  port: 6379
  password: "${redis_password}"
  db: 0
  prefix: "dj"

queue:
  enabled: true
  host: redis
  port: 6379
  password: "${redis_password}"
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5

email:
  enabled: false
CFGEOF
}

# 修改点：将用户端镜像源更换为 chuangke8/user:v0.1.7
write_compose_sqlite_file() {
  cat > "${1}" << SQLITEEOF
services:
  redis:
    image: redis:7-alpine
    container_name: dujiaonext-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--requirepass", "\${REDIS_PASSWORD}"]
    ports:
      - "127.0.0.1:\${REDIS_PORT}:6379"
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a \"\$\${REDIS_PASSWORD}\" ping 2>/dev/null && exit 0 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 30
      start_period: 5s
    networks:
      - dujiao-net

  api:
    image: dujiaonext/api:\${TAG}
    container_name: dujiaonext-api
    restart: unless-stopped
    environment:
      TZ: \${TZ}
      DJ_DEFAULT_ADMIN_USERNAME: \${DJ_DEFAULT_ADMIN_USERNAME}
      DJ_DEFAULT_ADMIN_PASSWORD: \${DJ_DEFAULT_ADMIN_PASSWORD}
    ports:
      - "\${API_PORT}:8080"
    volumes:
      - ./config/config.yml:/app/config.yml:ro
      - ./data/db:/app/db
      - ./data/uploads:/app/uploads
      - ./data/logs:/app/logs
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  user:
    image: chuangke8/user:v0.1.7
    container_name: dujiaonext-user
    restart: unless-stopped
    environment:
      TZ: \${TZ}
    ports:
      - "\${USER_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

  admin:
    image: dujiaonext/admin:\${TAG}
    container_name: dujiaonext-admin
    restart: unless-stopped
    environment:
      TZ: \${TZ}
    ports:
      - "\${ADMIN_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

networks:
  dujiao-net:
    driver: bridge
SQLITEEOF
}

# 修改点：将用户端镜像源更换为 chuangke8/user:v0.1.7
write_compose_postgres_file() {
  cat > "${1}" << POSTGRESEOF
services:
  redis:
    image: redis:7-alpine
    container_name: dujiaonext-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--requirepass", "\${REDIS_PASSWORD}"]
    ports:
      - "127.0.0.1:\${REDIS_PORT}:6379"
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a \"\$\${REDIS_PASSWORD}\" ping 2>/dev/null && exit 0 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 30
      start_period: 5s
    networks:
      - dujiao-net

  postgres:
    image: postgres:16-alpine
    container_name: dujiaonext-postgres
    restart: unless-stopped
    environment:
      TZ: \${TZ}
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:\${POSTGRES_PORT}:5432"
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 10
    networks:
      - dujiao-net

  api:
    image: dujiaonext/api:\${TAG}
    container_name: dujiaonext-api
    restart: unless-stopped
    environment:
      TZ: \${TZ}
      DJ_DEFAULT_ADMIN_USERNAME: \${DJ_DEFAULT_ADMIN_USERNAME}
      DJ_DEFAULT_ADMIN_PASSWORD: \${DJ_DEFAULT_ADMIN_PASSWORD}
    ports:
      - "\${API_PORT}:8080"
    volumes:
      - ./config/config.yml:/app/config.yml:ro
      - ./data/uploads:/app/uploads
      - ./data/logs:/app/logs
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  user:
    image: chuangke8/user:v0.1.7
    container_name: dujiaonext-user
    restart: unless-stopped
    environment:
      TZ: \${TZ}
    ports:
      - "\${USER_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

  admin:
    image: dujiaonext/admin:\${TAG}
    container_name: dujiaonext-admin
    restart: unless-stopped
    environment:
      TZ: \${TZ}
    ports:
      - "\${ADMIN_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

networks:
  dujiao-net:
    driver: bridge
POSTGRESEOF
}

# ══════════════════════════════════════════════════
# Nginx 配置逻辑
# ══════════════════════════════════════════════════
auto_install_nginx() {
  if command_exists nginx; then
    info "Nginx 已安装: $(nginx -v 2>&1)"
    systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
    return 0
  fi
  info "安装 Nginx..."
  if command_exists apt-get; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx
  elif command_exists yum; then
    yum install -y -q nginx
  else
    error "不支持的包管理器，请手动安装 Nginx"; print_fail_author; return 1
  fi
  systemctl enable nginx 2>/dev/null || true
  systemctl start nginx 2>/dev/null || true
  success "Nginx 安装完成"
}

auto_install_socat() {
  if command_exists socat; then
    info "socat 已安装: $(socat -V 2>/dev/null | head -n 1)"
    return 0
  fi
  info "安装 socat..."
  if command_exists apt-get; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq socat
  elif command_exists yum; then
    yum install -y -q socat
  else
    error "不支持的包管理器，请手动安装 socat"; print_fail_author; return 1
  fi
  command_exists socat || { error "socat 安装失败"; print_fail_author; return 1; }
  success "socat 安装完成"
}

auto_install_crontab() {
  if command_exists crontab; then
    info "crontab 已安装"
    return 0
  fi

  info "安装 cron/crontab..."
  if command_exists apt-get; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cron
    systemctl enable cron >/dev/null 2>&1 || true
    systemctl restart cron >/dev/null 2>&1 || true
  elif command_exists dnf; then
    dnf install -y -q cronie
    systemctl enable crond >/dev/null 2>&1 || true
    systemctl restart crond >/dev/null 2>&1 || true
  elif command_exists yum; then
    yum install -y -q cronie
    systemctl enable crond >/dev/null 2>&1 || true
    systemctl restart crond >/dev/null 2>&1 || true
  elif command_exists apk; then
    apk add --no-cache dcron
    rc-update add dcron default >/dev/null 2>&1 || true
    rc-service dcron restart >/dev/null 2>&1 || true
  else
    error "不支持的包管理器，请手动安装 cron/crontab"
    print_fail_author
    return 1
  fi

  command_exists crontab || {
    error "cron/crontab 安装失败"
    print_fail_author
    return 1
  }
  success "cron/crontab 安装完成"
}

ensure_https_firewall_ports() {
  local changed=false
  if command_exists ufw; then
    local ufw_status
    ufw_status="$(ufw status 2>/dev/null | head -n1 || true)"
    if [[ "${ufw_status}" == "Status: active" ]]; then
      info "检测到 UFW 已启用，自动放行 80/443..."
      run_as_root ufw allow 80/tcp >/dev/null 2>&1 || true
      run_as_root ufw allow 443/tcp >/dev/null 2>&1 || true
      changed=true
    fi
  fi

  if command_exists firewall-cmd && firewall-cmd --state >/dev/null 2>&1; then
    info "检测到 firewalld 已启用，自动放行 http/https..."
    run_as_root firewall-cmd --permanent --add-service=http >/dev/null 2>&1 || true
    run_as_root firewall-cmd --permanent --add-service=https >/dev/null 2>&1 || true
    run_as_root firewall-cmd --reload >/dev/null 2>&1 || true
    changed=true
  fi

  if [[ "${changed}" == "true" ]]; then
    success "本机防火墙已处理 80/443 端口放行"
  else
    info "未检测到已启用的 UFW / firewalld，跳过本机防火墙自动放行"
  fi
}

confirm_cloud_firewall_ports() {
  local answer=""
  echo "" >&2
  warn "请确认云安全组/服务商防火墙已放行 TCP 80 和 443"
  warn "本机防火墙已自动处理，但云安全组需你在控制台手动确认"
  printf '确认完成后输入 1 继续申请证书，输入其他任意内容取消: ' >&2
  read -r answer
  answer="$(trim "${answer}")"
  [[ "${answer}" == "1" ]]
}

write_nginx_api_site() {
  local conf_file="$1" server_name="$2" api_port="$3"
  local ssl="$4" cert_dir="$5"

  if [[ "${ssl}" == "true" ]]; then
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};
    ssl_certificate     ${cert_dir}/fullchain.pem;
    ssl_certificate_key ${cert_dir}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;
    client_max_body_size 100m;
    location / {
        proxy_pass         http://127.0.0.1:${api_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
}
NGEOF
  else
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    client_max_body_size 100m;
    location / {
        proxy_pass         http://127.0.0.1:${api_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
}
NGEOF
  fi
}

write_nginx_site() {
  local conf_file="$1"
  local server_name="$2"
  local proxy_port="$3"
  local api_port="$4"
  local ssl="$5"
  local cert_dir="$6"

  if [[ "${ssl}" == "true" ]]; then
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};

    ssl_certificate     ${cert_dir}/fullchain.pem;
    ssl_certificate_key ${cert_dir}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    client_max_body_size 100m;

    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        proxy_pass         http://127.0.0.1:${proxy_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
NGEOF
  else
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};

    client_max_body_size 100m;

    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        proxy_pass         http://127.0.0.1:${proxy_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
NGEOF
  fi
}

reload_nginx() {
  if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true
    success "Nginx 配置重载成功"
  else
    error "Nginx 配置检查失败:"
    nginx -t
    return 1
  fi
}

setup_nginx_sites() {
  local user_domain="$1" admin_domain="$2" api_domain="$3"
  local user_port="$4"   admin_port="$5"   api_port="$6"
  local ssl="$7"          cert_base="$8"

  local nginx_dir
  if [[ -d /etc/nginx/sites-enabled ]]; then
    nginx_dir="/etc/nginx/sites-available"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  else
    nginx_dir="/etc/nginx/conf.d"
    mkdir -p /etc/nginx/conf.d
  fi

  local user_cert="${cert_base}/${user_domain}"
  local admin_cert="${cert_base}/${admin_domain}"
  local api_cert="${cert_base}/${api_domain}"

  write_nginx_site     "${nginx_dir}/dujiao-user.conf"  "${user_domain}"  "${user_port}"  "${api_port}" "${ssl}" "${user_cert}"
  write_nginx_site     "${nginx_dir}/dujiao-admin.conf" "${admin_domain}" "${admin_port}" "${api_port}" "${ssl}" "${admin_cert}"
  write_nginx_api_site "${nginx_dir}/dujiao-api.conf"   "${api_domain}"   "${api_port}"   "${ssl}"      "${api_cert}"

  if [[ -d /etc/nginx/sites-enabled ]]; then
    ln -sf "${nginx_dir}/dujiao-user.conf"  /etc/nginx/sites-enabled/dujiao-user.conf
    ln -sf "${nginx_dir}/dujiao-admin.conf" /etc/nginx/sites-enabled/dujiao-admin.conf
    ln -sf "${nginx_dir}/dujiao-api.conf"   /etc/nginx/sites-enabled/dujiao-api.conf
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
  fi

  reload_nginx
}

# ══════════════════════════════════════════════════
# Docker 部署主流程
# ══════════════════════════════════════════════════
deploy_with_docker() {
  print_line
  echo "  ${BOLD}🐳 Docker Compose 部署${NC}"
  print_line

  auto_install_docker

  if ! docker info >/dev/null 2>&1; then
    error "无法连接 Docker daemon，请先启动 Docker"
    print_fail_author; return 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    error "未检测到 docker compose，请先安装 Docker Compose 插件"
    print_fail_author; return 1
  fi

  setup_docker_mirror
  fix_redis_kernel_params

  local db_mode
  _DB_MODE=""
  select_docker_database_mode
  db_mode="${_DB_MODE}"
  local latest_tag; latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  local default_tag="${latest_tag:-latest}"
  local tag; tag="$(prompt_with_default "请输入镜像版本 TAG" "${default_tag}")"
  [[ -z "${tag}" ]] && tag="${default_tag}"

  local deploy_dir tz api_port user_port admin_port
  local redis_port postgres_port redis_password
  local postgres_db postgres_user postgres_password
  local admin_username admin_password

  deploy_dir="$(prompt_with_default "Install directory" "${HOME}/dujiao-next")"
  if docker_install_residue_detected "${deploy_dir}"; then
    warn "检测到 ${deploy_dir} 存在未完成安装残留。"
    if ask_yes_no "是否先清理旧容器和数据后再继续全新安装" "y"; then
      cleanup_partial_docker_install "${deploy_dir}"
      success "旧安装残留已清理"
    else
      error "已取消安装。"
      print_fail_author; return 1
    fi
  fi
  tz="$(prompt_with_default "时区" "Asia/Shanghai")"
  api_port="$(prompt_with_default "API 端口" "8080")"
  user_port="$(prompt_with_default "User 端口" "8081")"
  admin_port="$(prompt_with_default "Admin 端口" "8082")"
  redis_port="$(prompt_with_default "Redis 端口" "6379")"
  redis_password="$(prompt_with_default "Redis 密码" "$(random_string 16)")"

  if [[ "${db_mode}" == "postgres" ]]; then
    postgres_port="$(prompt_with_default "PostgreSQL 端口" "5432")"
    postgres_db="$(prompt_with_default "数据库名" "dujiao_next")"
    postgres_user="$(prompt_with_default "数据库用户名" "dujiao")"
    postgres_password="$(prompt_with_default "数据库密码" "$(random_string 16)")"
  else
    postgres_port="5432"; postgres_db="dujiao_next"
    postgres_user="dujiao"; postgres_password="$(random_string 16)"
  fi

  admin_username="$(prompt_with_default "管理员用户名" "admin")"
  admin_password="$(prompt_with_default "管理员密码" "Admin@123456")"

  local user_domain="" admin_domain="" api_domain="" ssl_enabled="" acme_email=""
  _USER_DOMAIN="" _ADMIN_DOMAIN="" _API_DOMAIN="" _SSL_ENABLED="" _ACME_EMAIL=""
  
  # 域名配置
  echo "" >&2
  echo "🌐 域名配置" >&2
  echo "请为三端分别绑定独立域名，并确保 DNS 已解析到本服务器" >&2
  while true; do
    user_domain="$(prompt_with_default "用户端域名" "")"
    validate_domain "${user_domain}" && break
    warn "域名格式不正确"
  done
  while true; do
    admin_domain="$(prompt_with_default "管理端域名" "")"
    validate_domain "${admin_domain}" && break
    warn "域名格式不正确"
  done
  while true; do
    api_domain="$(prompt_with_default "API 域名" "")"
    validate_domain "${api_domain}" && break
    warn "域名格式不正确"
  done

  mkdir -p "${deploy_dir}/config" "${deploy_dir}/data/db" \
    "${deploy_dir}/data/uploads" "${deploy_dir}/data/logs" \
    "${deploy_dir}/data/redis"
  [[ "${db_mode}" == "postgres" ]] && mkdir -p "${deploy_dir}/data/postgres"

  local env_file="${deploy_dir}/.env"
  local config_file="${deploy_dir}/config/config.yml"
  local compose_file="${deploy_dir}/docker-compose.yml"

  write_docker_env_file "${env_file}" "${tag}" "${tz}" \
    "${api_port}" "${user_port}" "${admin_port}" \
    "${redis_port}" "${postgres_port}" "${redis_password}" \
    "${postgres_db}" "${postgres_user}" "${postgres_password}" \
    "${admin_username}" "${admin_password}"

  write_docker_config_file "${config_file}" "${db_mode}" \
    "${redis_password}" "${postgres_db}" "${postgres_user}" "${postgres_password}"

  if [[ "${db_mode}" == "postgres" ]]; then
    write_compose_postgres_file "${compose_file}"
  else
    write_compose_sqlite_file "${compose_file}"
  fi

  info "启动服务中..."
  cd "${deploy_dir}" && docker compose up -d

  wait_for_docker_dependencies "${env_file}" "${compose_file}" "${db_mode}" || true
  restart_docker_app_services "${env_file}" "${compose_file}" || true

  # Nginx 配置
  auto_install_nginx
  setup_nginx_sites "${user_domain}" "${admin_domain}" "${api_domain}" \
    "${user_port}" "${admin_port}" "${api_port}" "false" "${deploy_dir}/certs"

  save_deploy_state "docker" "${deploy_dir}" "${tag}" "${tag}" "${tag}" "${db_mode}"
  
  echo ""
  print_line
  echo "  ${G}${BOLD}🎉 Docker 部署完成！${NC}"
  print_line
  echo "  部署目录  : ${deploy_dir}"
  echo "  User 端域名: http://${user_domain}"
  echo "  Admin 端域名: http://${admin_domain}"
  echo "  API 端域名: http://${api_domain}"
  print_author
}

# ══════════════════════════════════════════════════
# 日常管理逻辑
# ══════════════════════════════════════════════════
do_status() {
  if ! load_deploy_state; then error "未找到部署记录"; return 1; fi
  local install_dir="${INSTALL_DIR:-}"
  cd "${install_dir}" && docker compose ps
}

do_logs() {
  if ! load_deploy_state; then error "未找到部署记录"; return 1; fi
  local install_dir="${INSTALL_DIR:-}"
  cd "${install_dir}" && docker compose logs -f --tail 100
}

handle_ops_menu() {
  while true; do
    print_line
    echo "  ${BOLD}日常管理${NC}"
    print_line
    echo "  1) 查看服务状态"
    echo "  2) 查看日志"
    echo "  3) 重启服务"
    echo "  4) 卸载系统"
    echo "  0) 返回上级"
    printf '%s' "  请选择 [0-4]: " >&2
    read -r choice
    case "${choice}" in
      1) do_status ;;
      2) do_logs ;;
      3) if load_deploy_state; then cd "${INSTALL_DIR}" && docker compose restart; fi ;;
      4) if ask_yes_no "确定卸载吗？" "n"; then 
           cd "${INSTALL_DIR}" && docker compose down -v
           rm -rf "${INSTALL_DIR}"
           rm -f "${STATE_FILE}"
           success "卸载完成"
           return 0
         fi ;;
      0) return 0 ;;
    esac
  done
}

# ══════════════════════════════════════════════════
# 主菜单
# ══════════════════════════════════════════════════
main() {
  if [[ "$(id -u)" -ne 0 ]]; then
    printf "${R}[ERROR]${NC} 请使用 root 权限运行此脚本\n"
    exit 1
  fi
  print_banner

  while true; do
    print_line
    echo "  1) 开始部署 (Docker)"
    echo "  2) 日常管理"
    echo "  0) 退出"
    print_line
    printf '%s' "  请选择 [0-2]: " >&2
    read -r choice
    case "${choice}" in
      1) deploy_with_docker ;;
      2) handle_ops_menu ;;
      0) echo "再见"; exit 0 ;;
      *) warn "无效选项" ;;
    esac
  done
}

main "$@"