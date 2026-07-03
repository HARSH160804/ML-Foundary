#!/bin/bash

# EC2 Initial Setup Script
# Run this once on your EC2 instance to install all dependencies

set -e

echo "=========================================="
echo "MLFoundry EC2 Setup - Installing Dependencies"
echo "=========================================="
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "🐋 Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install AWS CLI
echo "☁️  Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Nginx
echo "🌐 Installing Nginx..."
sudo apt-get install -y nginx

# Install Certbot for Let's Encrypt
echo "🔒 Installing Certbot..."
sudo apt-get install -y certbot python3-certbot-nginx

# Create deployment directory
echo "📁 Creating deployment directory..."
sudo mkdir -p /opt/mlfoundry
sudo chown ubuntu:ubuntu /opt/mlfoundry

# Create environment file
echo "📝 Creating environment file..."
cat > /opt/mlfoundry/.env << 'EOF'
APP_NAME=CodeML
ENV=production
MAX_FILE_SIZE_MB=50
MAX_FILE_SIZE_BYTES=52428800
N_TRIALS=50
TEST_SIZE=0.2
CV_FOLDS=5
STORAGE_BASE=/app/storage
UPLOADS_DIR=/app/storage/uploads
SESSIONS_DIR=/app/storage/sessions
MODELS_DIR=/app/storage/models
EOF

# Create Docker deployment script
echo "🚀 Creating deployment script..."
cat > /opt/mlfoundry/deploy.sh << 'EOF'
#!/bin/bash
set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="089781651605"
ECR_REPOSITORY="mlfoundry-backend"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
CONTAINER_NAME="mlfoundry-backend"

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

echo "🐋 Pulling latest image..."
docker pull ${ECR_URI}:latest

echo "🛑 Stopping existing container..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo "🚀 Starting new container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p 8000:8000 \
  --env-file /opt/mlfoundry/.env \
  -v /opt/mlfoundry/storage:/app/storage \
  ${ECR_URI}:latest

echo "✅ Deployment complete!"
echo "📊 Container status:"
docker ps | grep ${CONTAINER_NAME}

echo ""
echo "📝 Container logs (last 20 lines):"
docker logs --tail 20 ${CONTAINER_NAME}
EOF

chmod +x /opt/mlfoundry/deploy.sh

# Configure Nginx (basic HTTP for now)
echo "⚙️  Configuring Nginx..."
sudo tee /etc/nginx/sites-available/mlfoundry > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings for long ML training requests
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }

    location /health {
        proxy_pass http://localhost:8000/health;
        access_log off;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/mlfoundry /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo ""
echo "=========================================="
echo "✅ EC2 Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Installed:"
echo "  ✓ Docker & Docker Compose"
echo "  ✓ AWS CLI"
echo "  ✓ Nginx (reverse proxy)"
echo "  ✓ Certbot (for HTTPS)"
echo ""
echo "🔄 Next Steps:"
echo "  1. Log out and log back in (for Docker group changes)"
echo "  2. Configure AWS credentials:"
echo "     aws configure"
echo "  3. Run deployment script:"
echo "     /opt/mlfoundry/deploy.sh"
echo ""
echo "⚠️  IMPORTANT: Log out and log back in now!"
echo "   Run: exit"
echo "   Then SSH back in"
echo ""
