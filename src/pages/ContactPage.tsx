import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { 
  Phone, 
  Mail, 
  MapPin, 
  Clock, 
  MessageSquare, 
  ShieldCheck, 
  ArrowRight,
  Sparkles
} from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';
import { ContactSection } from '../components/ContactSection';

export const ContactPage: React.FC = () => {
  const pageSchema = {
    "@context": "https://schema.org",
    "@type": "ContactPage",
    "name": "Contact i Man Service Lahore",
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
      "openingHoursSpecification": [
        {
          "@type": "OpeningHoursSpecification",
          "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
          "opens": "09:00",
          "closes": "19:00"
        }
      ]
    }
  };

  return (
    <>
      <SeoHead
        title="Contact i Man Service | IT Support Lahore"
        description="Contact i Man Service at Siddique Trade Center, Gulberg II, Lahore. Call +92 314 9020008 or request an IT infrastructure proposal."
        canonical="https://www.imanservice.com/contact"
        ogType="website"
        schema={pageSchema}
      />

      {/* Hero */}
      <section className="bg-gradient-to-b from-[#034F4B] to-[#056D67] text-white pt-12 pb-14 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10 pointer-events-none bg-[radial-gradient(#C1F24F_1px,transparent_1px)] [background-size:20px_20px]" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex flex-wrap items-center gap-2 text-xs text-slate-300">
              <li>
                <Link to="/" className="hover:text-[#C1F24F] transition-colors">Home</Link>
              </li>
              <li><span>/</span></li>
              <li className="text-[#C1F24F] font-semibold" aria-current="page">Contact</li>
            </ol>
          </nav>

          <div className="max-w-3xl space-y-3">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-[#C1F24F]/30 text-xs font-semibold text-[#D8FA8A]">
              <MapPin className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Lahore Help Desk & Inquiry Hub</span>
            </div>
            
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight">
              Get in Touch with i Man Service
            </h1>
            
            <p className="text-base sm:text-lg text-slate-200 leading-relaxed font-light">
              Speak directly with our senior infrastructure engineers in Gulberg II, Lahore. Submit an inquiry below or reach out directly via Phone or WhatsApp for rapid response.
            </p>
          </div>
        </div>
      </section>

      {/* Main Contact Section with Form and Map */}
      <ContactSection />
    </>
  );
};
