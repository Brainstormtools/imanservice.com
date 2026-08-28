import React, { useState, useEffect } from 'react';
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
  Sparkles,
  PhoneCall
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
  const [isSubmitted, setIsSubmitted] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  useEffect(() => {
    if (initialService) {
      setServiceInterest(initialService);
    }
    if (prefillData) {
      if (prefillData.workstationsCount) setWorkstations(prefillData.workstationsCount);
      if (prefillData.serversCount) setServers(prefillData.serversCount);
      if (prefillData.notes) setNotes(prefillData.notes);
    }
  }, [initialService, prefillData, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    setTimeout(() => {
      setIsSubmitting(false);
      setIsSubmitted(true);
      confetti({
        particleCount: 70,
        spread: 80,
        origin: { y: 0.6 }
      });
    }, 600);
  };

  const handleReset = () => {
    setIsSubmitted(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-2xl w-full p-6 sm:p-8 shadow-2xl border border-slate-100 relative max-h-[92vh] overflow-y-auto">
        
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 min-w-[44px] min-h-[44px] flex items-center justify-center rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors"
          aria-label="Close modal"
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
              <h3 className="text-2xl font-bold text-slate-900 font-display">
                Request Tailored IT Infrastructure Proposal
              </h3>
              <p className="text-xs sm:text-sm text-slate-500 mt-1">
                Tell us about your organization's IT requirements. Our engineers will prepare a formal scope & SLA proposal within 24 hours.
              </p>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4 text-xs sm:text-sm">
              
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
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Company Name *
                  </label>
                  <div className="relative">
                    <Building className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      type="text"
                      required
                      value={companyName}
                      onChange={(e) => setCompanyName(e.target.value)}
                      placeholder="e.g. Acme Enterprises Ltd."
                      className="w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Contact Person Name *
                  </label>
                  <div className="relative">
                    <User className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      type="text"
                      required
                      value={contactPerson}
                      onChange={(e) => setContactPerson(e.target.value)}
                      placeholder="e.g. Zeeshan Usmani / IT Manager"
                      className="w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Business Email Address *
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="it@yourcompany.com"
                      className="w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Phone / Mobile Number *
                  </label>
                  <div className="relative">
                    <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    <input
                      type="tel"
                      required
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="e.g. +92 314 9020008 or 0314-9020008"
                      className="w-full min-h-[44px] pl-9 pr-3 py-2.5 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                    />
                  </div>
                </div>
              </div>

              {/* Asset Numbers & Timeline */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 bg-[#F4FAF8] p-3.5 rounded-xl border border-slate-200/80">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Approx. Workstations
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={workstations}
                    onChange={(e) => setWorkstations(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-md border border-slate-200 bg-white text-slate-800 font-semibold text-sm"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Approx. Servers
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={servers}
                    onChange={(e) => setServers(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-md border border-slate-200 bg-white text-slate-800 font-semibold text-sm"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Implementation Timeline
                  </label>
                  <select
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
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Specific Technical Requirements or Notes
                </label>
                <div className="relative">
                  <MessageSquare className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <textarea
                    rows={3}
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Describe your current pain points (e.g. slow network throughput, need 24/7 server monitoring, upcoming cloud migration)..."
                    className="w-full pl-9 pr-3 py-2 rounded-lg border border-slate-200 focus:outline-hidden focus:border-[#056D67] focus:ring-1 focus:ring-[#056D67] text-slate-800"
                  />
                </div>
              </div>

              {/* Submit Button */}
              <div className="pt-2">
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-sm transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {isSubmitting ? (
                    <span>Preparing Your Scope Request...</span>
                  ) : (
                    <>
                      <Send className="w-4 h-4 text-[#C1F24F]" />
                      <span>Submit Proposal Request to Engineering Team</span>
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

            <span className="text-xs font-bold uppercase tracking-wider text-[#056D67] bg-[#F4FAF8] px-3 py-1 rounded-full border border-[#056D67]/20">
              Proposal Request Received
            </span>

            <h3 className="text-2xl font-bold text-slate-900 font-display mt-3">
              Thank You, {contactPerson || 'Valued Client'}!
            </h3>

            <p className="text-sm text-slate-600 mt-2 max-w-md mx-auto leading-relaxed">
              Your inquiry for <strong>{companyName || 'your organization'}</strong> has been assigned to our Lahore Infrastructure Engineering Lead. We will contact you via email (<strong>{email || 'provided address'}</strong>) or phone (<strong>{phone || 'provided phone'}</strong>) with your customized scope.
            </p>

            <div className="mt-6 p-4 rounded-xl bg-[#F4FAF8] border border-slate-200 text-left text-xs text-slate-700 max-w-md mx-auto space-y-1.5">
              <div className="font-bold text-[#056D67] uppercase text-xs mb-1">
                Immediate Reference:
              </div>
              <div>• Service Pillar: <strong>{serviceInterest.toUpperCase()}</strong></div>
              <div>• Fleet Size: <strong>{workstations} Workstations & {servers} Servers</strong></div>
              <div>• Official Lahore Office: <strong>{COMPANY_INFO.address}</strong></div>
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
