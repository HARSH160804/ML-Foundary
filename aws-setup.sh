#!/bin/bash

# AWS MLFoundry Deployment - Automated Setup Script
# This script creates all necessary AWS resources

set -e  # Exit on any error

# Configuration
REGION="us-east-1"
ACCOUNT_ID="089781651605"
KEY_NAME="mlfoundry-deploy-key"
INSTANCE_NAME="mlfoundry-backend-prod"
SECURITY_GROUP_NAME="mlfoundry-sg"
INSTANCE_TYPE="t2.medium"
AMI_ID="ami-0d28727121d5d4a3c"  # Ubuntu 22.04 LTS in us-east-1 (latest)

echo "=========================================="
echo "MLFoundry AWS Setup - Automated"
echo "=========================================="
echo ""

# Step 1: Create Key Pair (if it doesn't exist)
echo "Step 1: Checking/Creating SSH Key Pair..."
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
    echo "✓ Key pair '$KEY_NAME' already exists"
else
    echo "Creating new key pair..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --region "$REGION" --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
    chmod 400 "${KEY_NAME}.pem"
    echo "✓ Key pair created and saved to ${KEY_NAME}.pem"
    echo "⚠️  IMPORTANT: Save this file securely! You cannot download it again."
fi
echo ""

# Step 2: Create Security Group
echo "Step 2: Checking/Creating Security Group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    echo "Creating security group..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "Security group for MLFoundry backend" \
        --region "$REGION" \
        --query 'GroupId' \
        --output text)
    
    # Add inbound rules
    echo "Adding security group rules..."
    
    # SSH (from your IP only)
    MY_IP=$(curl -s https://checkip.amazonaws.com)
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "${MY_IP}/32" --region "$REGION"
    
    # HTTP
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION"
    
    # HTTPS
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$REGION"
    
    echo "✓ Security group created: $SG_ID"
else
    echo "✓ Security group already exists: $SG_ID"
fi
echo ""

# Step 3: Launch EC2 Instance
echo "Step 3: Checking/Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running,pending,stopped" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "Launching EC2 instance..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}' \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --region "$REGION" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    echo "✓ Instance launched: $INSTANCE_ID"
    echo "⏳ Waiting for instance to start..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
    sleep 10  # Additional wait for SSH to be ready
else
    echo "✓ Instance already exists: $INSTANCE_ID"
fi
echo ""

# Step 4: Get Public IP
echo "Step 4: Getting Instance Public IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
    echo "⚠️  Instance is starting... waiting for public IP..."
    sleep 15
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
fi

echo "✓ Public IP: $PUBLIC_IP"
echo ""

# Step 5: Summary
echo "=========================================="
echo "✅ AWS Setup Complete!"
echo "=========================================="
echo ""
echo "📝 Resource Details:"
echo "-------------------"
echo "AWS Account ID:    $ACCOUNT_ID"
echo "Region:            $REGION"
echo "ECR Repository:    089781651605.dkr.ecr.us-east-1.amazonaws.com/mlfoundry-backend"
echo "Instance ID:       $INSTANCE_ID"
echo "Public IP:         $PUBLIC_IP"
echo "Security Group:    $SG_ID"
echo "SSH Key:           ${KEY_NAME}.pem"
echo ""
echo "🔐 GitHub Secrets (you'll need these):"
echo "--------------------------------------"
echo "AWS_ACCOUNT_ID:        $ACCOUNT_ID"
echo "AWS_REGION:            $REGION"
echo "ECR_REPOSITORY:        mlfoundry-backend"
echo "EC2_HOST:              $PUBLIC_IP"
echo "EC2_USERNAME:          ubuntu"
echo "EC2_SSH_KEY:           <content of ${KEY_NAME}.pem>"
echo ""
echo "📋 Next Steps:"
echo "--------------"
echo "1. Test SSH connection:"
echo "   ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "2. Run the EC2 setup script (I'll provide this next)"
echo ""
echo "3. Add GitHub Secrets (I'll guide you through this)"
echo ""
echo "🔒 Save ${KEY_NAME}.pem securely - you cannot download it again!"
echo ""
