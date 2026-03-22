#!/usr/bin/env bash
#
# setup-jenkins-job.sh
#
# Idempotent Jenkins job workspace bootstrap for Ubuntu servers.
#
# What this script does:
# 1) Ensures Jenkins and Git are installed.
# 2) Ensures /var/lib/jenkins ownership is jenkins:jenkins.
# 3) Clones (or updates) a GitHub repository into Jenkins workspace.
# 4) Supports private repositories via:
#    - HTTPS credentials (GIT_USERNAME + GIT_TOKEN)
#    - SSH key (existing key file path)
# 5) Restarts Jenkins and verifies service health.
# 6) Prints the final clone path.
#
# Safe for repeated execution:
# - Package install steps are conditional.
# - Repo clone is update-aware (fetch/reset) when directory already exists.
# - SSH known_hosts entries are appended only if missing.
#
# Usage examples:
#   Public HTTPS repo:
#     ./setup-jenkins-job.sh --repo-url https://github.com/org/repo.git --branch main
#
#   Private HTTPS repo (PAT):
#     GIT_USERNAME=myuser GIT_TOKEN=ghp_xxx ./setup-jenkins-job.sh \
#       --repo-url https://github.com/org/repo.git --private --auth https
#
#   Private SSH repo:
#     ./setup-jenkins-job.sh --repo-url git@github.com:org/repo.git \
#       --private --auth ssh --ssh-key-path /var/lib/jenkins/.ssh/id_ed25519

set -euo pipefail

REPO_URL=""
BRANCH="main"
PRIVATE_REPO="false"
AUTH_MODE="auto"     # auto | https | ssh
JOB_NAME=""
SSH_KEY_PATH="/var/lib/jenkins/.ssh/id_rsa"
WORKSPACE_ROOT="/var/lib/jenkins/workspace"

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $*"
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  setup-jenkins-job.sh --repo-url <url> [options]

Required:
  --repo-url <url>           GitHub repository URL (HTTPS or SSH)

Optional:
  --branch <name>            Branch to checkout (default: main)
  --private                  Mark repository as private
  --auth <auto|https|ssh>    Authentication mode (default: auto)
  --job-name <name>          Jenkins job/workspace folder name
  --ssh-key-path <path>      SSH private key path (default: /var/lib/jenkins/.ssh/id_rsa)
  --workspace-root <path>    Jenkins workspace root (default: /var/lib/jenkins/workspace)
  -h, --help                 Show this help

Environment variables for private HTTPS repos:
  GIT_USERNAME               GitHub username (or bot/service account)
  GIT_TOKEN                  GitHub personal access token
EOF
}

# Determine whether we should use sudo.
if [[ "${EUID}" -eq 0 ]]; then
    SUDO=""
else
    command -v sudo >/dev/null 2>&1 || die "This script needs root privileges (run as root or install sudo)."
    SUDO="sudo"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-url)
            REPO_URL="${2:-}"
            shift 2
            ;;
        --branch)
            BRANCH="${2:-}"
            shift 2
            ;;
        --private)
            PRIVATE_REPO="true"
            shift
            ;;
        --auth)
            AUTH_MODE="${2:-}"
            shift 2
            ;;
        --job-name)
            JOB_NAME="${2:-}"
            shift 2
            ;;
        --ssh-key-path)
            SSH_KEY_PATH="${2:-}"
            shift 2
            ;;
        --workspace-root)
            WORKSPACE_ROOT="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[[ -n "${REPO_URL}" ]] || {
    usage
    die "--repo-url is required."
}

# Infer auth mode from URL if user selected auto.
if [[ "${AUTH_MODE}" == "auto" ]]; then
    if [[ "${REPO_URL}" =~ ^git@ ]] || [[ "${REPO_URL}" =~ ^ssh:// ]]; then
        AUTH_MODE="ssh"
    else
        AUTH_MODE="https"
    fi
fi

[[ "${AUTH_MODE}" == "https" || "${AUTH_MODE}" == "ssh" ]] || die "--auth must be one of: auto, https, ssh"

# Derive job name from repo URL if not provided.
if [[ -z "${JOB_NAME}" ]]; then
    REPO_BASENAME="$(basename "${REPO_URL}")"
    JOB_NAME="${REPO_BASENAME%.git}"
fi

CLONE_PATH="${WORKSPACE_ROOT}/${JOB_NAME}"

install_git() {
    if command -v git >/dev/null 2>&1; then
        log "Git already installed."
        return
    fi

    log "Installing Git..."
    ${SUDO} apt-get update -y
    ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y git
}

install_jenkins() {
    if dpkg -s jenkins >/dev/null 2>&1; then
        log "Jenkins already installed."
        return
    fi

    log "Installing Jenkins and prerequisites..."
    ${SUDO} apt-get update -y
    ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jre curl gnupg apt-transport-https ca-certificates

    if [[ ! -f /usr/share/keyrings/jenkins-keyring.asc ]]; then
        curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | ${SUDO} tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
    fi

    if [[ ! -f /etc/apt/sources.list.d/jenkins.list ]]; then
        echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | ${SUDO} tee /etc/apt/sources.list.d/jenkins.list >/dev/null
    fi

    ${SUDO} apt-get update -y
    ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y jenkins
}

fix_jenkins_ownership() {
    log "Ensuring /var/lib/jenkins ownership is jenkins:jenkins..."
    ${SUDO} mkdir -p /var/lib/jenkins
    ${SUDO} chown -R jenkins:jenkins /var/lib/jenkins
}

ensure_jenkins_service() {
    log "Enabling and starting Jenkins service..."
    ${SUDO} systemctl enable jenkins >/dev/null 2>&1 || true
    ${SUDO} systemctl start jenkins
}

prepare_https_private_auth() {
    [[ -n "${GIT_USERNAME:-}" ]] || die "For private HTTPS repos, set GIT_USERNAME environment variable."
    [[ -n "${GIT_TOKEN:-}" ]] || die "For private HTTPS repos, set GIT_TOKEN environment variable."

    ASKPASS_FILE="$(mktemp)"
    cat > "${ASKPASS_FILE}" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) echo "${GIT_USERNAME}" ;;
  *Password*) echo "${GIT_TOKEN}" ;;
  *) echo "" ;;
esac
EOF
    chmod 700 "${ASKPASS_FILE}"

    export GIT_ASKPASS="${ASKPASS_FILE}"
    export GIT_TERMINAL_PROMPT=0
}

cleanup_https_private_auth() {
    if [[ -n "${ASKPASS_FILE:-}" ]] && [[ -f "${ASKPASS_FILE}" ]]; then
        rm -f "${ASKPASS_FILE}"
    fi
    unset GIT_ASKPASS || true
    unset GIT_TERMINAL_PROMPT || true
}

prepare_ssh_auth() {
    [[ -f "${SSH_KEY_PATH}" ]] || die "SSH key not found at ${SSH_KEY_PATH}"

    log "Preparing SSH known_hosts for github.com..."
    ${SUDO} mkdir -p /var/lib/jenkins/.ssh
    ${SUDO} touch /var/lib/jenkins/.ssh/known_hosts

    if ! ${SUDO} grep -q '^github.com ' /var/lib/jenkins/.ssh/known_hosts; then
        ssh-keyscan -H github.com | ${SUDO} tee -a /var/lib/jenkins/.ssh/known_hosts >/dev/null
    fi

    ${SUDO} chown -R jenkins:jenkins /var/lib/jenkins/.ssh
    ${SUDO} chmod 700 /var/lib/jenkins/.ssh
    ${SUDO} chmod 600 /var/lib/jenkins/.ssh/known_hosts

    export GIT_SSH_COMMAND="ssh -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
}

clone_or_update_repo() {
    log "Ensuring Jenkins workspace exists at ${WORKSPACE_ROOT}..."
    ${SUDO} mkdir -p "${WORKSPACE_ROOT}"
    ${SUDO} chown -R jenkins:jenkins "${WORKSPACE_ROOT}"

    if [[ -d "${CLONE_PATH}/.git" ]]; then
        log "Repository already exists. Updating branch ${BRANCH} at ${CLONE_PATH}..."
        ${SUDO} -u jenkins git -C "${CLONE_PATH}" fetch --all --prune
        ${SUDO} -u jenkins git -C "${CLONE_PATH}" checkout "${BRANCH}"
        ${SUDO} -u jenkins git -C "${CLONE_PATH}" reset --hard "origin/${BRANCH}"
    elif [[ -d "${CLONE_PATH}" ]]; then
        die "Target path exists but is not a Git repository: ${CLONE_PATH}"
    else
        log "Cloning repository into ${CLONE_PATH}..."
        ${SUDO} -u jenkins git clone --branch "${BRANCH}" "${REPO_URL}" "${CLONE_PATH}"
    fi

    ${SUDO} chown -R jenkins:jenkins "${CLONE_PATH}"
}

restart_and_verify_jenkins() {
    log "Restarting Jenkins service..."
    ${SUDO} systemctl restart jenkins

    log "Verifying Jenkins service status..."
    for _ in {1..12}; do
        if ${SUDO} systemctl is-active --quiet jenkins; then
            log "Jenkins service is running."
            return
        fi
        sleep 5
    done

    ${SUDO} systemctl --no-pager status jenkins || true
    die "Jenkins service did not become active in time."
}

main() {
    log "Starting Jenkins job setup..."
    install_git
    install_jenkins
    fix_jenkins_ownership
    ensure_jenkins_service

    if [[ "${PRIVATE_REPO}" == "true" ]]; then
        if [[ "${AUTH_MODE}" == "https" ]]; then
            log "Using private HTTPS authentication flow."
            prepare_https_private_auth
            trap cleanup_https_private_auth EXIT
        else
            log "Using private SSH authentication flow."
            prepare_ssh_auth
        fi
    else
        log "Repository marked as public; cloning without private credential setup."
    fi

    clone_or_update_repo
    restart_and_verify_jenkins

    echo ""
    echo "Repository clone path: ${CLONE_PATH}"
}

main
