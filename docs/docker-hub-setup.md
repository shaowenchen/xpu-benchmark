# Docker Hub Setup Guide

## Overview

This guide will help you set up Docker Hub credentials so that GitHub Actions can automatically build and publish Docker images.

## Steps

### 1. Create Docker Hub Account

If you don't have a Docker Hub account yet, please register first:

1. Visit [Docker Hub](https://hub.docker.com/)
2. Click "Sign Up" to create an account
3. Verify your email address

### 2. Create Access Token

1. Login to Docker Hub
2. Click on your username in the top right corner, select "Account Settings"
3. In the left menu, select "Security"
4. Click "New Access Token"
5. Enter token name (recommended: `GitHub Actions`)
6. Select permissions:
   - **Read & Write**: Recommended, allows pushing images
   - **Read Only**: Only allows pulling images
7. Click "Generate"
8. **Important**: Copy the generated token and save it in a secure place

### 3. Configure GitHub Secrets

1. In your GitHub repository, go to the "Settings" tab
2. In the left menu, select "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Add the following two secrets:

#### DOCKERHUB_USERNAME
- **Name**: `DOCKERHUB_USERNAME`
- **Value**: Your Docker Hub username

#### DOCKERHUB_TOKEN
- **Name**: `DOCKERHUB_TOKEN`
- **Value**: The access token you just created

### 4. Verify Setup

After setup is complete, when you push code to the `main` or `master` branch, GitHub Actions will automatically:

1. Build Docker images
2. Login to Docker Hub
3. Push images to your account

### 5. View Built Images

After building is complete, you can view the images at:

- **Docker Hub**: https://hub.docker.com/r/shaowenchen/xpu-benchmark
- **GitHub Actions**: View build logs in the "Actions" tab of your repository

## Image Tagging

GitHub Actions will create the following types of tags:

### Branch Tags
- `shaowenchen/xpu-benchmark:gpu-training-{commit-sha}` - Based on commit hash
- `shaowenchen/xpu-benchmark:gpu-training-{branch-name}` - Based on branch name

### Version Tags
- `shaowenchen/xpu-benchmark:gpu-training-v1.0.0` - Based on version number
- `shaowenchen/xpu-benchmark:gpu-training-latest` - Latest version

### Examples
```bash
# Pull image for specific commit
docker pull shaowenchen/xpu-benchmark:gpu-training-abc123

# Pull latest version
docker pull shaowenchen/xpu-benchmark:gpu-training-latest

# Pull specific version
docker pull shaowenchen/xpu-benchmark:gpu-training-v1.0.0
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```
   Error: unauthorized: authentication required
   ```
   **Solution**: Check if `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are set correctly

2. **Insufficient Permissions**
   ```
   Error: denied: requested access to the resource is denied
   ```
   **Solution**: Ensure the access token has "Read & Write" permissions

3. **Image Name Conflict**
   ```
   Error: denied: repository does not exist
   ```
   **Solution**: Ensure the Docker Hub account exists and the username is correct

### Debug Steps

1. Check if GitHub Secrets are set correctly
2. Verify if the Docker Hub access token is valid
3. View GitHub Actions logs for detailed error information
4. Ensure the repository has push permissions

## Security Recommendations

1. **Regular Token Rotation**: Recommend updating access tokens every 90 days
2. **Principle of Least Privilege**: Only grant necessary permissions
3. **Usage Monitoring**: Regularly check token usage
4. **Secure Storage**: Don't hardcode credentials in code

## Related Links

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Login Action](https://github.com/marketplace/actions/docker-login) 