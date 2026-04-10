#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:/usr/local/go/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

install_gh_repo() {
    sudo apt install -y wget
    sudo mkdir -p -m 755 /etc/apt/keyrings

    if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null; then
        log_error "Failed to download GitHub CLI keyring"
        return 1
    fi

    if [ ! -s /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
        log_error "GitHub CLI keyring file is empty"
        return 1
    fi

    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
}

# Track failures
declare -a FAILED_PACKAGES=()

cleanup() {
    local exit_code=$?
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo ""
        log_warning "Some packages failed to install:"
        printf '  - %s\n' "${FAILED_PACKAGES[@]}"
        exit_code=1
    fi
    if [ $exit_code -ne 0 ]; then
        log_error "DevOps tools installation encountered errors."
    fi
    exit $exit_code
}

trap cleanup EXIT

echo "Installing DevOps tools..."
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# ============================================================================
# kubectl - Kubernetes CLI (using new pkgs.k8s.io repo)
# ============================================================================
echo "[1/16] kubectl - Kubernetes CLI"
if command_exists kubectl; then
    log_success "kubectl is already installed"
else
    log_info "Installing kubectl..."
    # Install prerequisites
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg

    # Add Kubernetes GPG key (v1/stable channel for latest stable version)
    sudo mkdir -p /etc/apt/keyrings
    if [ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
        sudo rm /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    fi
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Add repository (v1/stable channel - always latest stable)
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt update
    if sudo apt install -y kubectl; then
        log_success "kubectl installed successfully"
    else
        log_error "Failed to install kubectl"
        FAILED_PACKAGES+=("kubectl")
    fi
fi

# ============================================================================
# kubectx - Kubernetes context switcher
# ============================================================================
echo ""
echo "[2/16] kubectx - Kubernetes context switcher"
if command_exists kubectx; then
    log_success "kubectx is already installed"
else
    log_info "Installing kubectx..."
    if sudo apt install -y kubectx; then
        log_success "kubectx installed successfully"
    else
        log_error "Failed to install kubectx"
        FAILED_PACKAGES+=("kubectx")
    fi
fi

# ============================================================================
# kubens - included with kubectx
# ============================================================================
echo ""
echo "[3/16] kubens - Kubernetes namespace switcher"
if command_exists kubens; then
    log_success "kubens is already installed (included with kubectx)"
else
    log_info "kubens should be included with kubectx package"
fi

# ============================================================================
# helm - Kubernetes package manager
# ============================================================================
echo ""
echo "[4/16] helm - Kubernetes package manager"
if command_exists helm; then
    log_success "helm is already installed"
else
    log_info "Installing helm..."
    if curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
        log_success "helm installed successfully"
    else
        log_error "Failed to install helm"
        FAILED_PACKAGES+=("helm")
    fi
fi

# ============================================================================
# k9s - Kubernetes TUI
# ============================================================================
echo ""
echo "[5/16] k9s - Kubernetes TUI"
if command_exists k9s; then
    log_success "k9s is already installed"
else
    log_info "Installing k9s..."
    K9S_DEB="/tmp/k9s_linux_amd64.deb"
    if wget -q -O "$K9S_DEB" https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb; then
        if sudo apt install -y "$K9S_DEB"; then
            log_success "k9s installed successfully"
        else
            log_error "Failed to install k9s"
            FAILED_PACKAGES+=("k9s")
        fi
        rm -f "$K9S_DEB"
    else
        log_error "Failed to download k9s"
        FAILED_PACKAGES+=("k9s")
    fi
fi

# ============================================================================
# stern - Multi-pod log tailing
# ============================================================================
echo ""
echo "[6/16] stern - Multi-pod log tailing for Kubernetes"
if command_exists stern; then
    log_success "stern is already installed"
else
    log_info "Installing stern..."
    STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d'"' -f4)
    if [ -n "$STERN_VERSION" ]; then
        STERN_TAR="/tmp/stern_linux_amd64.tar.gz"
        if curl -fsSL -o "$STERN_TAR" "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz"; then
            tar -xzf "$STERN_TAR" -C /tmp
            sudo mv /tmp/stern /usr/local/bin/
            sudo chmod +x /usr/local/bin/stern
            rm -f "$STERN_TAR"
            log_success "stern installed successfully"
        else
            log_error "Failed to download stern"
            FAILED_PACKAGES+=("stern")
        fi
    else
        log_error "Failed to get stern version"
        FAILED_PACKAGES+=("stern")
    fi
fi

# ============================================================================
# argocd - GitOps continuous delivery
# ============================================================================
echo ""
echo "[7/16] argocd - GitOps continuous delivery"
if command_exists argocd; then
    log_success "argocd is already installed"
else
    log_info "Installing argocd..."
    if curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64; then
        sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
        rm -f /tmp/argocd
        log_success "argocd installed successfully"
    else
        log_error "Failed to install argocd"
        FAILED_PACKAGES+=("argocd")
    fi
fi

# ============================================================================
# flux - Flux GitOps operator
# ============================================================================
echo ""
echo "[8/16] flux - Flux GitOps operator"
if command_exists flux; then
    log_success "flux is already installed"
else
    log_info "Installing flux..."
    if curl -s https://fluxcd.io/install.sh | sudo bash; then
        log_success "flux installed successfully"
    else
        log_error "Failed to install flux"
        FAILED_PACKAGES+=("flux")
    fi
fi

# ============================================================================
# terraform - Infrastructure as Code
# ============================================================================
echo ""
echo "[9/16] terraform - Infrastructure as Code"
if command_exists terraform; then
    log_success "terraform is already installed"
else
    log_info "Installing terraform..."
    sudo apt install -y gnupg software-properties-common

    # Add HashiCorp GPG key
    if [ -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
        sudo rm /usr/share/keyrings/hashicorp-archive-keyring.gpg
    fi
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt update
    if sudo apt install -y terraform; then
        log_success "terraform installed successfully"
    else
        log_error "Failed to install terraform"
        FAILED_PACKAGES+=("terraform")
    fi
fi

# ============================================================================
# ansible - Configuration management
# ============================================================================
echo ""
echo "[10/16] ansible - Configuration management"
if command_exists ansible; then
    log_success "ansible is already installed"
else
    log_info "Installing ansible..."
    if sudo apt install -y ansible; then
        log_success "ansible installed successfully"
    else
        log_error "Failed to install ansible"
        FAILED_PACKAGES+=("ansible")
    fi
fi

# ============================================================================
# aws-cli - AWS Command Line Interface
# ============================================================================
echo ""
echo "[11/16] aws-cli - AWS Command Line Interface"
if command_exists aws; then
    log_success "aws-cli is already installed"
else
    log_info "Installing aws-cli v2..."
    # Ensure unzip is available
    sudo apt install -y unzip
    AWS_ZIP="/tmp/awscliv2.zip"
    if curl -fsSL -o "$AWS_ZIP" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; then
        unzip -q -o "$AWS_ZIP" -d /tmp
        if sudo /tmp/aws/install; then
            log_success "aws-cli v2 installed successfully"
        else
            log_error "Failed to install aws-cli"
            FAILED_PACKAGES+=("aws-cli")
        fi
        rm -rf /tmp/aws "$AWS_ZIP"
    else
        log_error "Failed to download aws-cli"
        FAILED_PACKAGES+=("aws-cli")
    fi
fi

# ============================================================================
# gcloud - Google Cloud CLI
# ============================================================================
echo ""
echo "[12/16] gcloud - Google Cloud CLI"
if command_exists gcloud; then
    log_success "gcloud is already installed"
else
    log_info "Installing gcloud..."
    sudo apt install -y apt-transport-https ca-certificates gnupg curl

    # Add Google Cloud GPG key
    if [ -f /usr/share/keyrings/cloud.google.gpg ]; then
        sudo rm /usr/share/keyrings/cloud.google.gpg
    fi
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

    sudo apt update
    if sudo apt install -y google-cloud-cli; then
        log_success "gcloud installed successfully"
    else
        log_error "Failed to install gcloud"
        FAILED_PACKAGES+=("gcloud")
    fi
fi

# ============================================================================
# az - Azure CLI
# ============================================================================
echo ""
echo "[13/16] az - Azure CLI"
if command_exists az; then
    log_success "azure-cli is already installed"
else
    log_info "Installing azure-cli..."
    if curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; then
        log_success "azure-cli installed successfully"
    else
        log_error "Failed to install azure-cli"
        FAILED_PACKAGES+=("azure-cli")
    fi
fi

# ============================================================================
# gh - GitHub CLI (official apt repo, NOT snap)
# ============================================================================
echo ""
echo "[14/16] gh - GitHub CLI"
if command_exists gh; then
    log_success "gh is already installed"
else
    log_info "Installing gh..."
    if ! install_gh_repo; then
        log_error "Failed to configure gh apt repository"
        FAILED_PACKAGES+=("gh")
    else

        sudo apt update
        if sudo apt install -y gh; then
            log_success "gh installed successfully"
        else
            log_error "Failed to install gh"
            FAILED_PACKAGES+=("gh")
        fi
    fi
fi

# ============================================================================
# yq - YAML/XML/TOML processor
# ============================================================================
echo ""
echo "[15/16] yq - YAML/XML/TOML processor"
if command_exists yq; then
    log_success "yq is already installed"
else
    log_info "Installing yq..."
    if sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64; then
        sudo chmod +x /usr/local/bin/yq
        log_success "yq installed successfully"
    else
        log_error "Failed to install yq"
        FAILED_PACKAGES+=("yq")
    fi
fi

# ============================================================================
# httpie - User-friendly HTTP client
# ============================================================================
echo ""
echo "[16/16] httpie - User-friendly HTTP client"
if command_exists http; then
    log_success "httpie is already installed"
else
    log_info "Installing httpie..."
    if sudo apt install -y httpie; then
        log_success "httpie installed successfully"
    else
        log_error "Failed to install httpie"
        FAILED_PACKAGES+=("httpie")
    fi
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "==================================="
echo "DevOps tools installation complete!"
echo "==================================="
echo ""
echo "Installed tools:"
command_exists kubectl && echo "  - kubectl $(kubectl version --client --short 2>/dev/null || echo '')"
command_exists kubectx && echo "  - kubectx $(kubectx --version 2>/dev/null || echo '')"
command_exists kubens && echo "  - kubens (included with kubectx)"
command_exists helm && echo "  - helm $(helm version --short 2>/dev/null || echo '')"
command_exists k9s && echo "  - k9s $(k9s version --short 2>/dev/null || echo '')"
command_exists stern && echo "  - stern $(stern --version 2>/dev/null || echo '')"
command_exists argocd && echo "  - argocd $(argocd version --client --short 2>/dev/null || echo '')"
command_exists flux && echo "  - flux $(flux --version 2>/dev/null || echo '')"
command_exists terraform && echo "  - terraform $(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || echo '')"
command_exists ansible && echo "  - ansible $(ansible --version 2>/dev/null | head -1 || echo '')"
command_exists aws && echo "  - aws $(aws --version 2>/dev/null || echo '')"
command_exists gcloud && echo "  - gcloud $(gcloud version 2>/dev/null | head -1 || echo '')"
command_exists az && echo "  - az $(az version 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4 || echo '')"
command_exists gh && echo "  - gh $(gh --version 2>/dev/null | head -1 || echo '')"
command_exists yq && echo "  - yq $(yq --version 2>/dev/null || echo '')"
command_exists http && echo "  - httpie $(http --version 2>/dev/null || echo '')"
echo ""
echo "Next steps:"
echo "  - Configure AWS: aws configure"
echo "  - Configure GCloud: gcloud init"
echo "  - Configure Azure: az login"
echo "  - Configure GitHub: gh auth login"
echo "  - Configure kubectl: kubectl config view"
echo "  - Configure ArgoCD: argocd login <server>"
echo "  - Configure Flux: flux check --pre"
