import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { ShieldCheck, Lock, CheckCircle2, ArrowRight } from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

export const PrivacyPolicyPage: React.FC = () => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Privacy Policy | i Man Service",
    "description": "Privacy Policy for i Man Service Lahore. Explaining data collection, storage, and zero third-party disclosure for IT proposals and inquiries.",
    "publisher": {
      "@type": "Organization",
      "name": "i Man Service",
      "url": "https://www.imanservice.com/"
    }
  };

  return (
    <>
      <SeoHead
        title="Privacy Policy | i Man Service"
        description="Privacy Policy for i Man Service. We safeguard your corporate details, infrastructure specs, and contact information with zero third-party sharing."
        canonical="https://www.imanservice.com/privacy-policy"
        ogType="website"
        schema={pageSchema}
      />

      <section className="bg-[#034F4B] text-white py-12">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav aria-label="Breadcrumb" className="mb-4">
            <ol className="flex items-center space-x-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">Privacy Policy</li>
            </ol>
          </nav>
          
          <h1 className="text-3xl sm:text-4xl font-extrabold font-display">Privacy Policy</h1>
          <p className="text-slate-300 text-xs sm:text-sm mt-2">
            Last Updated: August 28, 2026 • Effective Date: January 1, 2024
          </p>
        </div>
      </section>

      <section className="py-12 sm:py-16 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 prose prose-slate max-w-none text-slate-700 text-sm leading-relaxed space-y-8">
          
          <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-xs flex items-start gap-3">
            <ShieldCheck className="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" />
            <div>
              <strong className="block font-bold">Privacy Reassurance</strong>
              Your details will only be used to respond to your inquiry and prepare customized IT proposals. We never sell, rent, or share your data with third parties.
            </div>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">1. Information We Collect</h2>
            <p>
              When you interact with <strong>i Man Service</strong> (via our contact forms, SLA scope calculator, proposal request forms, or direct email/telephone inquiries), we may collect the following personal and corporate information:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>Contact Identification:</strong> Full name, official email address, corporate telephone or mobile number.</li>
              <li><strong>Company Details:</strong> Organization name, office address, industry sector.</li>
              <li><strong>Infrastructure Specifications:</strong> Estimated workstation count, server fleet size, network topology notes, and SLA requirements submitted during proposal configuration.</li>
              <li><strong>Technical Metadata:</strong> Anonymized server logs including IP address, browser type, and submission timestamps to safeguard our API endpoints against abuse.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">2. How We Use Your Information</h2>
            <p>
              We collect information strictly for legitimate commercial and engineering purposes, including:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Responding promptly to your infrastructure audit or SLA inquiries.</li>
              <li>Formulating accurate, customized IT-AMC proposals and technical feasibility estimates.</li>
              <li>Executing contracted on-site audits, scheduled maintenance visits, and emergency SLA dispatches across Lahore.</li>
              <li>Fulfilling legal obligations and maintaining contractual SLA documentation.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">3. Zero Third-Party Sharing</h2>
            <p>
              <strong>i Man Service does not sell, lease, trade, or distribute your corporate or personal data to any external marketing agencies, advertising platforms, or unauthorized third parties.</strong>
            </p>
            <p>
              Data is accessible solely to authorized senior infrastructure engineers and account managers bound by strict confidentiality agreements.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">4. Data Security and Retention</h2>
            <p>
              We implement enterprise-grade technical and organizational safeguards, including SSL/TLS encryption for all data in transit, strict access control, and server-side validation. Your data is retained only for the duration required to service your account or maintain audit compliance.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900 font-display">5. Your Data Rights</h2>
            <p>
              Under applicable Pakistani privacy regulations and international data standards, you retain the right to:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Request a copy of the personal or corporate information we hold about you.</li>
              <li>Request correction or rectification of any inaccurate information.</li>
              <li>Request complete deletion or erasure of your inquiry data from our systems.</li>
            </ul>
          </div>

          <div className="pt-6 border-t border-slate-200">
            <h2 className="text-xl font-bold text-slate-900 font-display">6. Contact Our Data Privacy Desk</h2>
            <p>
              For any questions regarding this Privacy Policy or data protection practices, please contact:
            </p>
            <address className="not-italic bg-slate-50 p-4 rounded-xl border border-slate-200 space-y-1 text-xs text-slate-800">
              <strong className="block text-sm text-slate-900 font-bold">i Man Service — Data Privacy Officer</strong>
              <span>P-120, Siddique Trade Center, Gulberg II, Lahore, Pakistan</span><br />
              <span>Email: <a href="mailto:info@imanservice.com" className="text-[#056D67] font-semibold underline">info@imanservice.com</a></span><br />
              <span>Direct Phone: <a href="tel:+923149020008" className="text-[#056D67] font-semibold underline">+92 314 9020008</a></span>
            </address>
          </div>

        </div>
      </section>
    </>
  );
};
