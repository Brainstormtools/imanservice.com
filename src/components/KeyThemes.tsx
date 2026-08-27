import React from 'react';
import { 
  ShieldCheck, 
  Activity, 
  Clock, 
  Cpu, 
  TrendingUp, 
  CheckCircle2, 
  ArrowUpRight 
} from 'lucide-react';
import { KEY_MESSAGING_THEMES } from '../data/companyData';

interface KeyThemesProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
}

export const KeyThemes: React.FC<KeyThemesProps> = ({ onOpenQuote }) => {
  const iconMap: Record<string, React.ReactNode> = {
    ShieldCheck: <ShieldCheck className="w-6 h-6 text-[#056D67]" />,
    Activity: <Activity className="w-6 h-6 text-[#056D67]" />,
    Clock: <Clock className="w-6 h-6 text-[#056D67]" />,
    Cpu: <Cpu className="w-6 h-6 text-[#056D67]" />,
    TrendingUp: <TrendingUp className="w-6 h-6 text-[#056D67]" />
  };

  return (
    <section className="py-16 bg-[#F4FAF8] border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white border border-[#056D67]/20 text-[#056D67] text-xs font-bold uppercase tracking-wider mb-3">
            <span>Our Operational Philosophy</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display">
            Why Leading Enterprises Choose <span className="text-[#056D67]">IMAN SERVICE COMPANY</span>
          </h2>
          <p className="text-slate-600 text-sm sm:text-base mt-2">
            Five core differentiators that transform your IT infrastructure from a chaotic cost center into a predictable, high-performance competitive engine.
          </p>
        </div>

        {/* 5 Themes Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {KEY_MESSAGING_THEMES.map((theme, index) => {
            const isFeatured = index === 0; // Single Point of Accountability
            return (
              <div
                key={theme.id}
                id={`theme-card-${theme.id}`}
                className={`rounded-2xl p-6 transition-all duration-200 relative flex flex-col justify-between ${
                  isFeatured
                    ? 'bg-[#056D67] text-white shadow-xl md:col-span-2 lg:col-span-1 border-2 border-[#056D67]'
                    : 'bg-white text-slate-800 border border-slate-200 hover:border-[#056D67]/40 shadow-xs hover:shadow-md'
                }`}
              >
                <div>
                  {/* Top Bar inside Card */}
                  <div className="flex items-center justify-between mb-4">
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      isFeatured ? 'bg-white text-[#056D67]' : 'bg-[#F4FAF8] border border-[#056D67]/20'
                    }`}>
                      {iconMap[theme.icon]}
                    </div>
                    <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${
                      isFeatured 
                        ? 'bg-[#C1F24F] text-[#034F4B]' 
                        : 'bg-[#F4FAF8] text-[#056D67] border border-[#056D67]/20'
                    }`}>
                      {theme.stats}
                    </span>
                  </div>

                  {/* Title & Subtitle */}
                  <h3 className={`text-lg font-bold font-display ${isFeatured ? 'text-white' : 'text-slate-900'}`}>
                    {theme.title}
                  </h3>
                  <div className={`text-xs font-medium mt-0.5 mb-3 ${isFeatured ? 'text-[#D8FA8A]' : 'text-[#056D67]'}`}>
                    {theme.subtitle}
                  </div>

                  {/* Description */}
                  <p className={`text-xs sm:text-sm leading-relaxed ${isFeatured ? 'text-slate-100' : 'text-slate-600'}`}>
                    {theme.description}
                  </p>
                </div>

                {/* Card Footer */}
                <div className={`mt-5 pt-4 border-t flex items-center justify-between text-xs ${
                  isFeatured ? 'border-white/20 text-slate-200' : 'border-slate-100 text-slate-500'
                }`}>
                  <span className="flex items-center gap-1.5 font-medium">
                    <CheckCircle2 className={`w-3.5 h-3.5 ${isFeatured ? 'text-[#C1F24F]' : 'text-[#056D67]'}`} />
                    <span>Guaranteed Standard</span>
                  </span>
                  <button
                    onClick={() => onOpenQuote('all')}
                    className={`inline-flex items-center gap-1 font-semibold hover:underline ${
                      isFeatured ? 'text-[#C1F24F]' : 'text-[#056D67]'
                    }`}
                  >
                    <span>Inquire</span>
                    <ArrowUpRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })}

          {/* Quick CTA Card */}
          <div className="rounded-2xl p-6 bg-gradient-to-br from-white to-[#F4FAF8] border-2 border-dashed border-[#056D67]/40 flex flex-col justify-between">
            <div>
              <div className="w-10 h-10 rounded-lg bg-[#C1F24F] flex items-center justify-center text-[#034F4B] font-bold text-lg mb-3">
                ★
              </div>
              <h3 className="text-lg font-bold text-slate-900 font-display">
                Need an Integrated IT Solution?
              </h3>
              <p className="text-xs sm:text-sm text-slate-600 mt-2">
                Combine Network Auditing with an ongoing IT-AMC agreement and strategic advisory for complete peace of mind.
              </p>
            </div>
            <div className="mt-4 pt-3">
              <button
                onClick={() => onOpenQuote('all')}
                className="w-full py-2.5 px-4 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-semibold text-xs sm:text-sm transition-colors text-center"
              >
                Schedule Executive Consultation
              </button>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
