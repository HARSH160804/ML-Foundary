# 🎉 MLFoundry Deployment Status

## ✅ Backend is LIVE!

Your FastAPI backend is successfully deployed and running on AWS EC2.

**Backend URL:** http://100.57.5.255  
**API Documentation:** http://100.57.5.255/docs  
**Health Check:** http://100.57.5.255/health

---

## 🚀 What's Been Deployed

### Infrastructure
- ✅ EC2 Instance (t3.small, Ubuntu 22.04)
- ✅ Docker container running
- ✅ ECR repository with Docker image
- ✅ Security Group configured (HTTP/HTTPS/SSH)
- ✅ SSH key generated

### Application
- ✅ FastAPI backend containerized
- ✅ Multi-stage Docker build for production
- ✅ Nginx reverse proxy configured
- ✅ Health check endpoint working
- ✅ CORS configured for frontend

### CI/CD
- ✅ GitHub Actions workflow configured
- ✅ Automated build and deployment pipeline ready
- ⏳ **Needs GitHub Secrets** - See below

---

## 📋 Next Steps to Enable Auto-Deployment

### 1. Add GitHub Secrets (5 minutes)

Go to: **https://github.com/HARSH160804/ML-Foundary/settings/secrets/actions**

Click "New repository secret" and add these **6 secrets**:

| Secret Name | Where to Find Value |
|-------------|---------------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key |
| `AWS_ACCOUNT_ID` | `089781651605` |
| `EC2_HOST` | `100.57.5.255` |
| `EC2_USERNAME` | `ubuntu` |
| `EC2_SSH_KEY` | Content of `mlfoundry-deploy-key.pem` file |

**For EC2_SSH_KEY:**
```bash
cat mlfoundry-deploy-key.pem
```
Copy the entire output including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`

---

### 2. Test Auto-Deployment (2 minutes)

After adding secrets, test the pipeline:

```bash
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

Watch deployment: **https://github.com/HARSH160804/ML-Foundary/actions**

---

### 3. Deploy Frontend on AWS Amplify (10 minutes)

1. Go to: **https://console.aws.amazon.com/amplify/home?region=us-east-1**
2. Click **"New app"** → **"Host web app"**
3. Select **"GitHub"** and authorize
4. Choose repository: `HARSH160804/ML-Foundary`
5. Branch: `main`
6. **Important:** Add environment variable:
   - Key: `VITE_API_BASE_URL`
   - Value: `http://100.57.5.255`
7. Save and deploy

Your frontend will be available at: `https://[your-app-id].amplifyapp.com`

---

## 🔄 Daily Workflow (After Setup)

Once GitHub secrets are added, deployment is automatic:

```bash
# Make your code changes
git add .
git commit -m "Your changes"
git push origin main
```

**That's it!** GitHub Actions automatically:
1. Builds Docker image
2. Pushes to ECR
3. Deploys to EC2
4. Restarts container
5. Verifies health

Amplify automatically builds and deploys frontend changes.

---

## 🛠️ Useful Commands

### Check Backend Status
```bash
curl http://100.57.5.255/health
```

### SSH into EC2
```bash
ssh -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255
```

### View Container Logs
```bash
ssh -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255 "docker logs mlfoundry-backend"
```

### Restart Container
```bash
ssh -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255 "docker restart mlfoundry-backend"
```

### Manual Deployment
```bash
ssh -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255 '/opt/mlfoundry/deploy.sh'
```

---

## 📊 Current Status

| Component | Status | URL/Details |
|-----------|--------|-------------|
| Backend API | ✅ **LIVE** | http://100.57.5.255 |
| API Docs | ✅ **LIVE** | http://100.57.5.255/docs |
| Health Check | ✅ **LIVE** | http://100.57.5.255/health |
| Docker Image | ✅ In ECR | latest tag |
| EC2 Instance | ✅ Running | i-0c231a3dbf75bc50e |
| GitHub Actions | ⏳ Needs Secrets | Workflow ready |
| Frontend | ⏳ Pending | Setup Amplify |

---

## 💰 Monthly AWS Costs

| Service | Cost (Estimated) |
|---------|------------------|
| EC2 t3.small | ~$15/month |
| EBS 30GB | ~$3/month |
| ECR Storage | ~$1/month |
| Amplify | $0-1/month |
| **Total** | **~$20/month** |

---

## 📞 Important Links

- **GitHub Repo:** https://github.com/HARSH160804/ML-Foundary
- **GitHub Actions:** https://github.com/HARSH160804/ML-Foundary/actions
- **GitHub Secrets:** https://github.com/HARSH160804/ML-Foundary/settings/secrets/actions
- **AWS Amplify:** https://console.aws.amazon.com/amplify/home?region=us-east-1
- **AWS EC2:** https://console.aws.amazon.com/ec2/home?region=us-east-1

---

## ⚠️ Security Notes

- **SSH Key** (`mlfoundry-deploy-key.pem`) - Keep secure, never commit to Git
- **AWS Credentials** - Stored locally, never commit to Git
- **GitHub Secrets** - Encrypted by GitHub, safe to use
- The `.pem` file is already in `.gitignore`
- Rotate AWS keys periodically

---

## 🆘 Troubleshooting

### Cannot SSH
```bash
chmod 400 mlfoundry-deploy-key.pem
ssh -v -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255
```

### GitHub Actions Failing
1. Verify all 6 secrets are set correctly
2. Check SSH key has no extra spaces/newlines
3. View logs at: https://github.com/HARSH160804/ML-Foundary/actions

### Backend Not Responding
```bash
ssh -i mlfoundry-deploy-key.pem ubuntu@100.57.5.255
docker logs mlfoundry-backend
docker restart mlfoundry-backend
```

---

## ✨ You're Almost Done!

- ✅ Backend deployed and working
- ⏳ Add GitHub secrets (5 min)
- ⏳ Setup Amplify frontend (10 min)

**Total remaining time: ~15 minutes**

Start by adding the GitHub secrets, then test the auto-deployment!
