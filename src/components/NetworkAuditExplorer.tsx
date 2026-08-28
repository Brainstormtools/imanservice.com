import React, { useState } from 'react';
import { 
  ASSESSMENT_AREAS, 
  AUDIT_METHODOLOGY, 
  AUDIT_WHY_POINTS 
} from '../data/companyData';
import { 
  Network, 
  HardDrive, 
  Gauge, 
  Lock, 
  Search, 
  Activity, 
  ShieldAlert, 
  FileCheck, 
  AlertTriangle, 
  Eye, 
  Shield, 
  Cloud, 
  DollarSign, 
  Check, 
  FileText, 
  ArrowRight,
  Sparkles,
  Info
} from 'lucide-react';

interface NetworkAuditExplorerProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all') => void;
  onOpenChecklist: () => void;
}

export const NetworkAuditExplorer: React.FC<NetworkAuditExplorerProps> = ({
  onOpenQuote,
  onOpenChecklist
}) => {
  const [selectedAreaIdx, setSelectedAreaIdx] = useState<number>(0);
  const [checkedItems, setCheckedItems] = useState<Record<string, boolean>>({});

  const toggleCheck = (item: string) => {
    setCheckedItems(prev => ({
      ...prev,
      [item]: !prev[item]
    }));
  };

  const getAreaIcon = (icon: string) => {
    switch (icon) {
      case 'Network': return <Network className="w-5 h-5" />;
      case 'HardDrive': return <HardDrive className="w-5 h-5" />;
      case 'Gauge': return <Gauge className="w-5 h-5" />;
      case 'Lock': return <Lock className="w-5 h-5" />;
      default: return <Network className="w-5 h-5" />;
    }
  };

  const getMethodologyIcon = (icon: string) => {
    switch (icon) {
      case 'Search': return <Search className="w-5 h-5 text-[#056D67]" />;
      case 'Activity': return <Activity className="w-5 h-5 text-[#056D67]" />;
      case 'ShieldAlert': return <ShieldAlert className="w-5 h-5 text-[#056D67]" />;
      case 'FileCheck': return <FileCheck className="w-5 h-5 text-[#056D67]" />;
      default: return <Activity className="w-5 h-5 text-[#056D67]" />;
    }
  };

  const getWhyIcon = (icon: string) => {
    switch (icon) {
      case 'AlertTriangle': return <AlertTriangle className="w-5 h-5 text-[#056D67]" />;
      case 'Eye': return <Eye className="w-5 h-5 text-[#056D67]" />;
      case 'Shield': return <Shield className="w-5 h-5 text-[#056D67]" />;
      case 'Cloud': return <Cloud className="w-5 h-5 text-[#056D67]" />;
      case 'DollarSign': return <DollarSign className="w-5 h-5 text-[#056D67]" />;
      default: return <Check className="w-5 h-5 text-[#056D67]" />;
    }
  };

  const activeArea = ASSESSMENT_AREAS[selectedAreaIdx];

  return (
    <section id="network-audit" className="scroll-mt-[140px] py-20 bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Pillar Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-10 border-b border-slate-100">
          <div className="max-w-3xl">
            <div className="flex items-center gap-2 text-xs font-bold text-[#056D67] uppercase tracking-wider mb-2">
              <span className="w-6 h-0.5 bg-[#C1F24F]" />
              <span>Core Service Pillar 1</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display">
              Existing Network Audit
            </h2>
            <p className="text-slate-600 text-sm sm:text-base mt-3 leading-relaxed">
              A comprehensive evaluation of your entire IT infrastructure—encompassing hardware, software, connected devices, security protocols, and performance metrics. i Man Service delivers thorough, independent assessments that uncover risks, remove bottlenecks, and create a clear roadmap for scalable, future-ready operations.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={onOpenChecklist}
              id="audit-view-checklist-btn"
              className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-lg border border-[#056D67]/30 text-[#056D67] hover:bg-[#F4FAF8] font-semibold text-sm transition-all"
            >
              <FileText className="w-4 h-4 text-[#056D67]" />
              <span>View Audit Checklist</span>
            </button>
            <button
              onClick={() => onOpenQuote('audit')}
              id="audit-book-audit-btn"
              className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-semibold text-sm transition-all shadow-xs"
            >
              <span>Book Network Audit</span>
              <ArrowRight className="w-4 h-4 text-[#C1F24F]" />
            </button>
          </div>
        </div>

        {/* Section 1: What We Assess - Interactive Matrix */}
        <div className="mt-12">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-xl sm:text-2xl font-bold text-slate-900 font-display">
                What We Assess: Infrastructure Inspection Matrix
              </h3>
              <p className="text-slate-600 text-xs sm:text-sm">
                Explore the 4 specialized assessment dimensions and their deep-dive inspection parameters.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Left Tabs (Col 1-4) */}
            <div className="lg:col-span-4 space-y-2.5">
              {ASSESSMENT_AREAS.map((area, idx) => {
                const isActive = selectedAreaIdx === idx;
                return (
                  <button
                    key={area.area}
                    onClick={() => setSelectedAreaIdx(idx)}
                    id={`audit-tab-${idx}`}
                    className={`w-full text-left p-4 rounded-xl transition-all duration-200 flex items-center justify-between border ${
                      isActive 
                        ? 'bg-[#056D67] text-white border-[#056D67] shadow-md' 
                        : 'bg-[#F4FAF8] text-slate-700 border-slate-200/80 hover:bg-slate-100/80'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className={`p-2 rounded-lg ${isActive ? 'bg-white/15 text-[#C1F24F]' : 'bg-white text-[#056D67] border border-slate-200'}`}>
                        {getAreaIcon(area.icon)}
                      </div>
                      <div>
                        <div className="font-bold text-sm leading-tight">
                          {area.area}
                        </div>
                        <span className={`text-xs uppercase font-semibold ${isActive ? 'text-[#D8FA8A]' : 'text-slate-500'}`}>
                          {area.criticality} Priority
                        </span>
                      </div>
                    </div>
                    <ArrowRight className={`w-4 h-4 ${isActive ? 'text-[#C1F24F]' : 'text-slate-400'}`} />
                  </button>
                );
              })}
            </div>

            {/* Right Active Assessment Detail Card (Col 5-12) */}
            <div className="lg:col-span-8 bg-[#F4FAF8] border border-[#056D67]/20 rounded-2xl p-6 sm:p-7 shadow-xs">
              <div className="flex items-center justify-between border-b border-slate-200 pb-4 mb-5">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-[#056D67] text-[#C1F24F]">
                    {getAreaIcon(activeArea.icon)}
                  </div>
                  <div>
                    <h4 className="text-lg sm:text-xl font-bold text-slate-900 font-display">
                      {activeArea.area}
                    </h4>
                    <span className="text-xs text-[#056D67] font-semibold">
                      Official Audit Scope Specification
                    </span>
                  </div>
                </div>
                <span className="px-3 py-1 rounded-full bg-[#056D67]/10 text-[#056D67] text-xs font-bold uppercase tracking-wider border border-[#056D67]/20">
                  {activeArea.criticality} Level
                </span>
              </div>

              {/* What We Examine Narrative */}
              <div className="bg-white rounded-xl p-4 border border-slate-200 mb-6">
                <div className="text-xs font-bold uppercase tracking-wider text-[#056D67] mb-1 flex items-center gap-1.5">
                  <Info className="w-3.5 h-3.5" />
                  <span>Scope of Examination:</span>
                </div>
                <p className="text-sm text-slate-700 leading-relaxed font-medium">
                  {activeArea.examine}
                </p>
              </div>

              {/* Interactive Inspection Checkpoints */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-600">
                    Sample In-Depth Diagnostic Checkpoints
                  </span>
                  <span className="text-xs text-slate-500">
                    Click to simulate self-check
                  </span>
                </div>
                <div className="space-y-2.5">
                  {activeArea.checklist.map((item) => {
                    const isChecked = !!checkedItems[item];
                    return (
                      <div
                        key={item}
                        onClick={() => toggleCheck(item)}
                        role="checkbox"
                        aria-checked={isChecked}
                        tabIndex={0}
                        onKeyDown={(e) => { if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); toggleCheck(item); } }}
                        className={`cursor-pointer min-h-[44px] p-3 rounded-lg border transition-all flex items-start gap-3 select-none ${
                          isChecked 
                            ? 'bg-emerald-50 border-emerald-300 text-emerald-900' 
                            : 'bg-white border-slate-200 text-slate-700 hover:border-[#056D67]/40'
                        }`}
                      >
                        <div className={`w-5 h-5 rounded flex items-center justify-center flex-shrink-0 mt-0.5 border ${
                          isChecked 
                            ? 'bg-emerald-600 border-emerald-600 text-white' 
                            : 'border-slate-300 bg-white text-transparent'
                        }`}>
                          <Check className="w-3.5 h-3.5" />
                        </div>
                        <span className="text-xs sm:text-sm font-medium leading-snug">
                          {item}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* CTA footer inside detail */}
              <div className="mt-6 pt-4 border-t border-slate-200 flex flex-wrap items-center justify-between gap-3 text-xs">
                <span className="text-slate-600">
                  Includes full diagnostic telemetry and executive risk rating.
                </span>
                <button
                  onClick={() => onOpenQuote('audit')}
                  className="min-h-[44px] inline-flex items-center text-xs sm:text-sm font-bold text-[#056D67] hover:text-[#034F4B] underline py-1"
                >
                  Request Scope for this Area &rarr;
                </button>
              </div>

            </div>

          </div>
        </div>

        {/* Section 2: Our 4-Step Audit Methodology */}
        <div className="mt-20">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="text-xs font-bold text-[#056D67] uppercase tracking-wider bg-[#F4FAF8] px-3 py-1 rounded-full border border-[#056D67]/20">
              Standardized Assessment Workflow
            </span>
            <h3 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display mt-2">
              Our 4-Stage Audit Methodology
            </h3>
            <p className="text-slate-600 text-sm mt-2">
              Structured, non-intrusive processes that evaluate your digital estate without interrupting your live production traffic.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {AUDIT_METHODOLOGY.map((step) => (
              <div
                key={step.step}
                className="bg-white border border-slate-200 hover:border-[#056D67] rounded-2xl p-6 transition-all duration-200 shadow-xs hover:shadow-md flex flex-col justify-between relative group"
              >
                {/* Step Pill */}
                <div className="absolute -top-3 left-6 px-3 py-0.5 rounded-full bg-[#056D67] text-white text-xs font-extrabold tracking-wider uppercase border-2 border-white shadow-xs">
                  Stage 0{step.step}
                </div>

                <div className="pt-2">
                  <div className="w-12 h-12 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center mb-4 group-hover:bg-[#056D67] group-hover:text-white transition-colors">
                    {getMethodologyIcon(step.icon)}
                  </div>
                  <h4 className="text-lg font-bold text-slate-900 font-display group-hover:text-[#056D67] transition-colors">
                    {step.title}
                  </h4>
                  <p className="text-xs text-slate-600 mt-2 leading-relaxed">
                    {step.description}
                  </p>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-100">
                  <div className="text-xs uppercase font-bold text-[#056D67] tracking-wider">
                    Key Deliverable
                  </div>
                  <div className="text-xs font-semibold text-slate-800 mt-0.5">
                    {step.deliverable}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Section 3: Why Audit Your Network? */}
        <div className="mt-20 bg-[#056D67] rounded-3xl p-8 sm:p-10 text-white relative overflow-hidden">
          <div className="absolute right-0 top-0 w-96 h-96 bg-[#C1F24F]/10 rounded-full blur-3xl pointer-events-none" />

          <div className="max-w-3xl mb-8 relative z-10">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-[#D8FA8A] text-xs font-bold uppercase tracking-wider mb-2">
              <Sparkles className="w-3.5 h-3.5 text-[#C1F24F]" />
              <span>Business Value & ROI</span>
            </div>
            <h3 className="text-2xl sm:text-3xl font-extrabold text-white font-display">
              Why Audit Your Network with i Man Service?
            </h3>
            <p className="text-slate-200 text-sm sm:text-base mt-2">
              Auditing isn't an academic exercise—it is a critical protective measure that saves millions in downtime, eliminates wasteful hardware spend, and secures sensitive corporate assets.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 relative z-10">
            {AUDIT_WHY_POINTS.map((why, i) => (
              <div
                key={why.title}
                className="bg-white/10 backdrop-blur-xs border border-white/15 rounded-xl p-5 hover:bg-white/15 transition-all"
              >
                <div className="w-10 h-10 rounded-lg bg-[#C1F24F] text-[#034F4B] flex items-center justify-center font-bold mb-3">
                  {getWhyIcon(why.icon)}
                </div>
                <h4 className="font-bold text-sm text-white">
                  {why.title}
                </h4>
                <p className="text-xs text-slate-200 mt-1.5 leading-relaxed">
                  {why.description}
                </p>
              </div>
            ))}

            {/* Quick Consultation Callout */}
            <div className="bg-[#034F4B] border border-[#C1F24F]/40 rounded-xl p-5 flex flex-col justify-between">
              <div>
                <span className="text-xs font-bold uppercase tracking-wider text-[#C1F24F]">
                  Lahore Corporate Special
                </span>
                <h4 className="font-bold text-sm text-white mt-1">
                  Ready for an On-Site Preliminary Walkthrough?
                </h4>
                <p className="text-xs text-slate-300 mt-1.5">
                  Our certified network engineers can survey your Lahore facility within 24–48 hours.
                </p>
              </div>
              <button
                onClick={() => onOpenQuote('audit')}
                className="mt-4 w-full min-h-[44px] py-2.5 px-3 rounded-lg bg-[#C1F24F] text-[#034F4B] font-bold text-xs sm:text-sm hover:bg-[#D8FA8A] transition-colors text-center flex items-center justify-center"
              >
                Schedule On-Site Walkthrough
              </button>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
