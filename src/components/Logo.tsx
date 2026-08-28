import React from 'react';

interface LogoProps {
  variant?: 'light' | 'dark' | 'mono';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showTagline?: boolean;
  type?: 'full' | 'mark';
  className?: string;
}

export const Logo: React.FC<LogoProps> = ({
  variant = 'light',
  size = 'md',
  showTagline = false,
  type = 'mark',
  className = ''
}) => {
  const isDark = variant === 'dark';
  const tealColor = isDark ? '#2DD4BF' : '#056D67'; // Crisp bright teal for dark mode, brand deep teal for light
  const tealFill = isDark ? '#FFFFFF' : '#056D67';
  const helmetColor = '#C1F24F'; // High-vis lime accent from uploaded logo

  const sizeStyles = {
    sm: { height: 'h-8', iconWidth: 'w-6', fullWidth: 'w-36', text: 'text-base' },
    md: { height: 'h-10', iconWidth: 'w-7', fullWidth: 'w-44', text: 'text-lg' },
    lg: { height: 'h-14', iconWidth: 'w-10', fullWidth: 'w-56', text: 'text-2xl' },
    xl: { height: 'h-20', iconWidth: 'w-14', fullWidth: 'w-72', text: 'text-3xl' }
  }[size];

  // If user requests the complete full graphic lockup (matching lgo complete.jpeg)
  if (type === 'full') {
    return (
      <div className={`inline-flex items-center select-none ${className}`}>
        <svg
          viewBox="0 0 520 180"
          className={`${sizeStyles.fullWidth} h-auto`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* ================= 1. THE "i" ENGINEER MARK ================= */}
          {/* Helmet Dome with top ridges and brim */}
          <g>
            {/* Main Safety Helmet Dome */}
            <path
              d="M32 40 C32 18 42 8 58 8 C74 8 84 18 84 40 Z"
              fill={helmetColor}
            />
            {/* Helmet center ridge crest */}
            <path
              d="M53 8 C53 8 53 38 53 40 L63 40 C63 38 63 8 63 8 Z"
              fill="#A7DE2B"
              opacity="0.6"
            />
            {/* Helmet side groove 1 */}
            <path
              d="M42 16 C42 16 41 38 41 40 L45 40 C45 38 46 16 46 16 Z"
              fill="#A7DE2B"
              opacity="0.35"
            />
            {/* Helmet side groove 2 */}
            <path
              d="M74 16 C74 16 75 38 75 40 L71 40 C71 38 70 16 70 16 Z"
              fill="#A7DE2B"
              opacity="0.35"
            />
            {/* Helmet Curved Base Brim */}
            <rect
              x="24"
              y="38"
              width="68"
              height="8"
              rx="4"
              fill={helmetColor}
            />
          </g>

          {/* Head - Disc / Circle in Deep Teal */}
          <circle
            cx="58"
            cy="60"
            r="19"
            fill={tealFill}
          />

          {/* Body Columns forming the 'i' stem with classical serifs and V collar */}
          <g>
            {/* Left Pillar */}
            <path
              d="M24 74 
                 C35 74 38 78 38 88 
                 L38 126 
                 C38 136 35 140 24 140 
                 L51 140 
                 L51 86 
                 L39 74 
                 Z"
              fill={tealFill}
            />
            {/* Right Pillar */}
            <path
              d="M92 74 
                 C81 74 78 78 78 88 
                 L78 126 
                 C78 136 81 140 92 140 
                 L65 140 
                 L65 86 
                 L77 74 
                 Z"
              fill={tealFill}
            />
          </g>

          {/* ================= 2. THE "M A N" LETTERS ================= */}
          {/* Letter 'M' */}
          <path
            d="M102 74 L123 74 L154 114 L185 74 L206 74 L206 140 L186 140 L186 98 L159 133 L149 133 L122 98 L122 140 L102 140 Z"
            fill={tealFill}
          />

          {/* Letter 'A' with Lime Accent Triangle */}
          <g>
            {/* Outer 'A' geometry */}
            <path
              d="M214 140 L256 74 L288 74 L330 140 L308 140 L297 122 L247 122 L236 140 Z M257 106 L287 106 L272 82 Z"
              fill={tealFill}
            />
            {/* Inner signature Lime Green triangle */}
            <polygon
              points="272,96 250,138 294,138"
              fill={helmetColor}
            />
          </g>

          {/* Letter 'N' */}
          <path
            d="M340 74 L361 74 L408 119 L408 74 L428 74 L428 140 L407 140 L360 95 L360 140 L340 140 Z"
            fill={tealFill}
          />

          {/* ================= 3. SUBTITLE: "SERVICE COMPANY" ================= */}
          {/* Left Lime accent rule */}
          <line
            x1="24"
            y1="162"
            x2="95"
            y2="162"
            stroke={helmetColor}
            strokeWidth="3.5"
            strokeLinecap="round"
          />

          {/* Center subtitle text */}
          <text
            x="260"
            y="167"
            textAnchor="middle"
            fill={tealFill}
            fontSize="18"
            fontWeight="700"
            fontFamily="'Space Grotesk', 'Plus Jakarta Sans', sans-serif"
            letterSpacing="8.5"
          >
            SERVICE COMPANY
          </text>

          {/* Right Lime accent rule */}
          <line
            x1="425"
            y1="162"
            x2="496"
            y2="162"
            stroke={helmetColor}
            strokeWidth="3.5"
            strokeLinecap="round"
          />
        </svg>
      </div>
    );
  }

  // Default Standard Mark + Typography (Matches the uploaded Engineer Icon & Brand text)
  return (
    <div className={`inline-flex items-center gap-3 select-none ${className}`}>
      {/* Precision Vector Icon matching logo.jpeg */}
      <div className={`relative ${sizeStyles.iconWidth} ${sizeStyles.height} flex-shrink-0 flex items-center justify-center`}>
        <svg
          viewBox="0 0 100 135"
          className="w-full h-full drop-shadow-xs overflow-visible"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Hardhat Helmet (Lime Accent #C1F24F) */}
          <g>
            {/* Dome */}
            <path
              d="M20 38 C20 14 32 4 50 4 C68 4 80 14 80 38 Z"
              fill={helmetColor}
            />
            {/* Center crest ridge */}
            <path
              d="M45 4 C45 4 45 36 45 38 L55 38 C55 36 55 4 55 4 Z"
              fill="#A7DE2B"
              opacity="0.6"
            />
            {/* Left groove */}
            <path
              d="M32 12 C32 12 31 36 31 38 L36 38 C36 36 37 12 37 12 Z"
              fill="#A7DE2B"
              opacity="0.35"
            />
            {/* Right groove */}
            <path
              d="M68 12 C68 12 69 36 69 38 L64 38 C64 36 63 12 63 12 Z"
              fill="#A7DE2B"
              opacity="0.35"
            />
            {/* Helmet Visor Brim */}
            <rect
              x="12"
              y="36"
              width="76"
              height="8"
              rx="4"
              fill={helmetColor}
            />
          </g>

          {/* Engineer Head - Teal Circle */}
          <circle
            cx="50"
            cy="58"
            r="20"
            fill={tealFill}
          />

          {/* Left Column / Body */}
          <path
            d="M12 74 
               C24 74 27 78 27 88 
               L27 122 
               C27 132 24 135 12 135 
               L42 135 
               L42 86 
               L29 74 
               Z"
            fill={tealFill}
          />

          {/* Right Column / Body */}
          <path
            d="M88 74 
               C76 74 73 78 73 88 
               L73 122 
               C73 132 76 135 88 135 
               L58 135 
               L58 86 
               L71 74 
               Z"
            fill={tealFill}
          />
        </svg>
      </div>

      {/* Brand Name Typography */}
      <div className="flex flex-col">
        <div className="flex items-center tracking-tight font-extrabold font-display leading-tight">
          <span className={`text-xl sm:${sizeStyles.text} ${isDark ? 'text-white' : 'text-[#056D67]'}`}>
            i Man
          </span>
          <span className={`ml-1.5 font-light text-xl sm:${sizeStyles.text} ${isDark ? 'text-slate-200' : 'text-slate-700'}`}>
            Service
          </span>
          <span className="ml-2 text-[10px] font-bold px-1.5 py-0.5 rounded bg-[#C1F24F] text-[#034F4B] tracking-wider uppercase">
            IT
          </span>
        </div>
        {showTagline ? (
          <span className={`text-[10px] tracking-widest font-semibold uppercase ${isDark ? 'text-slate-300' : 'text-slate-500'}`}>
            Enterprise Infrastructure & SLA
          </span>
        ) : (
          <span className={`text-[10px] tracking-wider font-medium ${isDark ? 'text-slate-300' : 'text-[#056D67]/80'}`}>
            Enterprise IT Solutions
          </span>
        )}
      </div>
    </div>
  );
};
