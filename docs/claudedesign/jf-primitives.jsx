// jf-primitives.jsx — JejuFlow shared interactive primitives

const { useState, useEffect, useRef, useMemo } = React;

// ─────────────────────────────────────────────────────────────
// Spring-y motion: animate a number toward a target on each rAF
// ─────────────────────────────────────────────────────────────
function useSpring(target, { stiffness = 0.18, damping = 0.78 } = {}) {
  const [val, setVal] = useState(target);
  const stateRef = useRef({ pos: target, vel: 0 });
  const targetRef = useRef(target);
  useEffect(() => { targetRef.current = target; }, [target]);
  useEffect(() => {
    let raf;
    const step = () => {
      const s = stateRef.current;
      const f = (targetRef.current - s.pos) * stiffness;
      s.vel = (s.vel + f) * damping;
      s.pos = s.pos + s.vel;
      if (Math.abs(targetRef.current - s.pos) < 0.001 && Math.abs(s.vel) < 0.001) {
        s.pos = targetRef.current;
        setVal(s.pos);
        return;
      }
      setVal(s.pos);
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, stiffness, damping]);
  return val;
}

// ─────────────────────────────────────────────────────────────
// Color blender (hex → mixed hex)
// ─────────────────────────────────────────────────────────────
function hexToRgb(h) {
  const c = h.replace('#','');
  return [parseInt(c.slice(0,2),16), parseInt(c.slice(2,4),16), parseInt(c.slice(4,6),16)];
}
function rgbToHex([r,g,b]) {
  const h = n => Math.round(Math.max(0, Math.min(255, n))).toString(16).padStart(2,'0');
  return '#' + h(r) + h(g) + h(b);
}
function mix(a, b, t) {
  const A = hexToRgb(a), B = hexToRgb(b);
  return rgbToHex([A[0]+(B[0]-A[0])*t, A[1]+(B[1]-A[1])*t, A[2]+(B[2]-A[2])*t]);
}

// ─────────────────────────────────────────────────────────────
// Status bar — minimal, ink-colored
// ─────────────────────────────────────────────────────────────
const StatusBar = ({ ink = EG.ink }) => (
  <div style={{ height: 44, padding: '0 24px', display: 'flex', alignItems: 'center',
    justifyContent: 'space-between', fontFamily: FONT_BODY, fontSize: 14, fontWeight: 600,
    color: ink, letterSpacing: '-0.01em', flexShrink: 0 }}>
    <span>9:41</span>
    <span style={{ display: 'inline-flex', gap: 5, alignItems: 'center' }}>
      <svg width="16" height="10" viewBox="0 0 16 10"><path d="M1 7 L4 4 L7 7 L13 1" fill="none" stroke={ink} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/></svg>
      <span style={{ fontSize: 11, fontWeight: 600 }}>5G</span>
      <svg width="22" height="10" viewBox="0 0 22 10"><rect x="0.5" y="0.5" width="18" height="9" rx="2" fill="none" stroke={ink} strokeOpacity="0.5"/><rect x="2" y="2" width="14" height="6" rx="1" fill={ink}/><rect x="19.5" y="3.5" width="1.5" height="3" rx="0.5" fill={ink} opacity="0.5"/></svg>
    </span>
  </div>
);

// ─────────────────────────────────────────────────────────────
// Tab dock — pill-shaped indicator slides between tabs
// ─────────────────────────────────────────────────────────────
const TabDock = ({ active, t, onTab }) => {
  const tabs = [
    { id: 'home', label: t.home, icon: 'home' },
    { id: 'explore', label: t.explore, icon: 'explore' },
    { id: 'route', label: t.route, icon: 'route' },
    { id: 'settings', label: t.settings, icon: 'settings' },
  ];
  const idx = tabs.findIndex(x => x.id === active);
  const x = useSpring(idx);
  return (
    <div style={{
      position: 'absolute', bottom: 14, left: '50%', transform: 'translateX(-50%)',
      width: 340, height: 64, padding: 6,
      background: 'rgba(28,28,24,0.92)',
      backdropFilter: 'blur(20px) saturate(150%)',
      WebkitBackdropFilter: 'blur(20px) saturate(150%)',
      borderRadius: 999, display: 'flex',
      boxShadow: '0 18px 40px rgba(28,28,24,0.18), 0 2px 0 rgba(255,255,255,0.04) inset',
      fontFamily: FONT_BODY,
      zIndex: 50,
    }}>
      {/* sliding pill */}
      <div style={{
        position: 'absolute', top: 6, left: 6,
        width: (340 - 12) / 4, height: 52, borderRadius: 999,
        background: EG.surface, transform: `translateX(${x * (340 - 12) / 4}px)`,
        transition: 'background 0.2s',
      }} />
      {tabs.map((tab, i) => {
        const isActive = i === idx;
        return (
          <div key={tab.id} onClick={() => onTab(tab.id)}
            style={{
              position: 'relative', flex: 1, display: 'flex', alignItems: 'center',
              justifyContent: 'center', gap: 6, cursor: 'pointer',
              color: isActive ? EG.ink : 'rgba(252,249,242,0.62)',
              fontSize: 12, fontWeight: 600, letterSpacing: '-0.01em',
              transition: 'color 0.2s',
            }}>
            <DockIcon kind={tab.icon} active={isActive} />
            {isActive && <span>{tab.label}</span>}
          </div>
        );
      })}
    </div>
  );
};

const DockIcon = ({ kind, active }) => {
  const c = active ? EG.ink : 'rgba(252,249,242,0.62)';
  const sw = 1.6;
  if (kind === 'home') return <svg width="18" height="18" viewBox="0 0 20 20"><path d="M3 9 L10 3 L17 9 V17 H12 V12 H8 V17 H3 Z" fill="none" stroke={c} strokeWidth={sw} strokeLinejoin="round"/></svg>;
  if (kind === 'explore') return <svg width="18" height="18" viewBox="0 0 20 20"><circle cx="9" cy="9" r="6" fill="none" stroke={c} strokeWidth={sw}/><line x1="13.5" y1="13.5" x2="17" y2="17" stroke={c} strokeWidth={sw} strokeLinecap="round"/></svg>;
  if (kind === 'route') return <svg width="18" height="18" viewBox="0 0 20 20"><circle cx="5" cy="5" r="2" fill="none" stroke={c} strokeWidth={sw}/><circle cx="15" cy="15" r="2" fill="none" stroke={c} strokeWidth={sw}/><path d="M5 7 Q 5 14 10 14 Q 15 14 15 13" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/></svg>;
  if (kind === 'settings') return <svg width="18" height="18" viewBox="0 0 20 20"><line x1="3" y1="6" x2="17" y2="6" stroke={c} strokeWidth={sw} strokeLinecap="round"/><line x1="3" y1="14" x2="17" y2="14" stroke={c} strokeWidth={sw} strokeLinecap="round"/><circle cx="13" cy="6" r="2" fill={EG.surface} stroke={c} strokeWidth={sw}/><circle cx="7" cy="14" r="2" fill={EG.surface} stroke={c} strokeWidth={sw}/></svg>;
  return null;
};

// ─────────────────────────────────────────────────────────────
// Pill chip
// ─────────────────────────────────────────────────────────────
const Chip = ({ children, active, kind = 'default', onClick, style = {} }) => {
  const styles = {
    default: { bg: active ? EG.ink : EG.surfaceLow, fg: active ? EG.surface : EG.ink2, border: 'transparent' },
    primary: { bg: active ? EG.primary : EG.primaryC, fg: active ? '#fff' : EG.onPrimaryC, border: 'transparent' },
    secondary: { bg: active ? EG.secondary : EG.secondaryC, fg: active ? '#fff' : EG.onSecondaryC, border: 'transparent' },
    tertiary: { bg: active ? EG.tertiary : EG.tertiaryC, fg: active ? '#fff' : EG.onTertiaryC, border: 'transparent' },
    outline: { bg: 'transparent', fg: EG.ink, border: EG.outlineV },
  }[kind];
  return (
    <span onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 6, height: 30, padding: '0 14px',
      borderRadius: 999, fontSize: 12, fontWeight: 600, letterSpacing: '0.02em',
      background: styles.bg, color: styles.fg,
      border: `1px solid ${styles.border === 'transparent' ? styles.bg : styles.border}`,
      fontFamily: FONT_BODY, cursor: onClick ? 'pointer' : 'default',
      whiteSpace: 'nowrap', userSelect: 'none', transition: 'background 0.15s, color 0.15s',
      ...style,
    }}>{children}</span>
  );
};

// ─────────────────────────────────────────────────────────────
// Pill button — primary / secondary / tertiary / ghost
// ─────────────────────────────────────────────────────────────
const PillButton = ({ children, onClick, kind = 'primary', size = 'md', style = {}, leading, trailing }) => {
  const k = {
    primary: { bg: EG.primary, fg: '#fff' },
    secondary: { bg: EG.secondary, fg: '#fff' },
    tertiary: { bg: EG.tertiary, fg: '#fff' },
    ghost: { bg: EG.surfaceCt, fg: EG.ink },
    outline: { bg: 'transparent', fg: EG.ink, border: `1px solid ${EG.outlineV}` },
    inverse: { bg: EG.inverseSurface, fg: EG.inverseOnSurface },
  }[kind];
  const s = { md: { h: 48, fs: 14, px: 22 }, sm: { h: 36, fs: 12, px: 16 }, lg: { h: 56, fs: 16, px: 28 } }[size];
  return (
    <button onClick={onClick} style={{
      height: s.h, padding: `0 ${s.px}px`, borderRadius: 999, border: k.border || 'none',
      background: k.bg, color: k.fg, fontFamily: FONT_BODY, fontSize: s.fs, fontWeight: 600,
      letterSpacing: '-0.005em', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      transition: 'transform 0.12s, background 0.15s', whiteSpace: 'nowrap',
      ...style,
    }} onMouseDown={e => e.currentTarget.style.transform = 'scale(0.97)'}
       onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
       onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>
      {leading}{children}{trailing}
    </button>
  );
};

// ─────────────────────────────────────────────────────────────
// Spot photo — placeholder with stripe + monospace label
// ─────────────────────────────────────────────────────────────
const SpotImg = ({ spot, height = 120, radius = 24, style = {} }) => {
  const tone = {
    coast:  { bg: '#cdd9e0', stripe: '#b8c5cd' },
    oreum:  { bg: '#cad6c4', stripe: '#b3c0ad' },
    olle:   { bg: '#d2dac6', stripe: '#bdc6af' },
    museum: { bg: '#e3ddd2', stripe: '#d0c9bc' },
    cafe:   { bg: '#ebbca7', stripe: '#dcaa92' },
  }[spot.kind] || { bg: '#dcdad3', stripe: '#c5c7c2' };
  return (
    <div style={{
      position: 'relative', width: '100%', height, borderRadius: radius, overflow: 'hidden',
      background: tone.bg,
      backgroundImage: `repeating-linear-gradient(135deg, ${tone.stripe} 0 1px, transparent 1px 14px)`,
      ...style,
    }}>
      <span style={{
        position: 'absolute', left: 12, bottom: 10, fontFamily: FONT_MONO,
        fontSize: 9, color: 'rgba(28,28,24,0.55)', letterSpacing: '0.04em',
      }}>·· {spot.id}</span>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// Live bus ticker — counts down
// ─────────────────────────────────────────────────────────────
const BusTicker = ({ minutes, line, lang = 'ko' }) => {
  const [m, setM] = useState(minutes);
  const [dot, setDot] = useState(true);
  useEffect(() => { setM(minutes); }, [minutes]);
  useEffect(() => {
    const blink = setInterval(() => setDot(d => !d), 700);
    return () => clearInterval(blink);
  }, []);
  const t = I18N[lang];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontFamily: FONT_MONO,
      fontSize: 12, color: EG.ink, fontWeight: 500 }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: EG.tertiary,
        opacity: dot ? 1 : 0.25, transition: 'opacity 0.3s' }} />
      {t.busLine(line)} · {m} {t.busIn}
    </span>
  );
};

// ─────────────────────────────────────────────────────────────
// Map background — Jeju silhouette + spot dots
// ─────────────────────────────────────────────────────────────
const JejuMap = ({ spots = SPOTS, weather, highlightId, onPickSpot, dim = 0.5, showRoute, route = [] }) => {
  const w = WEATHERS[weather];
  const seaTint = mix(EG.surfaceCt, w.tint, 0.18);
  return (
    <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice"
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', display: 'block' }}>
      <defs>
        <radialGradient id="seaGrad" cx="50%" cy="50%" r="60%">
          <stop offset="0%" stopColor={EG.surface} />
          <stop offset="100%" stopColor={seaTint} />
        </radialGradient>
        <pattern id="seaTex" width="3" height="3" patternUnits="userSpaceOnUse" patternTransform="rotate(35)">
          <line x1="0" y1="1" x2="3" y2="1" stroke={EG.outlineV} strokeWidth="0.15" opacity="0.6"/>
        </pattern>
      </defs>
      <rect x="0" y="0" width="100" height="100" fill="url(#seaGrad)" opacity={dim} />
      <rect x="0" y="0" width="100" height="100" fill="url(#seaTex)" opacity={dim * 0.5}/>
      {/* Jeju island silhouette — simplified oval */}
      <path d="M 12 40 Q 12 22 30 16 Q 50 8 70 14 Q 88 18 92 38 Q 92 60 80 78 Q 60 92 40 90 Q 18 86 12 60 Z"
        fill={EG.primaryC} opacity={0.35} stroke={EG.primaryDim} strokeWidth="0.3"/>
      {/* Hallasan center */}
      <circle cx="50" cy="50" r="8" fill={EG.primaryDim} opacity="0.4" />
      <circle cx="50" cy="50" r="4" fill={EG.primary} opacity="0.4" />
      {/* contour rings */}
      {[14, 22, 30, 38].map(r => (
        <circle key={r} cx="50" cy="50" r={r} fill="none" stroke={EG.outlineV} strokeWidth="0.15" strokeDasharray="0.8 0.8" opacity="0.55"/>
      ))}
      {/* route polyline */}
      {showRoute && route.length > 1 && (
        <polyline
          points={route.map(s => `${s.pos.x},${s.pos.y}`).join(' ')}
          fill="none" stroke={EG.tertiary} strokeWidth="0.7" strokeDasharray="1.2 1" strokeLinecap="round"
        />
      )}
      {/* spots */}
      {spots.map(s => {
        const isOn = highlightId === s.id;
        return (
          <g key={s.id} onClick={onPickSpot ? (e) => { e.stopPropagation(); onPickSpot(s.id); } : undefined}
             style={{ cursor: onPickSpot ? 'pointer' : 'default' }}>
            {isOn && <circle cx={s.pos.x} cy={s.pos.y} r="3.4" fill={EG.tertiary} opacity="0.18">
              <animate attributeName="r" from="2" to="5" dur="1.6s" repeatCount="indefinite"/>
              <animate attributeName="opacity" from="0.4" to="0" dur="1.6s" repeatCount="indefinite"/>
            </circle>}
            <circle cx={s.pos.x} cy={s.pos.y} r={isOn ? 1.8 : 1.2}
              fill={isOn ? EG.tertiary : EG.ink} stroke={EG.surface} strokeWidth="0.4"/>
          </g>
        );
      })}
    </svg>
  );
};

Object.assign(window, {
  useSpring, mix, hexToRgb, rgbToHex,
  StatusBar, TabDock, Chip, PillButton, SpotImg, BusTicker, JejuMap,
});
