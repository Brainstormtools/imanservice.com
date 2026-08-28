import React from 'react';
import { Logo } from './Logo';
import { COMPANY_INFO } from '../data/companyData';
import { 
  Phone, 
  Mail, 
  MapPin, 
  Globe, 
  ShieldCheck, 
  ArrowUp,
  FileCheck,
  Calculator,
  Activity,
  MessageSquare
} from 'lucide-react';

interface FooterProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
  onOpenQuiz: () => void;
  onOpenChecklist: () => void;
}

export const Footer: React.FC<FooterProps> = ({
  onOpenQuote,
  onOpenQuiz,
  onOpenChecklist
}) => {
  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <footer className="bg-[#034F4B] text-slate-300 pt-16 pb-12 border-t border-[#056D67]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Top Footer Row */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-10 pb-12 border-b border-white/10">
          
          {/* Col 1: Brand & Tagline (Col 1-5) */}
          <div className="lg:col-span-5 space-y-4">
            <Logo variant="dark" size="lg" showTagline={true} />
            
            <p className="text-xs sm:text-sm text-slate-300 leading-relaxed max-w-sm pt-2">
              <strong>i Man Service</strong> is your single point of accountability for enterprise IT infrastructure, fixed-fee SLA-backed maintenance, independent audits, and strategic technology consulting.
            </p>

            {/* Location & Phone */}
            <div className="space-y-1 text-xs sm:text-sm pt-2">
              <div className="flex items-center gap-2.5 text-slate-200 min-h-[36px]">
                <MapPin className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <span>{COMPANY_INFO.address}, {COMPANY_INFO.city}</span>
              </div>
              <div className="flex items-center gap-2.5 text-slate-200">
                <Phone className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <a 
                  href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`} 
                  className="min-h-[44px] inline-flex items-center font-bold text-white hover:text-[#C1F24F] py-1"
                >
                  {COMPANY_INFO.phone} (Direct & 24/7 SLA)
                </a>
              </div>
              <div className="flex items-center gap-2.5 text-slate-200">
                <MessageSquare className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <a 
                  href={COMPANY_INFO.whatsappLink || 'https://wa.me/923149020008'} 
                  target="_blank" 
                  rel="noopener noreferrer" 
                  className="min-h-[44px] inline-flex items-center font-bold text-[#C1F24F] hover:underline py-1"
                >
                  WhatsApp: {COMPANY_INFO.whatsapp || '+92 314 9020008'}
                </a>
              </div>
              <div className="flex items-center gap-2.5 text-slate-200 min-h-[44px]">
                <Globe className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <a 
                  href={`https://${COMPANY_INFO.website}`} 
                  target="_blank" 
                  rel="noopener noreferrer" 
                  className="min-h-[44px] inline-flex items-center text-slate-200 hover:text-[#C1F24F] transition-colors"
                >
                  {COMPANY_INFO.website}
                </a>
              </div>
            </div>
          </div>

          {/* Col 2: Core Services (Col 6-8) */}
          <div className="lg:col-span-4 space-y-3">
            <h4 className="text-sm font-bold uppercase tracking-wider text-white font-display">
              Core Service Pillars
            </h4>
            <ul className="space-y-1 text-xs sm:text-sm">
              <li>
                <a href="#network-audit" className="min-h-[44px] hover:text-[#C1F24F] transition-colors flex items-center gap-2 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#C1F24F]" />
                  <span>1. Existing Networks Audit</span>
                </a>
              </li>
              <li>
                <a href="#it-amc" className="min-h-[44px] hover:text-[#C1F24F] transition-colors flex items-center gap-2 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#C1F24F]" />
                  <span>2. IT-AMC / SLA Contracts</span>
                </a>
              </li>
              <li>
                <a href="#it-consultancy" className="min-h-[44px] hover:text-[#C1F24F] transition-colors flex items-center gap-2 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#C1F24F]" />
                  <span>3. Strategic IT Consultancy</span>
                </a>
              </li>
              <li>
                <a href="#sla-matrix" className="min-h-[44px] hover:text-[#C1F24F] transition-colors flex items-center gap-2 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#C1F24F]" />
                  <span>SLA Severity & Escalation Matrix</span>
                </a>
              </li>
              <li>
                <a href="#sla-calculator" className="min-h-[44px] hover:text-[#C1F24F] transition-colors flex items-center gap-2 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#C1F24F]" />
                  <span>Interactive Fleet & SLA Estimator</span>
                </a>
              </li>
            </ul>
          </div>

          {/* Col 3: Interactive Utilities & Tools (Col 9-12) */}
          <div className="lg:col-span-3 space-y-3">
            <h4 className="text-sm font-bold uppercase tracking-wider text-white font-display">
              Client Tools & Resources
            </h4>
            <div className="space-y-2 pt-1">
              <button
                onClick={onOpenQuiz}
                className="w-full min-h-[44px] text-left p-2.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-xs font-semibold text-white transition-all flex items-center justify-between"
              >
                <span className="flex items-center gap-2">
                  <Activity className="w-3.5 h-3.5 text-[#C1F24F]" />
                  <span>IT Health Readiness Quiz</span>
                </span>
                <span className="text-xs text-[#C1F24F]">&rarr;</span>
              </button>

              <button
                onClick={onOpenChecklist}
                className="w-full min-h-[44px] text-left p-2.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-xs font-semibold text-white transition-all flex items-center justify-between"
              >
                <span className="flex items-center gap-2">
                  <FileCheck className="w-3.5 h-3.5 text-[#C1F24F]" />
                  <span>Download Audit Checklist</span>
                </span>
                <span className="text-xs text-[#C1F24F]">&rarr;</span>
              </button>

              <button
                onClick={() => onOpenQuote('all')}
                className="w-full min-h-[44px] text-left p-2.5 rounded-lg bg-[#056D67] hover:bg-[#096F67] border border-[#C1F24F]/30 text-xs font-bold text-[#C1F24F] transition-all flex items-center justify-between"
              >
                <span className="flex items-center gap-2">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  <span>Request Instant Proposal</span>
                </span>
                <span className="text-xs text-white">&rarr;</span>
              </button>
            </div>
          </div>

        </div>

        {/* Bottom Copyright Row */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-400">
          <div>
            © {new Date().getFullYear()} <strong>i Man Service</strong>. All Rights Reserved. {COMPANY_INFO.address}.
          </div>

          <div className="flex items-center gap-4">
            <span className="text-xs text-[#D8FA8A]">
              Single Point of Accountability for Enterprise IT
            </span>
            <button
              onClick={scrollToTop}
              className="min-w-[44px] min-h-[44px] flex items-center justify-center p-2 rounded-lg bg-white/5 hover:bg-white/15 text-slate-300 hover:text-white transition-colors"
              title="Scroll to top"
              aria-label="Scroll to top"
            >
              <ArrowUp className="w-4 h-4" />
            </button>
          </div>
        </div>

      </div>
    </footer>
  );
};
