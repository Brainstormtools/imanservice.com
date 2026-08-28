import React, { useState } from 'react';
import { CONSULTANCY_SERVICES } from '../data/companyData';
import { 
  Compass, 
  FileSearch, 
  LayoutGrid, 
  ShoppingBag, 
  Zap, 
  Check, 
  ArrowRight, 
  Sparkles, 
  ShieldCheck, 
  Target, 
  Layers
} from 'lucide-react';

interface ConsultancySectionProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
}

export const ConsultancySection: React.FC<ConsultancySectionProps> = ({ onOpenQuote }) => {
  const [selectedServiceIdx, setSelectedServiceIdx] = useState<number>(0);

  const getConsultingIcon = (icon: string) => {
    switch (icon) {
      case 'Compass': return <Compass className="w-5 h-5 text-[#056D67]" />;
      case 'FileSearch': return <FileSearch className="w-5 h-5 text-[#056D67]" />;
      case 'LayoutGrid': return <LayoutGrid className="w-5 h-5 text-[#056D67]" />;
      case 'ShoppingBag': return <ShoppingBag className="w-5 h-5 text-[#056D67]" />;
      case 'Zap': return <Zap className="w-5 h-5 text-[#056D67]" />;
      default: return <Compass className="w-5 h-5 text-[#056D67]" />;
    }
  };

  const activeService = CONSULTANCY_SERVICES[selectedServiceIdx];

  return (
    <section id="it-consultancy" className="py-20 bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Pillar Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-10 border-b border-slate-100">
          <div className="max-w-3xl">
            <div className="flex items-center gap-2 text-xs font-bold text-[#056D67] uppercase tracking-wider mb-2">
              <span className="w-6 h-0.5 bg-[#C1F24F]" />
              <span>Core Service Pillar 3</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display">
              Strategic IT Consultancy
            </h2>
            <p className="text-slate-600 text-sm sm:text-base mt-3 leading-relaxed">
              IT consulting is strategic advice that helps organizations improve the performance, scalability, and strategic value of their technology functions. i Man Service provides expert guidance that harmonizes technology with your most important business goals.
            </p>
          </div>

          <div>
            <button
              onClick={() => onOpenQuote('consultancy')}
              id="consulting-book-session-btn"
              className="inline-flex items-center gap-2 px-5 py-3 min-h-[44px] rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-semibold text-sm transition-all shadow-xs"
            >
              <span>Book Strategy Session</span>
              <ArrowRight className="w-4 h-4 text-[#C1F24F]" />
            </button>
          </div>
        </div>

        {/* Section 1: Our Consultancy Services Grid */}
        <div className="mt-12">
          <div className="mb-6">
            <h3 className="text-xl sm:text-2xl font-bold text-slate-900 font-display">
              Our 5 Specialized IT Consulting Domains
            </h3>
            <p className="text-slate-600 text-xs sm:text-sm">
              Tailored strategic advisory from enterprise architecture to vendor negotiations and cloud adoption.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {CONSULTANCY_SERVICES.map((service, idx) => (
              <div
                key={service.title}
                className="bg-[#F4FAF8] border border-slate-200 hover:border-[#056D67] rounded-2xl p-6 transition-all duration-200 shadow-xs hover:shadow-md flex flex-col justify-between"
              >
                <div>
                  <div className="w-11 h-11 rounded-xl bg-white border border-[#056D67]/20 flex items-center justify-center mb-4">
                    {getConsultingIcon(service.icon)}
                  </div>
                  <h4 className="text-lg font-bold text-slate-900 font-display">
                    {service.title}
                  </h4>
                  <p className="text-xs sm:text-sm text-slate-600 mt-2 leading-relaxed">
                    {service.description}
                  </p>
                </div>

                <div className="mt-5 pt-4 border-t border-slate-200/80">
                  <div className="text-xs uppercase font-bold text-[#056D67] tracking-wider mb-2">
                    Key Consulting Deliverables:
                  </div>
                  <ul className="space-y-1.5">
                    {service.outcomes.map((outcome, oIdx) => (
                      <li key={oIdx} className="text-xs text-slate-700 flex items-start gap-1.5 font-medium">
                        <Check className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                        <span>{outcome}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}

            {/* Free Advisory Session Card */}
            <div className="bg-gradient-to-br from-[#056D67] to-[#034F4B] text-white rounded-2xl p-6 flex flex-col justify-between border border-[#096F67]">
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-[#C1F24F]">
                  Executive Advisory
                </span>
                <h4 className="text-xl font-bold font-display mt-2">
                  Unsure Where to Start with Your Digital Strategy?
                </h4>
                <p className="text-xs text-slate-200 mt-2 leading-relaxed">
                  Schedule a complimentary 30-minute discovery session with our Lead Infrastructure Consultant to review your immediate technical bottlenecks.
                </p>
              </div>

              <button
                onClick={() => onOpenQuote('consultancy')}
                className="mt-6 w-full min-h-[44px] py-2.5 px-4 rounded-lg bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-xs sm:text-sm transition-colors text-center flex items-center justify-center"
              >
                Schedule 30-Min Strategy Call
              </button>
            </div>
          </div>
        </div>

        {/* Section 2: Why i Man Service for IT Consulting? */}
        <div className="mt-16 bg-[#F4FAF8] rounded-3xl p-8 sm:p-10 border border-[#056D67]/20">
          <div className="max-w-3xl mb-8">
            <span className="text-xs font-bold text-[#056D67] uppercase tracking-wider bg-white px-3 py-1 rounded-full border border-[#056D67]/20">
              Our Advisory Advantage
            </span>
            <h3 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-2">
              Why i Man Service for IT Consulting?
            </h3>
            <p className="text-slate-600 text-sm mt-1">
              We bring an objective, real-world perspective that bridges the gap between executive leadership and technical execution.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Advantage 1 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
              <div className="w-12 h-12 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center text-[#056D67] mb-4">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 font-display">
                Independent Voice
              </h4>
              <p className="text-xs sm:text-sm text-slate-600 mt-2 leading-relaxed">
                We provide unbiased, practical advice focused strictly on your best interests. We are not locked into single-vendor commission models.
              </p>
            </div>

            {/* Advantage 2 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
              <div className="w-12 h-12 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center text-[#056D67] mb-4">
                <Layers className="w-6 h-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 font-display">
                Holistic Approach
              </h4>
              <p className="text-xs sm:text-sm text-slate-600 mt-2 leading-relaxed">
                We align people, process, data, and technology into a cohesive roadmap rather than treating IT as disconnected software silos.
              </p>
            </div>

            {/* Advantage 3 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
              <div className="w-12 h-12 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center text-[#056D67] mb-4">
                <Target className="w-6 h-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 font-display">
                Actionable Roadmaps
              </h4>
              <p className="text-xs sm:text-sm text-slate-600 mt-2 leading-relaxed">
                We don't just identify problems—we tell you why they matter and exactly how to fix them with clear budgets, milestones, and timelines.
              </p>
            </div>

          </div>
        </div>

      </div>
    </section>
  );
};
