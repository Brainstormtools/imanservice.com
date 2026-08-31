import React, { useState } from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { 
  FileSearch, 
  ShieldCheck, 
  Activity, 
  Wifi, 
  Server, 
  Lock, 
  CheckCircle2, 
  ArrowRight, 
  ChevronDown, 
  ChevronUp, 
  Layers, 
  FileText, 
  HelpCircle,
  Clock,
  Sparkles
} from 'lucide-react';
import { ASSESSMENT_AREAS, AUDIT_METHODOLOGY, AUDIT_WHY_POINTS } from '../data/companyData';

interface NetworkAuditPageProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
  onOpenQuiz: () => void;
  onOpenChecklist: () => void;
}

export const NetworkAuditPage: React.FC<NetworkAuditPageProps> = ({
  onOpenQuote,
  onOpenQuiz,
  onOpenChecklist
}) => {
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "Service",
    "name": "Network Audit Services Lahore",
    "provider": {
      "@type": "LocalBusiness",
      "name": "i Man Service",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "P-120, Siddique Trade Center, Gulberg II",
        "addressLocality": "Lahore",
        "addressRegion": "Punjab",
        "postalCode": "54660",
        "addressCountry": "PK"
      }
    },
    "description": "Comprehensive IT infrastructure and enterprise network audit covering hardware assets, VLANs, Wi-Fi heatmapping, firewall security, and performance bottleneck diagnostics.",
    "serviceType": "IT Infrastructure Assessment",
    "areaServed": "Lahore, Pakistan"
  };

  const auditFaqs = [
    {
      q: "How long does an on-site network audit typically take in Lahore?",
      a: "For small-to-medium offices (20–100 nodes), our physical walk-through and automated discovery take approximately 1 to 2 business days. Comprehensive enterprise facilities with multiple server rooms or multi-floor operations typically require 3 to 5 days, followed by 3 days for telemetry synthesis and executive roadmap delivery."
    },
    {
      q: "Will the network audit cause any disruption to our live daily operations?",
      a: "No. Our diagnostic probes and discovery tools operate passively without degrading LAN/WAN throughput. Any active stress tests (such as WAN failover simulation or UPS load testing) are scheduled strictly during off-peak maintenance windows or weekends."
    },
    {
      q: "What concrete deliverables will our management receive upon audit completion?",
      a: "You receive an Executive Summary Scorecard (business-friendly risk summary), As-Built Network Topology Diagrams (Visio/PDF), Complete Asset & Warranty Inventory, Vulnerability & Security Matrix, and a Prioritised 30/60/90-Day Remediation Action Plan with estimated budgetary costs."
    },
    {
      q: "Do you sign Non-Disclosure Agreements (NDAs) before conducting the audit?",
      a: "Yes, absolutely. We execute a comprehensive mutual Non-Disclosure Agreement (NDA) prior to connecting any diagnostic equipment or inspecting server configurations to safeguard your proprietary data."
    }
  ];

  return (
    <>
      <SeoHead
        title="Network Audit Services Lahore | i Man Service"
        description="Comprehensive network audit, Wi-Fi heatmapping, firewall security analysis and infrastructure health assessment in Lahore, Pakistan."
        canonical="https://www.imanservice.com/network-audit"
        ogType="article"
        schema={pageSchema}
      />

      {/* Page Hero Header */}
      <section className="bg-gradient-to-b from-[#034F4B] to-[#056D67] text-white pt-12 pb-16 lg:pt-16 lg:pb-20 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:20px_20px]" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          {/* Breadcrumbs */}
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex flex-wrap items-center gap-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">Network Audit</li>
            </ol>
          </nav>

          <div className="max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <FileSearch className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Core Technology Pillar 1</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight leading-tight">
              Enterprise Network Audit Services in Lahore
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed font-light">
              Gain complete visibility into your digital estate. Our exhaustive diagnostics expose hidden bottlenecks, Wi-Fi dead zones, end-of-life hardware, and firewall vulnerabilities before they cause unexpected operational outages.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-4">
              <button
                onClick={() => onOpenQuote('audit')}
                className="min-h-[44px] px-6 py-3 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all shadow-md flex items-center gap-2"
              >
                <span>Request IT Proposal</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <button
                onClick={onOpenQuiz}
                className="min-h-[44px] px-5 py-3 rounded-lg bg-white/15 hover:bg-white/25 border border-white/30 text-white font-semibold text-sm transition-all flex items-center gap-2"
              >
                <Sparkles className="w-4 h-4 text-[#C1F24F]" />
                <span>Run Free IT Health Check</span>
              </button>

              <button
                onClick={onOpenChecklist}
                className="min-h-[44px] px-4 py-3 rounded-lg text-slate-200 hover:text-white font-medium text-sm transition-all flex items-center gap-1.5 underline underline-offset-4"
              >
                <FileText className="w-4 h-4 text-[#C1F24F]" />
                <span>Open Audit Checklist</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* 4 Assessment Domains */}
      <section className="py-14 sm:py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Comprehensive Scope</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              4 Critical Infrastructure Domains We Inspect
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              Every audit rigorously interrogates all physical, logical, and virtual layers across your corporate facility.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {ASSESSMENT_AREAS.map((area, idx) => (
              <div key={idx} className="p-6 rounded-2xl border border-slate-200 bg-[#F4FAF8]/30 hover:border-[#056D67] transition-all space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-bold text-slate-900 font-display flex items-center gap-2.5">
                    <span className="w-8 h-8 rounded-lg bg-[#056D67] text-white flex items-center justify-center text-xs font-bold">
                      0{idx + 1}
                    </span>
                    <span>{area.area}</span>
                  </h3>
                  <span className="text-xs font-semibold px-2.5 py-1 rounded bg-amber-50 text-amber-800 border border-amber-200">
                    {area.criticality}
                  </span>
                </div>
                <p className="text-xs sm:text-sm text-slate-600 leading-relaxed">
                  {area.examine}
                </p>
                <div className="pt-2 border-t border-slate-200">
                  <span className="text-xs font-bold text-slate-700 block mb-2">Detailed Inspection Scope:</span>
                  <ul className="space-y-1.5">
                    {area.checklist.map((item, cIdx) => (
                      <li key={cIdx} className="text-xs text-slate-600 flex items-start gap-2">
                        <CheckCircle2 className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 4-Step Methodology */}
      <section className="py-14 sm:py-20 bg-[#F4FAF8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Methodical Process</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              The 4-Stage Audit Execution Framework
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              Structured diagnostic procedures ensuring zero business downtime and verifiable findings.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {AUDIT_METHODOLOGY.map((step) => (
              <div key={step.step} className="bg-white p-6 rounded-xl border border-slate-200 shadow-xs flex flex-col justify-between">
                <div>
                  <div className="w-10 h-10 rounded-xl bg-[#056D67] text-[#C1F24F] font-extrabold text-lg flex items-center justify-center mb-4">
                    {step.step}
                  </div>
                  <h3 className="text-base font-bold text-slate-900 font-display mb-2">{step.title}</h3>
                  <p className="text-xs text-slate-600 leading-relaxed mb-4">{step.description}</p>
                </div>
                <div className="pt-3 border-t border-slate-100 bg-[#F4FAF8] p-2.5 rounded-lg">
                  <span className="text-xs font-bold text-[#056D67] uppercase block">Deliverable</span>
                  <span className="text-xs font-medium text-slate-800">{step.deliverable}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="py-14 sm:py-20 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Frequently Asked Questions</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              Network Audit Questions & Answers
            </h2>
          </div>

          <div className="space-y-3">
            {auditFaqs.map((faq, idx) => {
              const isOpen = expandedFaq === idx;
              return (
                <div key={idx} className="border border-slate-200 rounded-xl overflow-hidden">
                  <button
                    onClick={() => setExpandedFaq(isOpen ? null : idx)}
                    aria-expanded={isOpen}
                    aria-controls={`faq-audit-${idx}`}
                    className="w-full min-h-[44px] px-5 py-4 text-left font-semibold text-slate-900 text-sm sm:text-base flex items-center justify-between bg-slate-50 hover:bg-slate-100 transition-colors"
                  >
                    <span>{faq.q}</span>
                    {isOpen ? <ChevronUp className="w-5 h-5 text-[#056D67]" /> : <ChevronDown className="w-5 h-5 text-slate-500" />}
                  </button>
                  {isOpen && (
                    <div id={`faq-audit-${idx}`} className="p-5 text-xs sm:text-sm text-slate-600 bg-white border-t border-slate-200 leading-relaxed">
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* CTA Box */}
          <div className="mt-12 p-8 rounded-2xl bg-gradient-to-r from-[#034F4B] to-[#056D67] text-white text-center space-y-4">
            <h3 className="text-xl sm:text-2xl font-bold font-display">
              Ready to Audit Your Lahore Corporate Infrastructure?
            </h3>
            <p className="text-sm text-slate-200 max-w-xl mx-auto font-light">
              Schedule a preliminary discovery session with our Lead Infrastructure Architect at our Siddique Trade Center office.
            </p>
            <div className="flex flex-wrap justify-center gap-3 pt-2">
              <button
                onClick={() => onOpenQuote('audit')}
                className="min-h-[44px] px-6 py-3 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all"
              >
                Request IT Proposal
              </button>
              <Link
                to="/contact"
                className="min-h-[44px] px-6 py-3 rounded-lg bg-white/10 hover:bg-white/20 border border-white/30 text-white font-semibold text-sm transition-all flex items-center justify-center"
              >
                Contact Lahore Office
              </Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
