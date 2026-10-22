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
    const body = await readIntakeBody(req);

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

    if (notes.length > 3000 || serviceDomain.length > 100 || timeline.length > 100 || !Number.isSafeInteger(workstations) || !Number.isSafeInteger(servers)) errors.notes = 'Please shorten the proposal details and use valid equipment counts.';

    if (Object.keys(errors).length > 0) {
      return res.status(422).json({
        success: false,
        error: 'Validation Failed',
        message: 'Please complete all required fields.',
        errors
      });
    }

    await recordWebsiteLead('proposal', body, {name:contactPerson,email,phone,company:companyName,message:['Company: '+companyName,'Contact: '+contactPerson,'Phone: '+phone,'Service: '+serviceDomain,'Workstations: '+workstations,'Servers: '+servers,'Timeline: '+timeline,'',notes].join('\n')}, req);
    const webhookUrl = process.env.CONSULTATION_WEBHOOK_URL;

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
      message: 'Your formal IT proposal request has been recorded.',
      receivedAt: new Date().toISOString()
    });

  } catch (err: any) {
    if (err instanceof IntakeError) return res.status(err.status).json({success:false,message:err.message});
    return res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your proposal request. Please contact +92 314 9020008 directly.'
    });
  }
}
