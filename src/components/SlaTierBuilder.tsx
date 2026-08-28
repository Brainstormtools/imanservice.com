import React, { useState } from 'react';
import { 
  AMC_COVERAGE_ITEMS, 
  SLA_TIERS 
} from '../data/companyData';
import { 
  Monitor, 
  Share2, 
  Code, 
  Server, 
  Headphones, 
  ShieldCheck, 
  Check, 
  Clock, 
  Calculator, 
  ArrowRight, 
  CheckCircle2, 
  TrendingDown, 
  Sparkles,
  Sliders
} from 'lucide-react';

interface SlaTierBuilderProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
}

export const SlaTierBuilder: React.FC<SlaTierBuilderProps> = ({ onOpenQuote }) => {
  const [selectedCoverageIdx, setSelectedCoverageIdx] = useState<number>(0);
  const [selectedTierId, setSelectedTierId] = useState<string>('silver');
  
  // Dynamic Calculator State
  const [workstations, setWorkstations] = useState<number>(25);
  const [servers, setServers] = useState<number>(3);
  const [networkDevices, setNetworkDevices] = useState<number>(6);
  const [need24x7, setNeed24x7] = useState<boolean>(false);

  const getCoverageIcon = (icon: string) => {
    switch (icon) {
      case 'Monitor': return <Monitor className="w-5 h-5 text-[#056D67]" />;
      case 'Share2': return <Share2 className="w-5 h-5 text-[#056D67]" />;
      case 'Code': return <Code className="w-5 h-5 text-[#056D67]" />;
      case 'Server': return <Server className="w-5 h-5 text-[#056D67]" />;
      case 'Headphones': return <Headphones className="w-5 h-5 text-[#056D67]" />;
      case 'ShieldCheck': return <ShieldCheck className="w-5 h-5 text-[#056D67]" />;
      default: return <Server className="w-5 h-5 text-[#056D67]" />;
    }
  };

  // Estimated ROI / Uptime math
  const totalAssets = workstations + servers + networkDevices;
  const estimatedMonthlyTickets = Math.max(2, Math.round(workstations * 0.4 + servers * 1.2));
  const estimatedDowntimeHoursSavedYearly = Math.round(workstations * 2.8 + servers * 14.5);

  const selectedTier = SLA_TIERS.find(t => t.id === selectedTierId) || SLA_TIERS[1];
  const activeCoverage = AMC_COVERAGE_ITEMS[selectedCoverageIdx];

  const handleRequestQuoteForEstimate = () => {
    onOpenQuote('amc', {
      workstationsCount: workstations,
      serversCount: servers,
      networkDevicesCount: networkDevices,
      slaTier: selectedTier.name,
      notes: `Custom calculated scope for ${workstations} workstations, ${servers} servers, and ${networkDevices} network nodes under ${selectedTier.name} SLA.`
    });
  };

  return (
    <section id="it-amc" className="scroll-mt-[140px] py-20 bg-[#F4FAF8] border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Pillar Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-10 border-b border-slate-200">
          <div className="max-w-3xl">
            <div className="flex items-center gap-2 text-xs font-bold text-[#056D67] uppercase tracking-wider mb-2">
              <span className="w-6 h-0.5 bg-[#C1F24F]" />
              <span>Core Service Pillar 2</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 font-display">
              IT-AMC / SLA (Annual Maintenance Contract)
            </h2>
            <p className="text-slate-600 text-sm sm:text-base mt-3 leading-relaxed">
              An IT AMC is a fixed-fee agreement that keeps your computers, servers, and network maintained and supported throughout the year. At i Man Service, we go beyond reactive "break-fix" support—we deliver structured, SLA-backed maintenance that prevents downtime before it happens.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <a
              href="#sla-matrix"
              className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-lg border border-slate-300 hover:border-[#056D67] bg-white text-slate-700 font-semibold text-sm transition-all shadow-xs"
            >
              <Clock className="w-4 h-4 text-[#056D67]" />
              <span>View Escalation Matrix</span>
            </a>
            <button
              onClick={() => onOpenQuote('amc')}
              id="amc-get-quote-btn"
              className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-semibold text-sm transition-all shadow-xs"
            >
              <span>Get Custom AMC Quote</span>
              <ArrowRight className="w-4 h-4 text-[#C1F24F]" />
            </button>
          </div>
        </div>

        {/* Section 1: What We Cover (6 Coverage Domains) */}
        <div className="mt-12">
          <div className="mb-6">
            <h3 className="text-xl sm:text-2xl font-bold text-slate-900 font-display">
              What We Cover Under Our Fixed-Fee AMC
            </h3>
            <p className="text-slate-600 text-xs sm:text-sm">
              Comprehensive 360-degree coverage across every digital asset in your company.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {AMC_COVERAGE_ITEMS.map((item, idx) => {
              const isSelected = selectedCoverageIdx === idx;
              return (
                <div
                  key={item.title}
                  onClick={() => setSelectedCoverageIdx(idx)}
                  className={`cursor-pointer rounded-2xl p-6 transition-all duration-200 border flex flex-col justify-between ${
                    isSelected 
                      ? 'bg-white border-[#056D67] ring-2 ring-[#056D67]/20 shadow-md' 
                      : 'bg-white/80 border-slate-200 hover:border-[#056D67]/40 hover:bg-white shadow-xs'
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-11 h-11 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex items-center justify-center">
                        {getCoverageIcon(item.icon)}
                      </div>
                      <span className="text-xs uppercase font-bold text-[#056D67] bg-[#F4FAF8] px-2 py-0.5 rounded border border-[#056D67]/15">
                        Domain 0{idx + 1}
                      </span>
                    </div>

                    <h4 className="text-base sm:text-lg font-bold text-slate-900 font-display mb-2">
                      {item.title}
                    </h4>
                    <p className="text-xs text-slate-600 leading-relaxed mb-4">
                      {item.description}
                    </p>
                  </div>

                  {/* Included Tasks Checklist */}
                  <div className="pt-3 border-t border-slate-100">
                    <div className="text-xs uppercase font-bold text-slate-500 tracking-wider mb-2">
                      Core Maintenance Deliverables:
                    </div>
                    <ul className="space-y-1.5">
                      {item.includedTasks.map((task, tIdx) => (
                        <li key={tIdx} className="text-xs text-slate-700 flex items-start gap-1.5">
                          <Check className="w-3.5 h-3.5 text-[#056D67] flex-shrink-0 mt-0.5" />
                          <span>{task}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Section 2: Interactive SLA Tier & Scope Calculator */}
        <div id="sla-calculator" className="mt-20 scroll-mt-[140px]">
          <div className="bg-white rounded-3xl p-6 sm:p-10 border border-slate-200 shadow-xl relative overflow-hidden">
            
            {/* Header */}
            <div className="max-w-3xl mb-8">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F4FAF8] text-[#056D67] text-xs font-bold uppercase tracking-wider mb-2 border border-[#056D67]/20">
                <Calculator className="w-3.5 h-3.5 text-[#056D67]" />
                <span>Interactive AMC Configurator</span>
              </div>
              <h3 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display">
                Customize Your IT-AMC Tier & Scope
              </h3>
              <p className="text-slate-600 text-sm mt-1">
                Configure your digital fleet size, select your desired SLA response tier, and review your customized service-level commitments instantly.
              </p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
              
              {/* Left Configuration Sliders (Col 1-7) */}
              <div className="lg:col-span-7 space-y-6">
                
                {/* 1. Workstations Slider */}
                <div className="bg-[#F4FAF8] rounded-2xl p-5 border border-slate-200/80">
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-bold text-slate-900 flex items-center gap-2">
                      <Monitor className="w-4 h-4 text-[#056D67]" />
                      <span>Desktops & Laptops (Workstations)</span>
                    </label>
                    <span className="text-base font-extrabold text-[#056D67] bg-white px-3 py-0.5 rounded-lg border border-slate-200">
                      {workstations} Units
                    </span>
                  </div>
                  <input
                    type="range"
                    min="5"
                    max="200"
                    step="5"
                    value={workstations}
                    onChange={(e) => setWorkstations(Number(e.target.value))}
                    aria-label="Desktops and Laptops count"
                    className="w-full h-3 py-1 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#056D67]"
                  />
                  <div className="flex justify-between text-xs text-slate-500 mt-1.5">
                    <span>5 Units</span>
                    <span>50 Units</span>
                    <span>100 Units</span>
                    <span>200+ Units</span>
                  </div>
                </div>

                {/* 2. Servers Slider */}
                <div className="bg-[#F4FAF8] rounded-2xl p-5 border border-slate-200/80">
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-bold text-slate-900 flex items-center gap-2">
                      <Server className="w-4 h-4 text-[#056D67]" />
                      <span>Physical & Virtual Servers / Storage</span>
                    </label>
                    <span className="text-base font-extrabold text-[#056D67] bg-white px-3 py-0.5 rounded-lg border border-slate-200">
                      {servers} Servers
                    </span>
                  </div>
                  <input
                    type="range"
                    min="1"
                    max="25"
                    step="1"
                    value={servers}
                    onChange={(e) => setServers(Number(e.target.value))}
                    aria-label="Physical and Virtual Servers count"
                    className="w-full h-3 py-1 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#056D67]"
                  />
                  <div className="flex justify-between text-xs text-slate-500 mt-1.5">
                    <span>1 Server</span>
                    <span>5 Servers</span>
                    <span>15 Servers</span>
                    <span>25+ Servers</span>
                  </div>
                </div>

                {/* 3. Network Devices Slider */}
                <div className="bg-[#F4FAF8] rounded-2xl p-5 border border-slate-200/80">
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-bold text-slate-900 flex items-center gap-2">
                      <Share2 className="w-4 h-4 text-[#056D67]" />
                      <span>Routers, Managed Switches & Access Points</span>
                    </label>
                    <span className="text-base font-extrabold text-[#056D67] bg-white px-3 py-0.5 rounded-lg border border-slate-200">
                      {networkDevices} Devices
                    </span>
                  </div>
                  <input
                    type="range"
                    min="2"
                    max="50"
                    step="2"
                    value={networkDevices}
                    onChange={(e) => setNetworkDevices(Number(e.target.value))}
                    aria-label="Network Devices count"
                    className="w-full h-3 py-1 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#056D67]"
                  />
                  <div className="flex justify-between text-xs text-slate-500 mt-1.5">
                    <span>2 Devices</span>
                    <span>15 Devices</span>
                    <span>30 Devices</span>
                    <span>50+ Devices</span>
                  </div>
                </div>

                {/* 4. SLA Tier Selection */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-2.5">
                    Select SLA Response Level
                  </label>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    {SLA_TIERS.map((tier) => {
                      const isSelected = selectedTierId === tier.id;
                      return (
                        <button
                          key={tier.id}
                          type="button"
                          onClick={() => setSelectedTierId(tier.id)}
                          className={`p-3.5 min-h-[44px] rounded-xl border text-left transition-all relative ${
                            isSelected 
                              ? 'bg-[#056D67] text-white border-[#056D67] shadow-md ring-2 ring-[#056D67]/20' 
                              : 'bg-white text-slate-800 border-slate-200 hover:border-slate-300'
                          }`}
                        >
                          {tier.popular && (
                            <span className="absolute -top-2.5 right-2 text-[9px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-[#C1F24F] text-[#034F4B]">
                              Popular
                            </span>
                          )}
                          <div className="font-bold text-sm leading-tight">
                            {tier.name.split('(')[0]}
                          </div>
                          <div className={`text-xs mt-1 ${isSelected ? 'text-[#D8FA8A]' : 'text-[#056D67] font-semibold'}`}>
                            P1: {tier.responseCritical}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>

              </div>

              {/* Right Output Summary Box (Col 8-12) */}
              <div className="lg:col-span-5 bg-gradient-to-br from-[#034F4B] to-[#056D67] text-white rounded-2xl p-6 sm:p-7 shadow-lg border border-[#096F67]">
                
                <div className="flex items-center justify-between border-b border-white/15 pb-4 mb-4">
                  <div>
                    <span className="text-xs font-bold uppercase tracking-wider text-[#C1F24F]">
                      Contractual Specification
                    </span>
                    <h4 className="text-xl font-bold font-display text-white">
                      {selectedTier.name}
                    </h4>
                  </div>
                  <div className="text-right">
                    <span className="text-xs text-slate-300">Total Fleet</span>
                    <div className="text-xl font-extrabold text-[#C1F24F]">
                      {totalAssets} Nodes
                    </div>
                  </div>
                </div>

                {/* SLA Commitments List */}
                <div className="space-y-3 text-xs sm:text-sm">
                  <div className="flex justify-between py-1.5 border-b border-white/10">
                    <span className="text-slate-200">Critical (P1) Incident Response:</span>
                    <span className="font-bold text-[#C1F24F]">{selectedTier.responseCritical}</span>
                  </div>
                  <div className="flex justify-between py-1.5 border-b border-white/10">
                    <span className="text-slate-200">High (P2) Incident Response:</span>
                    <span className="font-semibold text-white">{selectedTier.responseHigh}</span>
                  </div>
                  <div className="flex justify-between py-1.5 border-b border-white/10">
                    <span className="text-slate-200">Routine (P3/P4) Turnaround:</span>
                    <span className="font-semibold text-white">{selectedTier.responseMedium}</span>
                  </div>
                  <div className="flex justify-between py-1.5 border-b border-white/10">
                    <span className="text-slate-200">Preventive Maintenance:</span>
                    <span className="font-semibold text-[#D8FA8A]">{selectedTier.preventiveVisits}</span>
                  </div>
                  <div className="flex justify-between py-1.5 border-b border-white/10">
                    <span className="text-slate-200">Service Reporting:</span>
                    <span className="font-semibold text-white">{selectedTier.reporting}</span>
                  </div>
                </div>

                {/* ROI & Downtime Estimate Badge */}
                <div className="mt-5 p-3.5 rounded-xl bg-white/10 border border-white/15">
                  <div className="flex items-center gap-2 text-xs font-bold text-[#C1F24F] mb-1">
                    <TrendingDown className="w-4 h-4" />
                    <span>Projected Productivity Impact</span>
                  </div>
                  <p className="text-xs text-slate-200">
                    Saves an estimated <strong className="text-white">{estimatedDowntimeHoursSavedYearly} hours</strong> of operational interruption and eliminates unpredictable emergency technician rates.
                  </p>
                </div>

                {/* Action CTA */}
                <button
                  onClick={handleRequestQuoteForEstimate}
                  id="sla-calc-request-quote-btn"
                  className="mt-6 w-full py-3.5 px-4 rounded-xl bg-[#C1F24F] hover:bg-[#D8FA8A] text-[#034F4B] font-bold text-sm transition-all transform hover:-translate-y-0.5 shadow-md flex items-center justify-center gap-2"
                >
                  <CheckCircle2 className="w-4 h-4 text-[#034F4B]" />
                  <span>Request Official Proposal for this Configuration</span>
                </button>

                <div className="mt-3 text-center text-xs text-slate-300">
                  Fixed annual pricing with flexible quarterly billing available for Lahore businesses.
                </div>

              </div>

            </div>

          </div>
        </div>

        {/* Section 3: Key Benefits of i Man Service IT-AMC */}
        <div className="mt-16 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex items-center gap-3">
            <span className="text-lg">✅</span>
            <div className="text-xs font-bold text-slate-800">Reduced System Downtime</div>
          </div>
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex items-center gap-3">
            <span className="text-lg">⚡</span>
            <div className="text-xs font-bold text-slate-800">Faster Issue Resolution</div>
          </div>
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex items-center gap-3">
            <span className="text-lg">📊</span>
            <div className="text-xs font-bold text-slate-800">Predictable IT Operating Costs</div>
          </div>
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex items-center gap-3">
            <span className="text-lg">🛡️</span>
            <div className="text-xs font-bold text-slate-800">Improved Infrastructure Lifespan</div>
          </div>
          <div className="bg-white p-4 rounded-xl border border-slate-200 flex items-center gap-3">
            <span className="text-lg">🔒</span>
            <div className="text-xs font-bold text-slate-800">Enhanced Cybersecurity Protection</div>
          </div>
        </div>

      </div>
    </section>
  );
};
