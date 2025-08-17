#!/bin/bash
set -e

echo "🚀 Deploying TaskFlow with Nginx Ingress"

# Check if nginx ingress controller is available
echo "🔍 Checking nginx ingress controller..."
if ! kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase=Running | grep -q controller; then
    echo "⚠️  Nginx ingress controller not found. Installing..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    echo "⏳ Waiting for nginx ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=300s
fi

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f namespace.yaml

# Apply configuration
echo "⚙️ Applying configuration..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f postgres.yaml
kubectl wait --for=condition=available deployment/taskflow-postgres -n taskflow --timeout=300s

# Deploy API
echo "🌐 Deploying API..."
kubectl apply -f api.yaml
kubectl wait --for=condition=available deployment/taskflow-api -n taskflow --timeout=300s

# Deploy Frontend
echo "🎨 Deploying Frontend..."
kubectl apply -f frontend.yaml
kubectl wait --for=condition=available deployment/taskflow-frontend -n taskflow --timeout=300s

# Deploy Ingress
echo "🌍 Deploying Ingress..."
kubectl apply -f ingress.yaml

# Wait for ingress to get an IP
echo "⏳ Waiting for ingress IP..."
for i in {1..30}; do
    INGRESS_IP=$(kubectl get ingress taskflow-ingress -n taskflow -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$INGRESS_IP" ] && [ "$INGRESS_IP" != "null" ]; then
        echo "✅ Ingress IP detected: $INGRESS_IP"
        break
    fi
    echo "Waiting for ingress IP (attempt $i/30)..."
    sleep 5
done

# If no LoadBalancer IP, try to get nginx service IP
if [ -z "$INGRESS_IP" ] || [ "$INGRESS_IP" = "null" ]; then
    echo "⚠️  No LoadBalancer IP found, checking nginx ingress service..."
    INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$INGRESS_IP" ] || [ "$INGRESS_IP" = "null" ]; then
        # For local development, use localhost
        INGRESS_IP="127.0.0.1"
        echo "📍 Using localhost for local development"
    fi
fi

# Update hosts file (user will be prompted for sudo password if needed)
echo "📝 Updating hosts file..."
echo "Note: You may be prompted for your password to update /etc/hosts"
grep -v "taskflow.local" /etc/hosts > /tmp/hosts.tmp 2>/dev/null || true
echo "$INGRESS_IP taskflow.local" >> /tmp/hosts.tmp
sudo cp /tmp/hosts.tmp /etc/hosts
rm /tmp/hosts.tmp

# Test the application
echo "🧪 Testing application..."
sleep 10

if curl -f -s "http://taskflow.local/health" > /dev/null; then
    echo "✅ Health check successful!"
else
    echo "⚠️  Health check failed, but deployment completed. Application might need more time to start."
fi

echo ""
echo "🎉 TaskFlow deployment completed!"
echo ""
echo "🌐 Access URLs:"
echo "  🎨 Frontend: http://taskflow.local"
echo "  🌐 API: http://taskflow.local/api"
echo "  🏥 Health: http://taskflow.local/health"
echo "  📚 Swagger: http://taskflow.local/swagger"
echo ""
echo "🔧 Useful commands:"
echo "  kubectl get pods -n taskflow"
echo "  kubectl logs -f deployment/taskflow-api -n taskflow"
echo "  kubectl logs -f deployment/taskflow-frontend -n taskflow"
echo "  kubectl describe ingress taskflow-ingress -n taskflow"