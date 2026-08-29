import React from 'react';
import { SeoHead } from '../components/SeoHead';
import { Hero } from '../components/Hero';
import { KeyThemes } from '../components/KeyThemes';
import { NetworkAuditExplorer } from '../components/NetworkAuditExplorer';
import { SlaTierBuilder } from '../components/SlaTierBuilder';
import { SlaMatrixTable } from '../components/SlaMatrixTable';
import { ConsultancySection } from '../components/ConsultancySection';
import { AboutSection } from '../components/AboutSection';
import { ContactSection } from '../components/ContactSection';

interface HomePageProps {
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
  onOpenQuiz: () => void;
  onOpenChecklist: () => void;
}

export const HomePage: React.FC<HomePageProps> = ({
  onOpenQuote,
  onOpenQuiz,
  onOpenChecklist
}) => {
  const homeSchema = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": ["LocalBusiness", "ITService", "Organization"],
        "@id": "https://www.imanservice.com/#organization",
        "name": "i Man Service",
        "url": "https://www.imanservice.com/",
        "logo": "https://www.imanservice.com/logo.png",
        "image": "https://www.imanservice.com/og-image.jpg",
        "description": "i Man Service provides network audits, fixed-fee IT-AMC/SLA maintenance and strategic IT consultancy for businesses in Lahore, Pakistan.",
        "telephone": "+923149020008",
        "email": "info@imanservice.com",
        "priceRange": "$$",
        "address": {
          "@type": "PostalAddress",
          "streetAddress": "P-120, Siddique Trade Center, Gulberg II",
          "addressLocality": "Lahore",
          "addressRegion": "Punjab",
          "postalCode": "54660",
          "addressCountry": "PK"
        },
        "geo": {
          "@type": "GeoCoordinates",
          "latitude": 31.5348,
          "longitude": 74.3486
        },
        "openingHoursSpecification": [
          {
            "@type": "OpeningHoursSpecification",
            "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
            "opens": "09:00",
            "closes": "19:00"
          }
        ]
      }
    ]
  };

  return (
    <>
      <SeoHead
        title="i Man Service | IT Infrastructure, Network Audit & AMC Lahore"
        description="i Man Service provides network audits, fixed-fee IT-AMC/SLA maintenance and strategic IT consultancy for businesses in Lahore, Pakistan."
        canonical="https://www.imanservice.com/"
        ogType="website"
        schema={homeSchema}
      />

      {/* 1. Hero Section */}
      <Hero 
        onOpenQuote={onOpenQuote}
        onOpenQuiz={onOpenQuiz}
      />

      {/* 2. Key Messaging Themes (5 Pillars) */}
      <KeyThemes 
        onOpenQuote={onOpenQuote}
      />

      {/* 3. Core Pillar 1: Existing Network Audit */}
      <NetworkAuditExplorer 
        onOpenQuote={onOpenQuote}
        onOpenChecklist={onOpenChecklist}
      />

      {/* 4. Core Pillar 2: IT-AMC / SLA (Annual Maintenance Contract & Scope Calculator) */}
      <SlaTierBuilder 
        onOpenQuote={onOpenQuote}
      />

      {/* 5. SLA Severity & Escalation Matrix Table */}
      <SlaMatrixTable 
        onOpenQuote={onOpenQuote}
      />

      {/* 6. Core Pillar 3: IT Consultancy Service */}
      <ConsultancySection 
        onOpenQuote={onOpenQuote}
      />

      {/* 7. About i Man Service & Commitments */}
      <AboutSection 
        onOpenQuote={onOpenQuote}
      />

      {/* 8. Contact Hub & Inquiry Desk (Lahore Office) */}
      <ContactSection />
    </>
  );
};
