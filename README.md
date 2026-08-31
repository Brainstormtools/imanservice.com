# i Man Service — Enterprise IT Infrastructure & AMC Portal

Official web portal and IT service platform for **i Man Service**, specializing in Network Audits, fixed-fee IT-AMC/SLA maintenance, and strategic IT consultancy for corporate and industrial enterprises across Lahore, Pakistan.

---

## 🚀 Technology Stack

- **Framework**: React 19 + TypeScript + Vite 6
- **Styling**: Tailwind CSS v4 + Lucide React Icons + Motion
- **Architecture**: Single Page Application with client-side routing & Vercel Serverless Functions (`/api/*`)
- **Interactive Features**: 
  - On-Site Network Audit Scoping Engine & Calculator
  - SLA Tier Customizer & Response-Time Matrix
  - Interactive IT Health Quiz & Downloadable Network Readiness Checklist
  - Honeypot-protected Lead & Proposal Request Dispatchers

---

## 🛠️ Local Development

1. **Install dependencies**:
   ```bash
   bun install
   # or
   npm install
   ```

2. **Configure Environment Variables** (Optional for local testing):
   Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
   Provide your consultation webhook URL if you wish to forward submitted leads to your CRM, Slack, or Zapier endpoint.

3. **Start the local development server**:
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000) to preview the portal.

4. **Verify TypeScript & Linting**:
   ```bash
   npm run lint
   ```

5. **Build for Production**:
   ```bash
   npm run build
   ```

---

## 🚢 Deploying from GitHub to Vercel

Follow these simple steps to deploy the repository directly to Vercel:

### Step 1: Push to GitHub
Ensure your repository is pushed to your GitHub account:
```bash
git add .
git commit -m "feat: complete i Man Service portal"
git push origin main
```

### Step 2: Import Project into Vercel
1. Log in to [vercel.com](https://vercel.com) and click **"Add New..."** > **"Project"**.
2. Select and import your GitHub repository (`iman-service-portal` or your repository name).
3. Vercel automatically detects the **Vite** framework preset:
   - **Framework Preset**: `Vite`
   - **Build Command**: `npm run build` or `vite build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install` or `bun install`

### Step 3: Configure Environment Variables in Vercel
Before clicking **Deploy**, navigate to the **Environment Variables** section in the Vercel project configuration:

1. Add the following key:
   - **Key**: `CONSULTATION_WEBHOOK_URL`
   - **Value**: Your secure destination webhook URL (e.g., Slack incoming webhook, Discord, Make.com, Zapier, or corporate CRM API endpoint).
   - **Target Environments**: Check `Production`, `Preview`, and `Development`.

> **How `CONSULTATION_WEBHOOK_URL` works**:  
> When a client submits an inquiry via the Contact form (`/api/contact`) or requests a formal IT infrastructure proposal (`/api/proposal`), the serverless function validates and sanitizes all inputs, blocks bot submissions via honeypot filtering, and forwards the structured lead payload (including client IP, timestamp, and asset specifications) to `CONSULTATION_WEBHOOK_URL`. The UI displays a confirmed delivery timestamp once the webhook returns HTTP 200.

### Step 4: Deploy & Verify
1. Click **Deploy**.
2. Once the build finishes, your site will be live on your Vercel URL (e.g., `https://iman-service.vercel.app`).
3. Under **Project Settings** > **Domains**, you can attach your custom domain (`www.imanservice.com`).

---

## 📄 License & Attribution
© 2026 i Man Service. All rights reserved.  
P-120, Siddique Trade Center, Gulberg II, Lahore, Punjab, Pakistan.
