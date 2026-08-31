import React, { useState, useEffect, useRef } from 'react';
import { 
  X, 
  ShieldCheck, 
  Send, 
  Phone, 
  Building, 
  User, 
  Mail, 
  MessageSquare, 
  CheckCircle, 
  PhoneCall,
  AlertCircle,
  Check
} from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';
import confetti from 'canvas-confetti';

interface QuoteModalProps {
  isOpen: boolean;
  initialService?: 'audit' | 'amc' | 'consultancy' | 'all';
  prefillData?: Record<string, any>;
  onClose: () => void;
}

export const QuoteModal: React.FC<QuoteModalProps> = ({
  isOpen,
  initialService = 'all',
  prefillData,
  onClose
}) => {
  const [serviceInterest, setServiceInterest] = useState<string>(initialService);
  const [companyName, setCompanyName] = useState<string>('');
  const [contactPerson, setContactPerson] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [phone, setPhone] = useState<string>('');
  const [workstations, setWorkstations] = useState<number>(20);
  const [servers, setServers] = useState<number>(2);
  const [urgency, setUrgency] = useState<string>('planned');
  const [notes, setNotes] = useState<string>('');
  const [honeypot, setHoneypot] = useState<string>('');
  
  const [isSubmitted, setIsSubmitted] = useState<boolean>(false);
  const [deliveryConfirmedAt, setDeliveryConfirmedAt] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  const modalRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLElement | null>(null);

  // Sync state on open
  useEffect(() => {
    if (isOpen) {
      triggerRef.current = document.activeElement as HTMLElement;
      document.body.style.overflow = 'hidden';
      
      if (initialService) {
        setServiceInterest(initialService);
      }
      if (prefillData) {
        if (prefillData.workstationsCount) setWorkstations(prefillData.workstationsCount);
        if (prefillData.serversCount) setServers(prefillData.serversCount);
        if (prefillData.notes) setNotes(prefillData.notes);
      }
      setIsSubmitted(false);
      setErrorMessage(null);
      setValidationErrors({});
    } else {
      document.body.style.overflow = '';
      if (triggerRef.current) {
        triggerRef.current.focus();
      }
    }

    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen, initialService, prefillData]);

  // Trap focus and handle escape
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
        return;
      }

      if (e.key === 'Tab' && modalRef.current) {
        const focusableElements = modalRef.current.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        if (focusableElements.length === 0) return;

        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault();
            lastElement.focus();
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault();
            firstElement.focus();
          }
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMessage(null);
    setValidationErrors({});

    try {
      const payload = {
        serviceDomain: serviceInterest,
        companyName: companyName.trim(),
        contactPerson: contactPerson.trim(),
        email: email.trim(),
        phone: phone.trim(),
        workstations: Number(workstations),
        servers: Number(servers),
        timeline: urgency,
        notes: notes.trim(),
        honeypot
      };

      const res = await fetch('/api/proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await res.json();

      if (!res.ok || !data.success) {
        if (data.errors) {
          setValidationErrors(data.errors);
        }
        throw new Error(data.message || 'Delivery failure: Proposal request could not be dispatched.');
      }

      setDeliveryConfirmedAt(data.receivedAt || new Date().toISOString());
      setIsSubmitted(true);
      try {
        confetti({
          particleCount: 70,
          spread: 80,
          origin: { y: 0.6 }
        });
      } catch (err) {
        // Confetti is decorative
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Delivery failure: A network error occurred while routing your proposal request. Please call us directly.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleReset = () => {
    setIsSubmitted(false);
    onClose();
  };

  return (
    <div 
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-xs animate-in fade-in duration-200"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div 
        ref={modalRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="proposal-modal-heading"
        aria-describedby="proposal-modal-desc"
        className="bg-white rounded-2xl max-w-2xl w-full p-6 sm:p-8 shadow-2xl border border-slate-100 relative max-h-[92vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        
        {/* Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute top-4 right-4 min-w-[44px] min-h-[44px] flex items-center justify-center rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors focus:outline-hidden focus:ring-2 focus:ring-[#056D67]"
          aria-label="Close proposal dialog"
        >
          <X className="w-5 h-5" />
        </button>

        {!isSubmitted ? (
          <div>
            {/* Header */}
            <div className="mb-6 border-b border-slate-100 pb-4 pr-10">
              <div className="flex items-center gap-2 text-xs font-bold text-[#056D67] uppercase tracking-wider mb-1">
                <ShieldCheck className="w-4 h-4 text-[#056D67]" />
                <span>Executive IT Proposal Request</span>
              </div>
              <h2 id="proposal-modal-heading" className="text-2xl font-bold text-slate-900 font-display">
                Request IT Infrastructure Proposal
              </h2>
              <p id="proposal-modal-desc" className="text-xs sm:text-sm text-slate-500 mt-1">
                Tell us about your organisation's IT requirements. Our engineers will prepare a formal scope &amp; SLA proposal within 24 hours.
              </p>
            </div>

            {/* Error Banner */}
            {errorMessage && (
              <div className="mb-4 p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs sm:text-sm flex items-start gap-2.5">
                <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0 mt-0.5" />
                <div>
                  <strong className="block font-bold text-rose-900">Delivery Notification</strong>
                  <span>{errorMessage}</span>
                </div>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4 text-xs sm:text-sm">
              
              {/* Honeypot anti-spam field */}
              <div className="hidden" aria-hidden="true">
                <label htmlFor="proposal_website">Leave this field blank</label>
                <input
                  type="text"
                  id="proposal_website"
                  name="honeypot"
                  tabIndex={-1}
                  autoComplete="off"
                  value={honeypot}
                  onChange={(e) => setHoneypot(e.target.value)}
                />
              </div>

              {/* Service Selection */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-2">
                  Service Domain of Interest *
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { id: 'all', label: 'All 3 Pillars' },
                    { id: 'audit', label: 'Network Audit' },
                    { id: 'amc', label: 'IT-AMC / SLA' },
                    { id: 'consultancy', label: 'IT Consultancy' }
                  ].map((s) => (
                    <button
                      type="button"
                      key={s.id}
                      onClick={() => setServiceInterest(s.id)}
                      className={`min-h-[44px] p-2.5 rounded-lg border text-xs font-bold transition-all text-center flex items-center justify-center ${
                        serviceInterest === s.id
                          ? 'bg-[#056D67] text-white border-[#056D67] shadow-xs'
                          : 'bg-[#F4FAF8] text-slate-700 border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      {s.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* 2-Col Contact Info */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label htmlFor="modal_company" className="block text-xs font-semibold text-slate-700 mb-1">
                    Company Name *
                  </label>
                  <div className="relative">
                    <Building className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      id="modal_company"
                      type="text"
                      required
                      autoComplete="organization"
                      value={companyName}
                      onChange={(e) => setCompanyName(e.target.value)}
                      placeholder="e.g. Acme Enterprises Ltd."
                      className={`w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border focus:outline-hidden focus:ring-1 text-slate-800 ${
                        validationErrors.companyName
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                  </div>
                  {validationErrors.companyName && (
                    <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.companyName}</span>
                  )}
                </div>

                <div>
                  <label htmlFor="modal_name" className="block text-xs font-semibold text-slate-700 mb-1">
                    Contact Person Name *
                  </label>
                  <div className="relative">
                    <User className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      id="modal_name"
                      type="text"
                      required
                      autoComplete="name"
                      value={contactPerson}
                      onChange={(e) => setContactPerson(e.target.value)}
                      placeholder="e.g. Zeeshan Usmani"
                      className={`w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border focus:outline-hidden focus:ring-1 text-slate-800 ${
                        validationErrors.contactPerson
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                  </div>
                  {validationErrors.contactPerson && (
                    <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.contactPerson}</span>
                  )}
                </div>

                <div>
                  <label htmlFor="modal_email" className="block text-xs font-semibold text-slate-700 mb-1">
                    Business Email Address *
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      id="modal_email"
                      type="email"
                      required
                      autoComplete="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="it@yourcompany.com"
                      className={`w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border focus:outline-hidden focus:ring-1 text-slate-800 ${
                        validationErrors.email
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                  </div>
                  {validationErrors.email && (
                    <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.email}</span>
                  )}
                </div>

                <div>
                  <label htmlFor="modal_phone" className="block text-xs font-semibold text-slate-700 mb-1">
                    Phone / Mobile Number *
                  </label>
                  <div className="relative">
                    <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      id="modal_phone"
                      type="tel"
                      required
                      autoComplete="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="e.g. +92 314 9020008"
                      className={`w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border focus:outline-hidden focus:ring-1 text-slate-800 ${
                        validationErrors.phone
                          ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/20'
                          : 'border-slate-200 focus:border-[#056D67] focus:ring-[#056D67]'
                      }`}
                    />
                  </div>
                  {validationErrors.phone && (
                    <span className="text-xs text-rose-600 font-medium mt-1 block">{validationErrors.phone}</span>
                  )}
                </div>
              </div>

              {/* Asset Numbers & Timeline */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 bg-[#F4FAF8] p-3.5 rounded-xl border border-slate-200/80">
                <div>
                  <label htmlFor="modal_workstations" className="block text-xs font-semibold text-slate-700 mb-1">
                    Approx. Workstations
                  </label>
                  <input
                    id="modal_workstations"
                    type="number"
                    min="1"
                    value={workstations}
                    onChange={(e) => setWorkstations(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-md border border-slate-200 bg-white text-slate-800 font-semibold text-sm"
                  />
                </div>

                <div>
                  <label htmlFor="modal_servers" className="block text-xs font-semibold text-slate-700 mb-1">
                    Approx. Servers
                  </label>
                  <input
                    id="modal_servers"
                    type="number"
                    min="0"
                    value={servers}
                    onChange={(e) => setServers(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-md border border-slate-200 bg-white text-slate-800 font-semibold text-sm"
                  />
                </div>

                <div>
                  <label htmlFor="modal_timeline" className="block text-xs font-semibold text-slate-700 mb-1">
                    Implementation Timeline
                  </label>
                  <select
                    id="modal_timeline"
                    value={urgency}
                    onChange={(e) => setUrgency(e.target.value)}
                    className="w-full min-h-[44px] px-2 py-2 rounded-md border border-slate-200 bg-white text-slate-800 text-xs font-semibold"
                  >
                    <option value="urgent">Immediate / Emergency</option>
                    <option value="planned">Within 30 Days</option>
                    <option value="exploring">Budget Planning / Q4</option>
                  </select>
                </div>
              </div>

              {/* Message / Scope Notes */}
              <div>
                <label htmlFor="modal_notes" className="block text-xs font-semibold text-slate-700 mb-1">
                  Specific Technical Requirements or Notes
                </label>
                <div className="relative">
                  <MessageSquare className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <textarea
                    id="modal_notes"
                    rows={3}
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Describe your current pain points (e.g. slow network throughput, need 24/7 server monitoring, upcoming cloud migration)..."
                    className="w-full pl-9 pr-3 py-2 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                  />
                </div>
              </div>

              {/* Privacy Reassurance */}
              <div className="p-2.5 rounded-lg bg-slate-50 border border-slate-200 text-xs text-slate-600 flex items-start gap-2">
                <ShieldCheck className="w-4 h-4 text-[#056D67] flex-shrink-0 mt-0.5" />
                <span>
                  Your details will only be used to formulate your proposal and will not be sold or shared with unauthorised third parties.
                </span>
              </div>

              {/* Submit Button */}
              <div className="pt-2">
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full min-h-[48px] py-3 px-4 rounded-xl bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-sm transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {isSubmitting ? (
                    <span>Dispatching Proposal Request...</span>
                  ) : (
                    <>
                      <Send className="w-4 h-4 text-[#C1F24F]" />
                      <span>Request IT Proposal</span>
                    </>
                  )}
                </button>
              </div>

              <div className="text-center text-xs text-slate-500">
                Or call our Lahore desk directly at <strong>{COMPANY_INFO.phone}</strong> for urgent emergency assistance.
              </div>

            </form>
          </div>
        ) : (
          /* Confirmation View */
          <div className="text-center py-6">
            <div className="w-16 h-16 rounded-full bg-[#F4FAF8] border-2 border-[#056D67] flex items-center justify-center mx-auto mb-4 text-[#056D67]">
              <CheckCircle className="w-10 h-10" />
            </div>

            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold uppercase tracking-wider mb-2">
              <Check className="w-3.5 h-3.5" />
              <span>Proposal Dispatch Confirmed</span>
            </div>

            <h3 className="text-2xl font-bold text-slate-900 font-display mt-2">
              Thank You, {contactPerson || 'Valued Client'}!
            </h3>

            <p className="text-sm text-slate-600 mt-2 max-w-md mx-auto leading-relaxed">
              Your proposal request for <strong>{companyName || 'your organisation'}</strong> has been confirmed and routed to our Lahore Infrastructure Engineering Lead. We will contact you at <strong>{email || phone}</strong> with your customised scope.
            </p>

            {deliveryConfirmedAt && (
              <div className="mt-2 text-xs text-slate-400">
                Delivered to consultation desk: {new Date(deliveryConfirmedAt).toLocaleTimeString()}
              </div>
            )}

            <div className="mt-6 p-4 rounded-xl bg-[#F4FAF8] border border-slate-200 text-left text-xs text-slate-700 max-w-md mx-auto space-y-1.5">
              <div className="font-bold text-[#056D67] uppercase text-xs mb-1">
                Immediate Reference:
              </div>
              <div>• Service Pillar: <strong>{serviceInterest.toUpperCase()}</strong></div>
              <div>• Fleet Size: <strong>{workstations} Workstations &amp; {servers} Servers</strong></div>
              <div>• Official Lahore Office: <address className="not-italic inline font-bold text-slate-900">{COMPANY_INFO.address}</address></div>
              <div>• Direct Phone: <strong>{COMPANY_INFO.phone}</strong></div>
            </div>

            <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
              <a
                href={`tel:${COMPANY_INFO.phoneRaw || '+923149020008'}`}
                className="min-h-[44px] py-2.5 px-4 rounded-lg bg-[#056D67] text-white font-bold text-xs sm:text-sm flex items-center justify-center gap-2"
              >
                <PhoneCall className="w-4 h-4 text-[#C1F24F]" />
                <span>Call Dispatch Desk Now</span>
              </a>
              <button
                type="button"
                onClick={handleReset}
                className="min-h-[44px] py-2.5 px-4 rounded-lg border border-slate-300 hover:bg-slate-100 text-slate-700 font-semibold text-xs sm:text-sm transition-colors flex items-center justify-center"
              >
                Close Window
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
