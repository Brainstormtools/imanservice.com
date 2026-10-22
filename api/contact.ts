import {readIntakeBody, recordWebsiteLead, IntakeError} from '../server/website-lead-intake.js';
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
    const body = await readIntakeBody(req);

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

    if (category.length > 100) errors.category = 'Please shorten the category.';

    if (Object.keys(errors).length > 0) {
      return res.status(422).json({
        success: false,
        error: 'Validation Failed',
        message: 'Please resolve the highlighted validation errors.',
        errors
      });
    }

    await recordWebsiteLead('contact', body, {name:fullName,email,phone,company:'',message:['Contact: '+fullName,'Phone: '+phone,'Category: '+category,'',message].join('\n')}, req);
    const webhookUrl = process.env.CONSULTATION_WEBHOOK_URL;

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

    if (webhookUrl?.trim()) {
      const webhookResponse = await fetch(webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Idempotency-Key': body.requestId,
          'User-Agent': 'iManService-Vercel-Serverless/1.0'
        },
        signal: AbortSignal.timeout(10000),
        body: JSON.stringify({...webhookPayload, requestId:body.requestId})
      }).catch(() => { throw new IntakeError(502,'Your enquiry is recorded, but consultation delivery is unconfirmed. Retry the same submission.'); });

      if (!webhookResponse.ok) {

        return res.status(502).json({
          success: false,
          error: 'Bad Gateway',
          message: 'Your enquiry is recorded, but consultation delivery is unconfirmed. Retry the same submission or call +92 314 9020008.'
        });
      }
    }

    // CRM persistence is confirmed; optional webhook delivery has also succeeded.
    return res.status(200).json({
      success: true,
      message: 'Your inquiry has been recorded. We will contact you shortly.',
      receivedAt: new Date().toISOString()
    });

  } catch (err: any) {
    if (err instanceof IntakeError) return res.status(err.status).json({success:false,message:err.message});
    return res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your request. Please call our dispatch desk at +92 314 9020008.'
    });
  }
}
