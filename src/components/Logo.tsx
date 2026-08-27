import React from 'react';

interface LogoProps {
  variant?: 'light' | 'dark' | 'mono';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showTagline?: boolean;
  className?: string;
}

export const Logo: React.FC<LogoProps> = ({
  variant = 'light',
  size = 'md',
  showTagline = false,
  className = ''
}) => {
  const isDark = variant === 'dark';

  const sizeClasses = {
    sm: { mark: 'w-7 h-7', text: 'text-base', sub: 'text-[9px]' },
    md: { mark: 'w-9 h-9', text: 'text-xl', sub: 'text-[10px]' },
    lg: { mark: 'w-12 h-12', text: 'text-2xl', sub: 'text-xs' },
    xl: { mark: 'w-16 h-16', text: 'text-3xl', sub: 'text-sm' }
  }[size];

  return (
    <div className={`flex items-center gap-3 select-none ${className}`}>
      {/* Brand Geometric Logo Mark */}
      <div className={`relative ${sizeClasses.mark} flex-shrink-0`}>
        <svg
          viewBox="0 0 100 100"
          className="w-full h-full drop-shadow-sm"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Main Rounded Hex/Shield in Deep Teal #056D67 */}
          <rect
            x="4"
            y="4"
            width="92"
            height="92"
            rx="22"
            fill="#056D67"
          />
          
          {/* Subtle geometric gradient overlay with Dark Teal #096F67 */}
          <path
            d="M4 48 L48 4 L96 48 L52 96 Z"
            fill="#096F67"
            opacity="0.25"
          />

          {/* Clean 'I' and 'M' / Interconnected Network Node Monogram */}
          {/* Left Vertical Pillar (White #FFFFFF) */}
          <rect
            x="24"
            y="24"
            width="14"
            height="52"
            rx="5"
            fill="#FFFFFF"
          />

          {/* Right Network Pillar */}
          <rect
            x="46"
            y="36"
            width="14"
            height="40"
            rx="5"
            fill="#FFFFFF"
          />

          {/* Connecting Bridge / Node Bar */}
          <path
            d="M32 44 C32 44 42 34 50 36"
            stroke="#FFFFFF"
            strokeWidth="6"
            strokeLinecap="round"
          />

          {/* Signature Lime Green #C1F24F Accent Square (Top Right Node) */}
          <rect
            x="66"
            y="18"
            width="18"
            height="18"
            rx="4"
            fill="#C1F24F"
          />

          {/* Mini pulse signal line in Lime */}
          <circle
            cx="75"
            cy="27"
            r="3"
            fill="#056D67"
          />
        </svg>
      </div>

      {/* Brand Typography */}
      <div className="flex flex-col">
        <div className="flex items-center tracking-tight font-extrabold font-display leading-tight">
          <span className={isDark ? 'text-white' : 'text-[#056D67]'}>
            IMAN
          </span>
          <span className={`ml-1.5 font-light ${isDark ? 'text-slate-200' : 'text-slate-700'}`}>
            SERVICE
          </span>
          <span className="ml-1.5 text-xs font-semibold px-1.5 py-0.5 rounded bg-[#C1F24F] text-[#034F4B] tracking-wider uppercase">
            IT
          </span>
        </div>
        {showTagline ? (
          <span className={`text-[10px] tracking-widest font-semibold uppercase ${isDark ? 'text-slate-300' : 'text-slate-500'}`}>
            Enterprise Infrastructure & SLA
          </span>
        ) : (
          <span className={`text-[10px] tracking-wider font-medium ${isDark ? 'text-slate-300' : 'text-[#056D67]/80'}`}>
            COMPANY
          </span>
        )}
      </div>
    </div>
  );
};
