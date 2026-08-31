import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { 
  Building2, 
  ShieldCheck, 
  CheckCircle2, 
  MapPin, 
  Phone, 
  Mail, 
  Clock, 
  Award, 
  Users, 
  ArrowRight,
  Sparkles
} from 'lucide-react';
import { COMPANY_INFO, ABOUT_COMMITMENTS } from '../data/companyData';

interface AboutPageProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
}

export const AboutPage: React.FC<AboutPageProps> = ({ onOpenQuote }) => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "AboutPage",
    "name": "About i Man Service Lahore",
    "mainEntity": {
      "@type": "LocalBusiness",
      "name": "i Man Service",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "P-120, Siddique Trade Center, Gulberg II",
        "addressLocality": "Lahore",
        "addressRegion": "Punjab",
        "postalCode": "54660",
        "addressCountry": "PK"
      },
      "telephone": "+923149020008",
      "email": "info@imanservice.com",
      "description": "i Man Service is Lahore's trusted enterprise IT infrastructure partner delivering network audits, SLA-backed AMC maintenance, and strategic technology consulting."
    }
  };

  const serviceAreas = [
    "Gulberg (I, II, III)",
    "DHA (Phases 1–9)",
    "Johar Town & Faisal Town",
    "Model Town & Garden Town",
    "Mall Road & Downtown Commercial",
    "Raiwind Road & Lake City",
    "Sundar Industrial Estate",
    "Multan Road Industrial Corridor"
  ];

  return (
    <>
      <SeoHead
        title="About i Man Service | Lahore IT Infrastructure Partner"
        description="Learn about i Man Service, Lahore’s dedicated IT infrastructure partner providing single-point accountability for networks, hardware, and SLAs."
        canonical="https://www.imanservice.com/about"
        ogType="website"
        schema={pageSchema}
      />

      {/* Hero */}
      <section className="bg-gradient-to-b from-[#034F4B] to-[#056D67] text-white pt-12 pb-16 lg:pt-16 lg:pb-20 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:20px_20px]" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex flex-wrap items-center gap-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">About Us</li>
            </ol>
          </nav>

          <div className="max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <Building2 className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Engineering Excellence</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight leading-tight">
              About i Man Service
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed font-light">
              We are a specialized IT infrastructure and engineering services firm headquartered at Siddique Trade Center in Gulberg II, Lahore. We eliminate the friction between hardware vendors, internet service providers, and software systems by serving as your single point of accountability.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-4">
              <button
                onClick={() => onOpenQuote('all')}
                className="min-h-[44px] px-6 py-3 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all shadow-md flex items-center gap-2"
              >
                <span>Request IT Proposal</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <Link
                to="/contact"
                className="min-h-[44px] px-5 py-3 rounded-lg bg-white/15 hover:bg-white/25 border border-white/30 text-white font-semibold text-sm transition-all flex items-center gap-2"
              >
                <MapPin className="w-4 h-4 text-[#C1F24F]" />
                <span>Visit Lahore Office</span>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* 4 Commitments */}
      <section className="py-14 sm:py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Core Values</span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-1">
              Our 4 Engineering Commitments
            </h2>
            <p className="text-sm text-slate-600 mt-2">
              How we partner with corporate leadership to deliver measurable uptime and predictable IT expenditures.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {ABOUT_COMMITMENTS.map((com, idx) => (
              <div key={idx} className="p-6 rounded-2xl border border-slate-200 bg-[#F4FAF8]/40 hover:border-[#056D67] transition-all space-y-3">
                <div className="w-10 h-10 rounded-xl bg-[#056D67] text-[#C1F24F] flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5" />
                </div>
                <h3 className="text-lg font-bold text-slate-900 font-display">{com.title}</h3>
                <p className="text-xs sm:text-sm text-slate-600 leading-relaxed">{com.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Lahore Service Coverage & Office Presence */}
      <section className="py-14 sm:py-20 bg-[#F4FAF8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            
            <div className="lg:col-span-7 space-y-6">
              <span className="text-xs uppercase font-bold text-[#056D67] tracking-wider">Local Presence</span>
              <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display">
                Fast On-Site Dispatch Across Lahore
              </h2>
              <p className="text-sm text-slate-600 leading-relaxed">
                Operating from our central hub at <strong>P-120, Siddique Trade Center, Gulberg II</strong>, our field engineering teams reach clients across Lahore rapidly during P1/P2 emergencies.
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                {serviceAreas.map((area, idx) => (
                  <div key={idx} className="flex items-center gap-2 p-2.5 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800">
                    <MapPin className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0" />
                    <span>{area}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="lg:col-span-5 bg-white p-7 rounded-2xl border border-slate-200 shadow-md space-y-4">
              <h3 className="text-lg font-bold text-slate-900 font-display border-b border-slate-100 pb-3">
                Lahore Headquarters
              </h3>
              
              <div className="space-y-3 text-xs text-slate-700">
                <div className="flex items-start gap-2.5">
                  <MapPin className="w-4 h-4 text-[#056D67] flex-shrink-0 mt-0.5" />
                  <span>P-120, Siddique Trade Center, Gulberg II, Lahore, Pakistan</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Phone className="w-4 h-4 text-[#056D67] flex-shrink-0" />
                  <a href="tel:+923149020008" className="hover:text-[#056D67] font-semibold min-h-[44px] flex items-center">
                    +92 314 9020008
                  </a>
                </div>
                <div className="flex items-center gap-2.5">
                  <Mail className="w-4 h-4 text-[#056D67] flex-shrink-0" />
                  <a href="mailto:info@imanservice.com" className="hover:text-[#056D67] min-h-[44px] flex items-center">
                    info@imanservice.com
                  </a>
                </div>
                <div className="flex items-start gap-2.5 pt-2 border-t border-slate-100">
                  <Clock className="w-4 h-4 text-[#056D67] flex-shrink-0 mt-0.5" />
                  <span>Monday – Saturday: 9:00 AM – 7:00 PM (Emergency SLA Support 24/7/365)</span>
                </div>
              </div>

              <div className="pt-3">
                <button
                  onClick={() => onOpenQuote('all')}
                  className="w-full min-h-[44px] py-2.5 px-4 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs transition-colors flex items-center justify-center gap-2"
                >
                  <span>Request IT Proposal</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#C1F24F]" />
                </button>
              </div>
            </div>

          </div>
        </div>
      </section>
    </>
  );
};
