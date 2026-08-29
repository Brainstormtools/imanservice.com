import React from 'react';
import { Phone, MessageSquare, ShieldCheck } from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

interface MobileQuickBarProps {
  onOpenQuote: () => void;
}

export const MobileQuickBar: React.FC<MobileQuickBarProps> = ({ onOpenQuote }) => {
  return (
    <div className="md:hidden fixed bottom-0 left-0 right-0 z-30 bg-[#034F4B]/95 backdrop-blur-md border-t border-[#056D67] p-2.5 shadow-2xl safe-area-pb">
      <div className="grid grid-cols-3 gap-2 max-w-md mx-auto">
        
        {/* Direct Phone Call */}
        <a
          href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`}
          className="min-h-[44px] flex flex-col items-center justify-center rounded-xl bg-white/10 hover:bg-white/20 text-white text-[11px] font-bold transition-all border border-white/15 active:scale-95"
          aria-label="Call i Man Service Helpline"
        >
          <Phone className="w-4 h-4 text-[#C1F24F] mb-0.5" />
          <span>Call Desk</span>
        </a>

        {/* WhatsApp Chat */}
        <a
          href={COMPANY_INFO.whatsappLink || 'https://wa.me/923149020008'}
          target="_blank"
          rel="noopener noreferrer"
          className="min-h-[44px] flex flex-col items-center justify-center rounded-xl bg-white/10 hover:bg-white/20 text-white text-[11px] font-bold transition-all border border-white/15 active:scale-95"
          aria-label="Chat with i Man Service on WhatsApp"
        >
          <MessageSquare className="w-4 h-4 text-[#C1F24F] mb-0.5" />
          <span>WhatsApp</span>
        </a>

        {/* Instant Quote / Proposal */}
        <button
          type="button"
          onClick={onOpenQuote}
          className="min-h-[44px] flex flex-col items-center justify-center rounded-xl bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] text-[11px] font-extrabold transition-all shadow-md active:scale-95"
          aria-label="Request IT Proposal"
        >
          <ShieldCheck className="w-4 h-4 text-[#034F4B] mb-0.5" />
          <span>Get Proposal</span>
        </button>

      </div>
    </div>
  );
};
