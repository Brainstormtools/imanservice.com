import express, { Request, Response, NextFunction } from 'express';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

// Durable in-memory storage for inquiries
interface InquiryRecord {
  id: string;
  type: 'contact' | 'proposal';
  timestamp: string;
  ip: string;
  data: Record<string, any>;
}

const inquiriesDatabase: InquiryRecord[] = [];

// Rate Limiter
interface RateLimitEntry {
  count: number;
  resetTime: number;
}
const rateLimitMap = new Map<string, RateLimitEntry>();
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const MAX_REQUESTS_PER_WINDOW = 20;

function rateLimiter(req: Request, res: Response, next: NextFunction) {
  const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown-ip';
  const now = Date.now();
  
  const entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW_MS });
    return next();
  }

  if (entry.count >= MAX_REQUESTS_PER_WINDOW) {
    res.setHeader('Retry-After', Math.ceil((entry.resetTime - now) / 1000));
    return res.status(429).json({
      success: false,
      error: 'Too Many Requests',
      message: 'You have exceeded the inquiry submission limit. Please try again in 15 minutes or call us directly at +92 314 9020008.'
    });
  }

  entry.count++;
  next();
}

// Clean up stale rate limits every 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of rateLimitMap.entries()) {
    if (now > entry.resetTime) {
      rateLimitMap.delete(ip);
    }
  }
}, 10 * 60 * 1000);

// Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  next();
});

// Request Body Parsers (Strict 32KB limit)
app.use(express.json({ limit: '32kb' }));
app.use(express.urlencoded({ extended: true, limit: '32kb' }));

// Input sanitization helper
function sanitizeString(val: any, maxLength = 1000): string {
  if (typeof val !== 'string') return '';
  return val
    .trim()
    .slice(0, maxLength)
    .replace(/[<>]/g, ''); // Strip potential HTML tags
}

function isValidEmail(email: string): boolean {
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email);
}

function isValidPhone(phone: string): boolean {
  // Supports Pakistani local (0300...), international (+92...), and general international formats
  const cleanPhone = phone.replace(/[\s\-\(\)\.]/g, '');
  return /^((\+92|0092|92)?(3\d{9})|(\+?[1-9]\d{6,14}))$/.test(cleanPhone);
}

// Asynchronous Webhook Dispatch
async function dispatchWebhook(type: string, data: Record<string, any>) {
  const webhookUrl = process.env.CONSULTATION_WEBHOOK_URL;
  if (!webhookUrl) return;

  try {
    const payload = {
      event: `iman_service_${type}`,
      timestamp: new Date().toISOString(),
      lead: data
    };
    await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    // Non-blocking logging
    console.error('[Webhook Error] Failed to forward lead:', err instanceof Error ? err.message : err);
  }
}

// ----------------------------------------------------
// API ROUTES
// ----------------------------------------------------

// 1. POST /api/contact
app.post('/api/contact', rateLimiter, async (req: Request, res: Response) => {
  try {
    const body = req.body || {};

    // Honeypot spam check
    if (body.honeypot || body._hp_check || body.website_url) {
      // Spam bot detected - return fast false success without saving
      return res.status(200).json({
        success: true,
        message: 'Your inquiry has been received.'
      });
    }

    const fullName = sanitizeString(body.fullName, 100);
    const phone = sanitizeString(body.phone, 30);
    const email = sanitizeString(body.email, 120);
    const category = sanitizeString(body.category, 100) || 'General Inquiry';
    const message = sanitizeString(body.message, 3000);

    // Validation
    const validationErrors: Record<string, string> = {};
    if (!fullName || fullName.length < 2) {
      validationErrors.fullName = 'Please provide your full name (minimum 2 characters).';
    }
    if (!phone || !isValidPhone(phone)) {
      validationErrors.phone = 'Please provide a valid contact number (e.g., +92 314 9020008 or 0314 9020008).';
    }
    if (!email || !isValidEmail(email)) {
      validationErrors.email = 'Please provide a valid corporate email address.';
    }
    if (!message || message.length < 5) {
      validationErrors.message = 'Please provide brief details about your inquiry or infrastructure project.';
    }

    if (Object.keys(validationErrors).length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Validation Failed',
        validationErrors,
        message: 'Please correct the highlighted errors and try again.'
      });
    }

    const record: InquiryRecord = {
      id: `cnt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      type: 'contact',
      timestamp: new Date().toISOString(),
      ip: (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown',
      data: {
        fullName,
        phone,
        email,
        category,
        message
      }
    };

    inquiriesDatabase.push(record);
    console.log(`[New Contact Lead] ID: ${record.id}, Name: ${fullName}, Phone: ${phone}, Category: ${category}`);

    // Fire webhook asynchronously
    dispatchWebhook('contact_inquiry', record.data);

    return res.status(200).json({
      success: true,
      inquiryId: record.id,
      message: 'Thank you! Your inquiry has been securely submitted to our engineering team in Lahore. We will contact you shortly.'
    });
  } catch (error) {
    console.error('[Contact Submission Error]', error);
    return res.status(500).json({
      success: false,
      error: 'Server Error',
      message: 'An unexpected error occurred while processing your request. Please call us directly at +92 314 9020008.'
    });
  }
});

// 2. POST /api/proposal
app.post('/api/proposal', rateLimiter, async (req: Request, res: Response) => {
  try {
    const body = req.body || {};

    // Honeypot check
    if (body.honeypot || body._hp_check || body.website_url) {
      return res.status(200).json({
        success: true,
        message: 'Proposal request received.'
      });
    }

    const fullName = sanitizeString(body.fullName, 100);
    const phone = sanitizeString(body.phone, 30);
    const email = sanitizeString(body.email, 120);
    const company = sanitizeString(body.company, 150) || 'Not Provided';
    const service = sanitizeString(body.service, 100) || 'Comprehensive IT Infrastructure';
    const estimatedScale = sanitizeString(body.estimatedScale, 100) || 'Standard Scope';
    const notes = sanitizeString(body.notes, 3000);

    const validationErrors: Record<string, string> = {};
    if (!fullName || fullName.length < 2) {
      validationErrors.fullName = 'Please provide your full name.';
    }
    if (!phone || !isValidPhone(phone)) {
      validationErrors.phone = 'Please provide a valid contact number (e.g. +92 314 9020008).';
    }
    if (!email || !isValidEmail(email)) {
      validationErrors.email = 'Please provide a valid work email address.';
    }

    if (Object.keys(validationErrors).length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Validation Failed',
        validationErrors,
        message: 'Please provide valid contact information to receive your tailored proposal.'
      });
    }

    const record: InquiryRecord = {
      id: `prop_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      type: 'proposal',
      timestamp: new Date().toISOString(),
      ip: (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown',
      data: {
        fullName,
        phone,
        email,
        company,
        service,
        estimatedScale,
        notes
      }
    };

    inquiriesDatabase.push(record);
    console.log(`[New Proposal Lead] ID: ${record.id}, Name: ${fullName}, Company: ${company}, Service: ${service}`);

    // Fire webhook asynchronously
    dispatchWebhook('proposal_request', record.data);

    return res.status(200).json({
      success: true,
      inquiryId: record.id,
      message: 'Proposal request received! Our senior IT infrastructure architects will prepare your customized SLA and scope breakdown within 1 business day.'
    });
  } catch (error) {
    console.error('[Proposal Submission Error]', error);
    return res.status(500).json({
      success: false,
      error: 'Server Error',
      message: 'Unable to submit proposal request at this moment. Please call +92 314 9020008.'
    });
  }
});

// JSON 404 for unknown API routes
app.all('/api/*', (req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: 'Not Found',
    message: `API endpoint ${req.method} ${req.path} does not exist.`
  });
});

// Explicit routes for robots.txt and sitemap.xml to guarantee proper Content-Type & 200 HTTP response
app.get('/robots.txt', (req: Request, res: Response) => {
  const robotsPath = path.join(process.cwd(), 'public', 'robots.txt');
  if (fs.existsSync(robotsPath)) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.sendFile(robotsPath);
  }
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.send("User-agent: *\nAllow: /\n\nSitemap: https://www.imanservice.com/sitemap.xml\n");
});

app.get('/sitemap.xml', (req: Request, res: Response) => {
  const sitemapPath = path.join(process.cwd(), 'public', 'sitemap.xml');
  if (fs.existsSync(sitemapPath)) {
    res.setHeader('Content-Type', 'application/xml; charset=utf-8');
    return res.sendFile(sitemapPath);
  }
  res.status(404).send('Sitemap not found');
});

// ----------------------------------------------------
// Page Metadata Definition for Edge / SSR Injection
// ----------------------------------------------------
interface PageMeta {
  title: string;
  description: string;
  canonical: string;
  ogTitle: string;
  ogDescription: string;
  ogType: string;
  schemaType: string;
  status?: number;
}

const PAGE_METAS: Record<string, PageMeta> = {
  '/': {
    title: 'i Man Service | IT Infrastructure, Network Audit & AMC Lahore',
    description: 'i Man Service provides network audits, fixed-fee IT-AMC/SLA maintenance and strategic IT consultancy for businesses in Lahore, Pakistan.',
    canonical: 'https://www.imanservice.com/',
    ogTitle: 'i Man Service | IT Infrastructure, Network Audit & AMC Lahore',
    ogDescription: 'i Man Service provides network audits, fixed-fee IT-AMC/SLA maintenance and strategic IT consultancy for businesses in Lahore, Pakistan.',
    ogType: 'website',
    schemaType: 'LocalBusiness'
  },
  '/network-audit': {
    title: 'Network Audit Services Lahore | i Man Service',
    description: 'Comprehensive network audit, Wi-Fi heatmapping, firewall security analysis and infrastructure health assessment in Lahore, Pakistan.',
    canonical: 'https://www.imanservice.com/network-audit',
    ogTitle: 'Network Audit Services Lahore | i Man Service',
    ogDescription: 'Comprehensive network audit, Wi-Fi heatmapping, firewall security analysis and infrastructure health assessment in Lahore, Pakistan.',
    ogType: 'article',
    schemaType: 'Service'
  },
  '/it-amc-sla': {
    title: 'IT AMC & SLA Support Services Lahore | i Man Service',
    description: 'Fixed-fee IT Annual Maintenance Contracts (IT-AMC) with structured SLA tiers, rapid on-site dispatch, and proactive 24/7 server monitoring in Lahore.',
    canonical: 'https://www.imanservice.com/it-amc-sla',
    ogTitle: 'IT AMC & SLA Support Services Lahore | i Man Service',
    ogDescription: 'Fixed-fee IT Annual Maintenance Contracts (IT-AMC) with structured SLA tiers, rapid on-site dispatch, and proactive 24/7 server monitoring in Lahore.',
    ogType: 'article',
    schemaType: 'Service'
  },
  '/it-consultancy': {
    title: 'IT Consultancy Services Lahore | i Man Service',
    description: 'Strategic IT consultancy, cloud migration architecture, zero-trust security roadmaps, and vendor-neutral technology procurement in Lahore.',
    canonical: 'https://www.imanservice.com/it-consultancy',
    ogTitle: 'IT Consultancy Services Lahore | i Man Service',
    ogDescription: 'Strategic IT consultancy, cloud migration architecture, zero-trust security roadmaps, and vendor-neutral technology procurement in Lahore.',
    ogType: 'article',
    schemaType: 'Service'
  },
  '/about': {
    title: 'About i Man Service | Lahore IT Infrastructure Partner',
    description: 'Learn about i Man Service, Lahore’s dedicated IT infrastructure partner providing single-point accountability for networks, hardware, and SLAs.',
    canonical: 'https://www.imanservice.com/about',
    ogTitle: 'About i Man Service | Lahore IT Infrastructure Partner',
    ogDescription: 'Learn about i Man Service, Lahore’s dedicated IT infrastructure partner providing single-point accountability for networks, hardware, and SLAs.',
    ogType: 'website',
    schemaType: 'AboutPage'
  },
  '/contact': {
    title: 'Contact i Man Service | IT Support Lahore',
    description: 'Contact i Man Service at Siddique Trade Center, Gulberg II, Lahore. Call +92 314 9020008 or request an IT infrastructure proposal.',
    canonical: 'https://www.imanservice.com/contact',
    ogTitle: 'Contact i Man Service | IT Support Lahore',
    ogDescription: 'Contact i Man Service at Siddique Trade Center, Gulberg II, Lahore. Call +92 314 9020008 or request an IT infrastructure proposal.',
    ogType: 'website',
    schemaType: 'ContactPage'
  },
  '/privacy-policy': {
    title: 'Privacy Policy | i Man Service',
    description: 'Privacy Policy for i Man Service. We safeguard your corporate details, infrastructure specs, and contact information with zero third-party sharing.',
    canonical: 'https://www.imanservice.com/privacy-policy',
    ogTitle: 'Privacy Policy | i Man Service',
    ogDescription: 'Privacy Policy for i Man Service. We safeguard your corporate details, infrastructure specs, and contact information with zero third-party sharing.',
    ogType: 'website',
    schemaType: 'WebPage'
  },
  '/terms-and-conditions': {
    title: 'Terms & Conditions | i Man Service',
    description: 'Terms and Conditions governing IT-AMC contracts, network audit engagements, and IT consultancy services provided by i Man Service.',
    canonical: 'https://www.imanservice.com/terms-and-conditions',
    ogTitle: 'Terms & Conditions | i Man Service',
    ogDescription: 'Terms and Conditions governing IT-AMC contracts, network audit engagements, and IT consultancy services provided by i Man Service.',
    ogType: 'website',
    schemaType: 'WebPage'
  }
};

function injectMetadata(html: string, pathname: string): { html: string; status: number } {
  const cleanPath = pathname.replace(/\/$/, '') || '/';
  const meta = PAGE_METAS[cleanPath];

  if (!meta) {
    // 404 Not Found Page
    const notFoundTitle = 'Page Not Found (404) | i Man Service';
    const notFoundDesc = 'The page you requested could not be found. Return to i Man Service homepage for Lahore IT Infrastructure, Network Audit, and IT-AMC services.';
    let modifiedHtml = html
      .replace(/<title>.*?<\/title>/i, `<title>${notFoundTitle}</title>`)
      .replace(/<meta name="description" content=".*?" \/>/i, `<meta name="description" content="${notFoundDesc}" />\n    <meta name="robots" content="noindex, follow" />`)
      .replace(/<link rel="canonical" href=".*?" \/>/i, '');
    return { html: modifiedHtml, status: 404 };
  }

  let modifiedHtml = html
    .replace(/<title>.*?<\/title>/i, `<title>${meta.title}</title>`)
    .replace(/<meta name="description" content=".*?" \/>/i, `<meta name="description" content="${meta.description}" />`)
    .replace(/<link rel="canonical" href=".*?" \/>/i, `<link rel="canonical" href="${meta.canonical}" />`)
    .replace(/<meta property="og:title" content=".*?" \/>/i, `<meta property="og:title" content="${meta.ogTitle}" />`)
    .replace(/<meta property="og:description" content=".*?" \/>/i, `<meta property="og:description" content="${meta.ogDescription}" />`)
    .replace(/<meta property="og:url" content=".*?" \/>/i, `<meta property="og:url" content="${meta.canonical}" />`)
    .replace(/<meta name="twitter:title" content=".*?" \/>/i, `<meta name="twitter:title" content="${meta.ogTitle}" />`)
    .replace(/<meta name="twitter:description" content=".*?" \/>/i, `<meta name="twitter:description" content="${meta.ogDescription}" />`)
    .replace(/<meta name="twitter:url" content=".*?" \/>/i, `<meta name="twitter:url" content="${meta.canonical}" />`);

  return { html: modifiedHtml, status: 200 };
}

// ----------------------------------------------------
// VITE & STATIC SERVING INTEGRATION
// ----------------------------------------------------

async function startServer() {
  const isProduction = process.env.NODE_ENV === 'production';

  if (!isProduction) {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'custom'
    });

    app.use(vite.middlewares);

    app.use('*', async (req: Request, res: Response, next: NextFunction) => {
      const url = req.originalUrl;
      try {
        const rawTemplate = fs.readFileSync(path.resolve(process.cwd(), 'index.html'), 'utf-8');
        const transformedHtml = await vite.transformIndexHtml(url, rawTemplate);
        const { html, status } = injectMetadata(transformedHtml, req.path);
        res.status(status).set({ 'Content-Type': 'text/html; charset=utf-8' }).send(html);
      } catch (e) {
        vite.ssrFixStacktrace(e as Error);
        next(e);
      }
    });
  } else {
    const distPath = path.resolve(process.cwd(), 'dist');
    const indexHtmlPath = path.join(distPath, 'index.html');
    
    // Serve static assets with long cache
    app.use(express.static(distPath, {
      maxAge: '1y',
      immutable: true,
      index: false
    }));

    app.get('*', (req: Request, res: Response) => {
      if (fs.existsSync(indexHtmlPath)) {
        const rawTemplate = fs.readFileSync(indexHtmlPath, 'utf-8');
        const { html, status } = injectMetadata(rawTemplate, req.path);
        res.status(status).set({ 'Content-Type': 'text/html; charset=utf-8' }).send(html);
      } else {
        res.status(500).send('Production build not found. Please run npm run build.');
      }
    });
  }

  // Error Handler Middleware
  app.use((err: any, req: Request, res: Response, next: NextFunction) => {
    if (err.type === 'entity.too.large' || err.status === 413) {
      return res.status(413).json({
        success: false,
        error: 'Payload Too Large',
        message: 'The submitted request body exceeds the maximum permitted size (32KB).'
      });
    }
    console.error('[Unhandled Server Error]', err);
    res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'A technical error occurred. Please contact support.'
    });
  });

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[i Man Service] Enterprise Server listening on http://0.0.0.0:${PORT}`);
  });
}

startServer();
