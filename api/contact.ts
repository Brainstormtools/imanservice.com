import type { IncomingMessage, ServerResponse } from 'http';

interface VercelRequest extends IncomingMessage {
  body?: any;
  query?: Record<string, string | string[]>;
  headers: Record<string, string | string[] | undefined>;
}

interface VercelResponse extends ServerResponse {
  status: (statusCode: number) => VercelResponse;
  json: (data: any) => VercelResponse;
  send: (data: any) => VercelResponse;
}

// Sanitization helper
function sanitize(input: any): string {
  if (typeof input !== 'string') return '';
  return input
    .replace(/[<>]/g, '') // Strip basic HTML tags
    .trim();
}

// Simple email format validator
function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 1. Enforce POST only
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({
      success: false,
      error: 'Method Not Allowed',
      message: 'This endpoint only accepts POST requests.'
    });
  }

  try {
    // 2. Parse request body if not already parsed
    let body = req.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch {
        return res.status(400).json({
          success: false,
          error: 'Bad Request',
          message: 'Invalid JSON payload.'
        });
      }
    } else if (!body && typeof req.on === 'function') {
      // In case body wasn't pre-parsed by the runner
      const buffers: Buffer[] = [];
      for await (const chunk of req) {
        buffers.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
      }
      const raw = Buffer.concat(buffers).toString('utf8');
      if (raw) {
        try {
          body = JSON.parse(raw);
        } catch {
          return res.status(400).json({
            success: false,
            error: 'Bad Request',
            message: 'Invalid JSON payload format.'
          });
        }
      }
    }

    body = body || {};

    // 3. Honeypot anti-spam verification
    if (body.honeypot && String(body.honeypot).trim().length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Spam Detected',
        message: 'Spam bot submission blocked.'
      });
    }

    // 4. Extract and sanitize fields
    const fullName = sanitize(body.fullName || body.name);
    const email = sanitize(body.email);
    const phone = sanitize(body.phone);
    const category = sanitize(body.category || body.subject || 'Existing Network Audit');
    const message = sanitize(body.message);

    // 5. Validation checks
    const errors: Record<string, string> = {};

    if (!fullName || fullName.length < 2 || fullName.length > 100) {
      errors.fullName = 'Full Name is required and must be between 2 and 100 characters.';
    }

    if (!email || !isValidEmail(email)) {
      errors.email = 'A valid corporate or personal email address is required.';
    }

    if (!phone || phone.length < 7 || phone.length > 25) {
      errors.phone = 'A valid phone or mobile number (at least 7 digits) is required.';
    }

    if (!message || message.length < 5 || message.length > 3000) {
      errors.message = 'Please provide details about your inquiry (between 5 and 3000 characters).';
    }

    if (Object.keys(errors).length > 0) {
      return res.status(422).json({
        success: false,
        error: 'Validation Failed',
        message: 'Please resolve the highlighted validation errors.',
        errors
      });
    }

    // 6. Check consultation webhook configuration
    const webhookUrl = process.env.CONSULTATION_WEBHOOK_URL;
    if (!webhookUrl || !webhookUrl.trim()) {
      return res.status(503).json({
        success: false,
        error: 'Service Unavailable',
        message: 'The consultation webhook endpoint is not configured on this server. Please call our hotline directly at +92 314 9020008 or reach out via WhatsApp.'
      });
    }

    // 7. Client metadata
    const forwarded = req.headers['x-forwarded-for'];
    const ip = typeof forwarded === 'string' ? forwarded.split(',')[0].trim() : (req.socket?.remoteAddress || 'unknown');
    const userAgent = typeof req.headers['user-agent'] === 'string' ? req.headers['user-agent'] : 'unknown';

    // 8. Forward payload to CONSULTATION_WEBHOOK_URL
    const webhookPayload = {
      formType: 'contact',
      source: 'i Man Service Official Portal',
      submittedAt: new Date().toISOString(),
      lead: {
        fullName,
        email,
        phone,
        category,
        message
      },
      meta: {
        ip,
        userAgent
      }
    };

    const webhookResponse = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'iManService-Vercel-Serverless/1.0'
      },
      body: JSON.stringify(webhookPayload)
    });

    if (!webhookResponse.ok) {
      const errorText = await webhookResponse.text().catch(() => '');
      console.error(`Webhook delivery failed with status ${webhookResponse.status}:`, errorText);
      return res.status(502).json({
        success: false,
        error: 'Bad Gateway',
        message: `Delivery to consultation backend failed (HTTP ${webhookResponse.status}). Please contact us directly at +92 314 9020008.`
      });
    }

    // 9. Confirmed delivery success
    return res.status(200).json({
      success: true,
      message: 'Your inquiry has been successfully delivered to our Lahore infrastructure lead. We will contact you shortly.',
      receivedAt: new Date().toISOString()
    });

  } catch (err: any) {
    console.error('Unhandled error in /api/contact handler:', err);
    return res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your request. Please call our dispatch desk at +92 314 9020008.'
    });
  }
}
