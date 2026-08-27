export interface ServicePillar {
  id: 'audit' | 'amc' | 'consultancy';
  title: string;
  subtitle: string;
  tagline: string;
  description: string;
  iconName: string;
  badge: string;
}

export interface AssessmentArea {
  area: string;
  examine: string;
  icon: string;
  criticality: 'High' | 'Critical' | 'Medium';
  checklist: string[];
}

export interface AuditMethodologyStep {
  step: number;
  title: string;
  description: string;
  deliverable: string;
  icon: string;
}

export interface AmcCoverageItem {
  title: string;
  description: string;
  icon: string;
  includedTasks: string[];
}

export interface SlaTier {
  id: string;
  name: string;
  tag: string;
  responseCritical: string;
  responseHigh: string;
  responseMedium: string;
  responseLow: string;
  preventiveVisits: string;
  reporting: string;
  bestFor: string;
  popular?: boolean;
}

export interface SlaSeverityRow {
  severity: string;
  level: string;
  example: string;
  ackTime: string;
  onsiteOrRemoteResolution: string;
  escalationManager: string;
}

export interface ConsultancyServiceItem {
  title: string;
  description: string;
  icon: string;
  outcomes: string[];
}

export interface QuoteRequestData {
  companyName: string;
  contactPerson: string;
  email: string;
  phone: string;
  serviceInterest: 'audit' | 'amc' | 'consultancy' | 'all';
  workstationsCount: number;
  serversCount: number;
  networkDevicesCount: number;
  slaTier: string;
  urgency: 'urgent' | 'planned' | 'exploring';
  notes: string;
}

export interface QuizQuestion {
  id: number;
  question: string;
  description: string;
  options: {
    label: string;
    points: number;
    riskNote?: string;
  }[];
}
