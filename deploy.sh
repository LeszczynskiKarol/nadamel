#!/bin/bash
S3_BUCKET="www.nadamel.pl"
CLOUDFRONT_ID="E2X8P8CF0SYYFQ"
cd /d/nadamel
npm run build
aws s3 sync dist/ s3://${S3_BUCKET} --delete
aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_ID} --paths "/*"
echo "✅ Deployed to https://www.nadamel.pl"