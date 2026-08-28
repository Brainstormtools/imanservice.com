/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { KeyThemes } from './components/KeyThemes';
import { NetworkAuditExplorer } from './components/NetworkAuditExplorer';
import { SlaTierBuilder } from './components/SlaTierBuilder';
import { SlaMatrixTable } from './components/SlaMatrixTable';
import { ConsultancySection } from './components/ConsultancySection';
import { AboutSection } from './components/AboutSection';
import { ContactSection } from './components/ContactSection';
import { Footer } from './components/Footer';
import { QuoteModal } from './components/QuoteModal';
import { ReadinessQuizModal } from './components/ReadinessQuizModal';
import { AuditChecklistModal } from './components/AuditChecklistModal';

export default function App() {
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

  return (
    <div className="min-h-screen flex flex-col bg-[#F4FAF8] text-slate-800 selection:bg-[#C1F24F] selection:text-[#034F4B]">
      
      {/* Navigation */}
      <Navbar 
        onOpenQuote={handleOpenQuote}
        onOpenQuiz={handleOpenQuiz}
        onOpenChecklist={handleOpenChecklist}
      />

      {/* Main Content Sections */}
      <main className="flex-grow">
        
        {/* 1. Hero Section */}
        <Hero 
          onOpenQuote={handleOpenQuote}
          onOpenQuiz={handleOpenQuiz}
        />

        {/* 2. Key Messaging Themes (5 Pillars) */}
        <KeyThemes 
          onOpenQuote={handleOpenQuote}
        />

        {/* 3. Core Pillar 1: Existing Network Audit */}
        <NetworkAuditExplorer 
          onOpenQuote={handleOpenQuote}
          onOpenChecklist={handleOpenChecklist}
        />

        {/* 4. Core Pillar 2: IT-AMC / SLA (Annual Maintenance Contract & Scope Calculator) */}
        <SlaTierBuilder 
          onOpenQuote={handleOpenQuote}
        />

        {/* 5. SLA Severity & Escalation Matrix Table */}
        <SlaMatrixTable 
          onOpenQuote={handleOpenQuote}
        />

        {/* 6. Core Pillar 3: IT Consultancy Service */}
        <ConsultancySection 
          onOpenQuote={handleOpenQuote}
        />

        {/* 7. About i Man Service & 4 Commitments */}
        <AboutSection 
          onOpenQuote={handleOpenQuote}
        />

        {/* 8. Contact Hub & Inquiry Desk (Lahore Office) */}
        <ContactSection />

      </main>

      {/* Footer */}
      <Footer 
        onOpenQuote={handleOpenQuote}
        onOpenQuiz={handleOpenQuiz}
        onOpenChecklist={handleOpenChecklist}
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
