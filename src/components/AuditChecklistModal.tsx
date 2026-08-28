import React, { useState } from 'react';
import { 
  X, 
  Printer, 
  CheckSquare, 
  Square, 
  FileCheck, 
  ShieldCheck,
  Building2
} from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

interface AuditChecklistModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenQuote: () => void;
}

export const AuditChecklistModal: React.FC<AuditChecklistModalProps> = ({
  isOpen,
  onClose,
  onOpenQuote
}) => {
  const [checkedItems, setCheckedItems] = useState<Record<string, boolean>>({});

  if (!isOpen) return null;

  const toggleItem = (id: string) => {
    setCheckedItems(prev => ({
      ...prev,
      [id]: !prev[id]
    }));
  };

  const checklistSections = [
    {
      category: "1. Network Infrastructure & Connectivity",
      items: [
        { id: "net-1", label: "Core & distribution switches firmware updated to latest stable vendor releases" },
        { id: "net-2", label: "VLAN segmentation configured separating guest, voice, CCTV, and corporate traffic" },
        { id: "net-3", label: "Wi-Fi access points mapped with RF coverage heatmaps (no dead zones)" },
        { id: "net-4", label: "Structured cabling certified (Cat6/Fiber) with labeled patch panels" },
        { id: "net-5", label: "Dual-WAN internet failover / SD-WAN configured with automatic failover" }
      ]
    },
    {
      category: "2. Hardware Asset Lifecycle & Health",
      items: [
        { id: "hw-1", label: "Complete inventory of all workstations, laptops, and serial numbers documented" },
        { id: "hw-2", label: "Identification of all devices reaching vendor End-of-Life (EOL) or End-of-Support" },
        { id: "hw-3", label: "Server storage RAID controller health and SMART disk telemetry verified" },
        { id: "hw-4", label: "Server room UPS battery health, load capacity, and runtime stress tested" },
        { id: "hw-5", label: "Server thermal management, dust filtration, and ventilation inspected" }
      ]
    },
    {
      category: "3. Cybersecurity, Firewall & Access Control",
      items: [
        { id: "sec-1", label: "Next-Gen Firewall rules audited, unused open ports closed, and UTM licenses active" },
        { id: "sec-2", label: "Centralized Endpoint Detection & Response (EDR) / Antivirus updated on all nodes" },
        { id: "sec-3", label: "Active Directory / Identity Access privilege audit (disabled former employee accounts)" },
        { id: "sec-4", label: "Multi-Factor Authentication (MFA) enforced on VPNs, email, and admin logins" },
        { id: "sec-5", label: "Automated vulnerability scan executed across public and internal IP ranges" }
      ]
    },
    {
      category: "4. Backup, Disaster Recovery & Compliance",
      items: [
        { id: "dr-1", label: "Automated 3-2-1 backup strategy in place (3 copies, 2 media types, 1 offsite/cloud)" },
        { id: "dr-2", label: "Ransomware-immutable or air-gapped backup copies maintained" },
        { id: "dr-3", label: "Quarterly test restore drill successfully performed and documented" },
        { id: "dr-4", label: "Disaster Recovery (DR) plan documented with clear RTO and RPO benchmarks" },
        { id: "dr-5", label: "SLA agreements in place for 24/7 hardware replacement and priority dispatch" }
      ]
    }
  ];

  const totalItems = 20;
  const completedCount = Object.values(checkedItems).filter(Boolean).length;
  const completionPercentage = Math.round((completedCount / totalItems) * 100);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-3xl w-full p-6 sm:p-8 shadow-2xl border border-slate-100 relative max-h-[90vh] overflow-y-auto">
        
        {/* Modal Top Bar */}
        <div className="flex items-center justify-between border-b border-slate-100 pb-4 mb-6 no-print">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#056D67] text-[#C1F24F] flex items-center justify-center font-bold">
              <FileCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-slate-900 font-display">
                Enterprise IT Infrastructure Audit Checklist
              </h3>
              <p className="text-xs text-slate-500">
                Official assessment framework by {COMPANY_INFO.name}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handlePrint}
              className="min-h-[44px] p-2.5 rounded-lg text-slate-600 hover:text-[#056D67] hover:bg-slate-100 transition-colors flex items-center justify-center gap-1.5 text-xs font-semibold"
              title="Print Checklist"
              aria-label="Print Checklist"
            >
              <Printer className="w-4 h-4" />
              <span className="hidden sm:inline">Print / Save PDF</span>
            </button>
            <button
              onClick={onClose}
              className="min-w-[44px] min-h-[44px] flex items-center justify-center p-2 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors"
              aria-label="Close checklist"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Printable Official Header (visible during print or in modal) */}
        <div className="mb-6 p-4 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="text-sm font-bold text-[#056D67]">
              {COMPANY_INFO.name} – Network Audit Division
            </div>
            <div className="text-xs text-slate-600">
              {COMPANY_INFO.address} • Tel: {COMPANY_INFO.phone} • {COMPANY_INFO.website}
            </div>
          </div>
          <div className="text-right">
            <span className="text-xs uppercase font-bold text-slate-500">Audit Progress</span>
            <div className="text-base font-extrabold text-[#056D67]">
              {completedCount} of {totalItems} Checked ({completionPercentage}%)
            </div>
          </div>
        </div>

        {/* Checklist Content Sections */}
        <div className="space-y-6">
          {checklistSections.map((section, sIdx) => (
            <div key={sIdx} className="bg-white border border-slate-200 rounded-xl p-4 sm:p-5">
              <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-3 flex items-center justify-between border-b border-slate-100 pb-2">
                <span>{section.category}</span>
              </h4>
              <div className="space-y-2.5">
                {section.items.map((item) => {
                  const isChecked = !!checkedItems[item.id];
                  return (
                    <div
                      key={item.id}
                      onClick={() => toggleItem(item.id)}
                      className={`min-h-[44px] cursor-pointer p-3 rounded-lg border transition-all flex items-start gap-3 select-none ${
                        isChecked 
                          ? 'bg-emerald-50/70 border-emerald-300 text-emerald-900' 
                          : 'bg-white border-slate-100 text-slate-700 hover:border-slate-300'
                      }`}
                    >
                      <div className="mt-0.5 flex-shrink-0">
                        {isChecked ? (
                          <CheckSquare className="w-4 h-4 text-emerald-600" />
                        ) : (
                          <Square className="w-4 h-4 text-slate-300" />
                        )}
                      </div>
                      <span className={`text-xs sm:text-sm ${isChecked ? 'line-through text-slate-500' : 'font-medium'}`}>
                        {item.label}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* Bottom Actions */}
        <div className="mt-6 pt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 no-print">
          <span className="text-xs text-slate-500">
            Need our certified engineers to conduct this full inspection on-site?
          </span>
          <button
            onClick={() => {
              onClose();
              onOpenQuote();
            }}
            className="min-h-[44px] px-5 py-2.5 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-xs sm:text-sm transition-colors flex items-center justify-center"
          >
            Schedule Professional Onsite Audit
          </button>
        </div>

      </div>
    </div>
  );
};
