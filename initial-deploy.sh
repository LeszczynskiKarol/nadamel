#!/bin/bash
cd /d/nadamel
npm run build
aws s3 sync dist/ s3://www.nadamel.pl --delete
echo "✅ Pliki wgrane do bucketu"