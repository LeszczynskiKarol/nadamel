// presign-upload/index.mjs
// Lambda: nadamel-presign
// Generuje presigned URL do uploadu plików na S3

import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { randomUUID } from "crypto";

const s3 = new S3Client({ region: process.env.AWS_REGION || "eu-north-1" });
const BUCKET = process.env.BUCKET_NAME || "nadamel-attachments";

const MAX_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_EXTENSIONS = [
  ".jpg", ".jpeg", ".png", ".gif", ".webp",
  ".pdf", ".doc", ".docx",
  ".zip", ".rar",
  ".xlsx", ".csv", ".txt",
];

const ALLOWED_ORIGINS = [
  "https://www.nadamel.pl",
  "https://nadamel.pl",
  "http://localhost:4321",
];

function getCorsOrigin(event) {
  const origin = event.headers?.origin || event.headers?.Origin || "";
  return ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
}

export const handler = async (event) => {
  const origin = getCorsOrigin(event);
  const headers = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json",
  };

  if (event.requestContext?.http?.method === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  try {
    const body = JSON.parse(event.body || "{}");
    const { filename, contentType, size } = body;

    if (!filename || !contentType) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Brak nazwy pliku lub typu" }),
      };
    }

    if (size && size > MAX_SIZE) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Plik za duży (maks. 10 MB)" }),
      };
    }

    const ext = "." + filename.split(".").pop().toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: "Niedozwolony format pliku. Dozwolone: " + ALLOWED_EXTENSIONS.join(", "),
        }),
      };
    }

    const date = new Date().toISOString().slice(0, 10);
    const uuid = randomUUID().slice(0, 8);
    const safeFilename = filename.replace(/[^a-zA-Z0-9._-]/g, "_");
    const key = `uploads/${date}/${uuid}-${safeFilename}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 600 });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ uploadUrl, key }),
    };
  } catch (error) {
    console.error("Presign error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Błąd generowania linku" }),
    };
  }
};
