#!/bin/bash
# ============================================================
# SETUP: Infrastruktura AWS dla formularza kontaktowego
# nadamel.pl
#
# Kompatybilny z Windows Git Bash / MINGW64
# ============================================================

set -e

REGION="eu-north-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="nadamel-attachments"
PRESIGN_FUNCTION="nadamel-presign"
CONTACT_FUNCTION="nadamel-contact"
API_NAME="nadamel-api"
ROLE_NAME="nadamel-lambda-role"
DOMAIN="nadamel.pl"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$SCRIPT_DIR/.tmp"
mkdir -p "$TMP_DIR"

# ── Konwertuj ścieżkę MINGW na Windows dla AWS CLI ──
to_win_path() {
  cygpath -w "$1" 2>/dev/null || echo "$1"
}

# ── Zipowanie + upload do Lambda ──
make_zip() {
  local src_dir="$1"
  local zip_name="$2"
  local zip_path="$TMP_DIR/$zip_name"
  rm -f "$zip_path"

  if command -v zip &>/dev/null; then
    (cd "$src_dir" && zip -r "$zip_path" . -x "*.git*" > /dev/null 2>&1)
  else
    local win_src win_zip
    win_src=$(to_win_path "$src_dir")
    win_zip=$(to_win_path "$zip_path")
    powershell.exe -NoProfile -Command "Compress-Archive -Path '${win_src}\\*' -DestinationPath '${win_zip}' -Force"
  fi

  if [ ! -f "$zip_path" ]; then
    echo "    BŁĄD: Nie udało się utworzyć $zip_path"
    exit 1
  fi
  echo "    ZIP: $(ls -lh "$zip_path" | awk '{print $5}')"
}

# ── fileb:// z poprawną ścieżką ──
fileb() {
  echo "fileb://$(to_win_path "$1")"
}

echo "============================================"
echo "  NADAMEL.PL — Setup AWS Infrastructure"
echo "============================================"
echo "Account: $ACCOUNT_ID"
echo "Region:  $REGION"
echo "TmpDir:  $TMP_DIR"
echo "============================================"
echo ""

# ============================================================
# 1. S3 BUCKET
# ============================================================
echo ">>> [1/7] S3 bucket: $BUCKET_NAME"

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" \
  2>/dev/null || echo "    Bucket juz istnieje"

aws s3api put-bucket-cors \
  --bucket "$BUCKET_NAME" \
  --cors-configuration '{"CORSRules":[{"AllowedOrigins":["https://nadamel.pl","https://www.nadamel.pl","http://localhost:4321"],"AllowedMethods":["PUT","GET"],"AllowedHeaders":["*"],"MaxAgeSeconds":3600}]}'
echo "    CORS OK"

aws s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET_NAME" \
  --lifecycle-configuration '{"Rules":[{"ID":"DeleteOldAttachments","Status":"Enabled","Filter":{"Prefix":"uploads/"},"Expiration":{"Days":30}}]}'
echo "    Lifecycle: auto-delete 30 dni"

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration '{"BlockPublicAcls":true,"IgnorePublicAcls":true,"BlockPublicPolicy":true,"RestrictPublicBuckets":true}'
echo "    Public access zablokowany"
echo ""

# ============================================================
# 2. IAM ROLE
# ============================================================
echo ">>> [2/7] IAM role: $ROLE_NAME"

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  2>/dev/null || echo "    Rola juz istnieje"

POLICY_DOC=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
    },
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail", "ses:SendRawEmail"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:${REGION}:${ACCOUNT_ID}:*"
    }
  ]
}
EOF
)

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "${ROLE_NAME}-policy" \
  --policy-document "$POLICY_DOC"
echo "    Policy OK (S3, SES, CloudWatch)"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo "    ARN: $ROLE_ARN"
echo ""

echo "    Czekam 10s na propagacje roli..."
sleep 10

# ============================================================
# 3. LAMBDA: PRESIGN UPLOAD
# ============================================================
echo ">>> [3/7] Lambda: $PRESIGN_FUNCTION"

cd "$SCRIPT_DIR/aws-lambdas/presign-upload"
npm install --production --silent 2>/dev/null || npm install --production 2>&1 | tail -3
make_zip "$SCRIPT_DIR/aws-lambdas/presign-upload" "presign-upload.zip"

PRESIGN_ZIP=$(fileb "$TMP_DIR/presign-upload.zip")
echo "    fileb: $PRESIGN_ZIP"

aws lambda create-function \
  --function-name "$PRESIGN_FUNCTION" \
  --runtime "nodejs20.x" \
  --role "$ROLE_ARN" \
  --handler "index.handler" \
  --zip-file "$PRESIGN_ZIP" \
  --timeout 10 \
  --memory-size 128 \
  --environment "Variables={BUCKET_NAME=${BUCKET_NAME}}" \
  --region "$REGION" \
  2>/dev/null || {
    echo "    Funkcja istnieje - aktualizuje..."
    aws lambda update-function-code \
      --function-name "$PRESIGN_FUNCTION" \
      --zip-file "$PRESIGN_ZIP" \
      --region "$REGION" > /dev/null
    sleep 5
    aws lambda update-function-configuration \
      --function-name "$PRESIGN_FUNCTION" \
      --environment "Variables={BUCKET_NAME=${BUCKET_NAME}}" \
      --region "$REGION" > /dev/null
  }
echo "    OK"
echo ""

# ============================================================
# 4. LAMBDA: CONTACT FORM
# ============================================================
echo ">>> [4/7] Lambda: $CONTACT_FUNCTION"

cd "$SCRIPT_DIR/aws-lambdas/contact-form"
npm install --production --silent 2>/dev/null || npm install --production 2>&1 | tail -3
make_zip "$SCRIPT_DIR/aws-lambdas/contact-form" "contact-form.zip"

CONTACT_ZIP=$(fileb "$TMP_DIR/contact-form.zip")
echo "    fileb: $CONTACT_ZIP"

aws lambda create-function \
  --function-name "$CONTACT_FUNCTION" \
  --runtime "nodejs20.x" \
  --role "$ROLE_ARN" \
  --handler "index.handler" \
  --zip-file "$CONTACT_ZIP" \
  --timeout 15 \
  --memory-size 128 \
  --environment "Variables={BUCKET_NAME=${BUCKET_NAME}}" \
  --region "$REGION" \
  2>/dev/null || {
    echo "    Funkcja istnieje - aktualizuje..."
    aws lambda update-function-code \
      --function-name "$CONTACT_FUNCTION" \
      --zip-file "$CONTACT_ZIP" \
      --region "$REGION" > /dev/null
    sleep 5
    aws lambda update-function-configuration \
      --function-name "$CONTACT_FUNCTION" \
      --environment "Variables={BUCKET_NAME=${BUCKET_NAME}}" \
      --region "$REGION" > /dev/null
  }
echo "    OK"
echo ""

# ============================================================
# 5. API GATEWAY (HTTP API)
# ============================================================
echo ">>> [5/7] API Gateway: $API_NAME"

EXISTING_API_ID=$(aws apigatewayv2 get-apis \
  --region "$REGION" \
  --query "Items[?Name=='${API_NAME}'].ApiId" --output text 2>/dev/null)

if [ -n "$EXISTING_API_ID" ] && [ "$EXISTING_API_ID" != "None" ]; then
  API_ID="$EXISTING_API_ID"
  echo "    API juz istnieje: $API_ID"
else
  API_ID=$(aws apigatewayv2 create-api \
    --name "$API_NAME" \
    --protocol-type "HTTP" \
    --cors-configuration '{"AllowOrigins":["https://www.nadamel.pl","https://nadamel.pl","http://localhost:4321"],"AllowMethods":["POST","OPTIONS"],"AllowHeaders":["Content-Type"],"MaxAge":3600}' \
    --region "$REGION" \
    --query "ApiId" --output text)
  echo "    Utworzono API: $API_ID"
fi

# Integracja: Presign
PRESIGN_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${PRESIGN_FUNCTION}"

PRESIGN_INTEGRATION_ID=$(aws apigatewayv2 create-integration \
  --api-id "$API_ID" \
  --integration-type "AWS_PROXY" \
  --integration-uri "$PRESIGN_ARN" \
  --payload-format-version "2.0" \
  --region "$REGION" \
  --query "IntegrationId" --output text 2>/dev/null) || true

if [ -n "$PRESIGN_INTEGRATION_ID" ]; then
  aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "POST /presign" \
    --target "integrations/${PRESIGN_INTEGRATION_ID}" \
    --region "$REGION" > /dev/null 2>&1 || true
  echo "    Route: POST /presign OK"
fi

# Integracja: Contact
CONTACT_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${CONTACT_FUNCTION}"

CONTACT_INTEGRATION_ID=$(aws apigatewayv2 create-integration \
  --api-id "$API_ID" \
  --integration-type "AWS_PROXY" \
  --integration-uri "$CONTACT_ARN" \
  --payload-format-version "2.0" \
  --region "$REGION" \
  --query "IntegrationId" --output text 2>/dev/null) || true

if [ -n "$CONTACT_INTEGRATION_ID" ]; then
  aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "POST /contact" \
    --target "integrations/${CONTACT_INTEGRATION_ID}" \
    --region "$REGION" > /dev/null 2>&1 || true
  echo "    Route: POST /contact OK"
fi

# Stage
aws apigatewayv2 create-stage \
  --api-id "$API_ID" \
  --stage-name '$default' \
  --auto-deploy \
  --region "$REGION" > /dev/null 2>&1 || echo "    Stage \$default juz istnieje"

# Permissions
aws lambda add-permission \
  --function-name "$PRESIGN_FUNCTION" \
  --statement-id "apigateway-presign-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*" \
  --region "$REGION" > /dev/null 2>&1 || true

aws lambda add-permission \
  --function-name "$CONTACT_FUNCTION" \
  --statement-id "apigateway-contact-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*" \
  --region "$REGION" > /dev/null 2>&1 || true

API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com"
echo "    API URL: $API_URL"
echo ""

# ============================================================
# 6. SES
# ============================================================
echo ">>> [6/7] SES: $DOMAIN"

SES_STATUS=$(aws ses get-identity-verification-attributes \
  --identities "$DOMAIN" \
  --region "$SES_REGION" \
  --query "VerificationAttributes.\"${DOMAIN}\".VerificationStatus" \
  --output text 2>/dev/null || echo "NotStarted")

SES_REGION="us-east-1"

if [ "$SES_STATUS" != "Success" ]; then
  VERIFICATION_TOKEN=$(aws ses verify-domain-identity \
    --domain "$DOMAIN" \
    --region "$SES_REGION" \
    --query "VerificationToken" --output text)

  echo ""
  echo "    DODAJ REKORD TXT W DNS:"
  echo "    Name:  _amazonses.$DOMAIN"
  echo "    Type:  TXT"
  echo "    Value: $VERIFICATION_TOKEN"
  echo ""

  DKIM_TOKENS=$(aws ses verify-domain-dkim \
    --domain "$DOMAIN" \
    --region "$SES_REGION" \
    --query "DkimTokens[]" --output text)

  echo "    DODAJ 3 REKORDY CNAME W DNS (DKIM):"
  for TOKEN in $DKIM_TOKENS; do
    echo "    CNAME: ${TOKEN}._domainkey.$DOMAIN -> ${TOKEN}.dkim.amazonses.com"
  done
  echo ""
else
  echo "    Domena $DOMAIN juz zweryfikowana w SES"
fi
echo ""

# ============================================================
# 7. MAIL FROM (opcjonalne)
# ============================================================
echo ">>> [7/7] MAIL FROM (opcjonalne)"

aws ses set-identity-mail-from-domain \
  --identity "$DOMAIN" \
  --mail-from-domain "mail.$DOMAIN" \
  --region "$SES_REGION" 2>/dev/null || true

echo "    Dodaj w DNS (opcjonalnie):"
echo "    MX:  mail.$DOMAIN -> 10 feedback-smtp.$SES_REGION.amazonses.com"
echo "    TXT: mail.$DOMAIN -> v=spf1 include:amazonses.com ~all"
echo ""

# ============================================================
# CLEANUP & SUMMARY
# ============================================================
rm -rf "$TMP_DIR"

echo "============================================"
echo "  GOTOWE!"
echo "============================================"
echo ""
echo "  S3 Bucket:  $BUCKET_NAME"
echo "  Lambda 1:   $PRESIGN_FUNCTION"
echo "  Lambda 2:   $CONTACT_FUNCTION"
echo "  API URL:    $API_URL"
echo ""
echo "  NASTEPNY KROK:"
echo "  W pliku ContactSection.astro zmien API_URL na:"
echo "  $API_URL"
echo ""
