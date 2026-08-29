import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { 
  Compass, 
  ShieldCheck, 
  Cloud, 
  Lock, 
  ShoppingBag, 
  Zap, 
  ArrowRight, 
  CheckCircle2, 
  Layers,
  Sparkles
} from 'lucide-react';
import { CONSULTANCY_SERVICES } from '../data/companyData';

interface ItConsultancyPageProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
}

export const ItConsultancyPage: React.FC<ItConsultancyPageProps> = ({ onOpenQuote }) => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "Service",
    "name": "IT Consultancy Services Lahore",
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
    "description": "Strategic IT consultancy, cloud migration architecture, zero-trust cybersecurity frameworks, and vendor-neutral technology procurement in Lahore, Pakistan.",
    "serviceType": "IT Strategy & Enterprise Advisory",
    "areaServed": "Lahore, Pakistan"
  };

  return (
    <>
      <SeoHead
        title="IT Consultancy Services Lahore | i Man Service"
        description="Strategic IT consultancy, cloud migration architecture, zero-trust security roadmaps, and vendor-neutral technology procurement in Lahore."
        canonical="https://www.imanservice.com/it-consultancy"
        ogType="article"
        schema={pageSchema}
      />

      {/* Page Hero Header */}
      <section className="bg-gradient-to-b from-[#034F4B] to-[#056D67] text-white pt-12 pb-16 lg:pt-16 lg:pb-20 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:20px_20px]" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex items-center space-x-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">IT Consultancy</li>
            </ol>
          </nav>

          <div className="max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <Compass className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Core Technology Pillar 3</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight leading-tight">
              Strategic IT Consultancy in Lahore
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed font-light">
              Transform your technology infrastructure from a reactive overhead into a scalable business accelerator. Our vendor-neutral IT architects advise leadership on multi-year roadmaps, hybrid-cloud migrations, Zero-Trust cybersecurity, and procurement cost optimization.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-4">
              <button
                onClick={() => onOpenQuote('consultancy')}
                className="min-h-[44px] px-6 py-3 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all shadow-md flex items-center gap-2"
              >
                <span>Request IT Proposal</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <button
                onClick={() => onOpenQuote('consultancy', { service: 'Discovery Strategy Session' })}
                className="min-h-[44px] px-5 py-3 rounded-lg bg-white/15 hover:bg-white/25 border border-white/30 text-white font-semibold text-sm transition-all flex items-center gap-2"
              >
                <Sparkles className="w-4 h-4 text-[#C1F24F]" />
                <span>Book a Consultation</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* 5 Specialized Consulting Domains */}
      <section className="py-14 sm:py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Advisory Practices</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              5 Specialized Technology Consulting Domains
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              Deep architectural acumen tailored for corporate enterprises, manufacturing hubs, and growing commercial businesses.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {CONSULTANCY_SERVICES.map((srv, idx) => (
              <div key={idx} className="p-6 rounded-2xl border border-slate-200 bg-[#F4FAF8]/30 hover:border-[#056D67] transition-all flex flex-col justify-between space-y-4">
                <div>
                  <div className="w-10 h-10 rounded-xl bg-[#056D67] text-[#C1F24F] flex items-center justify-center mb-3">
                    <Compass className="w-5 h-5" />
                  </div>
                  <h3 className="text-base font-bold text-slate-900 font-display mb-1">{srv.title}</h3>
                  <p className="text-xs text-slate-600 leading-relaxed mb-4">{srv.description}</p>
                  
                  <div className="pt-3 border-t border-slate-200 space-y-1.5">
                    <span className="text-[11px] font-bold text-slate-700 block">Key Consulting Deliverables:</span>
                    {srv.outcomes.map((out, oIdx) => (
                      <div key={oIdx} className="flex items-start gap-2 text-xs text-slate-600">
                        <CheckCircle2 className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                        <span>{out}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <button
                  onClick={() => onOpenQuote('consultancy', { service: srv.title })}
                  className="w-full min-h-[44px] py-2 px-3 rounded-lg bg-slate-100 hover:bg-[#056D67] hover:text-white text-slate-800 text-xs font-bold transition-colors flex items-center justify-center gap-1.5"
                >
                  <span>Request IT Proposal</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Engagement Models */}
      <section className="py-14 sm:py-20 bg-[#F4FAF8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Flexible Cooperation</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              Consulting Engagement Models
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              Choose the structure that matches your executive needs and project timelines.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="p-6 bg-white rounded-2xl border border-slate-200 shadow-xs space-y-3">
              <span className="text-xs font-bold uppercase text-[#056D67] tracking-wide">Model A</span>
              <h3 className="text-lg font-bold text-slate-900 font-display">Project-Based Architecture</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Fixed-scope design for specific initiatives: data center relocation, multi-branch SD-WAN rollout, or Microsoft 365 cloud migration.
              </p>
            </div>

            <div className="p-6 bg-white rounded-2xl border-2 border-[#056D67] shadow-xs space-y-3 relative">
              <span className="text-xs font-bold uppercase text-[#056D67] tracking-wide">Model B (Popular)</span>
              <h3 className="text-lg font-bold text-slate-900 font-display">Quarterly Technology Retainer</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Continuous advisory for executive boards, vendor review sessions, quarterly disaster recovery simulations, and security compliance oversight.
              </p>
            </div>

            <div className="p-6 bg-white rounded-2xl border border-slate-200 shadow-xs space-y-3">
              <span className="text-xs font-bold uppercase text-[#056D67] tracking-wide">Model C</span>
              <h3 className="text-lg font-bold text-slate-900 font-display">Virtual Head of IT / vCTO</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Fractional executive IT leadership for enterprises seeking strategic guidance, budget control, and staff mentoring without full-time C-level overhead.
              </p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};
