# 0) Tạo Docker config tạm để tránh dùng credential helper của Desktop
export DOCKER_CONFIG="$(pwd)/.docker-tmp"
mkdir -p "$DOCKER_CONFIG"
printf '{ "auths": {} }\n' > "$DOCKER_CONFIG/config.json"

# 1) Lấy thông tin từ Terraform
ECR_REPO=$(terraform -chdir=terraform output -raw ecr_repo_url)
AWS_REGION=${AWS_REGION:-ap-southeast-1}   # đổi region nếu bạn dùng khác

echo "Repo: $ECR_REPO"
echo "Region: $AWS_REGION"

# 2) Login ECR (ghi token vào config tạm)
aws ecr get-login-password --region "$AWS_REGION" \
| docker login --username AWS --password-stdin "${ECR_REPO%/*}"

# 3) Build & push :latest
docker build -t "$ECR_REPO:latest" .
docker push "$ECR_REPO:latest"

# 4) Kiểm tra đã có tag latest trong ECR
aws ecr describe-images \
  --repository-name "$(basename "$ECR_REPO")" \
  --region "$AWS_REGION" \
  --query "imageDetails[?contains(imageTags, 'latest')].[imageTags,imageDigest]" \
  --output table

# 5) Trigger App Runner deploy (nếu có output ARN)
if terraform -chdir=terraform output -raw apprunner_service_arn >/dev/null 2>&1; then
  SERVICE_ARN=$(terraform -chdir=terraform output -raw apprunner_service_arn)
  aws apprunner start-deployment --service-arn "$SERVICE_ARN" --region "$AWS_REGION"
  echo "Triggered deployment for $SERVICE_ARN"
else
  echo "⚠️ Chưa có output apprunner_service_arn trong terraform/outputs.tf"
fi

# 6) (tuỳ chọn) dọn config tạm sau khi xong
# rm -rf "$DOCKER_CONFIG"
