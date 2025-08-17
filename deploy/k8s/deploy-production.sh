#!/bin/bash
# TaskFlow Production-Ready Deployment Script
# Enterprise-grade deployment with error handling, validation, and environment awareness

set -euo pipefail

# Global configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="deployment-$(date +%Y%m%d-%H%M%S).log"
readonly NAMESPACE="${DEPLOYMENT_NAMESPACE:-taskflow}"
readonly ENVIRONMENT="${DEPLOYMENT_ENV:-development}"
readonly DRY_RUN="${DRY_RUN:-false}"
readonly SKIP_VALIDATION="${SKIP_VALIDATION:-false}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global variables
DEPLOYMENT_START_TIME=""
KUBECTL_ARGS=""
INGRESS_IP=""
BACKUP_FILES=()

# Logging functions
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_info() {
    log_with_timestamp "${BLUE}INFO${NC}: $*"
}

log_warning() {
    log_with_timestamp "${YELLOW}WARNING${NC}: $*"
}

log_error() {
    log_with_timestamp "${RED}ERROR${NC}: $*"
}

log_success() {
    log_with_timestamp "${GREEN}SUCCESS${NC}: $*"
}

# Error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Deployment failed with exit code $exit_code at line $line_number"
    log_error "Last command: $BASH_COMMAND"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        cleanup_on_failure
    fi
    
    show_troubleshooting_info
    exit $exit_code
}

trap 'handle_error $? $LINENO' ERR

# Cleanup functions
cleanup_on_failure() {
    log_warning "Performing cleanup due to deployment failure..."
    
    # Restore backup files
    restore_backups
    
    # Optionally remove failed deployment
    if confirm_action "Remove failed deployment resources?"; then
        kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
        log_info "Failed deployment resources removed"
    fi
}

restore_backups() {
    for backup_file in "${BACKUP_FILES[@]}"; do
        if [[ -f "$backup_file" ]]; then
            local original_file="${backup_file%.backup.*}"
            if [[ -f "$original_file" ]]; then
                cp "$backup_file" "$original_file"
                log_info "Restored $original_file from backup"
            fi
        fi
    done
}

show_troubleshooting_info() {
    log_error "Deployment failed. Troubleshooting information:"
    echo "  📋 Check pod status: kubectl get pods -n $NAMESPACE"
    echo "  📋 View recent events: kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp"
    echo "  📋 Check API logs: kubectl logs -f deployment/taskflow-api -n $NAMESPACE"
    echo "  📋 Check frontend logs: kubectl logs -f deployment/taskflow-frontend -n $NAMESPACE"
    echo "  📋 View deployment log: $LOG_FILE"
    echo "  📋 Manual cleanup: kubectl delete namespace $NAMESPACE"
}

# Validation functions
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check required commands
    local required_commands=("kubectl" "curl" "grep" "sed")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check kubectl version
    local kubectl_version
    kubectl_version=$(kubectl version --client --short 2>/dev/null | grep "Client Version" | cut -d' ' -f3)
    log_info "kubectl version: $kubectl_version"
    
    # Check cluster connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        log_error "Please ensure kubectl is configured and cluster is accessible"
        exit 1
    fi
    
    # Check cluster permissions
    if ! kubectl auth can-i create namespaces >/dev/null 2>&1; then
        log_error "Insufficient permissions to create namespaces"
        exit 1
    fi
    
    # Validate required files
    local required_files=("namespace.yaml" "configmap.yaml" "secret.yaml" "postgres.yaml" "api.yaml" "frontend.yaml" "ingress.yaml")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            log_error "Required file not found: $file"
            exit 1
        fi
    done
    
    log_success "Prerequisites validation completed"
}

validate_environment() {
    log_info "Validating environment configuration..."
    
    case "$ENVIRONMENT" in
        "development"|"dev")
            ENVIRONMENT="development"
            ;;
        "staging"|"stage")
            ENVIRONMENT="staging"
            ;;
        "production"|"prod")
            ENVIRONMENT="production"
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            log_error "Supported environments: development, staging, production"
            exit 1
            ;;
    esac
    
    log_info "Deploying to environment: $ENVIRONMENT"
    
    # Environment-specific validations
    if [[ "$ENVIRONMENT" == "production" ]]; then
        validate_production_requirements
    fi
}

validate_production_requirements() {
    log_info "Validating production-specific requirements..."
    
    # Check for sensitive variables (in production, secrets should come from external sources)
    if grep -q "dGFza2Zsb3c=" "$SCRIPT_DIR/secret.yaml" 2>/dev/null; then
        log_error "Production deployment detected hardcoded secrets"
        log_error "Please use external secret management for production"
        exit 1
    fi
    
    # Check for resource limits
    if ! grep -q "resources:" "$SCRIPT_DIR/api.yaml" 2>/dev/null; then
        log_warning "No resource limits defined for API deployment"
        log_warning "This is not recommended for production"
    fi
    
    # Require confirmation for production
    if [[ "${CONFIRM_PRODUCTION:-}" != "yes" ]]; then
        log_warning "Production deployment requires explicit confirmation"
        log_warning "Set CONFIRM_PRODUCTION=yes to proceed"
        exit 1
    fi
}

# Utility functions
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would prompt: $message"
        return 0
    fi
    
    read -p "$message (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

retry_command() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
            sleep "$delay"
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Command failed after $max_attempts attempts: $*"
    return 1
}

track_time() {
    local start_time=$(date +%s)
    "$@"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_info "Operation completed in ${duration}s: $*"
}

# Docker and image management
validate_container_images() {
    log_info "Validating container images..."
    
    local required_images=("taskflow-api:latest" "taskflow-web:latest")
    local missing_images=()
    
    for image in "${required_images[@]}"; do
        if ! docker image inspect "$image" >/dev/null 2>&1; then
            missing_images+=("$image")
        fi
    done
    
    if [[ ${#missing_images[@]} -gt 0 ]]; then
        log_error "Missing required container images:"
        for image in "${missing_images[@]}"; do
            log_error "  - $image"
        done
        log_error "Please build required images before deployment"
        exit 1
    fi
    
    log_success "Container images validation completed"
}

rebuild_frontend_if_needed() {
    log_info "Checking if frontend rebuild is needed..."
    
    # Check if source files are newer than the image
    local api_src_dir="$SCRIPT_DIR/../../src/TaskFlow.Web/src"
    if [[ -d "$api_src_dir" ]]; then
        local newest_src_file
        newest_src_file=$(find "$api_src_dir" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | xargs ls -t | head -1)
        
        if [[ -n "$newest_src_file" ]]; then
            local src_time
            src_time=$(stat -f %m "$newest_src_file" 2>/dev/null || stat -c %Y "$newest_src_file" 2>/dev/null)
            
            local image_time
            image_time=$(docker image inspect taskflow-web:latest --format='{{.Created}}' 2>/dev/null | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
            
            if [[ $src_time -gt $image_time ]]; then
                log_info "Source files newer than container image, rebuilding..."
                rebuild_frontend_container
            else
                log_info "Container image is up to date"
            fi
        fi
    fi
}

rebuild_frontend_container() {
    log_info "Rebuilding frontend container..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would rebuild frontend container"
        return 0
    fi
    
    local build_context="$SCRIPT_DIR/../.."
    if ! docker build -f "$build_context/deploy/docker/Dockerfile.web" -t taskflow-web:latest "$build_context"; then
        log_error "Failed to rebuild frontend container"
        exit 1
    fi
    
    log_success "Frontend container rebuilt successfully"
}

# Kubernetes deployment functions
check_nginx_ingress_controller() {
    log_info "Checking nginx ingress controller..."
    
    if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase=Running 2>/dev/null | grep -q controller; then
        log_success "Nginx ingress controller is running"
        return 0
    fi
    
    log_warning "Nginx ingress controller not found"
    
    if confirm_action "Install nginx ingress controller?"; then
        install_nginx_ingress_controller
    else
        log_error "Nginx ingress controller is required for deployment"
        exit 1
    fi
}

install_nginx_ingress_controller() {
    log_info "Installing nginx ingress controller..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would install nginx ingress controller"
        return 0
    fi
    
    local nginx_url="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml"
    
    if ! kubectl apply -f "$nginx_url"; then
        log_error "Failed to install nginx ingress controller"
        exit 1
    fi
    
    log_info "Waiting for nginx ingress controller to be ready..."
    if ! kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s; then
        log_error "Nginx ingress controller failed to become ready"
        exit 1
    fi
    
    log_success "Nginx ingress controller installed successfully"
}

deploy_kubernetes_resources() {
    log_info "Deploying Kubernetes resources..."
    
    # Set kubectl arguments
    if [[ "$DRY_RUN" == "true" ]]; then
        KUBECTL_ARGS="--dry-run=client"
        log_info "DRY RUN MODE: No actual changes will be made"
    fi
    
    # Deploy in order
    local resources=(
        "namespace.yaml:Namespace"
        "configmap.yaml:ConfigMap"
        "secret.yaml:Secret"
        "postgres.yaml:PostgreSQL"
        "api.yaml:API"
        "frontend.yaml:Frontend"
        "ingress.yaml:Ingress"
    )
    
    for resource in "${resources[@]}"; do
        local file="${resource%:*}"
        local name="${resource#*:}"
        
        log_info "Deploying $name..."
        track_time kubectl apply -f "$SCRIPT_DIR/$file" $KUBECTL_ARGS
        
        # Wait for deployments to be ready (skip in dry-run)
        if [[ "$DRY_RUN" != "true" && "$file" =~ \.yaml$ ]]; then
            wait_for_resource_ready "$file" "$name"
        fi
    done
    
    log_success "Kubernetes resources deployed successfully"
}

wait_for_resource_ready() {
    local file="$1"
    local name="$2"
    
    # Extract deployment names from the file
    local deployments
    deployments=$(grep -E "^  name: taskflow-" "$SCRIPT_DIR/$file" | grep -v "service\|ingress\|config\|secret" | awk '{print $2}' || true)
    
    for deployment in $deployments; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            log_info "Waiting for deployment $deployment to be ready..."
            if ! kubectl wait --for=condition=available deployment/"$deployment" -n "$NAMESPACE" --timeout=600s; then
                log_error "Deployment $deployment failed to become ready"
                return 1
            fi
            log_success "Deployment $deployment is ready"
        fi
    done
}

# Network configuration
configure_networking() {
    log_info "Configuring networking..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would configure networking"
        return 0
    fi
    
    detect_ingress_ip
    manage_hosts_file
}

detect_ingress_ip() {
    log_info "Detecting ingress IP address..."
    
    # Try to get LoadBalancer IP
    local attempts=0
    local max_attempts=30
    
    while [[ $attempts -lt $max_attempts ]]; do
        INGRESS_IP=$(kubectl get ingress taskflow-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [[ -n "$INGRESS_IP" && "$INGRESS_IP" != "null" ]]; then
            log_success "Ingress IP detected: $INGRESS_IP"
            return 0
        fi
        
        attempts=$((attempts + 1))
        log_info "Waiting for ingress IP (attempt $attempts/$max_attempts)..."
        sleep 5
    done
    
    # Fallback to localhost for local development
    log_warning "No LoadBalancer IP found, using localhost for local development"
    INGRESS_IP="127.0.0.1"
}

manage_hosts_file() {
    local hosts_entry="$INGRESS_IP taskflow.local"
    
    log_info "Managing hosts file entry: $hosts_entry"
    
    # Backup current hosts file
    local backup_file="/tmp/hosts.backup.$(date +%s)"
    cp /etc/hosts "$backup_file"
    BACKUP_FILES+=("$backup_file")
    log_info "Hosts file backed up to: $backup_file"
    
    # Remove existing entries
    grep -v "taskflow.local" /etc/hosts > /tmp/hosts.tmp 2>/dev/null || true
    echo "$hosts_entry" >> /tmp/hosts.tmp
    
    # Update hosts file
    if sudo cp /tmp/hosts.tmp /etc/hosts; then
        log_success "Hosts file updated: $hosts_entry"
    else
        log_error "Failed to update hosts file"
        return 1
    fi
    
    rm -f /tmp/hosts.tmp
}

# Validation and testing
validate_deployment() {
    log_info "Validating deployment..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would validate deployment"
        return 0
    fi
    
    # Check pod status
    log_info "Checking pod status..."
    kubectl get pods -n "$NAMESPACE"
    
    # Test health endpoints
    test_health_endpoints
    
    # Test application functionality
    test_application_functionality
}

test_health_endpoints() {
    log_info "Testing health endpoints..."
    
    local health_url="http://taskflow.local/health"
    local max_attempts=12
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s --connect-timeout 10 "$health_url" >/dev/null; then
            log_success "Health endpoint is accessible"
            return 0
        fi
        
        log_info "Health check attempt $attempt/$max_attempts..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    log_error "Health endpoint not accessible after $((max_attempts * 10)) seconds"
    return 1
}

test_application_functionality() {
    log_info "Testing application functionality..."
    
    # Test API endpoint
    local api_url="http://taskflow.local/api/tasks"
    if curl -f -s --connect-timeout 10 "$api_url" >/dev/null; then
        log_success "API endpoint is accessible"
    else
        log_error "API endpoint not accessible"
        return 1
    fi
    
    # Test frontend
    local frontend_url="http://taskflow.local"
    if curl -f -s --connect-timeout 10 "$frontend_url" | grep -q "<!DOCTYPE html"; then
        log_success "Frontend is accessible"
    else
        log_error "Frontend not accessible"
        return 1
    fi
}

# Main deployment workflow
main() {
    DEPLOYMENT_START_TIME=$(date +%s)
    
    log_info "Starting TaskFlow deployment"
    log_info "Environment: $ENVIRONMENT"
    log_info "Namespace: $NAMESPACE"
    log_info "Dry Run: $DRY_RUN"
    log_info "Log File: $LOG_FILE"
    
    # Validation phase
    if [[ "$SKIP_VALIDATION" != "true" ]]; then
        validate_prerequisites
        validate_environment
        validate_container_images
    fi
    
    # Preparation phase
    check_nginx_ingress_controller
    rebuild_frontend_if_needed
    
    # Deployment phase
    deploy_kubernetes_resources
    configure_networking
    
    # Validation phase
    validate_deployment
    
    # Success
    local deployment_end_time=$(date +%s)
    local total_duration=$((deployment_end_time - DEPLOYMENT_START_TIME))
    
    log_success "TaskFlow deployment completed successfully!"
    log_info "Total deployment time: ${total_duration}s"
    
    # Show access information
    show_access_information
}

show_access_information() {
    echo ""
    log_success "🌍 Access Information:"
    echo "  🎨 Frontend: http://taskflow.local"
    echo "  🌐 API: http://taskflow.local/api"
    echo "  🏥 Health: http://taskflow.local/health"
    echo "  📚 Swagger: http://taskflow.local/swagger"
    echo ""
    log_info "🔧 Useful Commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -f deployment/taskflow-api -n $NAMESPACE"
    echo "  kubectl logs -f deployment/taskflow-frontend -n $NAMESPACE"
    echo "  kubectl describe ingress taskflow-ingress -n $NAMESPACE"
    echo ""
    log_info "📋 Deployment Log: $LOG_FILE"
}

# Help and usage
show_help() {
    cat << EOF
TaskFlow Production-Ready Deployment Script

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -e, --environment ENV   Set deployment environment (development|staging|production)
    -n, --namespace NS      Set Kubernetes namespace (default: taskflow)
    -d, --dry-run          Perform a dry run without making changes
    -s, --skip-validation  Skip prerequisite validation
    -f, --force            Force deployment without confirmation prompts

ENVIRONMENT VARIABLES:
    DEPLOYMENT_ENV          Deployment environment (development|staging|production)
    DEPLOYMENT_NAMESPACE    Kubernetes namespace (default: taskflow)
    DRY_RUN                 Enable dry run mode (true|false)
    SKIP_VALIDATION         Skip validation checks (true|false)
    CONFIRM_PRODUCTION      Required for production deployments (yes)

EXAMPLES:
    # Development deployment
    $SCRIPT_NAME --environment development

    # Production deployment with confirmation
    CONFIRM_PRODUCTION=yes $SCRIPT_NAME --environment production

    # Dry run for validation
    $SCRIPT_NAME --dry-run --environment staging

    # Custom namespace
    $SCRIPT_NAME --namespace taskflow-dev --environment development

EOF
}

# Command line argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -s|--skip-validation)
            SKIP_VALIDATION="true"
            shift
            ;;
        -f|--force)
            CONFIRM_PRODUCTION="yes"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main deployment
main "$@"