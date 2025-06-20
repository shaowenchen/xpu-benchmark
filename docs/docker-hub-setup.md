# Docker Hub 设置指南

## 概述

本指南将帮助您设置 Docker Hub 凭据，以便 GitHub Actions 可以自动构建和发布 Docker 镜像。

## 步骤

### 1. 创建 Docker Hub 账户

如果您还没有 Docker Hub 账户，请先注册：

1. 访问 [Docker Hub](https://hub.docker.com/)
2. 点击 "Sign Up" 创建账户
3. 验证邮箱地址

### 2. 创建访问令牌

1. 登录 Docker Hub
2. 点击右上角的用户名，选择 "Account Settings"
3. 在左侧菜单中选择 "Security"
4. 点击 "New Access Token"
5. 输入令牌名称（建议：`GitHub Actions`）
6. 选择权限：
   - **Read & Write**: 推荐，允许推送镜像
   - **Read Only**: 仅允许拉取镜像
7. 点击 "Generate"
8. **重要**: 复制生成的令牌并保存到安全的地方

### 3. 配置 GitHub Secrets

1. 在您的 GitHub 仓库中，进入 "Settings" 标签
2. 在左侧菜单中选择 "Secrets and variables" > "Actions"
3. 点击 "New repository secret"
4. 添加以下两个密钥：

#### DOCKERHUB_USERNAME
- **Name**: `DOCKERHUB_USERNAME`
- **Value**: 您的 Docker Hub 用户名

#### DOCKERHUB_TOKEN
- **Name**: `DOCKERHUB_TOKEN`
- **Value**: 您刚才创建的访问令牌

### 4. 验证设置

设置完成后，当您推送代码到 `main` 或 `master` 分支时，GitHub Actions 将自动：

1. 构建 Docker 镜像
2. 登录到 Docker Hub
3. 推送镜像到您的账户

### 5. 查看构建的镜像

构建完成后，您可以在以下位置查看镜像：

- **Docker Hub**: https://hub.docker.com/r/shaowenchen/xpu-benchmark
- **GitHub Actions**: 在仓库的 "Actions" 标签中查看构建日志

## 镜像标签说明

GitHub Actions 会创建以下类型的标签：

### 分支标签
- `shaowenchen/xpu-benchmark:gpu-training-{commit-sha}` - 基于提交哈希
- `shaowenchen/xpu-benchmark:gpu-training-{branch-name}` - 基于分支名

### 版本标签
- `shaowenchen/xpu-benchmark:gpu-training-v1.0.0` - 基于版本号
- `shaowenchen/xpu-benchmark:gpu-training-latest` - 最新版本

### 示例
```bash
# 拉取特定提交的镜像
docker pull shaowenchen/xpu-benchmark:gpu-training-abc123

# 拉取最新版本
docker pull shaowenchen/xpu-benchmark:gpu-training-latest

# 拉取特定版本
docker pull shaowenchen/xpu-benchmark:gpu-training-v1.0.0
```

## 故障排除

### 常见问题

1. **认证失败**
   ```
   Error: unauthorized: authentication required
   ```
   **解决方案**: 检查 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN` 是否正确设置

2. **权限不足**
   ```
   Error: denied: requested access to the resource is denied
   ```
   **解决方案**: 确保访问令牌有 "Read & Write" 权限

3. **镜像名称冲突**
   ```
   Error: denied: repository does not exist
   ```
   **解决方案**: 确保 Docker Hub 账户存在且用户名正确

### 调试步骤

1. 检查 GitHub Secrets 是否正确设置
2. 验证 Docker Hub 访问令牌是否有效
3. 查看 GitHub Actions 日志获取详细错误信息
4. 确保仓库有推送权限

## 安全建议

1. **定期轮换令牌**: 建议每 90 天更新一次访问令牌
2. **最小权限原则**: 只授予必要的权限
3. **监控使用**: 定期检查令牌的使用情况
4. **安全存储**: 不要在代码中硬编码凭据

## 相关链接

- [Docker Hub 文档](https://docs.docker.com/docker-hub/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 登录 Action](https://github.com/marketplace/actions/docker-login) 