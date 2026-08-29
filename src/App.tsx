/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { RouterProvider, useRouter } from './router/Router';
import { Navbar } from './components/Navbar';
import { Footer } from './components/Footer';
import { MobileQuickBar } from './components/MobileQuickBar';
import { QuoteModal } from './components/QuoteModal';
import { ReadinessQuizModal } from './components/ReadinessQuizModal';
import { AuditChecklistModal } from './components/AuditChecklistModal';

// Pages
import { HomePage } from './pages/HomePage';
import { NetworkAuditPage } from './pages/NetworkAuditPage';
import { ItAmcSlaPage } from './pages/ItAmcSlaPage';
import { ItConsultancyPage } from './pages/ItConsultancyPage';
import { AboutPage } from './pages/AboutPage';
import { ContactPage } from './pages/ContactPage';
import { PrivacyPolicyPage } from './pages/PrivacyPolicyPage';
import { TermsPage } from './pages/TermsPage';
import { NotFoundPage } from './pages/NotFoundPage';

function AppContent() {
  const { path } = useRouter();

  // Modal states
  const [quoteModalOpen, setQuoteModalOpen] = useState(false);
  const [selectedServiceForQuote, setSelectedServiceForQuote] = useState<'audit' | 'amc' | 'consultancy' | 'all'>('all');
  const [quotePrefillData, setQuotePrefillData] = useState<Record<string, any> | undefined>(undefined);

  const [quizModalOpen, setQuizModalOpen] = useState(false);
  const [checklistModalOpen, setChecklistModalOpen] = useState(false);

  const handleOpenQuote = (
    service: 'audit' | 'amc' | 'consultancy' | 'all' = 'all', 
    prefill?: Record<string, any>
  ) => {
    setSelectedServiceForQuote(service);
    setQuotePrefillData(prefill);
    setQuoteModalOpen(true);
  };

  const handleOpenQuiz = () => {
    setQuizModalOpen(true);
  };

  const handleOpenChecklist = () => {
    setChecklistModalOpen(true);
  };

  // Route matching
  const renderCurrentPage = () => {
    const cleanPath = path.split('#')[0].replace(/\/$/, '') || '/';

    switch (cleanPath) {
      case '/':
        return (
          <HomePage 
            onOpenQuote={handleOpenQuote}
            onOpenQuiz={handleOpenQuiz}
            onOpenChecklist={handleOpenChecklist}
          />
        );
      case '/network-audit':
        return (
          <NetworkAuditPage 
            onOpenQuote={handleOpenQuote}
            onOpenQuiz={handleOpenQuiz}
            onOpenChecklist={handleOpenChecklist}
          />
        );
      case '/it-amc':
      case '/it-amc-sla':
        return (
          <ItAmcSlaPage 
            onOpenQuote={handleOpenQuote}
          />
        );
      case '/it-consultancy':
        return (
          <ItConsultancyPage 
            onOpenQuote={handleOpenQuote}
          />
        );
      case '/about':
        return (
          <AboutPage 
            onOpenQuote={handleOpenQuote}
          />
        );
      case '/contact':
        return (
          <ContactPage />
        );
      case '/privacy-policy':
        return (
          <PrivacyPolicyPage />
        );
      case '/terms-and-conditions':
      case '/terms':
        return (
          <TermsPage />
        );
      default:
        return (
          <NotFoundPage />
        );
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-[#F4FAF8] text-slate-800 selection:bg-[#C1F24F] selection:text-[#034F4B] pb-16 md:pb-0">
      {/* Navigation */}
      <Navbar 
        onOpenQuote={handleOpenQuote}
        onOpenQuiz={handleOpenQuiz}
        onOpenChecklist={handleOpenChecklist}
      />

      {/* Main Content Router */}
      <main className="flex-grow">
        {renderCurrentPage()}
      </main>

      {/* Footer */}
      <Footer 
        onOpenQuote={handleOpenQuote}
        onOpenQuiz={handleOpenQuiz}
        onOpenChecklist={handleOpenChecklist}
      />

      {/* Mobile Sticky Quick Action Bar */}
      <MobileQuickBar 
        onOpenQuote={() => handleOpenQuote('all')}
      />

      {/* Interactive Modals */}
      <QuoteModal 
        isOpen={quoteModalOpen}
        initialService={selectedServiceForQuote}
        prefillData={quotePrefillData}
        onClose={() => setQuoteModalOpen(false)}
      />

      <ReadinessQuizModal 
        isOpen={quizModalOpen}
        onClose={() => setQuizModalOpen(false)}
        onOpenQuote={handleOpenQuote}
      />

      <AuditChecklistModal 
        isOpen={checklistModalOpen}
        onClose={() => setChecklistModalOpen(false)}
        onOpenQuote={() => handleOpenQuote('audit')}
      />
    </div>
  );
}

export default function App() {
  return (
    <RouterProvider>
      <AppContent />
    </RouterProvider>
  );
}
