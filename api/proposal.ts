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
    .replace(/[<>]/g, '')
    .trim();
}

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
    // 2. Parse request body if needed
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

    // 3. Honeypot anti-spam check
    if (body.honeypot && String(body.honeypot).trim().length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Spam Detected',
        message: 'Spam bot submission blocked.'
      });
    }

    // 4. Extract and sanitize fields
    const serviceDomain = sanitize(body.serviceDomain || 'all');
    const companyName = sanitize(body.companyName);
    const contactPerson = sanitize(body.contactPerson);
    const email = sanitize(body.email);
    const phone = sanitize(body.phone);
    const workstations = Math.max(0, parseInt(String(body.workstations || 0), 10) || 0);
    const servers = Math.max(0, parseInt(String(body.servers || 0), 10) || 0);
    const timeline = sanitize(body.timeline || 'planned');
    const notes = sanitize(body.notes);

    // 5. Validation checks
    const errors: Record<string, string> = {};

    if (!companyName || companyName.length < 2 || companyName.length > 100) {
      errors.companyName = 'Company / Organization Name is required (2–100 characters).';
    }

    if (!contactPerson || contactPerson.length < 2 || contactPerson.length > 100) {
      errors.contactPerson = 'Contact person name is required (2–100 characters).';
    }

    if (!email || !isValidEmail(email)) {
      errors.email = 'A valid business email address is required.';
    }

    if (!phone || phone.length < 7 || phone.length > 25) {
      errors.phone = 'A valid contact phone or mobile number is required.';
    }

    if (Object.keys(errors).length > 0) {
      return res.status(422).json({
        success: false,
        error: 'Validation Failed',
        message: 'Please complete all required fields.',
        errors
      });
    }

    // 6. Check consultation webhook configuration
    const webhookUrl = process.env.CONSULTATION_WEBHOOK_URL;
    if (!webhookUrl || !webhookUrl.trim()) {
      return res.status(503).json({
        success: false,
        error: 'Service Unavailable',
        message: 'The proposal webhook service is not configured on this server. Please call our hotline directly at +92 314 9020008.'
      });
    }

    // 7. Client metadata
    const forwarded = req.headers['x-forwarded-for'];
    const ip = typeof forwarded === 'string' ? forwarded.split(',')[0].trim() : (req.socket?.remoteAddress || 'unknown');
    const userAgent = typeof req.headers['user-agent'] === 'string' ? req.headers['user-agent'] : 'unknown';

    // 8. Forward payload to CONSULTATION_WEBHOOK_URL
    const webhookPayload = {
      formType: 'proposal',
      source: 'i Man Service Official Portal - Executive Proposal Modal',
      submittedAt: new Date().toISOString(),
      proposalRequest: {
        serviceDomain,
        companyName,
        contactPerson,
        email,
        phone,
        workstations,
        servers,
        timeline,
        notes
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
      console.error(`Proposal webhook failed with status ${webhookResponse.status}:`, errorText);
      return res.status(502).json({
        success: false,
        error: 'Bad Gateway',
        message: `Delivery to proposal backend failed (HTTP ${webhookResponse.status}). Please call our dispatch desk at +92 314 9020008.`
      });
    }

    // 9. Confirmed delivery success
    return res.status(200).json({
      success: true,
      message: 'Your formal IT proposal request has been confirmed and delivered to our engineering leadership.',
      receivedAt: new Date().toISOString()
    });

  } catch (err: any) {
    console.error('Unhandled error in /api/proposal handler:', err);
    return res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your proposal request. Please contact +92 314 9020008 directly.'
    });
  }
}
