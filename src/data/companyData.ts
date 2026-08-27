import { 
  AssessmentArea, 
  AuditMethodologyStep, 
  AmcCoverageItem, 
  SlaTier, 
  SlaSeverityRow, 
  ConsultancyServiceItem, 
  QuizQuestion 
} from '../types';

export const COMPANY_INFO = {
  name: "IMAN SERVICE COMPANY",
  tagline: "Your Single Point of Accountability for Enterprise IT Infrastructure",
  phone: "042-37455670",
  phoneFormatted: "+92 42 37455670",
  email: "info@imanservice.com",
  supportEmail: "support@imanservice.com",
  website: "imanservice.com",
  address: "181 STREET 5 , BLOCK C , OPF LAHORE",
  city: "Lahore, Pakistan",
  hours: "Monday – Saturday: 9:00 AM – 7:00 PM (Emergency SLA Support 24/7/365)",
  overview: "IMAN SERVICE COMPANY is a trusted IT infrastructure and technology services provider committed to delivering excellence across the entire IT lifecycle. We empower businesses with reliable, secure, and future-ready technology solutions through three specialized service pillars: Existing Networks Audit, IT-AMC/SLA and IT Consultancy. With a comprehensive portfolio spanning hardware and software, we serve as a single point of accountability for all your technology needs. Our mission is to transform IT from a cost center into a strategic business enabler—ensuring your systems are always available, always secure, and always aligned with your business goals."
};

export const BRAND_COLORS = {
  primary: "#056D67",
  primaryDark: "#034F4B",
  tealDark: "#096F67",
  accent: "#C1F24F",
  accentLight: "#D8FA8A",
  white: "#FFFFFF",
  bgLight: "#F4FAF8"
};

export const KEY_MESSAGING_THEMES = [
  {
    id: "single-point",
    title: "Single Point of Accountability",
    subtitle: "One trusted partner across all IT domains",
    description: "One partner for maintenance, auditing, and consulting across all IT domains. Eliminate the blame game between hardware vendors, network operators, and software providers.",
    icon: "ShieldCheck",
    stats: "100% Consolidated Management"
  },
  {
    id: "proactive",
    title: "Proactive, Not Reactive",
    subtitle: "Preventing outages before they occur",
    description: "We prevent problems before they impact your business through continuous health checks, predictive diagnostics, and structured maintenance cycles.",
    icon: "Activity",
    stats: "Up to 85% Outage Reduction"
  },
  {
    id: "sla-backed",
    title: "SLA-Backed Reliability",
    subtitle: "Measurable, contractual commitments",
    description: "Every service comes with clear, measurable commitments. Guaranteed response times, strict escalation matrixes, and transparent monthly reporting.",
    icon: "Clock",
    stats: "99.9% Uptime Commitment"
  },
  {
    id: "end-to-end",
    title: "End-to-End Capability",
    subtitle: "Complete digital estate coverage",
    description: "From hardware, operating systems, and servers to active networking, surveillance, and voice infrastructure—we cover your entire IT ecosystem.",
    icon: "Cpu",
    stats: "Full Lifecycle Coverage"
  },
  {
    id: "strategic-partner",
    title: "Strategic Partnership",
    subtitle: "Aligning technology with business growth",
    description: "We align technology with your business goals for long-term success, transforming IT from a passive overhead into a scalable business accelerator.",
    icon: "TrendingUp",
    stats: "ROI-Focused Roadmaps"
  }
];

export const ASSESSMENT_AREAS: AssessmentArea[] = [
  {
    area: "Network Infrastructure",
    examine: "LAN/WAN throughput, Wi-Fi heatmaps, firewall configurations, structured cabling, core/edge switches, routers, and access points.",
    icon: "Network",
    criticality: "Critical",
    checklist: [
      "Core & Edge switch port configuration & VLAN segmentation",
      "Firewall security policy & rule-base optimization",
      "Wireless signal heatmapping & RF interference check",
      "Structured cabling integrity & bandwidth certification",
      "WAN redundancy, failover & gateway latency profiling"
    ]
  },
  {
    area: "Hardware & Assets",
    examine: "Servers, workstations, storage systems, networking gear—cataloging assets and identifying those approaching End-of-Life (EOL).",
    icon: "HardDrive",
    criticality: "High",
    checklist: [
      "Hardware asset inventory with serials & specs",
      "Warranty tracking & End-of-Life (EOL) timeline mapping",
      "Storage SAN/NAS RAID health & SMART drive diagnostics",
      "Power redundancy (UPS/PDU) load stress testing",
      "Component thermal profiling & dust/environmental review"
    ]
  },
  {
    area: "Performance & Health",
    examine: "Latency, packet loss, throughput bottlenecks, capacity planning, and system utilization across peak and non-peak hours.",
    icon: "Gauge",
    criticality: "High",
    checklist: [
      "Continuous jitter, latency, and packet loss telemetry",
      "Bandwidth hog detection & Quality of Service (QoS) validation",
      "Server CPU, Memory, and Disk I/O threshold analysis",
      "DNS resolution speed & DHCP pool saturation checks",
      "Capacity growth projections for the next 12–24 months"
    ]
  },
  {
    area: "Security & Compliance",
    examine: "Vulnerability scanning, patch status, access controls, backup verification, and Disaster Recovery (DR) plan review.",
    icon: "Lock",
    criticality: "Critical",
    checklist: [
      "External & internal automated vulnerability assessment",
      "OS & firmware patch baseline compliance check",
      "Active Directory / IAM privilege escalation verification",
      "Backup recovery test (RTO and RPO simulation)",
      "Disaster Recovery (DR) readiness against NIST/CIS guidelines"
    ]
  }
];

export const AUDIT_METHODOLOGY: AuditMethodologyStep[] = [
  {
    step: 1,
    title: "Discovery & Inventory",
    description: "Complete mapping of your digital estate using non-intrusive automated discovery tools, physical site walk-throughs, and structured stakeholder interviews.",
    deliverable: "Digital Estate Inventory & Topology Diagram",
    icon: "Search"
  },
  {
    step: 2,
    title: "Performance & Health Analysis",
    description: "Deep-dive analysis of system health under real-world load, measuring throughput bottlenecks, Wi-Fi coverage deadzones, and hardware stress points.",
    deliverable: "Telemetry & Bottleneck Diagnostic Report",
    icon: "Activity"
  },
  {
    step: 3,
    title: "Risk & Security Review",
    description: "Benchmarking infrastructure against industry cybersecurity and compliance standards (NIST, CIS, ISO) to expose vulnerabilities and outdated firmware.",
    deliverable: "Threat Vector & Vulnerability Matrix",
    icon: "ShieldAlert"
  },
  {
    step: 4,
    title: "Strategic Roadmap",
    description: "Actionable, multi-year plan with phased execution priorities, budget projections, and clear ROI justification for upgrades and optimization.",
    deliverable: "Executive Roadmap & Remediation Blueprint",
    icon: "FileCheck"
  }
];

export const AUDIT_WHY_POINTS = [
  {
    title: "Identify Potential Problems Before Downtime",
    description: "Catch failing hardware, thermal anomalies, and misconfigured routes before they cause catastrophic work stoppages.",
    icon: "AlertTriangle"
  },
  {
    title: "Gain Complete Insight into Performance",
    description: "Know exactly how every megabit of bandwidth and gigabyte of memory is utilized across your corporate ecosystem.",
    icon: "Eye"
  },
  {
    title: "Reduce Security & Compliance Risk",
    description: "Eliminate unpatched vulnerabilities, unmanaged open ports, and unsecured access points across your facility.",
    icon: "Shield"
  },
  {
    title: "Prepare for Cloud Migration & Modernization",
    description: "Ensure your local network topology, throughput, and security are primed for hybrid or full-cloud architectures.",
    icon: "Cloud"
  },
  {
    title: "Optimize Costs by Eliminating Waste",
    description: "Right-size your hardware, terminate zombie licenses, and eliminate unnecessary replacement expenses.",
    icon: "DollarSign"
  }
];

export const AMC_COVERAGE_ITEMS: AmcCoverageItem[] = [
  {
    title: "Hardware Maintenance",
    description: "Regular inspections, repairs, component swaps, and preventive maintenance for desktops, laptops, servers, workstations, printers, and electronic security equipment.",
    icon: "Monitor",
    includedTasks: [
      "Physical cleaning, thermal paste refresh & dust elimination",
      "Component diagnostics (Motherboard, RAM, Power Supply, HDD/SSD)",
      "Printer maintenance, network queue tuning & roller servicing",
      "CCTV NVR/DVR, biometric attendance & access control checks"
    ]
  },
  {
    title: "Network Support & Management",
    description: "Monitoring, optimization, and maintenance of your entire network infrastructure for reliable connectivity and secure communication.",
    icon: "Share2",
    includedTasks: [
      "Switch port configuration, VLAN tagging & traffic balancing",
      "Wi-Fi controller tuning & roaming optimization",
      "Router & gateway load balancing / multi-WAN failover",
      "Network cabling health & patch panel re-termination"
    ]
  },
  {
    title: "Software Maintenance",
    description: "Keeping operating systems, business applications, productivity suites, and software tools updated, secure, and performing efficiently.",
    icon: "Code",
    includedTasks: [
      "Windows / Linux / macOS OS patching & updates",
      "Enterprise productivity software troubleshooting",
      "Driver updates & firmware baseline maintenance",
      "Software license compliance audits & key management"
    ]
  },
  {
    title: "Server Monitoring & Support",
    description: "Proactive server monitoring, performance optimization, troubleshooting, and maintenance to maximize reliability and uptime.",
    icon: "Server",
    includedTasks: [
      "24/7/365 CPU, RAM, Disk I/O & event log surveillance",
      "Virtualization management (VMware, Hyper-V, Proxmox)",
      "Domain Controller (Active Directory, DNS, DHCP) health checks",
      "Automated daily backup verification & test restores"
    ]
  },
  {
    title: "IT Help Desk Support",
    description: "Dedicated help desk for quick technical issue resolution, minimizing disruption to daily business activities.",
    icon: "Headphones",
    includedTasks: [
      "Multi-channel ticketing (Phone, Email, Portal, WhatsApp)",
      "Remote desktop instant assistance within SLA minutes",
      "Onsite dispatch for hardware or physical line faults",
      "User onboarding & access permission provisioning"
    ]
  },
  {
    title: "Network Security Management",
    description: "Regular security updates, vulnerability assessments, antivirus management, firewall tuning, and proactive threat monitoring.",
    icon: "ShieldCheck",
    includedTasks: [
      "Centralized Endpoint Protection / Antivirus management",
      "Firewall intrusion prevention & web filtering policies",
      "Ransomware protection & air-gapped backup schedules",
      "Staff security hygiene & phishing awareness updates"
    ]
  }
];

export const SLA_TIERS: SlaTier[] = [
  {
    id: "bronze",
    name: "Standard Business (Bronze)",
    tag: "Essential IT Coverage",
    responseCritical: "< 4 Hours",
    responseHigh: "< 8 Hours",
    responseMedium: "< 24 Hours",
    responseLow: "< 48 Hours",
    preventiveVisits: "Quarterly Scheduled Visit",
    reporting: "Quarterly Executive Health Report",
    bestFor: "Small offices and non-critical standard business hours operations.",
    popular: false
  },
  {
    id: "silver",
    name: "Business Pro (Silver)",
    tag: "Most Popular for Growing SMBs",
    responseCritical: "< 2 Hours",
    responseHigh: "< 4 Hours",
    responseMedium: "< 12 Hours",
    responseLow: "< 24 Hours",
    preventiveVisits: "Bi-Monthly Scheduled Visits",
    reporting: "Monthly Detailed Incident & Health Report",
    bestFor: "Mid-sized companies requiring fast turnaround and high uptime.",
    popular: true
  },
  {
    id: "gold",
    name: "Enterprise Prime (Gold)",
    tag: "Mission-Critical 24/7 SLA",
    responseCritical: "< 1 Hour (Immediate Remote)",
    responseHigh: "< 2 Hours",
    responseMedium: "< 6 Hours",
    responseLow: "< 12 Hours",
    preventiveVisits: "Monthly Comprehensive Onsite Visits",
    reporting: "Real-time Dashboard + Monthly Executive Briefing",
    bestFor: "Large enterprises, financial, healthcare & 24/7 operations.",
    popular: false
  }
];

export const SLA_SEVERITY_MATRIX: SlaSeverityRow[] = [
  {
    severity: "Level 1: Critical",
    level: "P1",
    example: "Complete network outage, primary server down, core firewall failure, or active security breach affecting entire organization.",
    ackTime: "Within 15 Minutes",
    onsiteOrRemoteResolution: "Immediate remote response / Onsite dispatch < 1-2 Hours",
    escalationManager: "Lead Infrastructure Architect & Director of Operations"
  },
  {
    severity: "Level 2: High",
    level: "P2",
    example: "Major department unable to work, backup system failure, critical business software degraded, internet line degraded without failover.",
    ackTime: "Within 30 Minutes",
    onsiteOrRemoteResolution: "Remote triage < 1 Hour / Onsite within 2-4 Hours",
    escalationManager: "Senior Systems Engineer"
  },
  {
    severity: "Level 3: Medium",
    level: "P3",
    example: "Individual workstation issues, shared network printer offline, slow application performance for non-critical team.",
    ackTime: "Within 2 Hours",
    onsiteOrRemoteResolution: "Remote assistance within 4-8 Hours",
    escalationManager: "Helpdesk Team Lead"
  },
  {
    severity: "Level 4: Low / Request",
    level: "P4",
    example: "New user account creation, software upgrade request, minor aesthetic hardware adjustments, scheduled routine tasks.",
    ackTime: "Within 4 Hours",
    onsiteOrRemoteResolution: "Resolved within 24–48 Hours",
    escalationManager: "Tier-1 Technical Support Specialist"
  }
];

export const CONSULTANCY_SERVICES: ConsultancyServiceItem[] = [
  {
    title: "IT Strategy & Planning",
    description: "Development of a tailored IT strategy aligned with business goals, digital transformation planning, and long-term IT roadmap creation.",
    icon: "Compass",
    outcomes: [
      "3–5 Year IT Capability Roadmap",
      "Technology budget forecast & CAPEX/OPEX optimization",
      "Business continuity & scalable architecture milestones"
    ]
  },
  {
    title: "Technology Assessment",
    description: "In-depth evaluation of current IT infrastructure to identify gaps, risks, single points of failure, and digital opportunities.",
    icon: "FileSearch",
    outcomes: [
      "Complete IT maturity benchmark scorecard",
      "Gap analysis between business objectives and technology readiness",
      "Technical debt quantification & mitigation priorities"
    ]
  },
  {
    title: "Solution Architecture & Design",
    description: "Defining the right technology stack for every project stage—from pre-planning and vendor scoping through implementation.",
    icon: "LayoutGrid",
    outcomes: [
      "High-availability server & network blueprint",
      "Hybrid-cloud & on-premise integration models",
      "Zero-Trust cybersecurity framework designs"
    ]
  },
  {
    title: "Vendor Selection & Procurement",
    description: "Independent advice on software and hardware packages that work best for your business, preventing vendor lock-in.",
    icon: "ShoppingBag",
    outcomes: [
      "RFP drafting & vendor proposal evaluation",
      "Neutral price negotiation and technical validation",
      "Volume license optimization and hardware sizing"
    ]
  },
  {
    title: "Digital Transformation",
    description: "Practical, phased guidance to help your business modernize legacy workflows, adopt cloud tools, and succeed in today's digital landscape.",
    icon: "Zap",
    outcomes: [
      "Cloud migration strategy (Microsoft 365, AWS, Azure, Google Cloud)",
      "Legacy system modernization without operational interruption",
      "Change management & team technology adoption programs"
    ]
  }
];

export const ABOUT_COMMITMENTS = [
  {
    title: "Reliability",
    description: "Systems that stay online, fast, and secure when your business needs them most. We engineer redundancy into every solution.",
    icon: "CheckCircle2"
  },
  {
    title: "Transparency",
    description: "Clear SLAs, honest reporting, predictable pricing, and absolutely zero hidden fees or unexpected bill shocks.",
    icon: "FileText"
  },
  {
    title: "Expertise",
    description: "Certified network engineers, systems administrators, and enterprise security professionals with real-world battle-tested acumen.",
    icon: "Award"
  },
  {
    title: "Partnership",
    description: "We don't act as a distant vendor—we succeed when your business succeeds, treating your IT infrastructure like our own.",
    icon: "Handshake"
  }
];

export const HEALTH_QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: 1,
    question: "When was your last comprehensive network & IT infrastructure audit conducted?",
    description: "Infrastructure changes over time can introduce hidden security vulnerabilities and configuration drift.",
    options: [
      { label: "Never or more than 2 years ago", points: 0, riskNote: "High risk of unpatched vulnerabilities and undocumented assets." },
      { label: "Between 1 and 2 years ago", points: 10, riskNote: "Moderate risk—recommend a refresh to capture network topology changes." },
      { label: "Within the last 12 months", points: 20 },
      { label: "We conduct ongoing quarterly professional audits", points: 25 }
    ]
  },
  {
    id: 2,
    question: "How do you manage IT maintenance and system emergencies?",
    description: "Proactive AMC contracts reduce emergency downtime by up to 85% compared to ad-hoc repairs.",
    options: [
      { label: "Reactive 'Break-Fix' (we only call someone when things break)", points: 0, riskNote: "Severe risk of extended downtime, lost revenue, and high emergency repair bills." },
      { label: "Internal staff with no formal SLA commitments", points: 10, riskNote: "Staff may get overwhelmed during major outages without specialized escalation tiers." },
      { label: "Third-party vendor with loose verbal agreement", points: 15, riskNote: "Lacks contractual response time enforcement." },
      { label: "Structured IT-AMC with SLA-backed response & regular preventive visits", points: 25 }
    ]
  },
  {
    id: 3,
    question: "What is the current status of your data backups and Disaster Recovery (DR)?",
    description: "Backups are only as reliable as their latest successful restoration test.",
    options: [
      { label: "No regular automated backup schedule", points: 0, riskNote: "Catastrophic risk of permanent data loss in case of ransomware or hardware failure." },
      { label: "Manual backups onto external USB/hard drives occasionally", points: 10, riskNote: "High human error rate and susceptibility to physical theft or ransomware infection." },
      { label: "Automated daily backups, but rarely or never tested for recovery", points: 15, riskNote: "Unverified backups frequently fail during critical restores." },
      { label: "Automated 3-2-1 hybrid backups with scheduled test restore drills", points: 25 }
    ]
  },
  {
    id: 4,
    question: "How are your network security and firewall policies managed?",
    description: "Modern threats require unified endpoint protection, firewall rules, and patch management.",
    options: [
      { label: "Basic ISP router with default password & consumer antivirus", points: 0, riskNote: "Critical vulnerability to unauthorized intrusion and lateral cyber attacks." },
      { label: "Decent firewall in place, but firmware and rules haven't been updated recently", points: 10, riskNote: "Outdated firmware is the #1 vector for network penetration." },
      { label: "Enterprise firewall and managed antivirus on most machines", points: 20 },
      { label: "Centrally managed UTM/Next-Gen Firewall, VLAN segmentation, and updated EDR", points: 25 }
    ]
  }
];
