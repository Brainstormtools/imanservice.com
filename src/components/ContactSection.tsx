import React, { useState } from 'react';
import { COMPANY_INFO } from '../data/companyData';
import { 
  Phone, 
  MapPin, 
  Globe, 
  Clock, 
  Send, 
  CheckCircle, 
  Building2, 
  ShieldCheck,
  MessageSquare,
  AlertCircle,
  Check
} from 'lucide-react';
import { Link } from '../router/Router';
import confetti from 'canvas-confetti';

export const ContactSection: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [subject, setSubject] = useState('Existing Network Audit');
  const [message, setMessage] = useState('');
  const [honeypot, setHoneypot] = useState('');
  
  const [submitted, setSubmitted] = useState(false);
  const [deliveryConfirmedAt, setDeliveryConfirmedAt] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMessage(null);
    setValidationErrors({});

    try {
      const payload = {
        fullName: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        category: subject,
        message: message.trim(),
        honeypot
      };

      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await res.json();

      if (!res.ok || !data.success) {
        if (data.errors) {
          setValidationErrors(data.errors);
        }
        throw new Error(data.message || 'Delivery to consultation dispatch failed. Please call our Lahore desk.');
      }

      // Delivery confirmed by webhook response
      setDeliveryConfirmedAt(data.receivedAt || new Date().toISOString());
      setSubmitted(true);
      try {
        confetti({
          particleCount: 50,
          spread: 60,
          origin: { y: 0.7 }
        });
      } catch (err) {
        // decorative
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Delivery failure: Unable to dispatch enquiry to our backend. Please call our hotline directly.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <section id="contact" className="scroll-mt-[140px] py-16 sm:py-20 bg-[#F4FAF8]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-12 sm:mb-14">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white border border-[#056D67]/20 text-[#056D67] text-xs font-bold uppercase tracking-wider mb-2">
            <Building2 className="w-3.5 h-3.5 text-[#056D67]" />
            <span>Lahore Technology Operations Hub</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display">
            Contact i Man Service
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
                
                {/* Mobile / WhatsApp */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Phone className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs uppercase font-bold text-slate-300">Mobile & WhatsApp Helpline</div>
                    <a 
                      href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`} 
                      className="text-base font-extrabold text-[#C1F24F] hover:underline min-h-[44px] inline-flex items-center"
                    >
                      {COMPANY_INFO.phone}
                    </a>
                    <div className="text-xs text-slate-200">Available 24/7 for On-Site & SLA Dispatch</div>
                  </div>
                </div>

                {/* Address */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <MapPin className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs uppercase font-bold text-slate-300">Physical Address</div>
                    <address className="not-italic font-bold text-white leading-snug">{COMPANY_INFO.address}</address>
                  </div>
                </div>

                {/* Website */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Globe className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs uppercase font-bold text-slate-300">Official Web Portal</div>
                    <Link 
                      to="/"
                      className="font-bold text-white hover:text-[#C1F24F] underline min-h-[44px] inline-flex items-center"
                    >
                      {COMPANY_INFO.website}
                    </Link>
                  </div>
                </div>

                {/* Hours */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0 text-[#C1F24F]">
                    <Clock className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs uppercase font-bold text-slate-300">Operating Hours</div>
                    <div className="font-medium text-slate-100">{COMPANY_INFO.hours}</div>
                  </div>
                </div>

              </div>

              {/* Direct WhatsApp / Hotline Dual Action CTAs */}
              <div className="mt-6 pt-5 border-t border-white/15 grid grid-cols-1 sm:grid-cols-2 gap-3">
                <a
                  href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`}
                  className="w-full min-h-[44px] py-2.5 px-3 rounded-xl bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-xs sm:text-sm transition-all flex items-center justify-center gap-2 text-center"
                >
                  <Phone className="w-4 h-4" />
                  <span>Call {COMPANY_INFO.phone}</span>
                </a>
                <a
                  href={COMPANY_INFO.whatsappLink || 'https://wa.me/923149020008'}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full min-h-[44px] py-2.5 px-3 rounded-xl bg-white/15 hover:bg-white/25 text-white font-bold text-xs sm:text-sm border border-white/30 transition-all flex items-center justify-center gap-2 text-center"
                >
                  <MessageSquare className="w-4 h-4 text-[#C1F24F]" />
                  <span>Chat on WhatsApp</span>
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
                <div className="text-slate-500 mt-0.5">On-site engineers available for fast physical dispatch across Lahore industrial & commercial districts.</div>
              </div>
            </div>

          </div>

          {/* Right: Interactive Message Form (Col 6-12) */}
          <div className="lg:col-span-7 bg-white rounded-2xl p-6 sm:p-8 border border-slate-200 shadow-sm">
            
            {!submitted ? (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <h3 className="text-xl font-bold text-slate-900 font-display">
                    Send Us an Enquiry
                  </h3>
                  <p className="text-xs sm:text-sm text-slate-500 mt-1">
                    Fill out the form below and an infrastructure consultant will respond within 2–4 business hours.
                  </p>
                </div>

                {/* Delivery Failure or Validation Error Banner */}
                {errorMessage && (
                  <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs sm:text-sm flex items-start gap-2.5">
                    <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <strong className="block font-bold text-rose-900">Delivery Notification</strong>
                      <span>{errorMessage}</span>
                    </div>
                  </div>
                )}

                {/* Honeypot field */}
                <div className="hidden" aria-hidden="true">
                  <label htmlFor="contact_website">Leave this field blank</label>
                  <input
                    type="text"
                    id="contact_website"
                    name="honeypot"
                    tabIndex={-1}
                    autoComplete="off"
                    value={honeypot}
                    onChange={(e) => setHoneypot(e.target.value)}
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="contact-full-name" className="block text-xs font-semibold text-slate-700 mb-1">
                      Full Name *
                    </label>
                    <input
                      type="text"
                      id="contact-full-name"
                      name="fullName"
                      required
                      autoComplete="name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="e.g. Bilal Liaqat"
                      className={`w-full min-h-[44px] px-3.5 py-2.5 rounded-lg border text-xs sm:text-sm focus:outline-hidden focus:ring-1 ${
                        validationErrors.fullName
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                    {validationErrors.fullName && (
                      <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.fullName}</span>
                    )}
                  </div>

                  <div>
                    <label htmlFor="contact-phone" className="block text-xs font-semibold text-slate-700 mb-1">
                      Phone Number *
                    </label>
                    <input
                      type="tel"
                      id="contact-phone"
                      name="phone"
                      required
                      autoComplete="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="e.g. +92 314 9020008"
                      className={`w-full min-h-[44px] px-3.5 py-2.5 rounded-lg border text-xs sm:text-sm focus:outline-hidden focus:ring-1 ${
                        validationErrors.phone
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                    {validationErrors.phone && (
                      <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.phone}</span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="contact-email" className="block text-xs font-semibold text-slate-700 mb-1">
                      Corporate Email *
                    </label>
                    <input
                      type="email"
                      id="contact-email"
                      name="email"
                      required
                      autoComplete="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="name@company.com"
                      className={`w-full min-h-[44px] px-3.5 py-2.5 rounded-lg border text-xs sm:text-sm focus:outline-hidden focus:ring-1 ${
                        validationErrors.email
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                    {validationErrors.email && (
                      <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.email}</span>
                    )}
                  </div>

                  <div>
                    <label htmlFor="contact-category" className="block text-xs font-semibold text-slate-700 mb-1">
                      Enquiry Category
                    </label>
                    <select
                      id="contact-category"
                      name="category"
                      value={subject}
                      onChange={(e) => setSubject(e.target.value)}
                      className="w-full min-h-[44px] px-3 py-2.5 rounded-lg border border-slate-200 text-xs sm:text-sm focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] bg-white"
                    >
                      <option value="Existing Network Audit">1. Existing Network Audit</option>
                      <option value="IT-AMC / SLA Contract">2. IT-AMC / SLA Maintenance</option>
                      <option value="IT Consultancy Service">3. Strategic IT Consultancy</option>
                      <option value="Emergency Network Repair">Urgent Incident / Emergency</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label htmlFor="contact-message" className="block text-xs font-semibold text-slate-700 mb-1">
                    Message / Project Details *
                  </label>
                  <textarea
                    id="contact-message"
                    name="message"
                    rows={4}
                    required
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Tell us about your IT setup, pain points, or timeline..."
                    className={`w-full px-3.5 py-2.5 rounded-lg border text-xs sm:text-sm focus:outline-hidden focus:ring-1 ${
                      validationErrors.message
                        ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                        : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                    }`}
                  />
                  {validationErrors.message && (
                    <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.message}</span>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full min-h-[48px] py-3 px-4 rounded-xl bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs sm:text-sm transition-all flex items-center justify-center gap-2 shadow-xs disabled:opacity-50"
                >
                  {loading ? (
                    <span>Delivering to Consultation Dispatch...</span>
                  ) : (
                    <>
                      <Send className="w-4 h-4 text-[#C1F24F]" />
                      <span>Request IT Proposal</span>
                    </>
                  )}
                </button>

                <div className="pt-2 text-center text-xs text-slate-500 space-y-1">
                  <p>
                    Your details will only be used to respond to your enquiry and will not be sold or shared with unauthorised third parties.
                  </p>
                  <p className="text-xs text-slate-400">
                    By submitting, you agree to our <Link to="/privacy-policy" className="underline hover:text-[#056D67]">Privacy Policy</Link> and <Link to="/terms-and-conditions" className="underline hover:text-[#056D67]">Terms & Conditions</Link>.
                  </p>
                </div>
              </form>
            ) : (
              <div className="text-center py-8 space-y-4">
                <div className="w-16 h-16 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200 flex items-center justify-center mx-auto shadow-xs">
                  <CheckCircle className="w-9 h-9" />
                </div>
                
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100/80 text-emerald-800 text-xs font-bold uppercase tracking-wider">
                  <Check className="w-3.5 h-3.5" />
                  <span>Webhook Delivery Confirmed</span>
                </div>

                <h4 className="text-2xl font-bold text-slate-900 font-display">
                  Enquiry Dispatched Successfully
                </h4>
                
                <p className="text-sm text-slate-600 max-w-md mx-auto leading-relaxed">
                  Thank you, <strong>{name}</strong>. Your consultation enquiry has been confirmed and routed to our Lahore engineering dispatch team. We will reach out via <strong>{email || phone}</strong> shortly.
                </p>

                {deliveryConfirmedAt && (
                  <div className="p-3 rounded-lg bg-[#F4FAF8] border border-slate-200 text-xs text-slate-500 max-w-sm mx-auto">
                    Confirmed Dispatch Time: {new Date(deliveryConfirmedAt).toLocaleString()}
                  </div>
                )}

                <div className="pt-4">
                  <button
                    type="button"
                    onClick={() => {
                      setSubmitted(false);
                      setMessage('');
                    }}
                    className="text-xs font-bold text-[#056D67] hover:underline min-h-[44px] px-4 py-2 inline-flex items-center"
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
