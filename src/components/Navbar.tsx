import React, { useState, useEffect } from 'react';
import { Logo } from './Logo';
import { COMPANY_INFO } from '../data/companyData';
import { 
  Phone, 
  MapPin, 
  Globe, 
  ShieldCheck, 
  Menu, 
  X, 
  Calculator, 
  FileText, 
  ArrowRight,
  Sparkles
} from 'lucide-react';

interface NavbarProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
  onOpenQuiz: () => void;
  onOpenChecklist: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onOpenQuote,
  onOpenQuiz,
  onOpenChecklist
}) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 20) {
        setIsScrolled(true);
      } else {
        setIsScrolled(false);
      }
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { label: 'Overview', href: '#overview' },
    { label: 'Network Audit', href: '#network-audit' },
    { label: 'IT-AMC / SLA', href: '#it-amc' },
    { label: 'IT Consultancy', href: '#it-consultancy' },
    { label: 'SLA Calculator', href: '#sla-calculator' },
    { label: 'About Us', href: '#about' },
    { label: 'Contact', href: '#contact' },
  ];

  return (
    <header className="sticky top-0 z-40 w-full transition-all duration-200">
      {/* Top Corporate Info Bar */}
      <div className="bg-[#034F4B] text-white text-xs py-2 px-4 border-b border-[#056D67]">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-4 flex-wrap">
            <a 
              href={`tel:${COMPANY_INFO.phone}`} 
              className="flex items-center gap-1.5 font-medium hover:text-[#C1F24F] transition-colors"
              id="topbar-phone-link"
            >
              <Phone className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>{COMPANY_INFO.phone}</span>
            </a>
            <span className="hidden sm:inline text-slate-500">•</span>
            <div className="hidden md:flex items-center gap-1.5 text-slate-300">
              <MapPin className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>{COMPANY_INFO.address}</span>
            </div>
            <span className="hidden md:inline text-slate-500">•</span>
            <div className="hidden lg:flex items-center gap-1.5 text-slate-300">
              <Globe className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>{COMPANY_INFO.website}</span>
            </div>
          </div>

          <div className="flex items-center gap-3 ml-auto">
            <button
              onClick={onOpenQuiz}
              id="nav-readiness-quiz-btn"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#034F4B] bg-[#C1F24F] hover:bg-[#D8FA8A] px-2.5 py-1 rounded transition-colors shadow-xs"
            >
              <Sparkles className="w-3 h-3 text-[#034F4B]" />
              <span>Free IT Health Check</span>
            </button>
            <button
              onClick={onOpenChecklist}
              id="nav-audit-checklist-btn"
              className="hidden sm:inline-flex items-center gap-1 text-xs text-slate-200 hover:text-white transition-colors"
            >
              <FileText className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Audit Checklist</span>
            </button>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <nav 
        className={`w-full transition-all duration-300 ${
          isScrolled 
            ? 'bg-white/95 backdrop-blur-md shadow-md border-b border-slate-200/80 py-3' 
            : 'bg-white py-4 border-b border-slate-100'
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between">
          <a href="#" className="flex items-center focus:outline-hidden" id="nav-brand-logo">
            <Logo size="md" showTagline={false} />
          </a>

          {/* Desktop Nav Links */}
          <div className="hidden xl:flex items-center gap-6 text-sm font-medium text-slate-700">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                className="hover:text-[#056D67] transition-colors py-1 relative group"
              >
                {link.label}
                <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-[#056D67] transition-all duration-200 group-hover:w-full" />
              </a>
            ))}
          </div>

          {/* Action CTAs */}
          <div className="hidden sm:flex items-center gap-3">
            <a
              href="#sla-calculator"
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg border border-slate-200 text-slate-700 hover:border-[#056D67] hover:text-[#056D67] font-medium text-sm transition-all"
              id="nav-sla-calc-link"
            >
              <Calculator className="w-4 h-4 text-[#056D67]" />
              <span>SLA Estimator</span>
            </a>

            <button
              onClick={() => onOpenQuote('all')}
              id="nav-get-quote-cta"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-semibold text-sm transition-all shadow-sm group"
            >
              <ShieldCheck className="w-4 h-4 text-[#C1F24F]" />
              <span>Request IT Proposal</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
            </button>
          </div>

          {/* Mobile Menu Button */}
          <div className="flex xl:hidden items-center gap-2">
            <button
              onClick={() => onOpenQuote('all')}
              className="sm:hidden px-3 py-1.5 rounded-md bg-[#056D67] text-white text-xs font-semibold"
            >
              Quote
            </button>
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-700 hover:text-[#056D67] hover:bg-slate-100 transition-colors"
              aria-label="Toggle Menu"
              id="mobile-nav-toggle-btn"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown */}
        {mobileMenuOpen && (
          <div className="xl:hidden bg-white border-t border-slate-200 px-4 pt-3 pb-6 shadow-xl animate-in slide-in-from-top duration-200">
            <div className="flex flex-col space-y-3">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="px-3 py-2 rounded-md text-base font-medium text-slate-800 hover:bg-[#F4FAF8] hover:text-[#056D67]"
                >
                  {link.label}
                </a>
              ))}
              <div className="pt-3 border-t border-slate-100 flex flex-col gap-2.5">
                <button
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onOpenQuiz();
                  }}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-[#F4FAF8] text-[#034F4B] border border-[#056D67]/20 font-semibold text-sm"
                >
                  <Sparkles className="w-4 h-4 text-[#056D67]" />
                  <span>Take Free IT Health Quiz</span>
                </button>
                <button
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onOpenQuote('all');
                  }}
                  className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-[#056D67] text-white font-semibold text-sm"
                >
                  <ShieldCheck className="w-4 h-4 text-[#C1F24F]" />
                  <span>Request Custom IT Proposal</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
};
