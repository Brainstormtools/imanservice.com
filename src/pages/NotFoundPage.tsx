import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Link } from '../router/Router';
import { FileSearch, Clock, Compass, Home, Phone, ArrowRight } from 'lucide-react';
import { COMPANY_INFO } from '../data/companyData';

export const NotFoundPage: React.FC = () => {
  return (
    <>
      <SeoHead
        title="Page Not Found (404) | i Man Service"
        description="The page you requested could not be found. Return to i Man Service homepage for Lahore IT Infrastructure, Network Audit, and IT-AMC services."
        canonical="https://www.imanservice.com/404"
        noIndex={true}
      />

      <section className="min-h-[70vh] flex items-center justify-center py-16 px-4 bg-[#F4FAF8]">
        <div className="max-w-2xl w-full text-center space-y-6 bg-white p-8 sm:p-12 rounded-2xl border border-slate-200 shadow-xl">
          
          <div className="w-16 h-16 rounded-2xl bg-[#056D67]/10 text-[#056D67] border border-[#056D67]/20 flex items-center justify-center mx-auto text-2xl font-extrabold font-display">
            404
          </div>

          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 font-display">
            Page Not Found
          </h1>

          <p className="text-sm text-slate-600 max-w-md mx-auto leading-relaxed">
            The page you are looking for might have been moved, renamed, or is temporarily unavailable. Please explore our primary IT infrastructure services below:
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-left pt-2">
            <Link
              to="/network-audit"
              className="p-3.5 rounded-xl border border-slate-200 hover:border-[#056D67] bg-slate-50 hover:bg-[#F4FAF8] transition-all block"
            >
              <FileSearch className="w-4 h-4 text-[#056D67] mb-1.5" />
              <span className="font-bold text-xs text-slate-900 block">Network Audit</span>
              <span className="text-xs text-slate-500">Diagnostics & Heatmaps</span>
            </Link>

            <Link
              to="/it-amc-sla"
              className="p-3.5 rounded-xl border border-slate-200 hover:border-[#056D67] bg-slate-50 hover:bg-[#F4FAF8] transition-all block"
            >
              <Clock className="w-4 h-4 text-[#056D67] mb-1.5" />
              <span className="font-bold text-xs text-slate-900 block">IT-AMC / SLA</span>
              <span className="text-xs text-slate-500">Fixed-Fee Maintenance</span>
            </Link>

            <Link
              to="/it-consultancy"
              className="p-3.5 rounded-xl border border-slate-200 hover:border-[#056D67] bg-slate-50 hover:bg-[#F4FAF8] transition-all block"
            >
              <Compass className="w-4 h-4 text-[#056D67] mb-1.5" />
              <span className="font-bold text-xs text-slate-900 block">IT Consultancy</span>
              <span className="text-xs text-slate-500">Strategic Advisory</span>
            </Link>
          </div>

          <div className="pt-4 flex flex-wrap items-center justify-center gap-3 border-t border-slate-100">
            <Link
              to="/"
              className="min-h-[44px] px-6 py-2.5 rounded-lg bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-sm transition-colors flex items-center gap-2"
            >
              <Home className="w-4 h-4" />
              <span>Return to Homepage</span>
            </Link>

            <Link
              to="/contact"
              className="min-h-[44px] px-5 py-2.5 rounded-lg border border-slate-300 text-slate-700 hover:border-[#056D67] font-semibold text-sm transition-colors flex items-center gap-2"
            >
              <Phone className="w-4 h-4 text-[#056D67]" />
              <span>Contact Support</span>
            </Link>
          </div>

        </div>
      </section>
    </>
  );
};
