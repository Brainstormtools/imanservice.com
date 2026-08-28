import React from 'react';
import { 
  ShieldCheck, 
  Activity, 
  Server, 
  ArrowRight, 
  FileSearch, 
  Clock, 
  PhoneCall,
  CheckCircle,
  Network
} from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

interface HeroProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
  onOpenQuiz: () => void;
}

export const Hero: React.FC<HeroProps> = ({ onOpenQuote, onOpenQuiz }) => {
  return (
    <section id="overview" className="scroll-mt-[140px] relative overflow-hidden bg-gradient-to-b from-[#034F4B] via-[#056D67] to-[#056D67] text-white pt-10 pb-20 lg:pt-16 lg:pb-28">
      {/* Background Subtle Geometric Pattern */}
      <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:24px_24px]" />
      
      {/* Decorative Brand Accent Glows */}
      <div className="absolute top-10 right-10 w-96 h-96 rounded-full bg-[#C1F24F]/15 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-10 left-10 w-80 h-80 rounded-full bg-[#096F67]/60 blur-2xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Main Hero Copy (Col 1-7) */}
          <div className="lg:col-span-7 space-y-6">
            
            {/* Top Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/10 backdrop-blur-md border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <span className="w-2 h-2 rounded-full bg-[#C1F24F] animate-pulse" />
              <span>Lahore's Premier IT Infrastructure & AMC Partner</span>
            </div>

            {/* Headline */}
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight font-display text-white leading-tight">
              Transform IT into a <br className="hidden sm:inline" />
              <span className="text-[#C1F24F]">Strategic Business Enabler</span>
            </h1>

            {/* Sub-headline / Core Description */}
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed max-w-2xl font-light">
              <strong className="font-semibold text-white">i Man Service</strong> delivers reliable, secure, and future-ready IT infrastructure across the entire lifecycle. Your single point of accountability for <span className="text-white font-medium underline decoration-[#C1F24F] decoration-2 underline-offset-4">Existing Network Audit</span>, <span className="text-white font-medium underline decoration-[#C1F24F] decoration-2 underline-offset-4">IT-AMC/SLA Maintenance</span>, and <span className="text-white font-medium underline decoration-[#C1F24F] decoration-2 underline-offset-4">IT Consultancy</span>.
            </p>

            {/* Value Pillars Quick Chips */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
              <div className="flex items-center gap-2.5 bg-white/10 backdrop-blur-xs border border-white/10 rounded-lg p-2.5">
                <CheckCircle className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <span className="text-xs font-medium text-slate-100">Single Point Accountability</span>
              </div>
              <div className="flex items-center gap-2.5 bg-white/10 backdrop-blur-xs border border-white/10 rounded-lg p-2.5">
                <CheckCircle className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <span className="text-xs font-medium text-slate-100">Proactive SLA-Backed Care</span>
              </div>
              <div className="flex items-center gap-2.5 bg-white/10 backdrop-blur-xs border border-white/10 rounded-lg p-2.5">
                <CheckCircle className="w-4 h-4 text-[#C1F24F] flex-shrink-0" />
                <span className="text-xs font-medium text-slate-100">99.9% Uptime Commitment</span>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center gap-4 pt-4">
              <button
                onClick={() => onOpenQuote('all')}
                id="hero-request-quote-btn"
                className="min-h-[44px] inline-flex items-center justify-center gap-2.5 px-6 py-3.5 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm sm:text-base transition-all transform hover:-translate-y-0.5 shadow-lg shadow-[#034F4B]/30"
              >
                <span>Request Custom IT Proposal</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <button
                onClick={onOpenQuiz}
                id="hero-health-check-btn"
                className="min-h-[44px] inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-lg bg-white/15 hover:bg-white/25 border border-white/30 text-white font-semibold text-sm sm:text-base transition-all backdrop-blur-xs"
              >
                <Activity className="w-4 h-4 text-[#C1F24F]" />
                <span>Instant Infrastructure Health Check</span>
              </button>

              <a
                href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`}
                id="hero-call-direct-btn"
                className="min-h-[44px] inline-flex items-center gap-2 text-sm text-slate-200 hover:text-[#C1F24F] transition-colors py-2 px-2"
              >
                <PhoneCall className="w-4 h-4 text-[#C1F24F]" />
                <span>Direct Line: <strong>{COMPANY_INFO.phone}</strong></span>
              </a>
            </div>

          </div>

          {/* Right Interactive Card: 3 Core Pillars at a Glance (Col 8-12) */}
          <div className="lg:col-span-5">
            <div className="bg-white rounded-2xl p-6 sm:p-7 shadow-2xl text-slate-800 border border-slate-100 relative">
              
              {/* Header inside card */}
              <div className="flex items-center justify-between border-b border-slate-100 pb-4 mb-5">
                <div>
                  <div className="text-xs uppercase tracking-wider font-bold text-[#056D67]">
                    Enterprise Service Framework
                  </div>
                  <h2 className="text-xl font-bold text-slate-900 font-display">
                    3 Core Technology Pillars
                  </h2>
                </div>
                <div className="w-10 h-10 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center text-[#056D67]">
                  <Network className="w-5 h-5" />
                </div>
              </div>

              {/* Pillars Interactive List */}
              <div className="space-y-3.5">
                
                {/* Pillar 1 */}
                <a
                  href="#network-audit"
                  className="group block p-3.5 rounded-xl border border-slate-200 hover:border-[#056D67] bg-[#F4FAF8]/50 hover:bg-[#F4FAF8] transition-all"
                  id="hero-card-pillar-audit"
                >
                  <div className="flex items-start gap-3.5">
                    <div className="w-9 h-9 rounded-lg bg-[#056D67] text-white flex items-center justify-center flex-shrink-0 group-hover:bg-[#034F4B] transition-colors">
                      <FileSearch className="w-4 h-4 text-[#C1F24F]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-sm text-slate-900 group-hover:text-[#056D67] transition-colors">
                          1. Existing Network Audit
                        </span>
                        <span className="text-xs font-semibold uppercase px-2 py-0.5 rounded bg-white text-[#056D67] border border-slate-200">
                          Assessment
                        </span>
                      </div>
                      <p className="text-xs text-slate-600 mt-1 line-clamp-2">
                        Hardware asset cataloging, Wi-Fi heatmaps, firewall security review & EOL analysis.
                      </p>
                    </div>
                  </div>
                </a>

                {/* Pillar 2 */}
                <a
                  href="#it-amc"
                  className="group block p-3.5 rounded-xl border-2 border-[#056D67]/30 hover:border-[#056D67] bg-white hover:bg-[#F4FAF8] transition-all relative overflow-hidden"
                  id="hero-card-pillar-amc"
                >
                  <div className="absolute top-0 right-0 w-2 h-full bg-[#C1F24F]" />
                  <div className="flex items-start gap-3.5">
                    <div className="w-9 h-9 rounded-lg bg-[#056D67] text-white flex items-center justify-center flex-shrink-0">
                      <Clock className="w-4 h-4 text-[#C1F24F]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-sm text-slate-900 group-hover:text-[#056D67] transition-colors">
                          2. IT-AMC / SLA Contracts
                        </span>
                        <span className="text-xs font-bold uppercase px-2 py-0.5 rounded bg-[#C1F24F] text-[#034F4B]">
                          Fixed-Fee
                        </span>
                      </div>
                      <p className="text-xs text-slate-600 mt-1 line-clamp-2">
                        SLA-backed annual maintenance, 24/7 server monitoring, help desk & hardware upkeep.
                      </p>
                    </div>
                  </div>
                </a>

                {/* Pillar 3 */}
                <a
                  href="#it-consultancy"
                  className="group block p-3.5 rounded-xl border border-slate-200 hover:border-[#056D67] bg-[#F4FAF8]/50 hover:bg-[#F4FAF8] transition-all"
                  id="hero-card-pillar-consultancy"
                >
                  <div className="flex items-start gap-3.5">
                    <div className="w-9 h-9 rounded-lg bg-[#056D67] text-white flex items-center justify-center flex-shrink-0 group-hover:bg-[#034F4B] transition-colors">
                      <Server className="w-4 h-4 text-[#C1F24F]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-sm text-slate-900 group-hover:text-[#056D67] transition-colors">
                          3. IT Consultancy Service
                        </span>
                        <span className="text-xs font-semibold uppercase px-2 py-0.5 rounded bg-white text-[#056D67] border border-slate-200">
                          Strategy
                        </span>
                      </div>
                      <p className="text-xs text-slate-600 mt-1 line-clamp-2">
                        Independent IT strategy, solution architecture, vendor procurement & digital transformation.
                      </p>
                    </div>
                  </div>
                </a>

              </div>

              {/* Bottom Card Summary */}
              <div className="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                <span className="flex items-center gap-1">
                  <ShieldCheck className="w-4 h-4 text-[#056D67]" />
                  <span>Lahore On-Site Support</span>
                </span>
                <span className="font-semibold text-slate-800">
                  Mon – Sat 9am – 7pm
                </span>
              </div>

            </div>
          </div>

        </div>
      </div>
    </section>
  );
};
