import React, { useState, useEffect, useRef } from 'react';
import { HEALTH_QUIZ_QUESTIONS } from '../data/companyData';
import { 
  X, 
  Sparkles, 
  CheckCircle2, 
  AlertTriangle, 
  ShieldAlert, 
  ShieldCheck, 
  ArrowRight, 
  RotateCcw,
  FileText
} from 'lucide-react';
import confetti from 'canvas-confetti';

interface ReadinessQuizModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenQuote: (service?: 'audit' | 'amc' | 'consultancy' | 'all', prefill?: Record<string, any>) => void;
}

export const ReadinessQuizModal: React.FC<ReadinessQuizModalProps> = ({
  isOpen,
  onClose,
  onOpenQuote
}) => {
  const [currentStep, setCurrentStep] = useState<number>(0);
  const [selectedAnswers, setSelectedAnswers] = useState<number[]>([]);
  const [showResults, setShowResults] = useState<boolean>(false);
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      previousFocusRef.current = document.activeElement as HTMLElement;
      document.body.style.overflow = 'hidden';
      
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          onClose();
          return;
        }

        if (e.key === 'Tab' && modalRef.current) {
          const focusableElements = modalRef.current.querySelectorAll<HTMLElement>(
            'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
          );
          if (focusableElements.length === 0) return;

          const firstElement = focusableElements[0];
          const lastElement = focusableElements[focusableElements.length - 1];

          if (e.shiftKey && document.activeElement === firstElement) {
            e.preventDefault();
            lastElement.focus();
          } else if (!e.shiftKey && document.activeElement === lastElement) {
            e.preventDefault();
            firstElement.focus();
          }
        }
      };

      document.addEventListener('keydown', handleKeyDown);

      // Focus first interactive element in modal
      const timer = setTimeout(() => {
        if (modalRef.current) {
          const firstFocusable = modalRef.current.querySelector<HTMLElement>('button, [tabindex="0"]');
          firstFocusable?.focus();
        }
      }, 50);

      return () => {
        document.body.style.overflow = '';
        document.removeEventListener('keydown', handleKeyDown);
        clearTimeout(timer);
        if (previousFocusRef.current) {
          previousFocusRef.current.focus();
        }
      };
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const totalQuestions = HEALTH_QUIZ_QUESTIONS.length;
  const currentQuestion = HEALTH_QUIZ_QUESTIONS[currentStep];

  const handleSelectOption = (points: number, optionIdx: number) => {
    const nextAnswers = [...selectedAnswers];
    nextAnswers[currentStep] = points;
    setSelectedAnswers(nextAnswers);

    if (currentStep < totalQuestions - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      setShowResults(true);
      confetti({
        particleCount: 60,
        spread: 70,
        origin: { y: 0.6 }
      });
    }
  };

  const calculateTotalScore = () => {
    return selectedAnswers.reduce((sum, current) => sum + (current || 0), 0);
  };

  const totalScore = calculateTotalScore();

  const getRiskStatus = () => {
    if (totalScore >= 80) {
      return {
        level: 'Optimal / Low Risk',
        badgeColor: 'bg-emerald-100 text-emerald-800 border-emerald-300',
        icon: <ShieldCheck className="w-8 h-8 text-emerald-600" />,
        summary: 'Your IT infrastructure demonstrates mature policies, though continuous auditing is recommended to maintain compliance and guard against emerging threat vectors.'
      };
    } else if (totalScore >= 45) {
      return {
        level: 'Moderate Vulnerability Risk',
        badgeColor: 'bg-amber-100 text-amber-800 border-amber-300',
        icon: <AlertTriangle className="w-8 h-8 text-amber-600" />,
        summary: 'Several critical operational blindspots exist in your IT posture—particularly around SLA turnaround times, backup restore validation, or network configuration drift.'
      };
    } else {
      return {
        level: 'High / Critical Outage Risk',
        badgeColor: 'bg-rose-100 text-rose-800 border-rose-300',
        icon: <ShieldAlert className="w-8 h-8 text-rose-600" />,
        summary: 'Your organization is highly vulnerable to prolonged downtime, ransomware impact, or hardware failures. An immediate Existing Network Audit and structured IT-AMC are strongly advised.'
      };
    }
  };

  const riskStatus = getRiskStatus();

  const handleReset = () => {
    setCurrentStep(0);
    setSelectedAnswers([]);
    setShowResults(false);
  };

  const handleRequestRemediation = () => {
    onClose();
    onOpenQuote('audit', {
      notes: `Completed IT Health Readiness Quiz with score ${totalScore}/100 (${riskStatus.level}). Requesting priority assessment.`
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-xs animate-in fade-in duration-200">
      <div 
        ref={modalRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="quiz-modal-title"
        className="bg-white rounded-2xl max-w-xl w-full p-6 sm:p-8 shadow-2xl border border-slate-100 relative max-h-[90vh] overflow-y-auto"
      >
        
        {/* Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute top-4 right-4 min-w-[44px] min-h-[44px] flex items-center justify-center rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors focus:outline-hidden focus:ring-2 focus:ring-[#056D67]"
          aria-label="Close quiz modal"
        >
          <X className="w-5 h-5" />
        </button>

        {!showResults ? (
          <div>
            {/* Header */}
            <div className="mb-6 pr-10">
              <div className="flex items-center justify-between text-xs font-bold text-[#056D67] uppercase tracking-wider mb-2">
                <span className="flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>IT Health & Network Readiness Analyzer</span>
                </span>
                <span>Question {currentStep + 1} of {totalQuestions}</span>
              </div>
              
              {/* Progress Bar */}
              <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                <div 
                  className="bg-[#056D67] h-full transition-all duration-300"
                  style={{ width: `${((currentStep + 1) / totalQuestions) * 100}%` }}
                />
              </div>
            </div>

            {/* Question Card */}
            <div className="mb-6">
              <h3 id="quiz-modal-title" className="text-lg sm:text-xl font-bold text-slate-900 font-display">
                {currentQuestion.question}
              </h3>
              <p className="text-xs sm:text-sm text-slate-500 mt-1">
                {currentQuestion.description}
              </p>
            </div>

            {/* Options */}
            <div className="space-y-3">
              {currentQuestion.options.map((option, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleSelectOption(option.points, idx)}
                  className="w-full min-h-[48px] text-left p-4 rounded-xl border border-slate-200 hover:border-[#056D67] bg-[#F4FAF8]/60 hover:bg-[#F4FAF8] text-slate-800 text-sm font-medium transition-all flex items-center justify-between group focus:outline-hidden focus:ring-2 focus:ring-[#056D67]"
                >
                  <span className="pr-4">{option.label}</span>
                  <div className="w-6 h-6 rounded-full border border-slate-300 group-hover:border-[#056D67] group-hover:bg-[#056D67] group-hover:text-white flex items-center justify-center flex-shrink-0 transition-colors text-xs font-bold">
                    &rarr;
                  </div>
                </button>
              ))}
            </div>

            {/* Navigation back */}
            {currentStep > 0 && (
              <div className="mt-6 pt-4 border-t border-slate-100 flex justify-start">
                <button
                  type="button"
                  onClick={() => setCurrentStep(currentStep - 1)}
                  className="min-h-[44px] inline-flex items-center text-xs text-slate-500 hover:text-slate-800 font-medium"
                >
                  &larr; Previous Question
                </button>
              </div>
            )}
          </div>
        ) : (
          /* Results View */
          <div className="text-center py-2">
            <div className="w-16 h-16 rounded-2xl bg-[#F4FAF8] border border-slate-200 flex items-center justify-center mx-auto mb-4">
              {riskStatus.icon}
            </div>

            <div className={`inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider border mb-2 ${riskStatus.badgeColor}`}>
              {riskStatus.level}
            </div>

            <h3 id="quiz-modal-title" className="text-2xl font-extrabold text-slate-900 font-display">
              Readiness Score: {totalScore} / 100
            </h3>

            <p className="text-xs sm:text-sm text-slate-600 mt-2 max-w-md mx-auto leading-relaxed">
              {riskStatus.summary}
            </p>

            {/* Recommendations Box */}
            <div className="mt-6 p-4 rounded-xl bg-[#F4FAF8] border border-[#056D67]/20 text-left text-xs text-slate-700 space-y-2">
              <div className="font-bold text-[#056D67] uppercase text-xs">
                Recommended Next Steps from i Man Service:
              </div>
              <div className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-[#056D67] flex-shrink-0 mt-0.5" />
                <span>Perform an <strong>Existing Network Audit</strong> to inventory all hardware assets and firmware risks.</span>
              </div>
              <div className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-[#056D67] flex-shrink-0 mt-0.5" />
                <span>Establish an <strong>IT-AMC / SLA Agreement</strong> to secure contractual response times for outages.</span>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="mt-6 flex flex-col sm:flex-row items-center gap-3">
              <button
                type="button"
                onClick={handleRequestRemediation}
                className="w-full min-h-[44px] py-3 px-4 rounded-xl bg-[#056D67] hover:bg-[#034F4B] text-white font-bold text-sm transition-all shadow-md flex items-center justify-center gap-2"
              >
                <span>Request IT Proposal</span>
                <ArrowRight className="w-4 h-4 text-[#C1F24F]" />
              </button>
              <button
                type="button"
                onClick={handleReset}
                className="w-full sm:w-auto min-h-[44px] py-3 px-4 rounded-xl border border-slate-300 hover:bg-slate-100 text-slate-700 font-semibold text-xs transition-colors flex items-center justify-center gap-1.5"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>Retake Quiz</span>
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
