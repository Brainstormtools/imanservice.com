import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { 
  Clock, 
  ShieldCheck, 
  Server, 
  Headphones, 
  CheckCircle2, 
  ArrowRight, 
  Calculator, 
  Award,
  Layers,
  Sparkles
} from 'lucide-react';
import { SLA_TIERS, AMC_COVERAGE_ITEMS } from '../data/companyData';
import { SlaTierBuilder } from '../components/SlaTierBuilder';
import { SlaMatrixTable } from '../components/SlaMatrixTable';

interface ItAmcSlaPageProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
}

export const ItAmcSlaPage: React.FC<ItAmcSlaPageProps> = ({ onOpenQuote }) => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "Service",
    "name": "IT AMC & SLA Support Services Lahore",
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
    "description": "Fixed-fee IT Annual Maintenance Contracts (IT-AMC) with structured SLA tiers, rapid on-site dispatch, and proactive 24/7 server monitoring in Lahore, Pakistan.",
    "serviceType": "IT Maintenance & SLA Support",
    "areaServed": "Lahore, Pakistan"
  };

  return (
    <>
      <SeoHead
        title="IT AMC & SLA Support Services Lahore | i Man Service"
        description="Fixed-fee IT Annual Maintenance Contracts (IT-AMC) with structured SLA tiers, rapid on-site dispatch, and proactive 24/7 server monitoring in Lahore."
        canonical="https://www.imanservice.com/it-amc-sla"
        ogType="article"
        schema={pageSchema}
      />

      {/* Page Hero Header */}
      <section className="bg-gradient-to-b from-[#034F4B] to-[#056D67] text-white pt-12 pb-16 lg:pt-16 lg:pb-20 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:20px_20px]" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex flex-wrap items-center gap-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">IT-AMC & SLA Support</li>
            </ol>
          </nav>

          <div className="max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <Clock className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Core Technology Pillar 2</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight leading-tight">
              Fixed-Fee IT-AMC & SLA Support in Lahore
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed font-light">
              Eliminate unexpected IT downtime and unpredictable break-fix invoices. Our SLA-backed Annual Maintenance Contracts give your organisation dedicated help desk support, scheduled preventive physical maintenance, and guaranteed emergency on-site dispatch across Lahore.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-4">
              <button
                onClick={() => onOpenQuote('amc')}
                className="min-h-[44px] px-6 py-3 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all shadow-md flex items-center gap-2"
              >
                <span>Request IT Proposal</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <a
                href="#interactive-estimator"
                className="min-h-[44px] px-5 py-3 rounded-lg bg-white/15 hover:bg-white/25 border border-white/30 text-white font-semibold text-sm transition-all flex items-center gap-2"
              >
                <Calculator className="w-4 h-4 text-[#C1F24F]" />
                <span>Configure SLA Scope</span>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* 3 SLA Tiers Overview */}
      <section className="py-14 sm:py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Service Level Commitments</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              Contractual SLA Tiers Designed for Every Business Size
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              From growing SMBs needing standard business-hours support to 24/7 mission-critical operations.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {SLA_TIERS.map((tier) => (
              <div 
                key={tier.id}
                className={`p-6 sm:p-7 rounded-2xl border flex flex-col justify-between transition-all ${
                  tier.popular 
                    ? 'border-2 border-[#056D67] bg-[#F4FAF8]/60 shadow-lg relative' 
                    : 'border-slate-200 bg-white'
                }`}
              >
                {tier.popular && (
                  <span className="absolute -top-3 left-6 px-3 py-1 rounded-full bg-[#056D67] text-[#C1F24F] text-xs font-bold tracking-wide">
                    RECOMMENDED SMB SLA
                  </span>
                )}
                
                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-bold text-slate-900 font-display">{tier.name}</h3>
                    <p className="text-xs text-slate-500 mt-0.5">{tier.tag}</p>
                  </div>

                  <div className="space-y-2 py-3 border-y border-slate-200 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600 font-medium">Critical (P1) Response:</span>
                      <strong className="text-[#056D67]">{tier.responseCritical}</strong>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600 font-medium">High (P2) Response:</span>
                      <strong className="text-slate-800">{tier.responseHigh}</strong>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600 font-medium">Preventive Routine:</span>
                      <strong className="text-slate-800">{tier.preventiveVisits}</strong>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600 font-medium">Executive Reporting:</span>
                      <strong className="text-slate-800">{tier.reporting}</strong>
                    </div>
                  </div>

                  <p className="text-xs text-slate-600 leading-relaxed">
                    <strong>Best suited for:</strong> {tier.bestFor}
                  </p>
                </div>

                <button
                  onClick={() => onOpenQuote('amc', { tier: tier.name })}
                  className={`mt-6 w-full min-h-[44px] py-2.5 px-4 rounded-lg font-bold text-xs transition-colors flex items-center justify-center gap-2 ${
                    tier.popular
                      ? 'bg-[#056D67] text-white hover:bg-[#034F4B]'
                      : 'bg-slate-100 text-slate-800 hover:bg-[#056D67] hover:text-white'
                  }`}
                >
                  <span>Select {tier.name.split(' ')[0]} SLA</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Scope Calculator */}
      <div id="interactive-estimator" className="scroll-mt-[140px]">
        <SlaTierBuilder onOpenQuote={onOpenQuote} />
      </div>

      {/* Severity Matrix */}
      <SlaMatrixTable onOpenQuote={onOpenQuote} />
    </>
  );
};
