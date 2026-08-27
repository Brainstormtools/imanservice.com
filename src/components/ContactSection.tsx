import React, { useState } from 'react';
import { COMPANY_INFO } from '../data/companyData';
import { 
  Phone, 
  Mail, 
  MapPin, 
  Globe, 
  Clock, 
  Send, 
  CheckCircle, 
  Building2, 
  ShieldCheck,
  MessageSquare
} from 'lucide-react';
import confetti from 'canvas-confetti';

export const ContactSection: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [subject, setSubject] = useState('General IT Infrastructure Inquiry');
  const [message, setMessage] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setSubmitted(true);
      confetti({
        particleCount: 50,
        spread: 60,
        origin: { y: 0.7 }
      });
    }, 500);
  };

  return (
    <section id="contact" className="py-20 bg-[#F4FAF8]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-14">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white border border-[#056D67]/20 text-[#056D67] text-xs font-bold uppercase tracking-wider mb-2">
            <Building2 className="w-3.5 h-3.5 text-[#056D67]" />
            <span>Lahore Technology Operations Hub</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display">
            Contact IMAN SERVICE COMPANY
          </h2>
          <p className="text-slate-600 text-sm sm:text-base mt-2">
            Speak directly with our infrastructure specialists, book an on-site network audit, or activate emergency IT maintenance dispatch.
          </p>
        </div>

        {/* 2-Column Contact Container */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          
          {/* Left: Contact Info & Map Card (Col 1-5) */}
          <div className="lg:col-span-5 space-y-6">
            
            {/* Main Info Card */}
            <div className="bg-[#056D67] text-white rounded-2xl p-6 sm:p-7 shadow-lg relative overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-[#C1F24F]/10 rounded-full blur-2xl pointer-events-none" />
              
              <h3 className="text-xl font-bold font-display text-white mb-5">
                Headquarters & Dispatch Office
              </h3>

              <div className="space-y-4 text-xs sm:text-sm">
                
                {/* Phone */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Phone className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-slate-300">Direct Phone Line</div>
                    <a 
                      href={`tel:${COMPANY_INFO.phone}`} 
                      className="text-base font-extrabold text-[#C1F24F] hover:underline"
                    >
                      {COMPANY_INFO.phone}
                    </a>
                    <div className="text-[11px] text-slate-200">International: {COMPANY_INFO.phoneFormatted}</div>
                  </div>
                </div>

                {/* Address */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <MapPin className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-slate-300">Physical Address</div>
                    <div className="font-bold text-white leading-snug">{COMPANY_INFO.address}</div>
                    <div className="text-[11px] text-slate-200">{COMPANY_INFO.city}</div>
                  </div>
                </div>

                {/* Website */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Globe className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-slate-300">Official Web Portal</div>
                    <a 
                      href={`https://${COMPANY_INFO.website}`} 
                      target="_blank" 
                      rel="noopener noreferrer" 
                      className="font-bold text-white hover:text-[#C1F24F] underline"
                    >
                      {COMPANY_INFO.website}
                    </a>
                  </div>
                </div>

                {/* Hours */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Clock className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-slate-300">Operating Hours</div>
                    <div className="font-medium text-slate-100">{COMPANY_INFO.hours}</div>
                  </div>
                </div>

              </div>

              {/* Direct WhatsApp / Hotline CTA */}
              <div className="mt-6 pt-5 border-t border-white/15">
                <a
                  href={`tel:${COMPANY_INFO.phone}`}
                  className="w-full py-3 px-4 rounded-xl bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-xs sm:text-sm transition-all flex items-center justify-center gap-2 text-center"
                >
                  <Phone className="w-4 h-4" />
                  <span>Call {COMPANY_INFO.phone} Now</span>
                </a>
              </div>

            </div>

            {/* SLA Response Guarantee Badge */}
            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex items-center gap-4">
              <div className="w-10 h-10 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center text-[#056D67] flex-shrink-0">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div className="text-xs">
                <div className="font-bold text-slate-900">Lahore Rapid Response Fleet</div>
                <div className="text-slate-500 mt-0.5">Onsite engineers available for fast physical dispatch across Lahore industrial & commercial districts.</div>
              </div>
            </div>

          </div>

          {/* Right: Interactive Message Form (Col 6-12) */}
          <div className="lg:col-span-7 bg-white rounded-2xl p-6 sm:p-8 border border-slate-200 shadow-sm">
            
            {!submitted ? (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <h3 className="text-xl font-bold text-slate-900 font-display">
                    Send Us an Inquiry
                  </h3>
                  <p className="text-xs sm:text-sm text-slate-500 mt-1">
                    Fill out the form below and an infrastructure consultant will respond within 2–4 business hours.
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Full Name *
                    </label>
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="e.g. Bilal Liaqat"
                      className="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67]"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Phone Number *
                    </label>
                    <input
                      type="tel"
                      required
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="e.g. 0300-1234567"
                      className="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67]"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Corporate Email *
                    </label>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="name@company.com"
                      className="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67]"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Inquiry Category
                    </label>
                    <select
                      value={subject}
                      onChange={(e) => setSubject(e.target.value)}
                      className="w-full px-3 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] bg-white"
                    >
                      <option value="Existing Networks Audit">1. Existing Networks Audit</option>
                      <option value="IT-AMC / SLA Contract">2. IT-AMC / SLA Maintenance</option>
                      <option value="IT Consultancy Service">3. Strategic IT Consultancy</option>
                      <option value="Emergency Network Repair">Urgent Incident / Emergency</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Message / Project Details *
                  </label>
                  <textarea
                    rows={4}
                    required
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Tell us about your IT setup, pain points, or timeline..."
                    className="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67]"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 px-4 rounded-xl bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs sm:text-sm transition-all flex items-center justify-center gap-2 shadow-xs disabled:opacity-50"
                >
                  {loading ? (
                    <span>Sending Message...</span>
                  ) : (
                    <>
                      <Send className="w-4 h-4 text-[#C1F24F]" />
                      <span>Send Direct Message to IMAN Engineers</span>
                    </>
                  )}
                </button>
              </form>
            ) : (
              <div className="text-center py-10 space-y-4">
                <div className="w-14 h-14 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200 flex items-center justify-center mx-auto">
                  <CheckCircle className="w-8 h-8" />
                </div>
                <h4 className="text-2xl font-bold text-slate-900 font-display">
                  Message Sent Successfully!
                </h4>
                <p className="text-sm text-slate-600 max-w-md mx-auto">
                  Thank you, <strong>{name}</strong>. An IT consultant from our Lahore office has received your inquiry and will connect with you at <strong>{email || phone}</strong> shortly.
                </p>
                <div className="pt-4">
                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setMessage('');
                    }}
                    className="text-xs font-bold text-[#056D67] hover:underline"
                  >
                    Send Another Message
                  </button>
                </div>
              </div>
            )}

          </div>

        </div>

      </div>
    </section>
  );
};
