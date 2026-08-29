import React, { useState } from 'react';
import { SLA_SEVERITY_MATRIX, COMPANY_INFO } from '../data/companyData';
import { 
  ShieldAlert, 
  AlertCircle, 
  Clock, 
  FileText, 
  UserCheck, 
  CheckCircle,
  HelpCircle,
  PhoneCall,
  ArrowRight
} from 'lucide-react';

interface SlaMatrixTableProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
}

export const SlaMatrixTable: React.FC<SlaMatrixTableProps> = ({ onOpenQuote }) => {
  const [activeTab, setActiveTab] = useState<'matrix' | 'flow' | 'preventive'>('matrix');

  return (
    <section id="sla-matrix" className="scroll-mt-[140px] py-16 sm:py-20 bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F4FAF8] border border-[#056D67]/20 text-[#056D67] text-xs font-bold uppercase tracking-wider mb-2">
            <Clock className="w-3.5 h-3.5 text-[#056D67]" />
            <span>Strict Operational Governance</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display">
            Our Contractual SLA & Escalation Framework
          </h2>
          <p className="text-slate-600 text-sm sm:text-base mt-2">
            Defined response times, tiered incident classifications, scheduled preventive maintenance, and transparent monthly reporting.
          </p>
        </div>

        {/* Interactive View Selector */}
        <div className="flex justify-center mb-8">
          <div className="inline-flex flex-wrap sm:flex-nowrap p-1.5 rounded-xl bg-[#F4FAF8] border border-slate-200 text-xs sm:text-sm font-semibold gap-1">
            <button
              type="button"
              onClick={() => setActiveTab('matrix')}
              className={`min-h-[44px] px-4 py-2.5 rounded-lg transition-all flex items-center justify-center ${
                activeTab === 'matrix' 
                  ? 'bg-[#056D67] text-white shadow-xs' 
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Severity & Response Matrix
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('preventive')}
              className={`min-h-[44px] px-4 py-2.5 rounded-lg transition-all flex items-center justify-center ${
                activeTab === 'preventive' 
                  ? 'bg-[#056D67] text-white shadow-xs' 
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Preventive Maintenance Visits
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('flow')}
              className={`min-h-[44px] px-4 py-2.5 rounded-lg transition-all flex items-center justify-center ${
                activeTab === 'flow' 
                  ? 'bg-[#056D67] text-white shadow-xs' 
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Escalation Protocol
            </button>
          </div>
        </div>

        {/* Tab 1: Severity Matrix Table */}
        {activeTab === 'matrix' && (
          <div className="space-y-4 animate-in fade-in duration-200">
            {/* Mobile Card Layout (Visible on Small Viewports < 640px) */}
            <div className="sm:hidden space-y-4">
              {SLA_SEVERITY_MATRIX.map((row) => {
                const isP1 = row.level === 'P1';
                const isP2 = row.level === 'P2';
                return (
                  <div 
                    key={row.level}
                    className={`p-4 rounded-2xl border ${
                      isP1 
                        ? 'bg-rose-50/50 border-rose-200' 
                        : isP2 
                          ? 'bg-amber-50/40 border-amber-200' 
                          : 'bg-white border-slate-200'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className={`w-2.5 h-2.5 rounded-full ${
                          isP1 ? 'bg-red-600 animate-pulse' : isP2 ? 'bg-amber-500' : 'bg-[#056D67]'
                        }`} />
                        <span className="font-bold text-slate-900 font-display">{row.severity}</span>
                      </div>
                      <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-700">
                        {row.level}
                      </span>
                    </div>

                    <p className="text-xs text-slate-600 mb-3">{row.example}</p>

                    <div className="grid grid-cols-2 gap-2 text-xs pt-2 border-t border-slate-200/80">
                      <div>
                        <span className="text-slate-500 block text-[10px] uppercase">Ack Time</span>
                        <strong className="text-slate-800">{row.ackTime}</strong>
                      </div>
                      <div>
                        <span className="text-slate-500 block text-[10px] uppercase">Target Resolution</span>
                        <strong className="text-[#056D67]">{row.onsiteOrRemoteResolution}</strong>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Desktop Table (Visible >= 640px) */}
            <div className="hidden sm:block bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs sm:text-sm">
                  <thead className="bg-[#056D67] text-white uppercase text-xs font-bold tracking-wider">
                    <tr>
                      <th className="py-4 px-4 sm:px-6">Severity Level</th>
                      <th className="py-4 px-4 sm:px-6">Example Scenario</th>
                      <th className="py-4 px-4 sm:px-6">Initial Acknowledgement</th>
                      <th className="py-4 px-4 sm:px-6">Target Resolution Commitment</th>
                      <th className="py-4 px-4 sm:px-6">Escalation Authority</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {SLA_SEVERITY_MATRIX.map((row) => {
                      const isP1 = row.level === 'P1';
                      const isP2 = row.level === 'P2';
                      return (
                        <tr key={row.level} className={`hover:bg-[#F4FAF8]/60 transition-colors ${isP1 ? 'bg-red-50/40' : isP2 ? 'bg-amber-50/30' : ''}`}>
                          <td className="py-4 px-4 sm:px-6 font-bold whitespace-nowrap">
                            <div className="flex items-center gap-2">
                              <span className={`w-2.5 h-2.5 rounded-full ${
                                isP1 ? 'bg-red-600 animate-pulse' : isP2 ? 'bg-amber-500' : 'bg-[#056D67]'
                              }`} />
                              <span className="text-slate-900 font-display">{row.severity}</span>
                            </div>
                            <span className="text-xs text-slate-500 font-mono">Priority: {row.level}</span>
                          </td>
                          <td className="py-4 px-4 sm:px-6 text-slate-600 max-w-xs">
                            {row.example}
                          </td>
                          <td className="py-4 px-4 sm:px-6 font-bold text-slate-900 whitespace-nowrap">
                            <span className="px-2.5 py-1 rounded bg-slate-100 text-[#034F4B] border border-slate-200">
                              {row.ackTime}
                            </span>
                          </td>
                          <td className="py-4 px-4 sm:px-6 font-semibold text-[#056D67]">
                            {row.onsiteOrRemoteResolution}
                          </td>
                          <td className="py-4 px-4 sm:px-6 text-slate-700 text-xs font-medium">
                            {row.escalationManager}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Preventive Maintenance Visits */}
        {activeTab === 'preventive' && (
          <div className="bg-[#F4FAF8] rounded-2xl p-6 sm:p-8 border border-slate-200 animate-in fade-in duration-200">
            <div className="max-w-3xl mb-6">
              <h3 className="text-xl font-bold text-slate-900 font-display">
                Preventive Maintenance Protocol: Stopping Failures in Advance
              </h3>
              <p className="text-sm text-slate-600 mt-1">
                Rather than waiting for hardware to overheat or disks to corrupt, our certified engineers perform rigorous physical and digital health audits on scheduled cycles.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
                <div className="text-xs font-bold uppercase text-[#056D67] mb-2">Phase 1: Physical Inspection</div>
                <ul className="space-y-2 text-xs text-slate-700">
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Server rack ventilation, fan operation & dust clearing</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>UPS battery runtime test & power load balancing</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Patch cord strain relief & switch port thermal check</span>
                  </li>
                </ul>
              </div>

              <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
                <div className="text-xs font-bold uppercase text-[#056D67] mb-2">Phase 2: System Optimization</div>
                <ul className="space-y-2 text-xs text-slate-700">
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>OS security patch installation & kernel stability review</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Storage defragmentation, RAID rebuild status & SMART analysis</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Database index health & log rotation cleanup</span>
                  </li>
                </ul>
              </div>

              <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
                <div className="text-xs font-bold uppercase text-[#056D67] mb-2">Phase 3: DR & Reporting</div>
                <ul className="space-y-2 text-xs text-slate-700">
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Random backup file restoration verification test</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Antivirus definitions sync across all workstations</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <CheckCircle className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                    <span>Signed Monthly Health & Incident Summary report delivery</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Escalation Flow */}
        {activeTab === 'flow' && (
          <div className="bg-[#F4FAF8] rounded-2xl p-6 sm:p-8 border border-slate-200 animate-in fade-in duration-200">
            <div className="max-w-3xl mb-6">
              <h3 className="text-xl font-bold text-slate-900 font-display">
                Automated Ticket Escalation Matrix
              </h3>
              <p className="text-sm text-slate-600 mt-1">
                If an incident is not acknowledged or resolved within specified SLA milestones, it automatically elevates through our hierarchical management chain.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-white p-4 rounded-xl border border-slate-200">
                <div className="text-xs font-bold text-[#056D67]">Tier 1: Helpdesk Frontline</div>
                <div className="text-xs text-slate-500 mt-1">0 - 15 Mins</div>
                <p className="text-xs text-slate-700 mt-2">
                  Immediate triage, remote diagnostic session, user verification, and standard fix library execution.
                </p>
              </div>

              <div className="bg-white p-4 rounded-xl border border-slate-200">
                <div className="text-xs font-bold text-[#056D67]">Tier 2: Senior Systems Engineer</div>
                <div className="text-xs text-slate-500 mt-1">15 - 45 Mins</div>
                <p className="text-xs text-slate-700 mt-2">
                  Advanced troubleshooting, server virtualization debugging, firewall and routing analysis.
                </p>
              </div>

              <div className="bg-white p-4 rounded-xl border border-slate-200">
                <div className="text-xs font-bold text-[#056D67]">Tier 3: On-Site Dispatch Team</div>
                <div className="text-xs text-slate-500 mt-1">Within 1 - 2 Hours</div>
                <p className="text-xs text-slate-700 mt-2">
                  Certified hardware technician deployed directly to your Lahore premises with replacement spares.
                </p>
              </div>

              <div className="bg-white p-4 rounded-xl border border-slate-200">
                <div className="text-xs font-bold text-red-700">Tier 4: Operations Executive</div>
                <div className="text-xs text-slate-500 mt-1">Critical Incidents</div>
                <p className="text-xs text-slate-700 mt-2">
                  Direct engagement by Director of Operations with continuous executive status briefings.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Emergency Help Banner */}
        <div className="mt-8 p-5 rounded-2xl bg-slate-900 text-white flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#C1F24F] text-[#034F4B] flex items-center justify-center font-bold">
              <PhoneCall className="w-5 h-5" />
            </div>
            <div>
              <div className="text-xs font-semibold text-slate-300">Experiencing an Active Network Emergency in Lahore?</div>
              <div className="text-base font-bold text-white">Call Emergency Line: {COMPANY_INFO.phone}</div>
            </div>
          </div>
          <button
            type="button"
            onClick={() => onOpenQuote('amc')}
            className="min-h-[44px] px-5 py-2.5 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white text-xs sm:text-sm font-bold transition-colors flex items-center justify-center gap-2"
          >
            <span>Request IT Proposal</span>
            <ArrowRight className="w-4 h-4 text-[#C1F24F]" />
          </button>
        </div>

      </div>
    </section>
  );
};
