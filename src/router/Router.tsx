import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';

interface RouterContextType {
  path: string;
  pathname: string;
  hash: string;
  navigate: (to: string, options?: { replace?: boolean }) => void;
}

const getInitialPath = (): string => {
  if (typeof window === 'undefined') return '/';
  return window.location.pathname + window.location.hash;
};

const RouterContext = createContext<RouterContextType>({
  path: '/',
  pathname: '/',
  hash: '',
  navigate: () => {}
});

export const useRouter = () => useContext(RouterContext);

let activeScrollTimeout: ReturnType<typeof setTimeout> | null = null;
let activeScrollRaf: number | null = null;

/**
 * Robustly scrolls to a hash anchor element with sticky header offset
 * and respects prefers-reduced-motion. Retries automatically until the
 * target component mounts and finishes rendering.
 */
export function scrollToHash(hash: string, maxAttempts = 25): void {
  if (typeof window === 'undefined' || !hash) return;
  
  const id = hash.startsWith('#') ? hash.slice(1) : hash;
  if (!id) return;

  if (activeScrollTimeout !== null) {
    clearTimeout(activeScrollTimeout);
    activeScrollTimeout = null;
  }
  if (activeScrollRaf !== null) {
    cancelAnimationFrame(activeScrollRaf);
    activeScrollRaf = null;
  }

  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const behavior: ScrollBehavior = prefersReducedMotion ? 'auto' : 'smooth';

  let attempts = 0;

  const attemptScroll = () => {
    attempts++;

    // Locate the matching element by id, name attribute, or CSS selector
    let element: HTMLElement | null = document.getElementById(id);
    if (!element) {
      try {
        element = document.querySelector(`[name="${CSS.escape(id)}"]`) || document.querySelector(`#${CSS.escape(id)}`);
      } catch {
        // Ignore invalid selector syntax
      }
    }

    if (element) {
      // Calculate sticky header height dynamically
      const header = document.querySelector('header');
      const headerHeight = header ? header.getBoundingClientRect().height : 100;
      
      const rect = element.getBoundingClientRect();
      const elementAbsoluteTop = rect.top + window.pageYOffset;
      const targetScrollTop = Math.max(0, elementAbsoluteTop - headerHeight - 16);

      window.scrollTo({
        top: targetScrollTop,
        behavior
      });

      activeScrollTimeout = null;
      activeScrollRaf = null;
      return;
    }

    // If destination component is still mounting/rendering, retry
    if (attempts < maxAttempts) {
      const delay = Math.min(20 * attempts, 80);
      activeScrollTimeout = setTimeout(() => {
        activeScrollRaf = requestAnimationFrame(attemptScroll);
      }, delay);
    } else {
      activeScrollTimeout = null;
      activeScrollRaf = null;
    }
  };

  activeScrollRaf = requestAnimationFrame(attemptScroll);
}

export const RouterProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [fullPath, setFullPath] = useState<string>(getInitialPath);

  // Sync state on popstate and hashchange (browser Back / Forward navigation)
  useEffect(() => {
    const handleLocationChange = () => {
      const newPath = window.location.pathname + window.location.hash;
      setFullPath(newPath);

      if (window.location.hash) {
        scrollToHash(window.location.hash);
      }
    };

    window.addEventListener('popstate', handleLocationChange);
    window.addEventListener('hashchange', handleLocationChange);

    // Initial mount: check if there's a hash in the URL on first page load
    if (window.location.hash) {
      scrollToHash(window.location.hash);
    }

    return () => {
      window.removeEventListener('popstate', handleLocationChange);
      window.removeEventListener('hashchange', handleLocationChange);
      if (activeScrollTimeout) clearTimeout(activeScrollTimeout);
      if (activeScrollRaf) cancelAnimationFrame(activeScrollRaf);
    };
  }, []);

  // Intercept same-page <a href="#..."> clicks to apply smooth sticky header offset
  useEffect(() => {
    const handleAnchorClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.altKey || e.shiftKey) {
        return;
      }

      const target = (e.target as HTMLElement).closest('a');
      if (!target) return;

      const href = target.getAttribute('href');
      if (href && href.startsWith('#') && href.length > 1) {
        e.preventDefault();
        
        if (window.location.hash !== href) {
          window.history.pushState({}, '', href);
          setFullPath(window.location.pathname + href);
        }
        
        scrollToHash(href);
      }
    };

    document.addEventListener('click', handleAnchorClick);
    return () => document.removeEventListener('click', handleAnchorClick);
  }, []);

  const navigate = useCallback((to: string, options?: { replace?: boolean }) => {
    if (to.startsWith('http://') || to.startsWith('https://') || to.startsWith('tel:') || to.startsWith('mailto:')) {
      window.location.href = to;
      return;
    }

    const currentPathname = window.location.pathname;
    let targetPathname = '';
    let targetHash = '';

    if (to.startsWith('#')) {
      targetPathname = currentPathname;
      targetHash = to;
    } else {
      const [rawPath, rawHash] = to.split('#');
      targetPathname = rawPath || '/';
      if (!targetPathname.startsWith('/')) {
        targetPathname = '/' + targetPathname;
      }
      targetHash = rawHash ? `#${rawHash}` : '';
    }

    const nextFullPath = targetPathname + targetHash;
    const isPathChange = targetPathname !== currentPathname;

    // Update browser history
    if (options?.replace) {
      window.history.replaceState({}, '', nextFullPath);
    } else if (nextFullPath !== (window.location.pathname + window.location.hash)) {
      window.history.pushState({}, '', nextFullPath);
    }

    // Update React state
    setFullPath(nextFullPath);

    if (targetHash) {
      // Locate matching element and scroll with sticky header offset once rendered
      scrollToHash(targetHash);
    } else if (isPathChange) {
      // Scroll to top when changing paths without a hash
      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      window.scrollTo({ top: 0, behavior: prefersReducedMotion ? 'auto' : 'instant' });
    }
  }, []);

  const cleanPathname = fullPath.split('#')[0] || '/';
  const cleanHash = fullPath.includes('#') ? `#${fullPath.split('#')[1]}` : '';

  return (
    <RouterContext.Provider value={{ 
      path: fullPath, 
      pathname: cleanPathname, 
      hash: cleanHash, 
      navigate 
    }}>
      {children}
    </RouterContext.Provider>
  );
};

export interface LinkProps extends React.AnchorHTMLAttributes<HTMLAnchorElement> {
  to: string;
  replace?: boolean;
  children: ReactNode;
}

export const Link: React.FC<LinkProps> = ({ to, replace, children, onClick, className, ...props }) => {
  const { navigate, path } = useRouter();

  const handleClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.altKey || e.shiftKey) {
      return;
    }
    e.preventDefault();
    if (onClick) onClick(e);
    navigate(to, { replace });
  };

  const cleanCurrentPath = path.split('#')[0] || '/';
  const cleanTargetPath = to.split('#')[0] || '/';
  const isCurrent = path === to || (to !== '/' && (cleanCurrentPath === cleanTargetPath || (cleanTargetPath !== '/' && cleanCurrentPath.startsWith(cleanTargetPath))));

  return (
    <a
      href={to}
      onClick={handleClick}
      aria-current={isCurrent ? 'page' : undefined}
      className={className}
      {...props}
    >
      {children}
    </a>
  );
};
