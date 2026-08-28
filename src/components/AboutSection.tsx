import React from 'react';
import { 
  ABOUT_COMMITMENTS, 
  COMPANY_INFO 
} from '../data/companyData';
import { 
  CheckCircle2, 
  FileText, 
  Award, 
  Handshake, 
  Building2, 
  ShieldCheck, 
  ArrowRight,
  MapPin,
  Phone,
  Globe
} from 'lucide-react';
import { Logo } from './Logo';

interface AboutSectionProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
}

export const AboutSection: React.FC<AboutSectionProps> = ({ onOpenQuote }) => {
  const getCommitmentIcon = (icon: string) => {
    switch (icon) {
      case 'CheckCircle2': return <CheckCircle2 className="w-6 h-6 text-[#056D67]" />;
      case 'FileText': return <FileText className="w-6 h-6 text-[#056D67]" />;
      case 'Award': return <Award className="w-6 h-6 text-[#056D67]" />;
      case 'Handshake': return <Handshake className="w-6 h-6 text-[#056D67]" />;
      default: return <CheckCircle2 className="w-6 h-6 text-[#056D67]" />;
    }
  };

  return (
    <section id="about" className="py-20 bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Main Grid: Overview & Commitments */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Column: Company Story & Mission (Col 1-6) */}
          <div className="lg:col-span-6 space-y-6">
            
            {/* Full Corporate Brand Logo Banner */}
            <div className="p-3 sm:p-4 rounded-2xl bg-[#F4FAF8] border border-[#056D67]/15 inline-block max-w-full overflow-hidden">
              <Logo type="full" size="lg" />
            </div>

            <div className="inline-flex items-center gap-2 text-xs font-bold text-[#056D67] uppercase tracking-wider">
              <span className="w-6 h-0.5 bg-[#C1F24F]" />
              <span>About i Man Service</span>
            </div>

            <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display leading-tight">
              A Trusted IT Partner Built on <span className="text-[#056D67]">Accountability & Excellence</span>
            </h2>

            <p className="text-sm sm:text-base text-slate-600 leading-relaxed font-light">
              <strong className="text-slate-900 font-semibold">i Man Service</strong> is a comprehensive IT infrastructure and technology services provider dedicated to helping businesses leverage technology for sustainable growth.
            </p>

            <p className="text-sm sm:text-base text-slate-600 leading-relaxed font-light">
              We bring together three core capabilities—<strong>Network infrastructure auditing</strong>, <strong>IT maintenance and support (AMC/SLA)</strong>, and <strong>strategic IT consultancy</strong>—under one roof. This integrated approach means our clients benefit from a single point of accountability for all their technology needs.
            </p>

            {/* Quote / Mission Callout */}
            <div className="p-4 rounded-xl bg-[#F4FAF8] border-l-4 border-[#056D67] text-slate-800 text-xs sm:text-sm font-medium">
              "Our mission is to transform IT from a cost center into a strategic business enabler—ensuring your systems are always available, always secure, and always aligned with your business goals."
            </div>

            {/* Quick Contact Chips */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
              <div className="flex items-center gap-2 text-xs text-slate-700 bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                <MapPin className="w-4 h-4 text-[#056D67] flex-shrink-0" />
                <span className="truncate">Gulberg ll, Lahore</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-slate-700 bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                <Phone className="w-4 h-4 text-[#056D67] flex-shrink-0" />
                <span>{COMPANY_INFO.phone}</span>
              </div>
            </div>

          </div>

          {/* Right Column: 4 Commitments Grid (Col 7-12) */}
          <div className="lg:col-span-6">
            <div className="bg-[#F4FAF8] rounded-3xl p-6 sm:p-8 border border-[#056D67]/20 shadow-xs">
              <div className="mb-6">
                <span className="text-xs font-bold uppercase tracking-wider text-[#056D67]">
                  The i Man Standard
                </span>
                <h3 className="text-xl sm:text-2xl font-bold text-slate-900 font-display">
                  Our 4 Core Commitments to Every Client
                </h3>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {ABOUT_COMMITMENTS.map((comm) => (
                  <div
                    key={comm.title}
                    className="bg-white rounded-xl p-5 border border-slate-200 shadow-2xs flex flex-col justify-between"
                  >
                    <div>
                      <div className="w-10 h-10 rounded-lg bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center mb-3">
                        {getCommitmentIcon(comm.icon)}
                      </div>
                      <h4 className="text-base font-bold text-slate-900 font-display">
                        {comm.title}
                      </h4>
                      <p className="text-xs text-slate-600 mt-1.5 leading-relaxed">
                        {comm.description}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Bottom Card Action */}
              <div className="mt-6 pt-5 border-t border-slate-200 flex flex-wrap items-center justify-between gap-3">
                <span className="text-xs font-semibold text-slate-700">
                  Ready to partner with Lahore's premier IT team?
                </span>
                <button
                  onClick={() => onOpenQuote('all')}
                  className="min-h-[44px] px-4 py-2.5 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs sm:text-sm transition-colors flex items-center justify-center gap-1.5"
                >
                  <span>Start Conversation</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#C1F24F]" />
                </button>
              </div>

            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
