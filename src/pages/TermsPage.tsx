import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { FileText, ShieldCheck, CheckCircle2 } from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

export const TermsPage: React.FC = () => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Terms and Conditions | i Man Service",
    "description": "Terms and Conditions governing IT-AMC maintenance contracts, network audits, and IT consultancy services provided by i Man Service.",
    "publisher": {
      "@type": "Organization",
      "name": "i Man Service",
      "url": "https://www.imanservice.com/"
    }
  };

  return (
    <>
      <SeoHead
        title="Terms & Conditions | i Man Service"
        description="Terms and Conditions governing IT-AMC contracts, network audit engagements, and IT consultancy services provided by i Man Service."
        canonical="https://www.imanservice.com/terms-and-conditions"
        ogType="website"
        schema={pageSchema}
      />

      <section className="bg-[#034F4B] text-white py-12">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav aria-label="Breadcrumb" className="mb-4">
            <ol className="flex flex-wrap items-center gap-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">Terms & Conditions</li>
            </ol>
          </nav>
          
          <h1 className="text-3xl sm:text-4xl font-extrabold font-display">Terms & Conditions</h1>
          <p className="text-slate-300 text-xs sm:text-sm mt-2">
            Last Updated: August 28, 2026 • Governing Law: Punjab, Pakistan
          </p>
        </div>
      </section>

      <section className="py-12 sm:py-16 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 prose prose-slate max-w-none text-slate-700 text-sm leading-relaxed space-y-8">
          
          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">1. Agreement to Terms</h2>
            <p>
              By accessing the website of <strong>i Man Service</strong> (imanservice.com), engaging our diagnostic audit services, or entering into an Annual Maintenance Contract (IT-AMC) / SLA agreement, you agree to be bound by these Terms and Conditions and our Privacy Policy.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">2. Service Scope and Deliverables</h2>
            <p>
              i Man Service provides services across three primary disciplines:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>Existing Network Audit:</strong> Diagnostic evaluation of switches, routers, firewalls, wireless RF coverage, and asset inventories. Final findings are summarized in an Executive Remediation Roadmap.</li>
              <li><strong>IT-AMC / SLA Contracts:</strong> Fixed-fee annual maintenance covering desktop, server, and network equipment subject to the specific SLA Tier (Bronze, Silver, Gold, or Platinum) selected in the executed contract.</li>
              <li><strong>Strategic IT Consultancy:</strong> Advisory, solution architecture, cloud migration planning, and independent procurement guidance.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">3. Service Level Agreements (SLAs) & Response Metrics</h2>
            <p>
              Response and resolution windows are categorized by severity level (P1 Critical, P2 High, P3 Medium, P4 Low) as specified in the agreed contract. Target response times commence once an incident ticket is acknowledged via phone, email, or ticketing portal.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">4. Client Responsibilities</h2>
            <p>
              To enable effective execution of services, the client agrees to:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Provide reasonable and safe physical access to on-premise server rooms and networking closets in Lahore.</li>
              <li>Provide administrative access or escorted credentials necessary to inspect configurations.</li>
              <li>Maintain legitimate licensing for all third-party proprietary software running on the client’s systems.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">5. Confidentiality & Non-Disclosure (NDA)</h2>
            <p>
              i Man Service treats all network topologies, security credentials, server configurations, and corporate data accessed during an audit or maintenance engagement as strictly confidential. We commit never to disclose confidential client data to third parties.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">6. Payment Terms & Invoicing</h2>
            <p>
              IT-AMC services are billed in advance on a quarterly, bi-annual, or annual basis as agreed in the contract. Network audit engagements are invoiced per milestones (50% commencement, 50% deliverable presentation). Invoices are payable within 15 business days.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">7. Governing Law & Jurisdiction</h2>
            <p>
              These Terms and any contractual disputes arising hereunder shall be governed by and construed in accordance with the laws of the Islamic Republic of Pakistan, subject to the exclusive jurisdiction of the competent courts in Lahore.
            </p>
          </div>

          <div className="pt-6 border-t border-slate-200">
            <h2 className="text-xl font-bold text-slate-900 font-display">8. Contact Information</h2>
            <address className="not-italic bg-slate-50 p-4 rounded-xl border border-slate-200 space-y-1 text-xs text-slate-800">
              <strong className="block text-sm text-slate-900 font-bold">i Man Service — Legal & Contracts</strong>
              <span>P-120, Siddique Trade Center, Gulberg II, Lahore, Pakistan</span><br />
              <span>Email: <a href="mailto:info@imanservice.com" className="text-[#056D67] font-semibold underline">info@imanservice.com</a></span><br />
              <span>Phone: <a href="tel:+923149020008" className="text-[#056D67] font-semibold underline">+92 314 9020008</a></span>
            </address>
          </div>

        </div>
      </section>
    </>
  );
};
