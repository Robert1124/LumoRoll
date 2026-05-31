// lutroll-components.jsx — shared building blocks

const { useEffect, useState, useRef, useLayoutEffect } = React;

/* ──────────────────────────────────────────────
   Icons — minimal, rounded, friendly
   ────────────────────────────────────────────── */
const Icon = {
  plus: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 22} height={p.s || 22} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.7" strokeLinecap="round">
      <path d="M12 5v14M5 12h14"/>
    </svg>
  ),
  close: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 18} height={p.s || 18} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.8" strokeLinecap="round">
      <path d="M6 6l12 12M18 6L6 18"/>
    </svg>
  ),
  back: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 20} height={p.s || 20} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 5l-7 7 7 7"/>
    </svg>
  ),
  share: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 20} height={p.s || 20} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4v12M8 8l4-4 4 4M5 14v4a2 2 0 002 2h10a2 2 0 002-2v-4"/>
    </svg>
  ),
  download: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 20} height={p.s || 20} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4v12M8 12l4 4 4-4M5 18v1a2 2 0 002 2h10a2 2 0 002-2v-1"/>
    </svg>
  ),
  more: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 20} height={p.s || 20} fill="currentColor">
      <circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/>
    </svg>
  ),
  search: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 18} height={p.s || 18} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.7" strokeLinecap="round">
      <circle cx="11" cy="11" r="6"/><path d="M20 20l-3.5-3.5"/>
    </svg>
  ),
  photo: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 22} height={p.s || 22} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="3"/>
      <circle cx="9" cy="10.5" r="1.5"/>
      <path d="M3 17l5-5 4 4 3-3 6 6"/>
    </svg>
  ),
  film: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 22} height={p.s || 22} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.6" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2"/>
      <path d="M3 9h2M3 12h2M3 15h2M19 9h2M19 12h2M19 15h2"/>
      <rect x="7" y="8" width="10" height="8" rx="1.2"/>
    </svg>
  ),
  sparkle: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 18} height={p.s || 18} fill={p.c || "currentColor"}>
      <path d="M12 2c.4 4.6 2.4 6.6 7 7-4.6.4-6.6 2.4-7 7-.4-4.6-2.4-6.6-7-7 4.6-.4 6.6-2.4 7-7z"/>
      <path d="M19 14c.2 2 1 2.8 3 3-2 .2-2.8 1-3 3-.2-2-1-2.8-3-3 2-.2 2.8-1 3-3z" opacity=".7"/>
    </svg>
  ),
  check: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 18} height={p.s || 18} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12.5l4 4 10-10"/>
    </svg>
  ),
  cube: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 20} height={p.s || 20} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.6" strokeLinejoin="round">
      <path d="M12 3l8 4.5v9L12 21l-8-4.5v-9L12 3z"/>
      <path d="M4 7.5L12 12l8-4.5M12 12v9"/>
    </svg>
  ),
  swap: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 18} height={p.s || 18} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 8h13l-3-3M20 16H7l3 3"/>
    </svg>
  ),
  upload: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 22} height={p.s || 22} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 16v2a2 2 0 002 2h10a2 2 0 002-2v-2M12 14V4M8 8l4-4 4 4"/>
    </svg>
  ),
  hash: (p) => (
    <svg viewBox="0 0 24 24" width={p.s || 16} height={p.s || 16} fill="none"
         stroke={p.c || "currentColor"} strokeWidth="1.6" strokeLinecap="round">
      <path d="M9 4L7 20M17 4l-2 16M4 9h16M3 15h16"/>
    </svg>
  ),
};

/* ──────────────────────────────────────────────
   Buttons & pills
   ────────────────────────────────────────────── */
function PillButton({ children, onClick, variant = "ink", size = "md", style, leading, trailing, full }) {
  const sizes = {
    sm: { h: 32, px: 12, fs: 13, gap: 6 },
    md: { h: 44, px: 18, fs: 14.5, gap: 8 },
    lg: { h: 54, px: 22, fs: 16, gap: 10 },
  };
  const s = sizes[size];
  const variants = {
    ink: { bg: "var(--ink-900)", color: "var(--cream-50)", border: "transparent" },
    cream: { bg: "var(--cream-50)", color: "var(--ink-900)", border: "var(--hairline-strong)" },
    ghost: { bg: "transparent", color: "var(--ink-900)", border: "var(--hairline-strong)" },
    accent: { bg: "var(--peach)", color: "#2A1810", border: "transparent" },
  };
  const v = variants[variant];
  return (
    <button onClick={onClick} style={{
      height: s.h, paddingLeft: s.px, paddingRight: s.px,
      borderRadius: 999, background: v.bg, color: v.color,
      border: `1px solid ${v.border}`,
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: s.gap,
      fontSize: s.fs, fontWeight: 500, letterSpacing: "-0.005em",
      width: full ? "100%" : undefined,
      boxShadow: variant === "ink" ? "0 1px 0 rgba(255,255,255,0.08) inset, 0 6px 18px -8px rgba(31,26,20,0.45)" :
                  variant === "accent" ? "0 1px 0 rgba(255,255,255,0.4) inset, 0 6px 18px -8px rgba(232,155,122,0.6)" :
                  "var(--shadow-pill)",
      transition: "transform .12s ease, box-shadow .2s ease",
      ...style,
    }}>
      {leading}
      <span>{children}</span>
      {trailing}
    </button>
  );
}

function IconButton({ children, onClick, size = 44, bg = "rgba(31,26,20,0.04)", color = "var(--ink-900)", border = "var(--hairline)", style }) {
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: 999, background: bg, color,
      border: `1px solid ${border}`,
      display: "inline-flex", alignItems: "center", justifyContent: "center",
      ...style,
    }}>{children}</button>
  );
}

/* ──────────────────────────────────────────────
   Palette swatches — five tiny circles
   ────────────────────────────────────────────── */
function PaletteRow({ colors, size = 14, gap = 6, animate = false }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap }}>
      {colors.map((c, i) => (
        <div key={i} style={{
          width: size, height: size, borderRadius: "50%", background: c,
          boxShadow: "inset 0 0 0 1px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.35)",
          animation: animate ? `lr-pop-swatch 480ms ${i*80}ms cubic-bezier(.2,.8,.2,1) both` : undefined,
        }}/>
      ))}
    </div>
  );
}

/* ──────────────────────────────────────────────
   Film strip — the heart of the app
   Renders a horizontal scrollable strip with sprocket holes.
   ────────────────────────────────────────────── */
function FilmStrip({
  children, height = 200, dark = false, padding = 18,
  className = "", style = {}, scrollable = true,
}) {
  const bg = dark ? "var(--noir-800)" : "#2A2520";
  const holeBg = dark ? "#0F0C09" : "#0F0C09";
  return (
    <div className={className} style={{
      background: bg, borderRadius: 18, padding: `${padding}px 0`,
      position: "relative", boxShadow: "inset 0 1px 0 rgba(255,255,255,0.05), 0 18px 40px -20px rgba(31,26,20,0.5)",
      ...style,
    }}>
      {/* sprocket dots — top */}
      <div style={{
        position: "absolute", top: 7, left: 12, right: 12, height: 6,
        backgroundImage: `radial-gradient(circle, ${holeBg} 0 2.5px, transparent 3px)`,
        backgroundSize: "16px 6px", backgroundRepeat: "repeat-x",
      }}/>
      {/* sprocket dots — bottom */}
      <div style={{
        position: "absolute", bottom: 7, left: 12, right: 12, height: 6,
        backgroundImage: `radial-gradient(circle, ${holeBg} 0 2.5px, transparent 3px)`,
        backgroundSize: "16px 6px", backgroundRepeat: "repeat-x",
      }}/>
      <div className="lr-no-scrollbar" style={{
        display: "flex", gap: 8, padding: "0 14px", height,
        overflowX: scrollable ? "auto" : "hidden",
        scrollSnapType: scrollable ? "x mandatory" : undefined,
        WebkitOverflowScrolling: "touch",
      }}>
        {children}
      </div>
    </div>
  );
}

/* a frame inside the strip */
function FilmFrame({ src, filter, label, onClick, width = 180, height, snap = true, badge }) {
  return (
    <button onClick={onClick} style={{
      position: "relative", flex: "0 0 auto",
      width, height: height || "100%", borderRadius: 4, overflow: "hidden",
      scrollSnapAlign: snap ? "center" : undefined,
      background: "#0c0a08", cursor: onClick ? "pointer" : "default",
      boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.04)",
    }}>
      <img src={src} alt="" style={{
        width: "100%", height: "100%", objectFit: "cover", display: "block",
        filter: filter || "none",
        transition: "filter .35s ease",
      }}/>
      {label && (
        <div className="lr-mono" style={{
          position: "absolute", bottom: 6, left: 6,
          fontSize: 9, color: "rgba(255,255,255,0.85)",
          background: "rgba(0,0,0,0.45)", padding: "2px 6px", borderRadius: 4,
          letterSpacing: "0.04em",
        }}>{label}</div>
      )}
      {badge && (
        <div className="lr-mono" style={{
          position: "absolute", top: 6, left: 6, fontSize: 9,
          color: "var(--ink-900)", background: "var(--cream-50)", padding: "2px 6px",
          borderRadius: 4, letterSpacing: "0.06em", fontWeight: 500,
        }}>{badge}</div>
      )}
    </button>
  );
}

/* ──────────────────────────────────────────────
   Toast
   ────────────────────────────────────────────── */
function Toast({ message, visible, accent }) {
  return (
    <div style={{
      position: "absolute", left: "50%", bottom: 110,
      transform: `translate(-50%, ${visible ? 0 : 20}px)`,
      opacity: visible ? 1 : 0,
      transition: "all .35s cubic-bezier(.2,.8,.2,1)",
      pointerEvents: "none", zIndex: 70,
    }}>
      <div style={{
        background: "var(--ink-900)", color: "var(--cream-50)",
        padding: "12px 18px", borderRadius: 999,
        display: "flex", alignItems: "center", gap: 10,
        fontSize: 13.5, fontWeight: 500, letterSpacing: "-0.005em",
        boxShadow: "0 18px 40px -10px rgba(0,0,0,0.4)",
      }}>
        <span style={{
          width: 22, height: 22, borderRadius: 999, background: accent || "var(--peach)",
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          color: "#2A1810",
        }}><Icon.check s={14}/></span>
        {message}
      </div>
    </div>
  );
}

Object.assign(window, {
  Icon, PillButton, IconButton, PaletteRow, FilmStrip, FilmFrame, Toast,
});
