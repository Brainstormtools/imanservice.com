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
  Sparkles,
  MessageSquare
} from 'lucide-react';
import { Link, useRouter } from '../router/Router';

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
  const { path } = useRouter();

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

  // Close mobile menu on escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && mobileMenuOpen) {
        setMobileMenuOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [mobileMenuOpen]);

  const navLinks = [
    { label: 'Network Audit', href: '/network-audit' },
    { label: 'IT-AMC / SLA', href: '/it-amc-sla' },
    { label: 'IT Consultancy', href: '/it-consultancy' },
    { label: 'About Us', href: '/about' },
    { label: 'Contact', href: '/contact' },
  ];

  return (
    <>
      {/* 1. Accessible Skip to Main Content Link */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:p-3 focus:bg-[#056D67] focus:text-white focus:font-bold focus:rounded-lg focus:shadow-2xl focus:outline-hidden"
      >
        Skip to main content
      </a>

      <header className="sticky top-0 z-40 w-full transition-all duration-200">
        {/* Top Corporate Info Bar */}
        <div className="bg-[#034F4B] text-white text-xs py-1 px-3 sm:px-4 border-b border-[#056D67]">
          <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-1 sm:gap-3">
            <div className="flex items-center gap-1 sm:gap-3 flex-wrap">
              <a 
                href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`} 
                className="min-h-[44px] inline-flex items-center gap-1.5 font-medium hover:text-[#C1F24F] transition-colors px-2 py-1 rounded focus:outline-hidden focus:ring-1 focus:ring-[#C1F24F]"
                id="topbar-phone-link"
                aria-label="Call i Man Service Helpline"
              >
                <Phone className="w-3.5 h-3.5 text-[#C1F24F] flex-shrink-0" />
                <span className="text-xs font-semibold">{COMPANY_INFO.phone}</span>
              </a>
              <span className="text-slate-500 hidden sm:inline">•</span>
              <a 
                href={COMPANY_INFO.whatsappLink || 'https://wa.me/923149020008'} 
                target="_blank"
                rel="noopener noreferrer"
                className="min-h-[44px] inline-flex items-center gap-1.5 font-medium text-[#C1F24F] hover:underline transition-colors px-2 py-1 rounded focus:outline-hidden focus:ring-1 focus:ring-[#C1F24F]"
                id="topbar-whatsapp-link"
                aria-label="Chat with i Man Service on WhatsApp"
              >
                <MessageSquare className="w-3.5 h-3.5 text-[#C1F24F] flex-shrink-0" />
                <span className="text-xs font-semibold">WhatsApp</span>
              </a>
              <span className="hidden md:inline text-slate-500">•</span>
              <address className="not-italic hidden md:flex items-center gap-1.5 text-slate-300 text-xs">
                <MapPin className="w-3.5 h-3.5 text-[#C1F24F] flex-shrink-0" />
                <span className="truncate max-w-[280px] lg:max-w-none">{COMPANY_INFO.address}</span>
              </address>
            </div>

            <div className="flex items-center gap-2 sm:gap-3 ml-auto">
              <button
                type="button"
                onClick={onOpenQuiz}
                id="nav-readiness-quiz-btn"
                className="min-h-[44px] inline-flex items-center justify-center gap-1.5 text-xs font-bold text-[#034F4B] bg-[#C1F24F] hover:bg-[#D8FA8A] px-3 py-1.5 rounded-md transition-colors shadow-xs focus:outline-hidden focus:ring-2 focus:ring-white"
                aria-label="Run Free IT Health Check"
              >
                <Sparkles className="w-3.5 h-3.5 text-[#034F4B] flex-shrink-0" />
                <span className="hidden xs:inline">Run Free IT Health Check</span>
                <span className="xs:hidden">Health Check</span>
              </button>
              <button
                type="button"
                onClick={onOpenChecklist}
                id="nav-audit-checklist-btn"
                className="hidden lg:inline-flex items-center gap-1.5 text-xs font-medium text-slate-200 hover:text-white transition-colors min-h-[44px] px-2.5 rounded focus:outline-hidden focus:ring-1 focus:ring-white"
                aria-label="Open Audit Checklist"
              >
                <FileText className="w-3.5 h-3.5 text-[#C1F24F] flex-shrink-0" />
                <span>Audit Checklist</span>
              </button>
            </div>
          </div>
        </div>

        {/* Main Navbar */}
        <nav 
          aria-label="Main Navigation"
          className={`w-full transition-all duration-300 ${
            isScrolled 
              ? 'bg-white/95 backdrop-blur-md shadow-md border-b border-slate-200/80 py-2 sm:py-2.5' 
              : 'bg-white py-2.5 sm:py-3 border-b border-slate-100'
          }`}
        >
          <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 flex items-center justify-between">
            
            {/* Logo Links to Homepage */}
            <Link 
              to="/" 
              className="flex items-center focus:outline-hidden min-h-[44px] flex-shrink-0" 
              id="nav-brand-logo"
              aria-label="i Man Service Homepage"
            >
              <Logo size="md" showTagline={false} />
            </Link>

            {/* Desktop Nav Links */}
            <div className="hidden lg:flex items-center gap-6 text-sm font-medium text-slate-700">
              {navLinks.map((link) => {
                const isActive = path === link.href;
                return (
                  <Link
                    key={link.label}
                    to={link.href}
                    className={`transition-colors py-2 px-1 relative group min-h-[44px] flex items-center ${
                      isActive ? 'text-[#056D67] font-bold' : 'hover:text-[#056D67]'
                    }`}
                  >
                    {link.label}
                    <span 
                      className={`absolute bottom-1 left-0 h-0.5 bg-[#056D67] transition-all duration-200 ${
                        isActive ? 'w-full' : 'w-0 group-hover:w-full'
                      }`} 
                    />
                  </Link>
                );
              })}
            </div>

            {/* Action CTAs (Desktop) */}
            <div className="hidden lg:flex items-center gap-3">
              <Link
                to="/it-amc-sla#interactive-estimator"
                className="inline-flex items-center gap-1.5 px-3.5 py-2 min-h-[44px] rounded-lg border border-slate-200 text-slate-700 hover:border-[#056D67] hover:text-[#056D67] font-medium text-xs transition-all"
                id="nav-sla-calc-link"
              >
                <Calculator className="w-4 h-4 text-[#056D67]" />
                <span>SLA Estimator</span>
              </Link>

              <button
                type="button"
                onClick={() => onOpenQuote('all')}
                id="nav-get-quote-cta"
                className="inline-flex items-center gap-2 px-4 py-2 min-h-[44px] rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs sm:text-sm transition-all shadow-xs group focus:outline-hidden focus:ring-2 focus:ring-[#056D67]"
              >
                <ShieldCheck className="w-4 h-4 text-[#C1F24F]" />
                <span>Request IT Proposal</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
              </button>
            </div>

            {/* Mobile Controls */}
            <div className="flex lg:hidden items-center gap-2">
              <button
                type="button"
                onClick={() => onOpenQuote('all')}
                className="inline-flex items-center justify-center gap-1.5 px-3 py-2 min-h-[44px] rounded-lg bg-[#056D67] text-white text-xs font-bold shadow-xs hover:bg-[#034F4B] transition-colors"
                id="mobile-quick-quote-btn"
              >
                <ShieldCheck className="w-3.5 h-3.5 text-[#C1F24F]" />
                <span>Request IT Proposal</span>
              </button>
              
              <button
                type="button"
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="min-w-[44px] min-h-[44px] p-2 rounded-lg text-slate-700 hover:text-[#056D67] hover:bg-slate-100 flex items-center justify-center transition-colors focus:outline-hidden focus:ring-2 focus:ring-[#056D67]"
                aria-label={mobileMenuOpen ? 'Close Navigation Menu' : 'Open Navigation Menu'}
                aria-expanded={mobileMenuOpen}
                aria-controls="mobile-nav-menu"
                id="mobile-nav-toggle-btn"
              >
                {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </button>
            </div>
          </div>

          {/* Mobile Dropdown Menu */}
          {mobileMenuOpen && (
            <div 
              id="mobile-nav-menu"
              className="lg:hidden bg-white border-t border-slate-200 px-4 pt-3 pb-6 shadow-xl animate-in slide-in-from-top duration-200 max-h-[85vh] overflow-y-auto"
            >
              <div className="flex flex-col space-y-1">
                <Link
                  to="/"
                  onClick={() => setMobileMenuOpen(false)}
                  className={`min-h-[44px] px-3.5 py-2.5 rounded-lg text-base font-medium flex items-center transition-colors ${
                    path === '/' ? 'bg-[#F4FAF8] text-[#056D67] font-bold' : 'text-slate-800 hover:bg-[#F4FAF8]'
                  }`}
                >
                  Home
                </Link>

                {navLinks.map((link) => {
                  const isActive = path === link.href;
                  return (
                    <Link
                      key={link.label}
                      to={link.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`min-h-[44px] px-3.5 py-2.5 rounded-lg text-base font-medium flex items-center transition-colors ${
                        isActive ? 'bg-[#F4FAF8] text-[#056D67] font-bold' : 'text-slate-800 hover:bg-[#F4FAF8]'
                      }`}
                    >
                      {link.label}
                    </Link>
                  );
                })}
                
                <div className="pt-4 mt-2 border-t border-slate-100 flex flex-col gap-3">
                  <button
                    type="button"
                    onClick={() => {
                      setMobileMenuOpen(false);
                      onOpenQuiz();
                    }}
                    className="w-full min-h-[44px] flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-[#F4FAF8] text-[#034F4B] border border-[#056D67]/20 font-bold text-xs hover:bg-[#EAF5F2] transition-colors"
                  >
                    <Sparkles className="w-4 h-4 text-[#056D67]" />
                    <span>Run Free IT Health Check</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setMobileMenuOpen(false);
                      onOpenQuote('all');
                    }}
                    className="w-full min-h-[44px] flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-[#056D67] text-white font-bold text-xs hover:bg-[#034F4B] transition-colors shadow-xs"
                  >
                    <ShieldCheck className="w-4 h-4 text-[#C1F24F]" />
                    <span>Request IT Proposal</span>
                  </button>
                </div>
              </div>
            </div>
          )}
        </nav>
      </header>
    </>
  );
};
