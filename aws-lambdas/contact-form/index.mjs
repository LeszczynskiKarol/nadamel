// contact-form/index.mjs
// Lambda: nadamel-contact
// Przetwarza formularz kontaktowy i wysyła email przez SES

import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";
import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const REGION = process.env.AWS_REGION || "eu-north-1";
const SES_REGION = "us-east-1";
const ses = new SESClient({ region: SES_REGION });
const s3 = new S3Client({ region: REGION });

const BUCKET = process.env.BUCKET_NAME || "nadamel-attachments";
const TO_EMAIL = "biuro@nadamel.pl";
const FROM_EMAIL = "formularz@nadamel.pl";
const FROM_NAME = "nadamel.pl";

const ALLOWED_ORIGINS = [
  "https://www.nadamel.pl",
  "https://nadamel.pl",
  "http://localhost:4321",
];

function getCorsOrigin(event) {
  const origin = event.headers?.origin || event.headers?.Origin || "";
  return ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
}

function escapeHtml(str) {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + " B";
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
  return (bytes / (1024 * 1024)).toFixed(1) + " MB";
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
    const { name, email, phone, message, attachments } = body;

    // Walidacja
    if (!name || !email || !message) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Brak wymaganych pól (name, email, message)" }),
      };
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Nieprawidłowy adres email" }),
      };
    }

    // Generuj linki do pobrania załączników (ważne 7 dni)
    let attachmentsHtml = "";
    if (attachments && attachments.length > 0) {
      const attachmentLinks = [];
      for (const att of attachments) {
        try {
          const command = new GetObjectCommand({
            Bucket: BUCKET,
            Key: att.key,
          });
          const downloadUrl = await getSignedUrl(s3, command, {
            expiresIn: 7 * 24 * 60 * 60,
          });
          attachmentLinks.push(
            `<div style="margin-bottom:8px;padding:10px 14px;background:#f9fafb;border-radius:8px;border:1px solid #e5e7eb">
              <a href="${downloadUrl}" style="color:#0284c7;text-decoration:none;font-weight:600" target="_blank">
                📎 ${escapeHtml(att.name)}
              </a>
              <span style="color:#9ca3af;font-size:12px;margin-left:8px">(${formatSize(att.size || 0)})</span>
            </div>`
          );
        } catch (err) {
          console.error("Error generating download URL for:", att.key, err);
          attachmentLinks.push(
            `<div style="margin-bottom:8px;padding:10px 14px;background:#fef2f2;border-radius:8px;border:1px solid #fecaca">
              📎 ${escapeHtml(att.name)} — <em style="color:#999">błąd generowania linku</em>
            </div>`
          );
        }
      }
      attachmentsHtml = `
        <tr>
          <td style="padding:12px 16px;font-weight:600;color:#374151;vertical-align:top;width:140px;border-bottom:1px solid #e5e7eb">Załączniki:</td>
          <td style="padding:12px 16px;border-bottom:1px solid #e5e7eb">
            ${attachmentLinks.join("")}
            <p style="font-size:11px;color:#9ca3af;margin-top:8px">Linki do pobrania ważne 7 dni</p>
          </td>
        </tr>`;
    }

    // Email HTML
    const htmlBody = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f3f4f6">
  <div style="max-width:600px;margin:0 auto;padding:32px 16px">
    
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#92400e,#b45309);padding:24px 32px;border-radius:12px 12px 0 0">
      <h1 style="margin:0;color:#ffffff;font-size:20px;font-weight:700">🪵 Nowe zapytanie — nadamel.pl</h1>
      <p style="margin:8px 0 0;color:rgba(255,255,255,0.8);font-size:13px">${new Date().toLocaleDateString("pl-PL", { year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit" })}</p>
    </div>

    <!-- Data table -->
    <table style="width:100%;border-collapse:collapse;background:#ffffff;border:1px solid #e5e7eb;border-top:none">
      <tr>
        <td style="padding:12px 16px;font-weight:600;color:#374151;width:140px;border-bottom:1px solid #e5e7eb">Nadawca:</td>
        <td style="padding:12px 16px;color:#111827;border-bottom:1px solid #e5e7eb">${escapeHtml(name)}</td>
      </tr>
      <tr>
        <td style="padding:12px 16px;font-weight:600;color:#374151;border-bottom:1px solid #e5e7eb">Email:</td>
        <td style="padding:12px 16px;border-bottom:1px solid #e5e7eb">
          <a href="mailto:${escapeHtml(email)}" style="color:#0284c7;text-decoration:underline">${escapeHtml(email)}</a>
        </td>
      </tr>
      ${phone ? `<tr>
        <td style="padding:12px 16px;font-weight:600;color:#374151;border-bottom:1px solid #e5e7eb">Telefon:</td>
        <td style="padding:12px 16px;color:#111827;border-bottom:1px solid #e5e7eb">${escapeHtml(phone)}</td>
      </tr>` : ""}
      <tr>
        <td style="padding:12px 16px;font-weight:600;color:#374151;vertical-align:top;border-bottom:1px solid #e5e7eb">Wiadomość:</td>
        <td style="padding:12px 16px;color:#111827;line-height:1.6;border-bottom:1px solid #e5e7eb">${escapeHtml(message).replace(/\n/g, "<br>")}</td>
      </tr>
      ${attachmentsHtml}
    </table>

    <!-- Reply button -->
    <div style="text-align:center;padding:24px 0">
      <a href="mailto:${escapeHtml(email)}?subject=Re: Zapytanie — nadamel.pl" 
         style="display:inline-block;padding:12px 32px;background:#92400e;color:#ffffff;text-decoration:none;font-weight:600;border-radius:8px;font-size:14px">
        Odpowiedz na zapytanie →
      </a>
    </div>

    <!-- Footer -->
    <div style="text-align:center;padding-top:12px">
      <p style="font-size:11px;color:#9ca3af">
        Wiadomość z formularza kontaktowego · nadamel.pl
      </p>
    </div>
  </div>
</body>
</html>`;

    const command = new SendEmailCommand({
      Source: `${FROM_NAME} <${FROM_EMAIL}>`,
      Destination: { ToAddresses: [TO_EMAIL] },
      ReplyToAddresses: [email],
      Message: {
        Subject: {
          Data: `Nowe zapytanie: ${name}`,
          Charset: "UTF-8",
        },
        Body: {
          Html: { Data: htmlBody, Charset: "UTF-8" },
        },
      },
    });

    await ses.send(command);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ success: true }),
    };
  } catch (error) {
    console.error("Contact form error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Błąd wysyłania wiadomości" }),
    };
  }
};
